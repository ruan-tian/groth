import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../services/encryption_service.dart';

class AiConfigRepository {
  AiConfigRepository(this._db);

  final AppDatabase _db;

  Future<int> insertAiConfig(AiConfigsCompanion config) {
    final encryptedConfig = config.copyWith(
      apiKey: Value(EncryptionService.encrypt(config.apiKey.value)),
    );
    return _db.into(_db.aiConfigs).insert(encryptedConfig);
  }

  Future<void> updateAiConfig(AiConfigsCompanion config) async {
    final encryptedConfig = config.copyWith(
      apiKey: Value(EncryptionService.encrypt(config.apiKey.value)),
    );
    final id = config.id.value;
    await (_db.update(_db.aiConfigs)..where((t) => t.id.equals(id))).write(
      encryptedConfig,
    );
  }

  Future<void> deleteAiConfig(int id) async {
    await (_db.delete(_db.aiConfigs)..where((t) => t.id.equals(id))).go();
  }

  Future<List<AiConfig>> getAllAiConfigs() async {
    final configs = await _db.select(_db.aiConfigs).get();
    return configs
        .map((c) => c.copyWith(apiKey: EncryptionService.decrypt(c.apiKey)))
        .toList();
  }

  Future<AiConfig?> getEnabledAiConfig() async {
    final config = await (_db.select(_db.aiConfigs)
          ..where((t) => t.enabled.equals(true))
          ..limit(1))
        .getSingleOrNull();
    if (config == null) return null;
    return config.copyWith(apiKey: EncryptionService.decrypt(config.apiKey));
  }
}
