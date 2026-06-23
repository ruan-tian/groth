import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/encryption_service.dart';

class AiConfigRepository {
  AiConfigRepository(this._db);

  final AppDatabase _db;

  Future<int> insertAiConfig(AiConfigsCompanion config) async {
    final encryptedConfig = config.copyWith(
      apiKey: Value(await EncryptionService.encryptSecret(config.apiKey.value)),
    );
    return _db.into(_db.aiConfigs).insert(encryptedConfig);
  }

  Future<void> updateAiConfig(AiConfigsCompanion config) async {
    final encryptedConfig = config.copyWith(
      apiKey: Value(await EncryptionService.encryptSecret(config.apiKey.value)),
    );
    final id = config.id.value;
    await (_db.update(
      _db.aiConfigs,
    )..where((t) => t.id.equals(id))).write(encryptedConfig);
  }

  Future<void> deleteAiConfig(int id) async {
    await (_db.delete(_db.aiConfigs)..where((t) => t.id.equals(id))).go();
  }

  Future<List<AiConfig>> getAllAiConfigs() async {
    final configs = await _db.select(_db.aiConfigs).get();
    final decrypted = <AiConfig>[];
    for (final config in configs) {
      decrypted.add(await _decryptAndMigrate(config));
    }
    return decrypted;
  }

  Future<AiConfig?> getEnabledAiConfig() async {
    final config =
        await (_db.select(_db.aiConfigs)
              ..where((t) => t.enabled.equals(true))
              ..limit(1))
            .getSingleOrNull();
    if (config == null) return null;
    return _decryptAndMigrate(config);
  }

  Future<AiConfig> _decryptAndMigrate(AiConfig config) async {
    final decoded = await EncryptionService.decodeSecret(config.apiKey);
    if (decoded.shouldMigrate) {
      await (_db.update(
        _db.aiConfigs,
      )..where((t) => t.id.equals(config.id))).write(
        AiConfigsCompanion(
          apiKey: Value(
            await EncryptionService.encryptSecret(decoded.plainText),
          ),
        ),
      );
    }
    return config.copyWith(apiKey: decoded.plainText);
  }
}
