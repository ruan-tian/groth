import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/services/statistics_service.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

// Re-export canonical providers so existing imports of dashboard_provider.dart
// continue to work without changes.
export 'database_provider.dart' show appDatabaseProvider, databaseProvider;
export 'repository_providers.dart';
export 'service_providers.dart';

// =============================================================================
// Dashboard 数据模型
// =============================================================================

/// Dashboard 展示数据
class DashboardData {
  const DashboardData({
    required this.todayStudyMinutes,
    required this.todayFitnessMinutes,
    required this.todayJournalCount,
    required this.totalExp,
    required this.currentLevel,
    required this.expProgress,
    required this.weeklyStats,
    this.todayDietCount = 0,
    this.todayAvgHealthScore,
    this.lastNightSleepDuration,
    this.lastNightSleepQuality,
    this.todayFocusMinutes = 0,
  });

  /// 今日学习时长（分钟）
  final int todayStudyMinutes;

  /// 今日健身时长（分钟）
  final int todayFitnessMinutes;

  /// 今日日记篇数
  final int todayJournalCount;

  /// 总经验值
  final int totalExp;

  /// 当前等级
  final int currentLevel;

  /// 当前等级内经验值进度（距当前等级起点的 EXP）
  final int expProgress;

  /// 最近 7 天每日统计
  final List<DailyStats> weeklyStats;

  /// 今日饮食次数
  final int todayDietCount;

  /// 今日平均健康评分
  final double? todayAvgHealthScore;

  /// 昨晚睡眠时长（分钟）
  final int? lastNightSleepDuration;

  /// 昨晚睡眠质量（1-5）
  final int? lastNightSleepQuality;

  /// 今日专注时长（分钟）
  final int todayFocusMinutes;
}

// =============================================================================
// Dashboard Provider
// =============================================================================

/// Dashboard 主 Provider：聚合今日概览、经验值、等级、周统计、饮食、睡眠、专注
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final studyRepo = ref.watch(studyRepositoryProvider);
  final fitnessRepo = ref.watch(fitnessRepositoryProvider);
  final journalRepo = ref.watch(journalRepositoryProvider);
  final expRepo = ref.watch(expRepositoryProvider);
  final dietRepo = ref.watch(dietRepositoryProvider);
  final sleepRepo = ref.watch(sleepRepositoryProvider);
  final focusRepo = ref.watch(focusRepositoryProvider);
  final expService = ref.watch(expServiceProvider);
  final statsService = ref.watch(statisticsServiceProvider);

  final now = DateTime.now();

  // 并行获取今日各项数据
  final results = await Future.wait([
    studyRepo.getTotalStudyMinutesByDate(now),       // [0]
    fitnessRepo.getTotalFitnessMinutesByDate(now),    // [1]
    journalRepo.getJournalsByDate(now),               // [2]
    expRepo.getTotalExp(),                            // [3]
    statsService.getWeeklyStats(),                    // [4]
    dietRepo.getDietCountByDate(now),                 // [5]
    dietRepo.getAvgHealthScoreByDate(now),            // [6]
    sleepRepo.getSleepRecordByDate(
      DateTime(now.year, now.month, now.day - 1),
    ),                                                // [7]
    focusRepo.getTotalFocusMinutesByDate(now),        // [8]
  ]);

  final todayStudyMinutes = results[0] as int;
  final todayFitnessMinutes = results[1] as int;
  final todayJournals = results[2] as List<dynamic>;
  final totalExp = results[3] as int;
  final weeklyStats = results[4] as List<DailyStats>;
  final todayDietCount = results[5] as int;
  final todayAvgHealthScore = results[6] as double?;
  final lastNightSleep = results[7] as SleepRecord?;
  final todayFocusMinutes = results[8] as int;

  final currentLevel = expService.calculateLevel(totalExp);
  final expProgress = expService.getExpProgress(totalExp, currentLevel);

  return DashboardData(
    todayStudyMinutes: todayStudyMinutes,
    todayFitnessMinutes: todayFitnessMinutes,
    todayJournalCount: todayJournals.length,
    totalExp: totalExp,
    currentLevel: currentLevel,
    expProgress: expProgress,
    weeklyStats: weeklyStats,
    todayDietCount: todayDietCount,
    todayAvgHealthScore: todayAvgHealthScore,
    lastNightSleepDuration: lastNightSleep?.durationMinutes,
    lastNightSleepQuality: lastNightSleep?.qualityLevel,
    todayFocusMinutes: todayFocusMinutes,
  );
});
