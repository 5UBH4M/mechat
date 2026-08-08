import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/message_entity.dart';

class MessageDao {
  final Future<Database> Function() _getDatabase;

  MessageDao(this._getDatabase);

  Future<void> insertMessage(MessageEntity msg, String chatId,
      {bool synced = false}) async {
    final db = await _getDatabase();
    await db.insert(
      'messages',
      _messageToRow(msg, chatId, synced),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMessages(
      List<MessageEntity> msgs, String chatId,
      {bool synced = true}) async {
    final db = await _getDatabase();
    final batch = db.batch();
    for (final msg in msgs) {
      batch.insert('messages', _messageToRow(msg, chatId, synced),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<MessageEntity>> getMessages(String chatId,
      {int limit = 50, int offset = 0}) async {
    final db = await _getDatabase();

    final rows = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return rows.reversed.map(_rowToMessage).toList();
  }

  Future<List<MessageEntity>> getAllMessages(String chatId) async {
    final db = await _getDatabase();
    final rows = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(_rowToMessage).toList();
  }

  Future<int> getMessageCount(String chatId) async {
    final db = await _getDatabase();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM messages WHERE chat_id = ?',
      [chatId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<DateTime?> getLatestMessageTimestamp(String chatId) async {
    final db = await _getDatabase();
    final rows = await db.query(
      'messages',
      columns: ['timestamp'],
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(rows.first['timestamp'] as int);
  }

  Future<void> updateMessageStatus(
      String messageId, String status) async {
    final db = await _getDatabase();
    await db.update(
      'messages',
      {'status': status, 'synced': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> updateMessageField(
      String messageId, Map<String, dynamic> fields) async {
    final db = await _getDatabase();
    await db.update('messages', fields,
        where: 'id = ?', whereArgs: [messageId]);
  }

  Future<void> markSynced(String messageId) async {
    final db = await _getDatabase();
    await db.update('messages', {'synced': 1},
        where: 'id = ?', whereArgs: [messageId]);
  }

  Future<List<MessageEntity>> getUnsyncedMessages() async {
    final db = await _getDatabase();
    final rows = await db.query(
      'messages',
      where: 'synced = 0',
      orderBy: 'timestamp ASC',
    );
    return rows.map(_rowToMessage).toList();
  }

  Future<String?> getUnsyncedChatId(String messageId) async {
    final db = await _getDatabase();
    final rows = await db.query('messages',
        columns: ['chat_id'],
        where: 'id = ?',
        whereArgs: [messageId],
        limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['chat_id'] as String?;
  }

  Future<bool> hasMessage(String messageId) async {
    final db = await _getDatabase();
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM messages WHERE id = ?',
      [messageId],
    ));
    return (count ?? 0) > 0;
  }

  Future<Set<String>> getMessageIds(String chatId) async {
    final db = await _getDatabase();
    final rows = await db.query('messages',
        columns: ['id'], where: 'chat_id = ?', whereArgs: [chatId]);
    return rows.map((r) => r['id'] as String).toSet();
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await _getDatabase();
    await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
  }

  Future<List<MessageEntity>> searchMessages(String query,
      {String? chatId}) async {
    final db = await _getDatabase();
    final where =
        chatId != null ? 'chat_id = ? AND content LIKE ?' : 'content LIKE ?';
    final args =
        chatId != null ? [chatId, '%$query%'] : ['%$query%'];
    final rows = await db.query(
      'messages',
      where: where,
      whereArgs: args,
      orderBy: 'timestamp DESC',
      limit: 100,
    );
    return rows.map(_rowToMessage).toList();
  }

  Map<String, dynamic> _messageToRow(
      MessageEntity msg, String chatId, bool synced) {
    return {
      'id': msg.id,
      'chat_id': chatId,
      'sender_id': msg.senderId,
      'receiver_id': msg.receiverId,
      'content': msg.content,
      'type': msg.type,
      'timestamp': msg.timestamp.millisecondsSinceEpoch,
      'status': msg.status,
      'file_url': msg.fileUrl,
      'file_name': msg.fileName,
      'file_size': msg.fileSize,
      'duration': msg.duration,
      'replied_to_message_id': msg.repliedToMessageId,
      'replied_to_message_content': msg.repliedToMessageContent,
      'reactions': jsonEncode(msg.reactions),
      'starred_by': jsonEncode(msg.starredBy),
      'is_forwarded': msg.isForwarded ? 1 : 0,
      'local_file_path': msg.localFilePath,
      'synced': synced ? 1 : 0,
    };
  }

  MessageEntity _rowToMessage(Map<String, dynamic> row) {
    return MessageEntity(
      id: row['id'] as String,
      senderId: row['sender_id'] as String,
      receiverId: row['receiver_id'] as String,
      content: row['content'] as String? ?? '',
      type: row['type'] as String? ?? 'text',
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      status: row['status'] as String? ?? 'sent',
      fileUrl: row['file_url'] as String? ?? '',
      fileName: row['file_name'] as String? ?? '',
      fileSize: row['file_size'] as int? ?? 0,
      duration: row['duration'] as int? ?? 0,
      repliedToMessageId:
          row['replied_to_message_id'] as String? ?? '',
      repliedToMessageContent:
          row['replied_to_message_content'] as String? ?? '',
      reactions: _decodeReactions(row['reactions'] as String?),
      starredBy: _decodeStarredBy(row['starred_by'] as String?),
      isForwarded: (row['is_forwarded'] as int? ?? 0) == 1,
      localFilePath: row['local_file_path'] as String? ?? '',
    );
  }

  Map<String, String> _decodeReactions(String? json) {
    if (json == null || json.isEmpty || json == '{}') return {};
    try {
      return Map<String, String>.from(jsonDecode(json));
    } catch (_) {
      return {};
    }
  }

  List<String> _decodeStarredBy(String? json) {
    if (json == null || json.isEmpty || json == '[]') return [];
    try {
      return List<String>.from(jsonDecode(json));
    } catch (_) {
      return [];
    }
  }
}
