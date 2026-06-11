import 'dart:convert';
import 'dart:typed_data'; // Required for Uint8List
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptorService {
  static final EncryptorService _instance = EncryptorService._internal();
  factory EncryptorService() => _instance;
  EncryptorService._internal();

  // Generate AES Key from Chat ID
  enc.Key _deriveKey(String chatId) {
    // Generate a 32-byte key using SHA-256 of the chatId
    final bytes = utf8.encode(chatId);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  // Encrypt a message
  String encrypt(String text, String chatId) {
    if (text.isEmpty) return '';
    try {
      final key = _deriveKey(chatId);
      final iv = enc.IV.fromLength(16); // Random IV
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      
      final encrypted = encrypter.encrypt(text, iv: iv);
      // Combine IV and Ciphertext so IV can be used for decryption
      final combined = '${iv.base64}:${encrypted.base64}';
      return combined;
    } catch (e) {
      return text; // Fallback
    }
  }

  // Decrypt a message
  String decrypt(String encryptedText, String chatId) {
    if (encryptedText.isEmpty) return '';
    if (!encryptedText.contains(':')) return encryptedText; // Fallback if plain text
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return encryptedText;

      final key = _deriveKey(chatId);
      final iv = enc.IV.fromBase64(parts[0]);
      final ciphertext = parts[1];
      
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt64(ciphertext, iv: iv);
      return decrypted;
    } catch (e) {
      return '[Decryption Error]';
    }
  }
}
