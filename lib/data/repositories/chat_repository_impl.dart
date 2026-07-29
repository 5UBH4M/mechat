import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  @override
  Future<List<ChatEntity>> getCachedChatsSync() async {
    return _localDb.getAllChats();
  }

  @override
  Stream<List<ChatEntity>> getChats(String uid) {
    final controller = StreamController<List<ChatEntity>>.broadcast();

    // 1. Send cached chats immediately
    _localDb.getAllChats().then((cached) {
      if (!controller.isClosed) {
        controller.add(cached);
      }
    });

    // 2. Stream from Firestore (process docChanges only)
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
    final controller = StreamController<List<MessageEntity>>.broadcast();

    // 1. Load ALL messages from SQLite for this chatId → emit immediately
    _localDb.getAllMessages(chatId).then((cached) {
      if (!controller.isClosed) {
        controller.add(cached);
      }
      _fetchAndSyncNewMessages(chatId, controller);
    });

    // 4. Start Firestore snapshot listener on messages collection for this chat
    final firestoreStream = _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(150)
        .snapshots();

    StreamSubscription? sub;
    sub = firestoreStream.listen(
      (snapshot) async {
        bool hasChanges = false;
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;

          final msgModel = MessageModel.fromJson(data);
          final decryptedMsg = _decryptMessage(msgModel, chatId);

          if (change.type == DocumentChangeType.added) {
            if (!(await _localDb.hasMessage(decryptedMsg.id))) {
              await _localDb.insertMessage(decryptedMsg, chatId, synced: true);
              hasChanges = true;
            }
          } else if (change.type == DocumentChangeType.modified) {
            await _localDb.insertMessage(decryptedMsg, chatId, synced: true);
            hasChanges = true;
          } else if (change.type == DocumentChangeType.removed) {
            await _localDb.deleteMessage(decryptedMsg.id);
            hasChanges = true;
          }
        }

        if (hasChanges && !controller.isClosed) {
          final updatedMessages = await _localDb.getAllMessages(chatId);
          controller.add(updatedMessages);
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
  
  Future<void> _fetchAndSyncNewMessages(String chatId, StreamController<List<MessageEntity>> controller) async {
    // 3. Fetch from Firestore: messages newer than latest local timestamp
    final latestTimestamp = await _localDb.getLatestMessageTimestamp(chatId);
    
    Query query = _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true);
        
    if (latestTimestamp != null) {
        query = query.where('timestamp', isGreaterThan: latestTimestamp.toIso8601String());
    } else {
        query = query.limit(150);
    }
    
    final snapshot = await query.get();
    
    if (snapshot.docs.isNotEmpty) {
        bool hasNew = false;
        for (final doc in snapshot.docs) {
           final msgModel = MessageModel.fromJson(doc.data() as Map<String, dynamic>);
           final decryptedMsg = _decryptMessage(msgModel, chatId);
           
           if (!(await _localDb.hasMessage(decryptedMsg.id))) {
               await _localDb.insertMessage(decryptedMsg, chatId, synced: true);
               hasNew = true;
           }
        }
        
        if (hasNew && !controller.isClosed) {
            final updatedMessages = await _localDb.getAllMessages(chatId);
            controller.add(updatedMessages);
        }
    }
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
  Future<void> sendMessage(MessageEntity message, String chatId) async {
    // 1. Insert DECRYPTED message into SQLite
    final localMsg = (message as MessageModel).copyWith(status: 'sending');
    await _localDb.insertMessage(localMsg, chatId, synced: false);
    
    // Update local chat's last message
    await _localDb.updateChatLastMessage(chatId, localMsg);

    // 2. Encrypt content for Firestore
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

      // Chat doc is guaranteed to exist by _initializeChatThread
      batch.update(chatRef, {
        'lastMessage': msgModel.toFirestore(),
        'unreadCounts.${message.receiverId}': FieldValue.increment(1),
      });

      await batch.commit();

      // 4. On success: update SQLite status='sent', synced=1
      await _localDb.updateMessageStatus(message.id, 'sent');
      await _localDb.markSynced(message.id);
      
      final sentMsgLocal = localMsg.copyWith(status: 'sent');
      await _localDb.updateChatLastMessage(chatId, sentMsgLocal);
      
    } catch (e) {
      // 5. On failure: leave in SQLite as synced=0
    }
  }

  @override
  Future<void> sendMediaMessage({
    required MessageEntity message,
    required String chatId,
    required String filePath,
    required void Function(double progress) onProgress,
  }) async {
    // Insert into SQLite first
    final localMsg = (message as MessageModel).copyWith(status: 'sending');
    await _localDb.insertMessage(localMsg, chatId, synced: false);
    await _localDb.updateChatLastMessage(chatId, localMsg);
    
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
        content: message.content,
        type: message.type,
        timestamp: message.timestamp,
        status: 'sent', // Will be set to sent upon successful sendMessage
        fileUrl: fileUrl,
        fileName: message.fileName,
        fileSize: message.fileSize,
        duration: message.duration,
        repliedToMessageId: message.repliedToMessageId,
        repliedToMessageContent: message.repliedToMessageContent,
      );
      
      // Update local db with fileUrl so UI can access it
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
    // Update local SQLite
    await _localDb.updateMessageStatus(messageId, status);
  
    // Update Firestore
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
    await _localDb.deleteMessage(messageId);
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
    await syncToFirestore();
  }
  
  @override
  Future<void> syncToFirestore() async {
    final unsynced = await _localDb.getUnsyncedMessages();
    if (unsynced.isEmpty) return;
    
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
      
      try {
        final chatRef = _db.collection(AppConstants.chatsCollection).doc(chatId);
        final msgRef = chatRef
            .collection(AppConstants.messagesCollection)
            .doc(localMsg.id);

        final chatDoc = await chatRef.get();
        final batch = _db.batch();
        batch.set(msgRef, msgModel.toFirestore());

        if (chatDoc.exists) {
          batch.update(chatRef, {
            'lastMessage': msgModel.toFirestore(),
            'unreadCounts.${localMsg.receiverId}': FieldValue.increment(1),
          });
        } else {
          batch.set(chatRef, {
            'lastMessage': msgModel.toFirestore(),
            'unreadCounts': {
              localMsg.receiverId: FieldValue.increment(1),
            },
            'participants': localMsg.senderId == localMsg.receiverId
                ? [localMsg.senderId]
                : (localMsg.senderId.compareTo(localMsg.receiverId) < 0
                    ? [localMsg.senderId, localMsg.receiverId]
                    : [localMsg.receiverId, localMsg.senderId]),
          });
        }
        await batch.commit();
        
        await _localDb.updateMessageStatus(localMsg.id, 'sent');
        await _localDb.markSynced(localMsg.id);
      } catch (_) {
        // Will retry later
      }
    }
  }
  
  @override
  Future<void> pullNewMessages(String chatId) async {
      // One-time fetch from Firestore of messages newer than latest local
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
    // Update Firestore — the snapshot listener will sync back to local SQLite
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
