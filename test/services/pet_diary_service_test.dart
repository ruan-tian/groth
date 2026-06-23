import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/ai/repositories/ai_config_repository.dart';
import 'package:growth_os/features/pet/repositories/pet_diary_repository.dart';
import 'package:growth_os/core/repositories/setting_repository.dart';
import 'package:growth_os/core/services/ai_service.dart';
import 'package:growth_os/core/services/encryption_service.dart';
import 'package:growth_os/features/pet/services/pet_diary_service.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late SettingRepository settingRepo;
  late AiConfigRepository aiConfigRepo;
  late PetDiaryService service;
  late int aiCallCount;
  late String capturedPrompt;

  Future<String> fakeAiCaller({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    aiCallCount++;
    capturedPrompt = userPrompt;
    return '''
{
  "title": "鐖嵃灏忚",
  "mood": "proud",
  "panels": [
    {"caption": "鏃╁畨缈婚〉", "bubble": "鎴戞妸绾搁〉閾哄钩鍟?},
    {"caption": "鏄ㄦ棩鍥炴兂", "bubble": "鍔姏琚垜鏀跺ソ鍟?},
    {"caption": "浠婃棩鍑哄彂", "bubble": "浠婂ぉ涔熸參鎱㈡潵"}
  ],
  "diary": "鏃╀笂鎴戠炕寮€绮夎壊灏忔湰鏈紝鍏堢湅浜嗘槰澶╃殑鎽樿銆備綘鏈変竴鐐瑰涔犲拰鎴愰暱鐨勭埅鍗帮紝鎴戞妸瀹冧滑璐村湪绾搁〉涓娿€傛病鏈夌湅鍒板畬鏁存棩璁版鏂囷紝鎵€浠ユ垜鍙啓鎴戠煡閬撶殑灏忎簨銆備粖澶╂垜鎯崇户缁櫔浣犺交杞诲紑濮嬶紝鎶婁簨鎯呬竴浠朵欢鏀惧ソ銆?,
  "closing": "浠婂ぉ涔熻鐢滅敎鐪嬪ソ"
}
''';
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('growth_os_diary_test_');
    KeyMaterialService.resetForTests(directory: tempDir);
    db = AppDatabase(NativeDatabase.memory());
    settingRepo = SettingRepository(db);
    aiConfigRepo = AiConfigRepository(db);
    service = PetDiaryService(
      db: db,
      diaryRepository: PetDiaryRepository(db),
      aiConfigRepository: aiConfigRepo,
      settingRepository: settingRepo,
      aiService: AiService(),
      aiCaller: fakeAiCaller,
    );
    aiCallCount = 0;
    capturedPrompt = '';
  });

  tearDown(() async {
    await db.close();
    KeyMaterialService.resetForTests();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('does not auto-generate before 6 AM', () async {
    await _enableAutoDiary(settingRepo);
    await _insertAiConfig(aiConfigRepo);

    final diary = await service.ensureTodayDiary(
      now: DateTime(2026, 6, 8, 5, 59),
    );

    expect(diary, isNull);
    expect(aiCallCount, 0);
    expect(await db.select(db.petDiaries).get(), isEmpty);
  });

  test('generates once after 6 AM and is idempotent', () async {
    await _enableAutoDiary(settingRepo);
    await _insertAiConfig(aiConfigRepo);

    final now = DateTime(2026, 6, 8, 6, 1);
    final first = await service.ensureTodayDiary(now: now);
    final second = await service.ensureTodayDiary(now: now);
    final rows = await db.select(db.petDiaries).get();

    expect(first?.generationStatus, 'ready');
    expect(second?.id, first?.id);
    expect(rows, hasLength(1));
    expect(aiCallCount, 1);
  });

  test(
    'creates pending diary when auto generation is not authorized',
    () async {
      await _insertAiConfig(aiConfigRepo);

      final diary = await service.ensureTodayDiary(
        now: DateTime(2026, 6, 8, 7),
      );

      expect(diary?.generationStatus, 'pending');
      expect(aiCallCount, 0);
    },
  );

  test('creates pending diary when AI config is missing', () async {
    await _enableAutoDiary(settingRepo);

    final diary = await service.ensureTodayDiary(now: DateTime(2026, 6, 8, 7));

    expect(diary?.generationStatus, 'pending');
    expect(aiCallCount, 0);
  });

  test('prompt does not include full user journal text', () async {
    await _enableAutoDiary(settingRepo);
    await _insertAiConfig(aiConfigRepo);
    const privateJournalText = '杩欐槸鐢ㄦ埛瀹屾暣鏃ヨ姝ｆ枃锛屼笉搴旇鍙戠粰鐢滅敎鏃ヨ prompt';
    final nowMs = DateTime(2026, 6, 7, 21).millisecondsSinceEpoch;
    await db
        .into(db.dailyJournals)
        .insert(
          DailyJournalsCompanion.insert(
            journalDate: '2026-06-07',
            title: '绉佷汉澶嶇洏',
            content: privateJournalText,
            plainText: const Value(privateJournalText),
            markdownContent: const Value(privateJournalText),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    await service.ensureTodayDiary(now: DateTime(2026, 6, 8, 7));

    expect(capturedPrompt, isNot(contains(privateJournalText)));
    expect(capturedPrompt, contains('"containsFullJournalText": false'));
  });
}

Future<void> _enableAutoDiary(SettingRepository repo) {
  return repo.setSetting(PetDiaryService.autoEnabledKey, 'true');
}

Future<void> _insertAiConfig(AiConfigRepository repo) {
  final nowMs = DateTime(2026, 6, 8, 6).millisecondsSinceEpoch;
  return repo
      .insertAiConfig(
        AiConfigsCompanion.insert(
          provider: 'test',
          baseUrl: 'https://example.com/v1',
          apiKey: 'sk-test',
          modelName: 'test-model',
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      )
      .then((_) {});
}

