import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class KeyMaterialService {
  KeyMaterialService._();

  static const _fileName = 'growth_os_secret_material.json';
  static const _purpose = 'growth_os_local_secret_v2';
  static Directory? debugDirectoryOverride;
  static Key? _cachedKey;

  static Future<Key> loadOrCreateKey() async {
    final cached = _cachedKey;
    if (cached != null) return cached;

    final dir =
        debugDirectoryOverride ?? await getApplicationSupportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(p.join(dir.path, _fileName));
    final material = await _loadOrCreateMaterial(file);
    final digest = sha256.convert([
      ...utf8.encode(_purpose),
      ...material.salt,
      ...material.keyMaterial,
    ]);
    return _cachedKey = Key(Uint8List.fromList(digest.bytes));
  }

  static void resetForTests({Directory? directory}) {
    debugDirectoryOverride = directory;
    _cachedKey = null;
  }

  static Future<_LocalKeyMaterial> _loadOrCreateMaterial(File file) async {
    if (await file.exists()) {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) {
        final salt = decoded['salt'];
        final keyMaterial = decoded['keyMaterial'];
        if (salt is String && keyMaterial is String) {
          return _LocalKeyMaterial(
            salt: base64Decode(salt),
            keyMaterial: base64Decode(keyMaterial),
          );
        }
      }
    }

    final material = _LocalKeyMaterial(
      salt: _randomBytes(16),
      keyMaterial: _randomBytes(32),
    );
    await file.writeAsString(
      jsonEncode({
        'version': 1,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'salt': base64Encode(material.salt),
        'keyMaterial': base64Encode(material.keyMaterial),
      }),
    );
    return material;
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}

class EncryptionService {
  EncryptionService._();

  static const _v2Prefix = 'v2:';

  static final _legacyKey = Key.fromUtf8('GrowthOS_PetKey_2026_Secure32B!!');
  static final _legacyIv = IV.fromUtf8('GrowthOS_IV_16b!');
  static final _legacyEncrypter = Encrypter(AES(_legacyKey, mode: AESMode.cbc));

  static Future<String> encryptSecret(String plainText) async {
    if (plainText.isEmpty) return plainText;
    final key = await KeyMaterialService.loadOrCreateKey();
    final ivBytes = KeyMaterialService._randomBytes(16);
    final iv = IV(ivBytes);
    final encrypted = Encrypter(
      AES(key, mode: AESMode.cbc),
    ).encrypt(plainText, iv: iv);
    return '$_v2Prefix${base64Encode(ivBytes)}:${encrypted.base64}';
  }

  static Future<String> decryptSecret(String encryptedText) async {
    if (encryptedText.isEmpty) return encryptedText;
    if (isV2CipherText(encryptedText)) {
      return _decryptV2(
        encryptedText,
        await KeyMaterialService.loadOrCreateKey(),
      );
    }
    return _decryptLegacyOrPlain(encryptedText);
  }

  static Future<SecretDecodeResult> decodeSecret(String text) async {
    final plainText = await decryptSecret(text);
    return SecretDecodeResult(
      plainText: plainText,
      shouldMigrate: text.isNotEmpty && !isV2CipherText(text),
    );
  }

  static String encrypt(String plainText) {
    final encrypted = _legacyEncrypter.encrypt(plainText, iv: _legacyIv);
    return encrypted.base64;
  }

  static String decrypt(String encryptedText) {
    if (isV2CipherText(encryptedText)) return encryptedText;
    return _decryptLegacyOrPlain(encryptedText);
  }

  static String maskApiKey(String apiKey) {
    if (apiKey.length <= 8) return '****';
    final prefix = apiKey.substring(0, 3);
    final suffix = apiKey.substring(apiKey.length - 4);
    return '$prefix****$suffix';
  }

  static bool isEncrypted(String text) {
    if (isV2CipherText(text)) return true;
    try {
      final encrypted = Encrypted.fromBase64(text);
      final plain = _legacyEncrypter.decrypt(encrypted, iv: _legacyIv);
      return plain.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static bool isV2CipherText(String text) => text.startsWith(_v2Prefix);

  static String _decryptV2(String encryptedText, Key key) {
    final parts = encryptedText.substring(_v2Prefix.length).split(':');
    if (parts.length != 2) return encryptedText;
    try {
      final iv = IV(base64Decode(parts[0]));
      final encrypted = Encrypted.fromBase64(parts[1]);
      return Encrypter(AES(key, mode: AESMode.cbc)).decrypt(encrypted, iv: iv);
    } catch (_) {
      return '';
    }
  }

  static String _decryptLegacyOrPlain(String encryptedText) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      return _legacyEncrypter.decrypt(encrypted, iv: _legacyIv);
    } catch (_) {
      return encryptedText;
    }
  }
}

class SecretDecodeResult {
  const SecretDecodeResult({
    required this.plainText,
    required this.shouldMigrate,
  });

  final String plainText;
  final bool shouldMigrate;
}

class _LocalKeyMaterial {
  const _LocalKeyMaterial({required this.salt, required this.keyMaterial});

  final Uint8List salt;
  final Uint8List keyMaterial;
}
