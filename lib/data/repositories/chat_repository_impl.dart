import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cross_file/cross_file.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/services/encryptor_service.dart';
import '../../core/utils/image_helper.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final EncryptorService _encryptor = EncryptorService();
  final AppDatabase _localDb = AppDatabase.instance;
  final Map<String, StreamController<List<MessageEntity>>> _messageControllers = {};

  Future<void> _emitLocalMessages(String chatId) async {
    final ctrl = _messageControllers[chatId];
    if (ctrl != null && !ctrl.isClosed) {
      final msgs = await _localDb.getAllMessages(chatId);
      ctrl.add(msgs);
    }
  }

  @override
  Future<List<ChatEntity>> getCachedChatsSync() async {
    return _localDb.getAllChats();
  }

  @override
  Stream<List<ChatEntity>> getChats(String uid) {
    final controller = StreamController<List<ChatEntity>>();

    _localDb.getAllChats().then((cached) {
      if (!controller.isClosed) {
        controller.add(cached);
      }
    });

    final firestoreStream = _db
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: uid)
        .snapshots();

    StreamSubscription? sub;
    sub = firestoreStream.listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data != null) {
            final chatModel = ChatModel.fromJson(data);
            final decryptedChat = _decryptChatLastMessage(chatModel);

            if (change.type == DocumentChangeType.removed) {
              await _localDb.deleteChat(decryptedChat.id);
            } else {
              await _localDb.upsertChat(decryptedChat);
            }
          }
        }

        final updatedChats = await _localDb.getAllChats();
        if (!controller.isClosed) {
          controller.add(updatedChats);
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
    final existing = _messageControllers[chatId];
    if (existing != null && !existing.isClosed) {
      existing.close();
    }

    final controller = StreamController<List<MessageEntity>>();
    _messageControllers[chatId] = controller;

    _localDb.getAllMessages(chatId).then((cached) {
      if (!controller.isClosed) {
        controller.add(cached);
      }
    });

    final firestoreStream = _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(150)
        .snapshots();

    StreamSubscription? sub;
    bool isFirstSnapshot = true;
    sub = firestoreStream.listen(
      (snapshot) async {
        bool hasChanges = false;

        if (isFirstSnapshot) {
          isFirstSnapshot = false;
          final localIds = await _localDb.getMessageIds(chatId);
          final newMsgs = <MessageEntity>[];
          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;
            final msgModel = MessageModel.fromJson(data);
            final decryptedMsg = _decryptMessage(msgModel, chatId);
            if (!localIds.contains(decryptedMsg.id)) {
              newMsgs.add(decryptedMsg);
            }
          }
          if (newMsgs.isNotEmpty) {
            await _localDb.insertMessages(newMsgs, chatId, synced: true);
            hasChanges = true;
          }
          final unsynced = await _localDb.getUnsyncedMessages();
          if (unsynced.isNotEmpty) {
            for (final msg in unsynced) {
              await _localDb.updateMessageStatus(msg.id, 'sent');
              await _localDb.markSynced(msg.id);
            }
            hasChanges = true;
          }
        } else {
          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;
            final msgModel = MessageModel.fromJson(data);
            final decryptedMsg = _decryptMessage(msgModel, chatId);

            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              await _localDb.insertMessage(decryptedMsg, chatId, synced: true);
              hasChanges = true;
            } else if (change.type == DocumentChangeType.removed) {
              await _localDb.deleteMessage(decryptedMsg.id);
              hasChanges = true;
            }
          }
        }

        if (hasChanges) {
          await _emitLocalMessages(chatId);
        }
      },
      onError: (err) {
        controller.addError(err);
      },
    );

    controller.onCancel = () {
      sub?.cancel();
      _messageControllers.remove(chatId);
      controller.close();
    };

    return controller.stream;
  }

  MessageEntity _decryptMessage(MessageModel msg, String chatId) {
    String decryptedContent = msg.content;
    String decryptedReplyContent = msg.repliedToMessageContent;

    if (msg.type == 'text' || msg.content.isNotEmpty) {
      try {
        decryptedContent = _encryptor.decrypt(msg.content, chatId);
      } catch (e) {
        decryptedContent = msg.content;
      }
    }

    if (msg.repliedToMessageContent.isNotEmpty) {
      try {
        decryptedReplyContent = _encryptor.decrypt(
          msg.repliedToMessageContent,
          chatId,
        );
      } catch (e) {
        decryptedReplyContent = msg.repliedToMessageContent;
      }
    }

    return msg.copyWith(
      content: decryptedContent,
      repliedToMessageContent: decryptedReplyContent,
    );
  }

  @override
  Future<void> insertLocalMessage(MessageEntity message, String chatId) async {
    final localMsg = MessageEntity(
      id: message.id,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: message.content,
      type: message.type,
      timestamp: message.timestamp,
      status: 'sending',
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      duration: message.duration,
      repliedToMessageId: message.repliedToMessageId,
      repliedToMessageContent: message.repliedToMessageContent,
      reactions: message.reactions,
      starredBy: message.starredBy,
      isForwarded: message.isForwarded,
      localFilePath: message.localFilePath,
    );
    await _localDb.insertMessage(localMsg, chatId, synced: false);
    await _localDb.updateChatLastMessage(chatId, localMsg);
    await _emitLocalMessages(chatId);
  }

  @override
  Future<void> syncMessageToFirestore(MessageEntity message, String chatId) async {
    final encryptedContent = _encryptor.encrypt(message.content, chatId);
    final encryptedReplyContent = message.repliedToMessageContent.isNotEmpty
        ? _encryptor.encrypt(message.repliedToMessageContent, chatId)
        : '';

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
      repliedToMessageContent: encryptedReplyContent,
    );

    try {
      final chatRef = _db.collection(AppConstants.chatsCollection).doc(chatId);
      final msgRef = chatRef
          .collection(AppConstants.messagesCollection)
          .doc(message.id);

      final batch = _db.batch();
      batch.set(msgRef, msgModel.toFirestore());
      batch.set(chatRef, {
        'lastMessage': msgModel.toFirestore(),
        'unreadCounts.${message.receiverId}': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await batch.commit();

      await Future.wait([
        _localDb.updateMessageStatus(message.id, 'sent'),
        _localDb.markSynced(message.id),
      ]);
      await _emitLocalMessages(chatId);
    } catch (e) {
      debugPrint('syncMessageToFirestore failed: $e');
    }
  }

  @override
  Future<void> sendMessage(MessageEntity message, String chatId) async {
    final localMsg = MessageEntity(
      id: message.id,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: message.content,
      type: message.type,
      timestamp: message.timestamp,
      status: 'sending',
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      duration: message.duration,
      repliedToMessageId: message.repliedToMessageId,
      repliedToMessageContent: message.repliedToMessageContent,
      reactions: message.reactions,
      starredBy: message.starredBy,
      isForwarded: message.isForwarded,
      localFilePath: message.localFilePath,
    );
    await _localDb.insertMessage(localMsg, chatId, synced: false);
    await _localDb.updateChatLastMessage(chatId, localMsg);
    await _emitLocalMessages(chatId);

    final encryptedContent = _encryptor.encrypt(message.content, chatId);
    final encryptedReplyContent = message.repliedToMessageContent.isNotEmpty
        ? _encryptor.encrypt(message.repliedToMessageContent, chatId)
        : '';

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
      repliedToMessageContent: encryptedReplyContent,
    );

    try {
      final chatRef = _db.collection(AppConstants.chatsCollection).doc(chatId);
      final msgRef = chatRef
          .collection(AppConstants.messagesCollection)
          .doc(message.id);

      final batch = _db.batch();
      batch.set(msgRef, msgModel.toFirestore());
      batch.set(chatRef, {
        'lastMessage': msgModel.toFirestore(),
        'unreadCounts.${message.receiverId}': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await batch.commit();

      await Future.wait([
        _localDb.updateMessageStatus(message.id, 'sent'),
        _localDb.markSynced(message.id),
      ]);

      final sentMsgLocal = MessageEntity(
        id: localMsg.id,
        senderId: localMsg.senderId,
        receiverId: localMsg.receiverId,
        content: localMsg.content,
        type: localMsg.type,
        timestamp: localMsg.timestamp,
        status: 'sent',
        fileUrl: localMsg.fileUrl,
        fileName: localMsg.fileName,
        fileSize: localMsg.fileSize,
        duration: localMsg.duration,
        repliedToMessageId: localMsg.repliedToMessageId,
        repliedToMessageContent: localMsg.repliedToMessageContent,
      );
      await _localDb.updateChatLastMessage(chatId, sentMsgLocal);
      await _emitLocalMessages(chatId);
    } catch (e) {
      debugPrint('sendMessage failed: $e');
    }
  }

  @override
  Future<void> sendMediaMessage({
    required MessageEntity message,
    required String chatId,
    required String filePath,
    required void Function(double progress) onProgress,
  }) async {
    final localMsg = MessageEntity(
      id: message.id,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: message.content,
      type: message.type,
      timestamp: message.timestamp,
      status: 'sending',
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      duration: message.duration,
      repliedToMessageId: message.repliedToMessageId,
      repliedToMessageContent: message.repliedToMessageContent,
      localFilePath: message.localFilePath,
    );
    await _localDb.insertMessage(localMsg, chatId, synced: false);
    await _localDb.updateChatLastMessage(chatId, localMsg);
    await _emitLocalMessages(chatId);

    try {
      onProgress(0.01);

      String fileUrl = '';

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

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress.clamp(0.01, 0.99));
        });

        final snapshot = await uploadTask;
        fileUrl = await snapshot.ref.getDownloadURL();
      } catch (_) {
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
        content: message.content,
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

      await _localDb.updateMessageField(message.id, {'fileUrl': fileUrl});

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
    await _localDb.updateMessageStatus(messageId, status);
    await _emitLocalMessages(chatId);

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
    try {
      await _db.collection(AppConstants.chatsCollection).doc(chatId).update({
        'typingStatus.$uid': isTyping,
      });
    } catch (e) {
      debugPrint('setTypingStatus failed: $e');
    }
  }

  @override
  Future<void> deleteMessageForMe({
    required String chatId,
    required String messageId,
    required String uid,
  }) async {
    await _localDb.deleteMessage(messageId);
    await _emitLocalMessages(chatId);
  }

  @override
  Future<void> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
  }) async {
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
    await syncToFirestore();
  }

  @override
  Future<void> syncToFirestore() async {
    final unsynced = await _localDb.getUnsyncedMessages();
    if (unsynced.isEmpty) return;

    try {
      final batch = _db.batch();
      for (final localMsg in unsynced) {
        final chatId = await _localDb.getUnsyncedChatId(localMsg.id);
        if (chatId == null) continue;

        final encryptedContent = _encryptor.encrypt(localMsg.content, chatId);
        final encryptedReplyContent = localMsg.repliedToMessageContent.isNotEmpty
            ? _encryptor.encrypt(localMsg.repliedToMessageContent, chatId)
            : '';

        final msgModel = MessageModel(
            id: localMsg.id,
            senderId: localMsg.senderId,
            receiverId: localMsg.receiverId,
            content: encryptedContent,
            type: localMsg.type,
            timestamp: localMsg.timestamp,
            status: 'sent',
            fileUrl: localMsg.fileUrl,
            fileName: localMsg.fileName,
            fileSize: localMsg.fileSize,
            duration: localMsg.duration,
            repliedToMessageId: localMsg.repliedToMessageId,
            repliedToMessageContent: encryptedReplyContent,
        );

        final chatRef = _db.collection(AppConstants.chatsCollection).doc(chatId);
        final msgRef = chatRef
            .collection(AppConstants.messagesCollection)
            .doc(localMsg.id);

        batch.set(msgRef, msgModel.toFirestore());

        batch.set(chatRef, {
          'lastMessage': msgModel.toFirestore(),
          'unreadCounts': {
            localMsg.receiverId: FieldValue.increment(1),
          },
        }, SetOptions(merge: true));

        await Future.wait([
          _localDb.updateMessageStatus(localMsg.id, 'sent'),
          _localDb.markSynced(localMsg.id),
        ]);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('syncOfflineMessages failed: $e');
    }
  }

  @override
  Future<void> pullNewMessages(String chatId) async {
      final latestTimestamp = await _localDb.getLatestMessageTimestamp(chatId);

      Query query = _db
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .collection(AppConstants.messagesCollection)
          .orderBy('timestamp', descending: true);

      if (latestTimestamp != null) {
          query = query.where('timestamp', isGreaterThan: latestTimestamp.toIso8601String());
      }

      final snapshot = await query.get();

      for (final doc in snapshot.docs) {
         final msgModel = MessageModel.fromJson(doc.data() as Map<String, dynamic>);
         final decryptedMsg = _decryptMessage(msgModel, chatId);

         if (!(await _localDb.hasMessage(decryptedMsg.id))) {
             await _localDb.insertMessage(decryptedMsg, chatId, synced: true);
         }
      }
  }

  @override
  Future<List<MessageEntity>> getLocalMessages(String chatId, {int limit = 50, int offset = 0}) async {
    return _localDb.getMessages(chatId, limit: limit, offset: offset);
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

    try {
      if (reaction.isEmpty) {
        await msgRef.update({'reactions.$userId': FieldValue.delete()});
      } else {
        await msgRef.update({'reactions.$userId': reaction});
      }
    } catch (e) {
      debugPrint('addReaction failed: $e');
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

    try {
      if (isStarred) {
        await msgRef.update({
          'starredBy': FieldValue.arrayUnion([userId]),
        });
      } else {
        await msgRef.update({
          'starredBy': FieldValue.arrayRemove([userId]),
        });
      }
    } catch (e) {
      debugPrint('toggleStar failed: $e');
    }
  }
}
