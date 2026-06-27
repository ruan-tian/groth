import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/statistics_service.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/service_providers.dart';

// Re-export canonical providers for backward compatibility
export '../../../shared/providers/database_provider.dart' show appDatabaseProvider, databaseProvider;
export '../../../shared/providers/repository_providers.dart';
export '../../../shared/providers/service_providers.dart';

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
  final expRepo = ref.watch(expRepositoryProvider);
  final dietRepo = ref.watch(dietRepositoryProvider);
  final sleepRepo = ref.watch(sleepRepositoryProvider);
  final expService = ref.watch(expServiceProvider);
  final statsService = ref.watch(statisticsServiceProvider);

  final now = DateTime.now();

  // 周统计已经包含今天的学习、健身、日记、饮食次数、专注和任务数据，
  // 首页直接复用，避免同一次刷新里重复执行多条今日查询。
  final results = await Future.wait<Object?>([
    statsService.getWeeklyStats(),
    expRepo.getTotalExp(),
    dietRepo.getAvgHealthScoreByDate(now),
    sleepRepo.getSleepRecordByDate(DateTime(now.year, now.month, now.day - 1)),
  ]);

  final weeklyStats = results[0] as List<DailyStats>;
  final todayStats = weeklyStats.isNotEmpty
      ? weeklyStats.last
      : DailyStats.empty(now);
  final totalExp = results[1] as int;
  final todayAvgHealthScore = results[2] as double?;
  final lastNightSleep = results[3] as SleepRecord?;

  final levelProgress = expService.calculateLevelProgress(totalExp);

  return DashboardData(
    todayStudyMinutes: todayStats.studyMinutes,
    todayFitnessMinutes: todayStats.fitnessMinutes,
    todayJournalCount: todayStats.journalCount,
    totalExp: totalExp,
    currentLevel: levelProgress.level,
    expProgress: levelProgress.expProgress,
    weeklyStats: weeklyStats,
    todayDietCount: todayStats.dietCount,
    todayAvgHealthScore: todayAvgHealthScore,
    lastNightSleepDuration: lastNightSleep?.durationMinutes,
    lastNightSleepQuality: lastNightSleep?.qualityLevel,
    todayFocusMinutes: todayStats.focusMinutes,
  );
});
