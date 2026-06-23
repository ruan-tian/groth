import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/repositories/ai_config_repository.dart';
import '../../../core/repositories/pet_diary_repository.dart';
import '../../../core/repositories/setting_repository.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/domain/pet/pet_diary_draft.dart';
import '../../../core/utils/pet_diary_prompt_builder.dart';

typedef PetDiaryAiCaller =
    Future<String> Function({
      required String apiKey,
      required String baseUrl,
      required String model,
      required String systemPrompt,
      required String userPrompt,
      double temperature,
      int maxTokens,
    });

typedef PetDiarySettingWriter = Future<void> Function(String key, String value);

class PetDiaryService {
  PetDiaryService({
    required AppDatabase db,
    required PetDiaryRepository diaryRepository,
    required AiConfigRepository aiConfigRepository,
    required SettingRepository settingRepository,
    required AiService aiService,
    PetDiaryPromptBuilder promptBuilder = const PetDiaryPromptBuilder(),
    PetDiaryAiCaller? aiCaller,
    PetDiarySettingWriter? settingWriter,
  }) : _db = db,
       _diaryRepository = diaryRepository,
       _aiConfigRepository = aiConfigRepository,
       _settingRepository = settingRepository,
       _promptBuilder = promptBuilder,
       _aiCaller = aiCaller ?? aiService.callApi,
       _settingWriter = settingWriter ?? settingRepository.setSetting;

  static const autoEnabledKey = 'pet_diary_auto_enabled';
  static const privacyConfirmedKey = 'pet_diary_privacy_confirmed';

  final AppDatabase _db;
  final PetDiaryRepository _diaryRepository;
  final AiConfigRepository _aiConfigRepository;
  final SettingRepository _settingRepository;
  final PetDiaryPromptBuilder _promptBuilder;
  final PetDiaryAiCaller _aiCaller;
  final PetDiarySettingWriter _settingWriter;

  Future<PetDiary?> ensureTodayDiary({
    DateTime? now,
    bool force = false,
    bool manual = false,
  }) async {
    final current = now ?? DateTime.now();
    final diaryDate = formatDate(current);
    final existing = await _diaryRepository.getDiaryByDate(diaryDate);

    if (!force && existing != null) {
      if (existing.generationStatus == 'ready' ||
          existing.generationStatus == 'failed') {
        return existing;
      }
      if (!manual && current.hour < 6) {
        return existing;
      }
    }

    if (!manual && current.hour < 6) {
      return existing;
    }

    final summary = await buildTodaySummary(now: current);
    final autoEnabled = await isAutoEnabled();
    if (!manual && !autoEnabled) {
      return _savePending(diaryDate, summary);
    }

    final config = await _aiConfigRepository.getEnabledAiConfig();
    if (config == null) {
      if (existing != null) return existing;
      return _savePending(diaryDate, summary);
    }

    try {
      final raw = await _aiCaller(
        apiKey: config.apiKey,
        baseUrl: config.baseUrl,
        model: config.modelName,
        systemPrompt: _promptBuilder.buildSystemPrompt(),
        userPrompt: _promptBuilder.buildUserPrompt(
          diaryDate: diaryDate,
          dataSummary: summary,
        ),
        temperature: config.temperature,
        maxTokens: config.maxTokens,
      );
      final draft = PetDiaryDraft.fromJson(_decodeJsonObject(raw));
      return _saveReady(diaryDate, summary, draft);
    } catch (_) {
      return _saveFailed(diaryDate, summary);
    }
  }

  Future<bool> isAutoEnabled() async {
    return (await _settingRepository.getSetting(autoEnabledKey)) == 'true';
  }

  Future<void> setAutoEnabled(bool enabled) async {
    await _settingWriter(autoEnabledKey, enabled.toString());
  }

  Future<bool> isPrivacyConfirmed() async {
    return (await _settingRepository.getSetting(privacyConfirmedKey)) == 'true';
  }

  Future<void> markPrivacyConfirmed() async {
    await _settingWriter(privacyConfirmedKey, 'true');
  }

