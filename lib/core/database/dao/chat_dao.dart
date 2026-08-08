import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/chat_entity.dart';
import '../../../domain/entities/message_entity.dart';

class ChatDao {
  final Future<Database> Function() _getDatabase;

  ChatDao(this._getDatabase);

  Future<void> upsertChat(ChatEntity chat) async {
    final db = await _getDatabase();
    await db.insert('chats', _chatToRow(chat),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatEntity>> getAllChats() async {
    final db = await _getDatabase();
    final rows = await db.query('chats', orderBy: 'updated_at DESC');
    return rows.map(_rowToChat).toList();
  }

  Future<ChatEntity?> getChat(String chatId) async {
    final db = await _getDatabase();
    final rows = await db.query('chats',
        where: 'id = ?', whereArgs: [chatId], limit: 1);
    if (rows.isEmpty) return null;
    return _rowToChat(rows.first);
  }

  Future<void> updateUnreadCounts(String chatId, Map<String, int> counts) async {
    final db = await _getDatabase();
    await db.update('chats', {'unread_counts': jsonEncode(counts)},
        where: 'id = ?', whereArgs: [chatId]);
  }

  Future<void> updateChatLastMessage(
      String chatId, MessageEntity msg) async {
    final db = await _getDatabase();
    await db.update(
      'chats',
      {
        'last_message_id': msg.id,
        'last_message_content': msg.content,
        'last_message_timestamp': msg.timestamp.millisecondsSinceEpoch,
        'last_message_sender_id': msg.senderId,
        'last_message_receiver_id': msg.receiverId,
        'last_message_type': msg.type,
        'last_message_status': msg.status,
        'last_message_file_url': msg.fileUrl,
        'last_message_file_name': msg.fileName,
        'updated_at': msg.timestamp.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> deleteChat(String chatId) async {
    final db = await _getDatabase();
    await db.delete('messages', where: 'chat_id = ?', whereArgs: [chatId]);
    await db.delete('chats', where: 'id = ?', whereArgs: [chatId]);
  }

  Map<String, dynamic> _chatToRow(ChatEntity chat) {
    final lm = chat.lastMessage;
    return {
      'id': chat.id,
      'participants': jsonEncode(chat.participants),
      'last_message_id': lm?.id ?? '',
      'last_message_content': lm?.content ?? '',
      'last_message_timestamp':
          lm?.timestamp.millisecondsSinceEpoch ?? 0,
      'last_message_sender_id': lm?.senderId ?? '',
      'last_message_receiver_id': lm?.receiverId ?? '',
      'last_message_type': lm?.type ?? 'text',
      'last_message_status': lm?.status ?? '',
      'last_message_file_url': lm?.fileUrl ?? '',
      'last_message_file_name': lm?.fileName ?? '',
      'unread_counts': jsonEncode(chat.unreadCounts),
      'is_notes_to_self': chat.isNotesToSelf ? 1 : 0,
      'disappearing_timer': chat.disappearingTimer,
      'typing_status': jsonEncode(chat.typingStatus),
      'is_connection_established':
          chat.isConnectionEstablished ? 1 : 0,
      'connection_requested_by': chat.connectionRequestedBy,
      'updated_at':
          lm?.timestamp.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    };
  }

  ChatEntity _rowToChat(Map<String, dynamic> row) {
    final lastMsgTs = row['last_message_timestamp'] as int? ?? 0;
    MessageEntity? lastMessage;
    if (lastMsgTs > 0) {
      lastMessage = MessageEntity(
        id: row['last_message_id'] as String? ?? '',
        senderId: row['last_message_sender_id'] as String? ?? '',
        receiverId:
            row['last_message_receiver_id'] as String? ?? '',
        content: row['last_message_content'] as String? ?? '',
        type: row['last_message_type'] as String? ?? 'text',
        timestamp: DateTime.fromMillisecondsSinceEpoch(lastMsgTs),
        status: row['last_message_status'] as String? ?? '',
        fileUrl: row['last_message_file_url'] as String? ?? '',
        fileName: row['last_message_file_name'] as String? ?? '',
      );
    }

    return ChatEntity(
      id: row['id'] as String,
      participants: List<String>.from(
          jsonDecode(row['participants'] as String? ?? '[]')),
      lastMessage: lastMessage,
      unreadCounts: Map<String, int>.from(
          jsonDecode(row['unread_counts'] as String? ?? '{}')),
      isNotesToSelf: (row['is_notes_to_self'] as int? ?? 0) == 1,
      disappearingTimer: row['disappearing_timer'] as int? ?? 0,
      typingStatus: Map<String, bool>.from(
          jsonDecode(row['typing_status'] as String? ?? '{}')),
      isConnectionEstablished:
          (row['is_connection_established'] as int? ?? 1) == 1,
      connectionRequestedBy:
          row['connection_requested_by'] as String? ?? '',
    );
  }
}
