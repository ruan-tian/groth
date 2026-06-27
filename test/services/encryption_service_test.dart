import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/ai/repositories/ai_config_repository.dart';
import 'package:growth_os/features/ai/repositories/api_config_repository.dart';
import 'package:growth_os/core/services/encryption_service.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('growth_os_secret_test_');
    KeyMaterialService.resetForTests(directory: tempDir);
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    KeyMaterialService.resetForTests();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('encryptSecret writes v2 ciphertext and decrypts it', () async {
    final encrypted = await EncryptionService.encryptSecret('sk-test-secret');

    expect(encrypted, startsWith('v2:'));
    expect(encrypted, isNot(contains('sk-test-secret')));
    expect(await EncryptionService.decryptSecret(encrypted), 'sk-test-secret');
  });

  test('AI config repository stores api key as v2 ciphertext', () async {
    final repo = AiConfigRepository(db);
    await repo.insertAiConfig(
      AiConfigsCompanion.insert(
        provider: 'openai',
        baseUrl: 'https://api.example.com',
        apiKey: 'sk-ai-secret',
        modelName: 'test-model',
        createdAt: 1,
        updatedAt: 1,
      ),
    );

    final raw = await db.select(db.aiConfigs).getSingle();
    expect(raw.apiKey, startsWith('v2:'));
    expect(raw.apiKey, isNot('sk-ai-secret'));

    final config = await repo.getEnabledAiConfig();
    expect(config!.apiKey, 'sk-ai-secret');
  });

  test(
    'weather API config repository stores api key as v2 ciphertext',
    () async {
      final repo = ApiConfigRepository(db);
      await repo.upsertConfig(
        provider: 'qweather',
        apiKey: 'weather-secret',
        baseUrl: null,
        isActive: true,
      );

      final raw = await db.select(db.apiConfigs).getSingle();
      expect(raw.apiKey, startsWith('v2:'));
      expect(raw.apiKey, isNot('weather-secret'));

      final config = await repo.getActiveWeatherConfig();
      expect(config!.apiKey, 'weather-secret');
    },
  );

  test('legacy AI ciphertext is migrated to v2 on read', () async {
    final legacy = EncryptionService.encrypt('legacy-secret');
    await db
        .into(db.aiConfigs)
        .insert(
          AiConfigsCompanion.insert(
            provider: 'openai',
            baseUrl: 'https://api.example.com',
            apiKey: legacy,
            modelName: 'test-model',
            createdAt: 1,
            updatedAt: 1,
          ),
        );

    final config = await AiConfigRepository(db).getEnabledAiConfig();
    final raw = await db.select(db.aiConfigs).getSingle();

    expect(config!.apiKey, 'legacy-secret');
    expect(raw.apiKey, startsWith('v2:'));
  });
}

