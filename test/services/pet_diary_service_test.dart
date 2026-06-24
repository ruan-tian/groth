import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/ai/repositories/ai_config_repository.dart';
import 'package:growth_os/features/fitness/repositories/fitness_repository.dart';
import 'package:growth_os/features/health/repositories/diet_repository.dart';
import 'package:growth_os/features/health/repositories/sleep_repository.dart';
import 'package:growth_os/features/health/repositories/weather_repository.dart';
import 'package:growth_os/features/pet/repositories/exp_repository.dart';
import 'package:growth_os/features/pet/repositories/pet_diary_repository.dart';
import 'package:growth_os/core/repositories/setting_repository.dart';
import 'package:growth_os/core/services/ai_service.dart';
import 'package:growth_os/core/services/encryption_service.dart';
import 'package:growth_os/features/pet/services/pet_diary_data_collector.dart';
import 'package:growth_os/features/pet/services/pet_diary_service.dart';
import 'package:growth_os/features/plan/repositories/task_repository.dart';
import 'package:growth_os/features/study/repositories/study_repository.dart';

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
  "title": "爪印小记",
  "mood": "proud",
  "panels": [
    {"caption": "早安翻页", "bubble": "我把纸页铺平啦"},
    {"caption": "昨日回想", "bubble": "努力被我收好啦"},
    {"caption": "今日出发", "bubble": "今天也慢慢来"}
  ],
  "diary": "早上我翻开粉色小本本，先看了昨天的摘要。你有一点学习和成长的爪印，我把它们贴在纸页上。没有看到完整日记正文，所以我只写我知道的小事。今天我想继续陪你轻轻开始，把事情一件件放好。",
  "closing": "今天也被甜甜看好"
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
      dataCollector: PetDiaryDataCollector(
        studyRepo: StudyRepository(db),
        fitnessRepo: FitnessRepository(db),
        dietRepo: DietRepository(db),
        sleepRepo: SleepRepository(db),
        taskRepo: DailyTaskRepository(db),
        expRepo: ExpRepository(db),
        weatherRepo: WeatherRepository(db),
      ),
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
    const privateJournalText = '这是用户完整日记正文，不应该发给甜甜日记 prompt';
    final nowMs = DateTime(2026, 6, 7, 21).millisecondsSinceEpoch;
    await db
        .into(db.dailyJournals)
        .insert(
          DailyJournalsCompanion.insert(
            journalDate: '2026-06-07',
            title: '私人复盘',
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
