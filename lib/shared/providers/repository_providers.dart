import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/ai_config_repository.dart';
import '../../core/repositories/ai_chat_repository.dart';
import '../../core/repositories/api_config_repository.dart';
import '../../core/repositories/diet_repository.dart';
import '../../core/repositories/exp_repository.dart';
import '../../core/repositories/fitness_repository.dart';
import '../../core/repositories/focus_repository.dart';
import '../../core/repositories/journal_repository.dart';
import '../../core/repositories/knowledge_card_repository.dart';
import '../../core/repositories/knowledge_source_repository.dart';
import '../../core/repositories/music_repository.dart';
import '../../core/repositories/pet_diary_repository.dart';
import '../../core/repositories/setting_repository.dart';
import '../../core/repositories/sleep_repository.dart';
import '../../core/repositories/study_repository.dart';
import '../../core/repositories/weather_repository.dart';
import '../../core/repositories/weather_search_history_repository.dart';
import 'database_provider.dart';

/// 学习记录仓库 Provider。
final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StudyRepository(db);
});

/// 知识卡片仓库 Provider。
final knowledgeCardRepositoryProvider = Provider<KnowledgeCardRepository>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return KnowledgeCardRepository(db);
});

/// 本地知识库资料仓库 Provider。
final knowledgeSourceRepositoryProvider = Provider<KnowledgeSourceRepository>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return KnowledgeSourceRepository(db);
});

/// 健身记录仓库 Provider。
final fitnessRepositoryProvider = Provider<FitnessRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FitnessRepository(db);
});

/// 成长日记仓库 Provider。
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return JournalRepository(db);
});

/// Pet diary repository Provider.
final petDiaryRepositoryProvider = Provider<PetDiaryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PetDiaryRepository(db);
});

/// 经验值仓库 Provider。
final expRepositoryProvider = Provider<ExpRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ExpRepository(db);
});

/// 系统设置仓库 Provider。
final settingRepositoryProvider = Provider<SettingRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingRepository(db);
});

/// AI 配置仓库 Provider。
final aiConfigRepositoryProvider = Provider<AiConfigRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AiConfigRepository(db);
});

/// 饮食记录仓库 Provider。
final dietRepositoryProvider = Provider<DietRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DietRepository(db);
});

/// 睡眠记录仓库 Provider。
final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SleepRepository(db);
});

/// 专注记录仓库 Provider。
final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FocusRepository(db);
});

/// 天气记录仓库 Provider。
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WeatherRepository(db);
});

/// API 配置仓库 Provider。
final apiConfigRepositoryProvider = Provider<ApiConfigRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ApiConfigRepository(db);
});

/// 天气城市搜索历史仓库 Provider。
final weatherSearchHistoryRepositoryProvider =
    Provider<WeatherSearchHistoryRepository>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return WeatherSearchHistoryRepository(db);
    });

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MusicRepository(db);
});
/// AI 对话历史仓库 Provider。
final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AiChatRepository(db);
});