  Future<Map<String, dynamic>> buildTodaySummary({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startMs = yesterday.millisecondsSinceEpoch;
    final endMs = today.millisecondsSinceEpoch;
    final yesterdayKey = formatDate(yesterday);
    final todayKey = formatDate(today);

    final studyRecords =
        await (_db.select(_db.studyRecords)..where(
              (t) =>
                  t.startTime.isBiggerOrEqualValue(startMs) &
                  t.startTime.isSmallerThanValue(endMs),
            ))
            .get();
    final fitnessRecords =
        await (_db.select(_db.fitnessRecords)..where(
              (t) =>
                  t.startTime.isBiggerOrEqualValue(startMs) &
                  t.startTime.isSmallerThanValue(endMs),
            ))
            .get();
    final dietRecords = await (_db.select(
      _db.dietRecords,
    )..where((t) => t.mealDate.equals(yesterdayKey))).get();
    final sleepRecords = await (_db.select(
      _db.sleepRecords,
    )..where((t) => t.sleepDate.equals(yesterdayKey))).get();
    final expLogs =
        await (_db.select(_db.growthExpLogs)..where(
              (t) =>
                  t.createdAt.isBiggerOrEqualValue(startMs) &
                  t.createdAt.isSmallerThanValue(endMs),
            ))
            .get();
    final tasks = await (_db.select(
      _db.dailyTasks,
    )..where((t) => t.taskDate.equals(yesterdayKey))).get();
    final weather = await _loadWeather(yesterdayKey, todayKey);

    final studyMinutes = studyRecords.fold<int>(
      0,
      (sum, record) => sum + record.durationMinutes,
    );
    final fitnessMinutes = fitnessRecords.fold<int>(
      0,
      (sum, record) => sum + record.durationMinutes,
    );
    final expGained = expLogs.fold<int>(0, (sum, log) => sum + log.expValue);
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final sleepMinutes = sleepRecords.fold<int>(
      0,
      (sum, record) => sum + record.durationMinutes,
    );

    return {
      'date': {
        'diaryDate': todayKey,
        'summaryDate': yesterdayKey,
        'todayGreeting': _todayGreeting(current),
      },
      'study': {'recordCount': studyRecords.length, 'minutes': studyMinutes},
      'fitness': {
        'recordCount': fitnessRecords.length,
        'minutes': fitnessMinutes,
      },
      'diet': {
        'recordCount': dietRecords.length,
        'mealTypes': dietRecords
            .map((record) => record.mealType)
            .toSet()
            .toList(),
        'averageHealthScore': _averageInt(
          dietRecords.map((record) => record.healthScore),
        ),
      },
      'sleep': {
        'recordCount': sleepRecords.length,
        'minutes': sleepMinutes,
        'averageQuality': _averageInt(
          sleepRecords.map((record) => record.qualityLevel),
        ),
      },
      'growth': {'expGained': expGained, 'expLogCount': expLogs.length},
      'tasks': {'total': tasks.length, 'completed': completedTasks},
      'weather': weather == null
          ? null
          : {
              'date': weather.date,
              'city': weather.city,
              'type': weather.weatherType,
              'temperature': weather.temperature,
              'humidity': weather.humidity,
            },
      'privacy': {
        'containsFullJournalText': false,
        'containsOnlySummary': true,
      },
    };
  }

  Future<PetDiary> _saveReady(
    String diaryDate,
    Map<String, dynamic> summary,
    PetDiaryDraft draft,
  ) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return _diaryRepository.saveForDate(
      PetDiariesCompanion.insert(
        diaryDate: diaryDate,
        title: draft.title,
        contentMarkdown: draft.toMarkdown(),
        mood: Value(draft.mood),
        comicPanelsJson: Value(
          jsonEncode(draft.panels.map((panel) => panel.toJson()).toList()),
        ),
        dataSummaryJson: Value(jsonEncode(summary)),
        generationStatus: const Value('ready'),
        generationMode: const Value('ai'),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );
  }

  Future<PetDiary> _savePending(
    String diaryDate,
    Map<String, dynamic> summary,
  ) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return _diaryRepository.saveForDate(
      PetDiariesCompanion.insert(
        diaryDate: diaryDate,
        title: '甜甜还在想',
        contentMarkdown: '甜甜还在整理今天的小日记。开启自动生成或手动确认后，我会只带着摘要去写。',
        mood: const Value('cozy'),
        comicPanelsJson: Value(jsonEncode(_pendingPanels())),
        dataSummaryJson: Value(jsonEncode(summary)),
        generationStatus: const Value('pending'),
        generationMode: const Value('manual'),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );
  }

  Future<PetDiary> _saveFailed(String diaryDate, Map<String, dynamic> summary) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return _diaryRepository.saveForDate(
      PetDiariesCompanion.insert(
        diaryDate: diaryDate,
        title: '墨水打翻了',
        contentMarkdown: '甜甜刚才没有写成功，但昨天的摘要已经安全放在本地。可以稍后再试一次。',
        mood: const Value('worried'),
        comicPanelsJson: Value(jsonEncode(_pendingPanels())),
        dataSummaryJson: Value(jsonEncode(summary)),
        generationStatus: const Value('failed'),
        generationMode: const Value('ai'),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );
  }

  Future<DailyWeather?> _loadWeather(
    String yesterdayKey,
    String todayKey,
  ) async {
    final yesterday =
        await (_db.select(_db.dailyWeatherTable)
              ..where((t) => t.date.equals(yesterdayKey))
              ..limit(1))
            .getSingleOrNull();
    if (yesterday != null) return yesterday;

    return (_db.select(_db.dailyWeatherTable)
          ..where((t) => t.date.equals(todayKey))
          ..limit(1))
        .getSingleOrNull();
  }

  Map<String, dynamic> _decodeJsonObject(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```json\s*|^```\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '').trim();
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      text = text.substring(start, end + 1);
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Pet diary response is not a JSON object');
    }
    return decoded;
  }

  static String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static double? _averageInt(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }

  static String _todayGreeting(DateTime now) {
    if (now.hour < 12) return '早安';
    if (now.hour < 18) return '午后好';
    return '晚上好';
  }

  static List<Map<String, String>> _pendingPanels() => const [
    {'caption': '合上的日记本', 'bubble': '甜甜还在想今天写什么'},
    {'caption': '整理小纸条', 'bubble': '只看摘要，不翻你的私密正文'},
    {'caption': '等待墨水干', 'bubble': '准备好了就让我写吧'},
  ];
}
