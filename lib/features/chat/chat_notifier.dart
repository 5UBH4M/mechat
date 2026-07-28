import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/service_providers.dart';
import '../../core/utils/local_media_store.dart';
import '../../data/models/message_model.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../auth/auth_notifier.dart';

/// Cached user profile data for chat tiles (display name, avatar, online status)
class UserProfileData {
  final String displayName;
  final String profilePictureUrl;
  final bool isOnline;
  final DateTime lastSeen;
  final bool lastSeenVisible;

  const UserProfileData({
    this.displayName = 'Loading...',
    this.profilePictureUrl = '',
    this.isOnline = false,
    required this.lastSeen,
    this.lastSeenVisible = true,
  });
}

/// Single Firestore stream per user uid, auto-disposed when no widget watches it.
/// Replaces N individual StreamBuilders in HomeScreen chat tiles.
final userProfileProvider = StreamProvider.autoDispose
    .family<UserProfileData, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) {
      return UserProfileData(lastSeen: DateTime.now());
    }
    final data = snapshot.data();
    return UserProfileData(
      displayName: data?['displayName'] ?? 'Unknown User',
      profilePictureUrl: data?['profilePictureUrl'] ?? '',
      isOnline: data?['isOnline'] ?? false,
      lastSeen: (data?['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeenVisible: data?['lastSeenVisible'] ?? true,
    );
  });
});
// 1. Stream Provider for Recent Chats list
final recentChatsProvider = StreamProvider.autoDispose<List<ChatEntity>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;
  if (user == null) return const Stream.empty();

  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.getChats(user.uid);
});

// 2. Stream Provider for Messages in a specific chat
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<MessageEntity>, String>((ref, chatId) {
      final chatRepo = ref.watch(chatRepositoryProvider);

      return chatRepo.getMessages(chatId);
    });

// 4. Pending messages for optimistic UI updates (instant message display)
final pendingMessagesProvider =
    StateProvider<List<MessageEntity>>((_) => []);

// 5. Cached messages for instant display while Firestore loads
final cachedMessagesProvider =
    FutureProvider.family<List<MessageEntity>, String>((ref, chatId) async {
  final hive = ref.watch(hiveServiceProvider);
  final encryptor = ref.watch(encryptorServiceProvider);
  final cachedJsonList = await hive.getCachedMessages(chatId);
  return cachedJsonList.map((json) {
    final model = MessageModel.fromJson(json);
    String content = model.content;
    String replyContent = model.repliedToMessageContent;
    if (model.type == 'text' || model.content.isNotEmpty) {
      try {
        content = encryptor.decrypt(model.content, chatId);
      } catch (_) {
        content = model.content;
      }
    }
    if (model.repliedToMessageContent.isNotEmpty) {
      try {
        replyContent = encryptor.decrypt(model.repliedToMessageContent, chatId);
      } catch (_) {
        replyContent = model.repliedToMessageContent;
      }
    }
    return MessageEntity(
      id: model.id,
      senderId: model.senderId,
      receiverId: model.receiverId,
      content: content,
      type: model.type,
      timestamp: model.timestamp,
      status: model.status,
      fileUrl: model.fileUrl,
      fileName: model.fileName,
      fileSize: model.fileSize,
      duration: model.duration,
      repliedToMessageId: model.repliedToMessageId,
      repliedToMessageContent: replyContent,
      reactions: model.reactions,
      starredBy: model.starredBy,
      isForwarded: model.isForwarded,
    );
  }).toList();
});

// 3. Notifier for sending messages and performing actions
class ChatNotifier extends StateNotifier<double> {
  final ChatRepository _chatRepository;
  final Ref _ref;

  ChatNotifier(this._chatRepository, this._ref)
    : super(0.0) { // State represents upload progress
    loadPersistedPending();
  }

  void loadPersistedPending() {
    final hive = _ref.read(hiveServiceProvider);
    final saved = hive.getPendingMessages();
    if (saved.isEmpty) return;
    
    final messages = saved.map((json) => MessageEntity(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'sending',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      repliedToMessageId: json['repliedToMessageId'] as String? ?? '',
      repliedToMessageContent: json['repliedToMessageContent'] as String? ?? '',
      localFilePath: json['localFilePath'] as String? ?? '',
    )).toList();
    
    final notifier = _ref.read(pendingMessagesProvider.notifier);
    notifier.state = messages;
  }

