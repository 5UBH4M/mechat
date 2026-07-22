import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../theme/theme_controller.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  late Box _userBox;
  late Box _chatBox;
  late Box _settingsBox;
  late Box _outboxBox;
  late Box _secureBox;

  bool _isInitialized = false;

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'HiveService.init() must be called before accessing boxes',
      );
    }
  }

  Future<void> init() async {
    await Hive.initFlutter();

    // Open all non-encrypted boxes in parallel — ~2x faster than sequential
    final results = await Future.wait([
      Hive.openBox(AppConstants.userBoxName),
      Hive.openBox(AppConstants.chatCacheBoxName),
      Hive.openBox(AppConstants.settingsBoxName),
      Hive.openBox(AppConstants.offlineOutboxBoxName),
      Hive.openBox(ThemeController.boxName),
    ]);
    _userBox = results[0];
    _chatBox = results[1];
    _settingsBox = results[2];
    _outboxBox = results[3];

    // Open encrypted box for sensitive key material
    const secureStorage = FlutterSecureStorage();
    String? encryptionKeyBase64;
    bool secureStorageFailed = false;

    try {
      encryptionKeyBase64 = await secureStorage.read(key: '_hive_encryption_key');
    } catch (e) {
      debugPrint('Secure storage read failed (using fallback): $e');
      secureStorageFailed = true;
    }

    List<int> encryptionKey;

    if (encryptionKeyBase64 != null) {
      encryptionKey = base64Url.decode(encryptionKeyBase64);
    } else {
      // Check for legacy key in unencrypted box (migration or fallback)
      final legacyKeyRaw = _settingsBox.get('_hive_encryption_key');
      if (legacyKeyRaw != null) {
        encryptionKey = List<int>.from(legacyKeyRaw as List);
        
        if (!secureStorageFailed) {
          try {
            await secureStorage.write(
              key: '_hive_encryption_key', 
              value: base64Url.encode(encryptionKey)
            );
            await _settingsBox.delete('_hive_encryption_key');
          } catch (e) {
            debugPrint('Secure storage write failed during migration: $e');
          }
        }
      } else {
        encryptionKey = Hive.generateSecureKey();
        
        bool wroteToSecureStorage = false;
        if (!secureStorageFailed) {
          try {
            await secureStorage.write(
              key: '_hive_encryption_key', 
              value: base64Url.encode(encryptionKey)
            );
            wroteToSecureStorage = true;
          } catch (e) {
            debugPrint('Secure storage write failed for new key: $e');
          }
        }

        // If secure storage couldn't be written to, store in settings box
        if (!wroteToSecureStorage) {
          await _settingsBox.put('_hive_encryption_key', encryptionKey);
        }
      }
    }

    try {
      _secureBox = await Hive.openBox(
        'secure_keys_box',
        encryptionCipher: HiveAesCipher(Uint8List.fromList(encryptionKey)),
      );
    } catch (e) {
      debugPrint('Failed to open secure box (likely lost key), resetting: $e');
      await Hive.deleteBoxFromDisk('secure_keys_box');
      _secureBox = await Hive.openBox(
        'secure_keys_box',
        encryptionCipher: HiveAesCipher(Uint8List.fromList(encryptionKey)),
      );
    }

    _isInitialized = true;
  }


  Future<void> saveUser(Map<String, dynamic> userMap) async {
    _checkInitialized();
    await _userBox.put(AppConstants.keyAuthUser, jsonEncode(userMap));
  }

  Map<String, dynamic>? getUser() {
    _checkInitialized();
    final raw = _userBox.get(AppConstants.keyAuthUser);
    if (raw == null) return null;
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  Future<void> clearUser() async {
    await _userBox.delete(AppConstants.keyAuthUser);
  }


  Future<void> saveThemeMode(String mode) async {
    await _settingsBox.put(AppConstants.keyThemeMode, mode);
  }

  String getThemeMode() {
    return _settingsBox.get(AppConstants.keyThemeMode, defaultValue: 'dark')
        as String;
  }

  Future<void> saveCustomTheme(Map<String, dynamic> customThemeMap) async {
    await _settingsBox.put('customTheme', jsonEncode(customThemeMap));
  }

  Map<String, dynamic>? getCustomTheme() {
    final raw = _settingsBox.get('customTheme');
    if (raw == null) return null;
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }


  Future<void> cacheChats(List<Map<String, dynamic>> chats) async {
    await _chatBox.put('chats_list', jsonEncode(chats));
  }

  List<Map<String, dynamic>> getCachedChats() {
    final raw = _chatBox.get('chats_list');
    if (raw == null) return [];
    final list = jsonDecode(raw as String) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> cacheMessages(
    String chatId,
    List<Map<String, dynamic>> messages,
  ) async {
    await _chatBox.put('messages_$chatId', jsonEncode(messages));
  }

  List<Map<String, dynamic>> getCachedMessages(String chatId) {
    final raw = _chatBox.get('messages_$chatId');
    if (raw == null) return [];
    final list = jsonDecode(raw as String) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }


  Future<void> queueOfflineMessage(Map<String, dynamic> message) async {
    final List<Map<String, dynamic>> currentQueue = getOfflineMessagesQueue();
    currentQueue.add(message);
    await _outboxBox.put('queue', jsonEncode(currentQueue));
  }

  List<Map<String, dynamic>> getOfflineMessagesQueue() {
    final raw = _outboxBox.get('queue');
    if (raw == null) return [];
    final list = jsonDecode(raw as String) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> clearOfflineMessagesQueue() async {
    await _outboxBox.delete('queue');
  }


  Future<void> saveE2EKeys(String privateKey, String publicKey) async {
    _checkInitialized();
    await _secureBox.put(AppConstants.keyE2EPrivateKey, privateKey);
    await _secureBox.put(AppConstants.keyE2EPublicKey, publicKey);
  }

  String? getE2EPrivateKey() {
    _checkInitialized();
    return _secureBox.get(AppConstants.keyE2EPrivateKey) as String?;
  }

  String? getE2EPublicKey() {
    _checkInitialized();
    return _secureBox.get(AppConstants.keyE2EPublicKey) as String?;
  }


  Future<void> saveChatWallpaper(String path) async {
    await _settingsBox.put('chat_wallpaper_path', path);
  }

  String? getChatWallpaper() {
    return _settingsBox.get('chat_wallpaper_path') as String?;
  }

  Future<void> removeChatWallpaper() async {
    await _settingsBox.delete('chat_wallpaper_path');
  }

  // Clear all caches on logout
  Future<void> clearAllCache() async {
    await _userBox.clear();
    await _chatBox.clear();
    await _outboxBox.clear();
    await _secureBox.clear();
    
    // Purge encryption key
    const secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: '_hive_encryption_key');
    // Keep settings (like theme)
  }
}
