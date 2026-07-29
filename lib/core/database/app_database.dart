import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/chat_entity.dart';

/// Local-first SQLite database. Primary source of truth for messages and chats.
/// Firestore acts as a relay/sync layer, not the source of truth.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  Database? _db;
  String? _dbPath;

  String? get databasePath => _dbPath;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    _dbPath = p.join(dir.path, 'mechat.db');
    return openDatabase(
      _dbPath!,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        content TEXT NOT NULL DEFAULT '',
        type TEXT NOT NULL DEFAULT 'text',
        timestamp INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'sending',
        file_url TEXT DEFAULT '',
        file_name TEXT DEFAULT '',
        file_size INTEGER DEFAULT 0,
        duration INTEGER DEFAULT 0,
        replied_to_message_id TEXT DEFAULT '',
        replied_to_message_content TEXT DEFAULT '',
        reactions TEXT DEFAULT '{}',
        starred_by TEXT DEFAULT '[]',
        is_forwarded INTEGER DEFAULT 0,
        local_file_path TEXT DEFAULT '',
        synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_msg_chat ON messages(chat_id)');
    await db.execute(
        'CREATE INDEX idx_msg_ts ON messages(chat_id, timestamp DESC)');

    await db.execute('''
      CREATE TABLE chats (
        id TEXT PRIMARY KEY,
        participants TEXT NOT NULL DEFAULT '[]',
        last_message_id TEXT DEFAULT '',
        last_message_content TEXT DEFAULT '',
        last_message_timestamp INTEGER DEFAULT 0,
        last_message_sender_id TEXT DEFAULT '',
        last_message_receiver_id TEXT DEFAULT '',
        last_message_type TEXT DEFAULT 'text',
        last_message_status TEXT DEFAULT '',
        last_message_file_url TEXT DEFAULT '',
        last_message_file_name TEXT DEFAULT '',
        unread_counts TEXT DEFAULT '{}',
        is_notes_to_self INTEGER DEFAULT 0,
        disappearing_timer INTEGER DEFAULT 0,
        typing_status TEXT DEFAULT '{}',
        is_connection_established INTEGER DEFAULT 1,
        connection_requested_by TEXT DEFAULT '',
        updated_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_chat_updated ON chats(updated_at DESC)');

    await db.execute('''
      CREATE TABLE user_profiles (
        uid TEXT PRIMARY KEY,
        display_name TEXT DEFAULT '',
        profile_picture_url TEXT DEFAULT '',
        is_online INTEGER DEFAULT 0,
        last_seen INTEGER DEFAULT 0,
        last_seen_visible INTEGER DEFAULT 1,
        about TEXT DEFAULT '',
        fetched_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ==================== Messages ====================

  Future<void> insertMessage(MessageEntity msg, String chatId,
      {bool synced = false}) async {
    final db = await database;
    await db.insert(
      'messages',
      _messageToRow(msg, chatId, synced),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMessages(
      List<MessageEntity> msgs, String chatId,
      {bool synced = true}) async {
    final db = await database;
    final batch = db.batch();
    for (final msg in msgs) {
      batch.insert('messages', _messageToRow(msg, chatId, synced),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<MessageEntity>> getMessages(String chatId,
      {int limit = 50, int offset = 0}) async {
    final db = await database;
    // Query in descending order for pagination, then reverse for display
    final rows = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    // Reverse so oldest is first (chronological order)
    return rows.reversed.map(_rowToMessage).toList();
  }

  Future<List<MessageEntity>> getAllMessages(String chatId) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(_rowToMessage).toList();
  }

  Future<int> getMessageCount(String chatId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM messages WHERE chat_id = ?',
      [chatId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<DateTime?> getLatestMessageTimestamp(String chatId) async {
    final db = await database;
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
    final db = await database;
    await db.update(
      'messages',
      {'status': status, 'synced': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> updateMessageField(
      String messageId, Map<String, dynamic> fields) async {
    final db = await database;
    await db.update('messages', fields,
        where: 'id = ?', whereArgs: [messageId]);
  }

  Future<void> markSynced(String messageId) async {
    final db = await database;
    await db.update('messages', {'synced': 1},
        where: 'id = ?', whereArgs: [messageId]);
  }

  Future<List<MessageEntity>> getUnsyncedMessages() async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'synced = 0',
      orderBy: 'timestamp ASC',
    );
    return rows.map(_rowToMessage).toList();
  }

  Future<String?> getUnsyncedChatId(String messageId) async {
    final db = await database;
    final rows = await db.query('messages',
        columns: ['chat_id'],
        where: 'id = ?',
        whereArgs: [messageId],
        limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['chat_id'] as String?;
  }

  Future<bool> hasMessage(String messageId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM messages WHERE id = ?',
      [messageId],
    ));
    return (count ?? 0) > 0;
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
  }

  Future<List<MessageEntity>> searchMessages(String query,
      {String? chatId}) async {
    final db = await database;
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

  // ==================== Chats ====================

  Future<void> upsertChat(ChatEntity chat) async {
    final db = await database;
    await db.insert('chats', _chatToRow(chat),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatEntity>> getAllChats() async {
    final db = await database;
    final rows = await db.query('chats', orderBy: 'updated_at DESC');
    return rows.map(_rowToChat).toList();
  }

  Future<ChatEntity?> getChat(String chatId) async {
    final db = await database;
    final rows = await db.query('chats',
        where: 'id = ?', whereArgs: [chatId], limit: 1);
    if (rows.isEmpty) return null;
    return _rowToChat(rows.first);
  }

  Future<void> updateUnreadCounts(String chatId, Map<String, int> counts) async {
    final db = await database;
    await db.update('chats', {'unread_counts': jsonEncode(counts)},
        where: 'id = ?', whereArgs: [chatId]);
  }

  Future<void> updateChatLastMessage(
      String chatId, MessageEntity msg) async {
    final db = await database;
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
    final db = await database;
    await db.delete('messages', where: 'chat_id = ?', whereArgs: [chatId]);
    await db.delete('chats', where: 'id = ?', whereArgs: [chatId]);
  }

  // ==================== User Profiles ====================

  Future<void> cacheUserProfile(String uid, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'user_profiles',
      {
        'uid': uid,
        'display_name': data['displayName'] ?? data['display_name'] ?? '',
        'profile_picture_url':
            data['profilePictureUrl'] ?? data['profile_picture_url'] ?? '',
        'is_online': (data['isOnline'] ?? data['is_online'] ?? false) ? 1 : 0,
        'last_seen': data['lastSeen'] is DateTime
            ? (data['lastSeen'] as DateTime).millisecondsSinceEpoch
            : data['last_seen'] ?? 0,
        'last_seen_visible':
            (data['lastSeenVisible'] ?? data['last_seen_visible'] ?? true)
                ? 1
                : 0,
        'about': data['about'] ?? '',
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedProfile(String uid,
      {Duration maxAge = const Duration(minutes: 5)}) async {
    final db = await database;
    final rows = await db.query('user_profiles',
        where: 'uid = ?', whereArgs: [uid], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final fetchedAt = row['fetched_at'] as int;
    final age =
        DateTime.now().millisecondsSinceEpoch - fetchedAt;
    if (age > maxAge.inMilliseconds) return null; // stale
    return {
      'displayName': row['display_name'],
      'profilePictureUrl': row['profile_picture_url'],
      'isOnline': (row['is_online'] as int) == 1,
      'lastSeen': DateTime.fromMillisecondsSinceEpoch(row['last_seen'] as int),
      'lastSeenVisible': (row['last_seen_visible'] as int) == 1,
      'about': row['about'],
    };
  }

  // ==================== Utilities ====================

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('chats');
    await db.delete('user_profiles');
  }

  // ==================== Mapping Helpers ====================

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