  String getChatId(String uid1, String uid2) {
    if (uid1 == uid2 || uid2 == 'notes_to_self') return 'notes_$uid1';
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  void _addPending(MessageEntity msg) {
    final notifier = _ref.read(pendingMessagesProvider.notifier);
    notifier.state = [...notifier.state, msg];
    _persistPending();
  }

  void _persistPending() {
    final hive = _ref.read(hiveServiceProvider);
    final pending = _ref.read(pendingMessagesProvider);
    final jsonList = pending.map((m) => {
      'id': m.id,
      'senderId': m.senderId,
      'receiverId': m.receiverId,
      'content': m.content,
      'type': m.type,
      'timestamp': m.timestamp.toIso8601String(),
      'status': m.status,
      'fileUrl': m.fileUrl,
      'fileName': m.fileName,
      'fileSize': m.fileSize,
      'duration': m.duration,
      'repliedToMessageId': m.repliedToMessageId,
      'repliedToMessageContent': m.repliedToMessageContent,
      'localFilePath': m.localFilePath,
    }).toList();
    hive.savePendingMessages(jsonList);
  }

  void _removePending(String messageId) {
    final notifier = _ref.read(pendingMessagesProvider.notifier);
    notifier.state = notifier.state.where((m) => m.id != messageId).toList();
    _persistPending();
  }

  Future<void> sendTextMessage({
    required String receiverId,
    required String content,
    String repliedToMessageId = '',
    String repliedToMessageContent = '',
  }) async {
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;

    final chatId = getChatId(sender.uid, receiverId);
    final message = MessageEntity(
      id: const Uuid().v4(),
      senderId: sender.uid,
      receiverId: receiverId == 'notes_to_self' ? sender.uid : receiverId,
      content: content,
      type: 'text',
      timestamp: DateTime.now(),
      status: 'sending',
      repliedToMessageId: repliedToMessageId,
      repliedToMessageContent: repliedToMessageContent,
    );

    _addPending(message);

    // Fire network call in background — don't block the UI
    _initializeChatThread(chatId, sender.uid, receiverId).then((_) {
      return _chatRepository.sendMessage(message, chatId);
    }).then((_) {
      _removePending(message.id);
    }).catchError((_) {});
  }

  Future<void> sendMessage(MessageEntity message, String receiverId) async {
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;

    final chatId = getChatId(sender.uid, receiverId);
    await _initializeChatThread(chatId, sender.uid, receiverId);
    await _chatRepository.sendMessage(message, chatId);
  }

  Future<void> sendFileMessage({
    required String receiverId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String type, // 'image', 'video', 'audio', 'document'
    int duration = 0,
    String repliedToMessageId = '',
    String repliedToMessageContent = '',
  }) async {
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;

    final chatId = getChatId(sender.uid, receiverId);
    final messageId = const Uuid().v4();

    // Copy to persistent local storage so it survives app restart
    String localPath = filePath;
    if (type == 'image' || type == 'video') {
      try {
        localPath = await LocalMediaStore.saveFile(filePath, messageId, fileName);
      } catch (_) {
        // Fall back to original temp path
      }
    }

    final message = MessageEntity(
      id: messageId,
      senderId: sender.uid,
      receiverId: receiverId == 'notes_to_self' ? sender.uid : receiverId,
      content: '',
      type: type,
      timestamp: DateTime.now(),
      status: 'sending',
      fileName: fileName,
      fileSize: fileSize,
      duration: duration,
      repliedToMessageId: repliedToMessageId,
      repliedToMessageContent: repliedToMessageContent,
      localFilePath: localPath,
    );

    _addPending(message);

    // Reset progress and run upload in background — don't block the caller
    state = 0.0;

    _initializeChatThread(chatId, sender.uid, receiverId).then((_) {
      return _chatRepository.sendMediaMessage(
        message: message,
        chatId: chatId,
        filePath: filePath,
        onProgress: (progress) {
          state = progress;
        },
      );
    }).then((_) {
      _removePending(message.id);
    }).catchError((_) {
      state = -1.0;
      Future.delayed(const Duration(seconds: 3), () {
        if (state == -1.0) state = 0.0;
      });
    });
  }

  Future<void> setTypingStatus(String receiverId, bool isTyping) async {
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;

    final chatId = getChatId(sender.uid, receiverId);
    await _chatRepository.setTypingStatus(
      chatId: chatId,
      uid: sender.uid,
      isTyping: isTyping,
    );
  }

  Future<void> markAsRead(String receiverId, String messageId) async {
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;

    final chatId = getChatId(sender.uid, receiverId);

    final batch = FirebaseFirestore.instance.batch();

    final msgRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);
    batch.update(msgRef, {'status': 'read'});

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    batch.update(chatRef, {'unreadCounts.${sender.uid}': 0});

    await batch.commit();
  }

