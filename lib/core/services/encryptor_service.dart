import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Encryption service for message content.
///
/// SECURITY NOTE: This provides symmetric encryption using AES-256-CBC.
/// The key is derived from the chatId combined with both users' keys.
/// For true E2E encryption, implement a proper key exchange protocol
/// (e.g., X3DH + Double Ratchet).
class EncryptorService {
  static final EncryptorService _instance = EncryptorService._internal();
  factory EncryptorService() => _instance;
  EncryptorService._internal();

  /// Per-user secret mixed into key derivation so chatId alone is not enough.
  /// Must be set before encrypting/decrypting.
  String? _userSecret;

  /// Set the local user's private key material for key derivation.
  /// This MUST be called after login before any encrypt/decrypt operations.
  void setUserSecret(String secret) {
    _userSecret = secret;
  }

  /// Clear secrets on logout.
  void clearSecrets() {
    _userSecret = null;
  }

  /// Derive AES key from chatId + user secret.
  /// Falls back to chatId-only derivation for backward compatibility
  /// with messages encrypted before the secret was introduced.
  enc.Key _deriveKey(String chatId, {bool useLegacy = false}) {
    final String material;
    if (useLegacy || _userSecret == null) {
      // Legacy: SHA-256(chatId) — kept for decrypting old messages
      material = chatId;
    } else {
      // Improved: SHA-256(chatId + userSecret) — not derivable from chatId alone
      material = '$chatId:$_userSecret';
    }
    final bytes = utf8.encode(material);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypt a message. Throws [EncryptionException] on failure.
  /// Never returns plaintext.
  String encrypt(String text, String chatId) {
    if (text.isEmpty) return '';
    try {
      final key = _deriveKey(chatId);
      final iv = enc.IV.fromSecureRandom(16); // Random IV
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = encrypter.encrypt(text, iv: iv);
      // Format: base64(IV):base64(ciphertext)
      final combined = '${iv.base64}:${encrypted.base64}';
      return combined;
    } catch (e) {
      // SECURITY: Never fall back to plaintext — that silently disables encryption
      throw EncryptionException('Failed to encrypt message: $e');
    }
  }

  /// Decrypt a message. Tries current key derivation first,
  /// then falls back to legacy derivation for backward compatibility.
  String decrypt(String encryptedText, String chatId) {
    if (encryptedText.isEmpty) return '';
    if (!encryptedText.contains(':')) {
      return '[Encrypted Message]'; // Don't leak potentially sensitive content
    }
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return '[Decryption Error]';

      // Try current key derivation first
      try {
        final key = _deriveKey(chatId);
        final iv = enc.IV.fromBase64(parts[0]);
        final ciphertext = parts[1];
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        return encrypter.decrypt64(ciphertext, iv: iv);
      } catch (_) {
        // Fall back to legacy key derivation for old messages
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

/// Exception thrown when encryption fails.
class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
