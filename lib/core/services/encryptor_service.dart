import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;


class EncryptorService {
  static final EncryptorService _instance = EncryptorService._internal();
  factory EncryptorService() => _instance;
  EncryptorService._internal();


  String? _userSecret;


  void setUserSecret(String secret) {
    _userSecret = secret;
  }


  void clearSecrets() {
    _userSecret = null;
  }


  enc.Key _deriveKey(String chatId, {bool useLegacy = false}) {
    final String material;
    if (useLegacy || _userSecret == null) {

      material = chatId;
    } else {

      material = '$chatId:$_userSecret';
    }
    final bytes = utf8.encode(material);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }


  String encrypt(String text, String chatId) {
    if (text.isEmpty) return '';
    try {
      final key = _deriveKey(chatId);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = encrypter.encrypt(text, iv: iv);

      final combined = '${iv.base64}:${encrypted.base64}';
      return combined;
    } catch (e) {

      throw EncryptionException('Failed to encrypt message: $e');
    }
  }


  String decrypt(String encryptedText, String chatId) {
    if (encryptedText.isEmpty) return '';
    if (!encryptedText.contains(':')) {
      return '[Encrypted Message]';
    }
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return '[Decryption Error]';


      try {
        final key = _deriveKey(chatId);
        final iv = enc.IV.fromBase64(parts[0]);
        final ciphertext = parts[1];
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        return encrypter.decrypt64(ciphertext, iv: iv);
      } catch (_) {

        final key = _deriveKey(chatId, useLegacy: true);
        final iv = enc.IV.fromBase64(parts[0]);
        final ciphertext = parts[1];
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        return encrypter.decrypt64(ciphertext, iv: iv);
      }
    } catch (e) {
      return '[Decryption Error]';
    }
  }
}


class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