  Future<void> markAllAsRead(String receiverId, List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;

    final chatId = getChatId(sender.uid, receiverId);
    final batch = FirebaseFirestore.instance.batch();

    for (var msgId in messageIds) {
      final msgRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(msgId);
      batch.update(msgRef, {'status': 'read'});
    }

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    batch.update(chatRef, {'unreadCounts.${sender.uid}': 0});

    await batch.commit();
  }

  Future<void> resetUnreadCount(String receiverId) async {
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;
    final chatId = getChatId(sender.uid, receiverId);
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'unreadCounts.${sender.uid}': 0,
    });
  }

  Future<void> deleteMessageForMe(String receiverId, String messageId) async {
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;

    final chatId = getChatId(sender.uid, receiverId);
    await _chatRepository.deleteMessageForMe(
      chatId: chatId,
      messageId: messageId,
      uid: sender.uid,
    );
  }

  Future<void> deleteMessageForEveryone(
    String receiverId,
    String messageId,
  ) async {
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;

    final chatId = getChatId(sender.uid, receiverId);
    await _chatRepository.deleteMessageForEveryone(
      chatId: chatId,
      messageId: messageId,
    );
  }

  // Helper to ensure firestore has a chat document ready
  static final Set<String> _initializedChats = {};

  Future<void> _initializeChatThread(
    String chatId,
    String senderId,
    String receiverId,
  ) async {
    if (_initializedChats.contains(chatId)) return;

    final isNotes = receiverId == 'notes_to_self' || receiverId == senderId;
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final snap = await chatDoc.get();

    if (!snap.exists) {
      final participants = isNotes ? [senderId] : [senderId, receiverId];
      await chatDoc.set({
        'id': chatId,
        'participants': participants,
        'unreadCounts': {senderId: 0, if (!isNotes) receiverId: 0},
        'typingStatus': {senderId: false, if (!isNotes) receiverId: false},
        'isNotesToSelf': isNotes,
        'lastMessage': null,
      });
    }

    _initializedChats.add(chatId);
  }

  Future<void> syncOffline() async {
    await _chatRepository.syncOfflineMessages();
  }

  Future<void> addReaction(
    String receiverId,
    String messageId,
    String reaction,
  ) async {
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;

    final chatId = getChatId(sender.uid, receiverId);
    await _chatRepository.addReaction(
      chatId: chatId,
      messageId: messageId,
      userId: sender.uid,
      reaction: reaction,
    );
  }

  Future<void> toggleStar(
    String receiverId,
    String messageId,
    bool isStarred,
  ) async {
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;

    final chatId = getChatId(sender.uid, receiverId);
    await _chatRepository.toggleStar(
      chatId: chatId,
      messageId: messageId,
      userId: sender.uid,
      isStarred: isStarred,
    );
  }

  Future<void> forwardMessage(
    MessageEntity originalMessage,
    String newReceiverId,
  ) async {
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;

    final newChatId = getChatId(sender.uid, newReceiverId);
    final forwardedMessage = MessageEntity(
      id: const Uuid().v4(),
      senderId: sender.uid,
      receiverId: newReceiverId == 'notes_to_self' ? sender.uid : newReceiverId,
      content: originalMessage.content,
      type: originalMessage.type,
      timestamp: DateTime.now(),
      status: 'sending',
      fileUrl: originalMessage.fileUrl,
      fileName: originalMessage.fileName,
      fileSize: originalMessage.fileSize,
      duration: originalMessage.duration,
      isForwarded: true,
    );

    await _initializeChatThread(newChatId, sender.uid, newReceiverId);
    await _chatRepository.sendMessage(forwardedMessage, newChatId);
  }
}

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, double>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repo, ref);
});
