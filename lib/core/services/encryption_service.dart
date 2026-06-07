import 'package:encrypt/encrypt.dart';

class EncryptionService {
  EncryptionService._();

  // AES-256 要求 32 字节密钥 (256 bits)
  static final _key = Key.fromUtf8('GrowthOS_PetKey_2026_Secure32B!!'); // 32 bytes
  static final _iv = IV.fromUtf8('GrowthOS_IV_16b!'); // 16 bytes
  static final _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  static String encrypt(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  static String decrypt(String encryptedText) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (_) {
      // 解密失败，可能是明文数据（兼容旧数据）
      return encryptedText;
    }
  }

  static String maskApiKey(String apiKey) {
    if (apiKey.length <= 8) return '****';
    final prefix = apiKey.substring(0, 3);
    final suffix = apiKey.substring(apiKey.length - 4);
    return '$prefix****$suffix';
  }

  static bool isEncrypted(String text) {
    try {
      decrypt(text);
      return true;
    } catch (_) {
      return false;
    }
  }
}
