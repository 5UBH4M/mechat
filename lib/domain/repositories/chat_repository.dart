import '../entities/chat_entity.dart';
import '../entities/message_entity.dart';

abstract class ChatRepository {
  Stream<List<ChatEntity>> getChats(String uid);
  Future<List<ChatEntity>> getCachedChatsSync();

  Stream<List<MessageEntity>> getMessages(String chatId);

  Future<void> sendMessage(MessageEntity message, String chatId);

  Future<void> sendMediaMessage({
    required MessageEntity message,
    required String chatId,
    required String filePath,
    required void Function(double progress) onProgress,
  });

  Future<void> updateMessageStatus({
    required String chatId,
    required String messageId,
    required String status,
  });

  Future<void> setTypingStatus({
    required String chatId,
    required String uid,
    required bool isTyping,
  });

  Future<void> deleteMessageForMe({
    required String chatId,
    required String messageId,
    required String uid,
  });

  Future<void> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
  });

  Future<void> syncOfflineMessages();

  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String reaction,
  });

  Future<void> toggleStar({
    required String chatId,
    required String messageId,
    required String userId,
    required bool isStarred,
  });
}
