import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/chat_entity.dart';
import 'dao/message_dao.dart';
import 'dao/chat_dao.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  Database? _db;
  String? _dbPath;

  String? get databasePath => _dbPath;

  MessageDao get messageDao => MessageDao(() => database);
  ChatDao get chatDao => ChatDao(() => database);

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
    if (age > maxAge.inMilliseconds) return null;
    return {
      'displayName': row['display_name'],
      'profilePictureUrl': row['profile_picture_url'],
      'isOnline': (row['is_online'] as int) == 1,
      'lastSeen': DateTime.fromMillisecondsSinceEpoch(row['last_seen'] as int),
      'lastSeenVisible': (row['last_seen_visible'] as int) == 1,
      'about': row['about'],
    };
  }

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

  Future<void> insertMessage(MessageEntity msg, String chatId, {bool synced = false}) =>
      messageDao.insertMessage(msg, chatId, synced: synced);

  Future<void> insertMessages(List<MessageEntity> msgs, String chatId, {bool synced = true}) =>
      messageDao.insertMessages(msgs, chatId, synced: synced);

  Future<List<MessageEntity>> getMessages(String chatId, {int limit = 50, int offset = 0}) =>
      messageDao.getMessages(chatId, limit: limit, offset: offset);

  Future<List<MessageEntity>> getAllMessages(String chatId) =>
      messageDao.getAllMessages(chatId);

  Future<int> getMessageCount(String chatId) =>
      messageDao.getMessageCount(chatId);

  Future<DateTime?> getLatestMessageTimestamp(String chatId) =>
      messageDao.getLatestMessageTimestamp(chatId);

  Future<void> updateMessageStatus(String messageId, String status) =>
      messageDao.updateMessageStatus(messageId, status);

  Future<void> updateMessageField(String messageId, Map<String, dynamic> fields) =>
      messageDao.updateMessageField(messageId, fields);

  Future<void> markSynced(String messageId) =>
      messageDao.markSynced(messageId);

  Future<List<MessageEntity>> getUnsyncedMessages() =>
      messageDao.getUnsyncedMessages();

  Future<String?> getUnsyncedChatId(String messageId) =>
      messageDao.getUnsyncedChatId(messageId);

  Future<bool> hasMessage(String messageId) =>
      messageDao.hasMessage(messageId);

  Future<Set<String>> getMessageIds(String chatId) =>
      messageDao.getMessageIds(chatId);

  Future<void> deleteMessage(String messageId) =>
      messageDao.deleteMessage(messageId);

  Future<List<MessageEntity>> searchMessages(String query, {String? chatId}) =>
      messageDao.searchMessages(query, chatId: chatId);

  Future<void> upsertChat(ChatEntity chat) =>
      chatDao.upsertChat(chat);

  Future<List<ChatEntity>> getAllChats() =>
      chatDao.getAllChats();

  Future<ChatEntity?> getChat(String chatId) =>
      chatDao.getChat(chatId);

  Future<void> updateUnreadCounts(String chatId, Map<String, int> counts) =>
      chatDao.updateUnreadCounts(chatId, counts);

  Future<void> updateChatLastMessage(String chatId, MessageEntity msg) =>
      chatDao.updateChatLastMessage(chatId, msg);

  Future<void> deleteChat(String chatId) =>
      chatDao.deleteChat(chatId);
}
