import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cross_file/cross_file.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/encryptor_service.dart';
import '../../core/services/hive_service.dart';
import '../../core/utils/image_helper.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final HiveService _hive = HiveService();
  final EncryptorService _encryptor = EncryptorService();

  @override
  Stream<List<ChatEntity>> getChats(String uid) {
    // Return a combined stream of Local Cache (immediate) + Firestore stream
    final controller = StreamController<List<ChatEntity>>.broadcast();

    // 1. Send cached chats immediately
    final cached = _hive.getCachedChats().map((json) {
      final model = ChatModel.fromJson(json);
      return _decryptChatLastMessage(model);
    }).toList();

    // Sort cached chats (Notes to self on top, then by timestamp desc)
    _sortChats(cached);
    controller.add(cached);

    // 2. Stream from Firestore
    final firestoreStream = _db
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: uid)
        .snapshots();

    StreamSubscription? sub;
    sub = firestoreStream.listen(
      (snapshot) async {
        final List<ChatModel> chatModels = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          chatModels.add(ChatModel.fromJson(data));
        }

        // Cache the raw JSON values before decryption
        final rawJsonList = chatModels.map((e) => e.toJson()).toList();
        await _hive.cacheChats(rawJsonList);

        // Decrypt last messages for presentation
        final decryptedList = chatModels.map((model) {
          return _decryptChatLastMessage(model);
        }).toList();

        _sortChats(decryptedList);
        if (!controller.isClosed) {
          controller.add(decryptedList);
        }
      },
      onError: (err) {
        controller.addError(err);
      },
    );

    controller.onCancel = () {
      sub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  void _sortChats(List<ChatEntity> list) {
    list.sort((a, b) {
      // Notes to self always first
      if (a.isNotesToSelf && !b.isNotesToSelf) return -1;
      if (!a.isNotesToSelf && b.isNotesToSelf) return 1;

      final aTime =
          a.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime); // Latest first
    });
  }

  ChatEntity _decryptChatLastMessage(ChatModel chat) {
    if (chat.lastMessage == null) return chat;
    final decryptedContent = _encryptor.decrypt(
      chat.lastMessage!.content,
      chat.id,
    );
    final decryptedMsg = (chat.lastMessage as MessageModel).copyWith(
      content: decryptedContent,
    );
    return chat.copyWith(lastMessage: decryptedMsg);
  }

  @override
  Stream<List<MessageEntity>> getMessages(String chatId) {
    final controller = StreamController<List<MessageEntity>>.broadcast();

    // 1. Emit cached messages immediately
    final cached = _hive.getCachedMessages(chatId).map((json) {
      final model = MessageModel.fromJson(json);
      return _decryptMessage(model, chatId);
    }).toList();
    controller.add(cached);

    // 2. Stream from Firestore
    final firestoreStream = _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots();

    StreamSubscription? sub;
    sub = firestoreStream.listen(
      (snapshot) async {
        final List<MessageModel> messages = [];
        for (final doc in snapshot.docs) {
          messages.add(MessageModel.fromJson(doc.data()));
        }

        // Cache raw message maps
        final rawJsonList = messages.map((e) => e.toJson()).toList();
        await _hive.cacheMessages(chatId, rawJsonList);

        // Decrypt content for UI
        final decryptedList = messages
            .map((m) => _decryptMessage(m, chatId))
            .toList();

        if (!controller.isClosed) {
          controller.add(decryptedList);
        }
      },
      onError: (err) {
        controller.addError(err);
      },
    );

    controller.onCancel = () {
      sub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  MessageEntity _decryptMessage(MessageModel msg, String chatId) {
    String decryptedContent = msg.content;
    String decryptedReplyContent = msg.repliedToMessageContent;

    if (msg.type == 'text' || msg.content.isNotEmpty) {
      decryptedContent = _encryptor.decrypt(msg.content, chatId);
    }

    if (msg.repliedToMessageContent.isNotEmpty) {
      try {
        decryptedReplyContent = _encryptor.decrypt(
          msg.repliedToMessageContent,
          chatId,
        );
      } catch (e) {
        // Fallback in case it wasn't encrypted or failed to decrypt
        decryptedReplyContent = msg.repliedToMessageContent;
      }
    }

    return msg.copyWith(
      content: decryptedContent,
      repliedToMessageContent: decryptedReplyContent,
    );
  }

  @override
  Future<void> sendMessage(MessageEntity message, String chatId) async {
    final encryptedContent = _encryptor.encrypt(message.content, chatId);
    final msgModel = MessageModel(
      id: message.id,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: encryptedContent,
      type: message.type,
      timestamp: message.timestamp,
      status: 'sent',
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      duration: message.duration,
      repliedToMessageId: message.repliedToMessageId,
      repliedToMessageContent: message.repliedToMessageContent.isNotEmpty
          ? _encryptor.encrypt(message.repliedToMessageContent, chatId)
          : '',
    );

    // Check internet connectivity
    // If offline, queue message
    final isOnline = await _isNetworkAvailable();
    if (!isOnline) {
      // Cache with status 'sending'
      final offlineMsg = msgModel.copyWith(status: 'sending');
      await _hive.queueOfflineMessage({
        'chatId': chatId,
        'message': offlineMsg.toJson(),
      });

      // Update local message list cache immediately
      final localMsgs = _hive.getCachedMessages(chatId);
      localMsgs.add(offlineMsg.toJson());
      await _hive.cacheMessages(chatId, localMsgs);
      return;
    }

    // Write to messages subcollection
    final chatRef = _db.collection(AppConstants.chatsCollection).doc(chatId);
    final msgRef = chatRef
        .collection(AppConstants.messagesCollection)
        .doc(message.id);

    final batch = _db.batch();
    batch.set(msgRef, msgModel.toFirestore());

    // Update main chat thread details
    // Increment unread count for recipient
    final updateData = {
      'lastMessage': msgModel.toFirestore(),
      'unreadCounts.${message.receiverId}': FieldValue.increment(1),
    };
    batch.update(chatRef, updateData);

    await batch.commit();
  }

  @override
  Future<void> sendMediaMessage({
    required MessageEntity message,
    required String chatId,
    required String filePath,
    required void Function(double progress) onProgress,
  }) async {
    try {
      onProgress(0.01);

      String fileUrl = '';

      // Try Firebase Storage first for proper file handling
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_media')
            .child(chatId)
            .child('${message.id}_${message.fileName}');

        final UploadTask uploadTask;
        if (kIsWeb) {
          uploadTask = storageRef.putData(
            await XFile(filePath).readAsBytes(),
            SettableMetadata(
              contentType: _getContentType(message.type, message.fileName),
            ),
          );
        } else {
          uploadTask = storageRef.putFile(
            File(filePath),
            SettableMetadata(
              contentType: _getContentType(message.type, message.fileName),
            ),
          );
        }

        // Listen to real upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress.clamp(0.01, 0.99));
        });

        // Wait for upload to complete
        final snapshot = await uploadTask;
        fileUrl = await snapshot.ref.getDownloadURL();
      } catch (_) {
        // Fallback to base64 for images if Storage fails
        if (message.type == 'image') {
          fileUrl = await ImageHelper.convertToBase64(
            filePath,
            maxWidth: 1280,
            quality: 85,
          );
        } else {
          final bytes = kIsWeb
              ? await XFile(filePath).readAsBytes()
              : await File(filePath).readAsBytes();
          fileUrl = 'data:audio/aac;base64,${base64Encode(bytes)}';
        }
      }

      onProgress(1.0);

      final mediaMessage = MessageModel(
        id: message.id,
        senderId: message.senderId,
        receiverId: message.receiverId,
        content: '',
        type: message.type,
        timestamp: message.timestamp,
        status: 'sent',
        fileUrl: fileUrl,
        fileName: message.fileName,
        fileSize: message.fileSize,
        duration: message.duration,
        repliedToMessageId: message.repliedToMessageId,
        repliedToMessageContent: message.repliedToMessageContent,
      );

      await sendMessage(mediaMessage, chatId);
    } catch (e) {
      rethrow;
    }
  }

  String _getContentType(String type, String fileName) {
    switch (type) {
      case 'image':
        if (fileName.endsWith('.png')) return 'image/png';
        if (fileName.endsWith('.gif')) return 'image/gif';
        return 'image/jpeg';
      case 'video':
        return 'video/mp4';
      case 'audio':
        if (fileName.endsWith('.m4a')) return 'audio/mp4';
        return 'audio/mpeg';
      case 'document':
        if (fileName.endsWith('.pdf')) return 'application/pdf';
        return 'application/octet-stream';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Future<void> updateMessageStatus({
    required String chatId,
    required String messageId,
    required String status,
  }) async {
    await _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId)
        .update({'status': status});
  }

  @override
  Future<void> setTypingStatus({
    required String chatId,
    required String uid,
    required bool isTyping,
  }) async {
    await _db.collection(AppConstants.chatsCollection).doc(chatId).update({
      'typingStatus.$uid': isTyping,
    });
  }

  @override
  Future<void> deleteMessageForMe({
    required String chatId,
    required String messageId,
    required String uid,
  }) async {
    // Delete for me: remove message from local cache
    final localList = _hive.getCachedMessages(chatId);
    localList.removeWhere((element) => element['id'] == messageId);
    await _hive.cacheMessages(chatId, localList);
  }

  @override
  Future<void> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
  }) async {
    // Delete for everyone: update Firestore message document
    final docRef = _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId);

    await docRef.update({
      'content': _encryptor.encrypt('This message was deleted', chatId),
      'type': 'text',
      'fileUrl': '',
      'fileName': '',
      'fileSize': 0,
      'duration': 0,
    });
  }

  @override
  Future<void> syncOfflineMessages() async {
    final queue = _hive.getOfflineMessagesQueue();
    if (queue.isEmpty) return;

    for (final item in queue) {
      final chatId = item['chatId'] as String;
      final msgJson = item['message'] as Map<String, dynamic>;
      final msg = MessageModel.fromJson(msgJson);
      try {
        await sendMessage(msg, chatId);
      } catch (_) {
        // Stop syncing if we hit network issues again
        return;
      }
    }
    await _hive.clearOfflineMessagesQueue();
  }

  Future<bool> _isNetworkAvailable() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  @override
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String reaction,
  }) async {
    final msgRef = _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId);

    if (reaction.isEmpty) {
      await msgRef.update({'reactions.$userId': FieldValue.delete()});
    } else {
      await msgRef.update({'reactions.$userId': reaction});
    }
  }

  @override
  Future<void> toggleStar({
    required String chatId,
    required String messageId,
    required String userId,
    required bool isStarred,
  }) async {
    final msgRef = _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId);

    if (isStarred) {
      await msgRef.update({
        'starredBy': FieldValue.arrayUnion([userId]),
      });
    } else {
      await msgRef.update({
        'starredBy': FieldValue.arrayRemove([userId]),
      });
    }
  }
}
