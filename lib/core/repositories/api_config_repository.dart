import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../services/encryption_service.dart';

class ApiConfigRepository {
  ApiConfigRepository(this._db);
  final AppDatabase _db;

  Future<ApiConfig?> getConfig(String provider) async {
    final config =
        await (_db.select(_db.apiConfigs)
              ..where((t) => t.provider.equals(provider))
              ..limit(1))
            .getSingleOrNull();
    return _decryptAndMigrate(config);
  }

  Future<ApiConfig?> getActiveWeatherConfig() async {
    final config =
        await (_db.select(_db.apiConfigs)
              ..where((t) => t.isActive.equals(true))
              ..limit(1))
            .getSingleOrNull();
    return _decryptAndMigrate(config);
  }

  Future<void> upsertConfig({
    required String provider,
    String? apiKey,
    String? baseUrl,
    required bool isActive,
  }) async {
    final existing = await getConfig(provider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final encryptedKey = apiKey == null || apiKey.isEmpty
        ? apiKey
        : await EncryptionService.encryptSecret(apiKey);

    if (existing != null) {
      await (_db.update(
        _db.apiConfigs,
      )..where((t) => t.provider.equals(provider))).write(
        ApiConfigsCompanion(
          apiKey: Value(encryptedKey),
          baseUrl: Value(baseUrl),
          isActive: Value(isActive),
          updatedAt: Value(now),
        ),
      );
    } else {
      await _db
          .into(_db.apiConfigs)
          .insert(
            ApiConfigsCompanion(
              provider: Value(provider),
              apiKey: Value(encryptedKey),
              baseUrl: Value(baseUrl),
              isActive: Value(isActive),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }
  }

  Future<List<ApiConfig>> getAllConfigs() async {
    final configs = await (_db.select(
      _db.apiConfigs,
    )..orderBy([(t) => OrderingTerm.asc(t.provider)])).get();
    final decrypted = <ApiConfig>[];
    for (final config in configs) {
      decrypted.add(await _decryptAndMigrate(config) ?? config);
    }
    return decrypted;
  }

  Future<ApiConfig?> _decryptAndMigrate(ApiConfig? config) async {
    if (config == null || config.apiKey == null || config.apiKey!.isEmpty) {
      return config;
    }
    final decoded = await EncryptionService.decodeSecret(config.apiKey!);
    if (decoded.shouldMigrate) {
      await (_db.update(
        _db.apiConfigs,
      )..where((t) => t.id.equals(config.id))).write(
        ApiConfigsCompanion(
          apiKey: Value(
            await EncryptionService.encryptSecret(decoded.plainText),
          ),
        ),
      );
    }
    return config.copyWith(apiKey: Value(decoded.plainText));
  }
}
