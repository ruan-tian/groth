import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sort_button.dart';

import '../../core/database/app_database.dart';
import '../../core/services/statistics_service.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

// =============================================================================
// 学习记录 Provider
// =============================================================================

/// 按日期获取学习记录（FutureProvider.family）
///
/// 用法：`ref.watch(studyRecordsProvider(date))`
final studyRecordsProvider = FutureProvider.family<List<StudyRecord>, DateTime>(
  (ref, date) async {
    final repo = ref.watch(studyRepositoryProvider);
    return repo.getStudyRecordsByDate(date);
  },
);

/// 今日学习记录
final todayStudyRecordsProvider = FutureProvider<List<StudyRecord>>((ref) {
  final repo = ref.watch(studyRepositoryProvider);
  return repo.getStudyRecordsByDate(DateTime.now());
});

/// 今日学习总时长（分钟）
final todayStudyMinutesProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(studyRepositoryProvider);
  return repo.getTotalStudyMinutesByDate(DateTime.now());
});

/// 最近 7 天学习总时长（分钟）
final weeklyStudyMinutesProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(studyRepositoryProvider);
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 6));
  final records = await repo.getStudyRecordsByRange(weekAgo, now);
  return records.fold<int>(0, (sum, r) => sum + r.durationMinutes);
});

/// 最近 7 天每日统计
final weeklyDailyStudyProvider = FutureProvider<List<DailyStats>>((ref) {
  final statsService = ref.watch(statisticsServiceProvider);
  return statsService.getWeeklyStats();
});

/// 最近 5 条学习记录（按创建时间倒序）
final recentStudyRecordsProvider = FutureProvider<List<StudyRecord>>((ref) {
  final repo = ref.watch(studyRepositoryProvider);
  return repo.getRecentStudyRecords(limit: 5);
});

/// 最近 30 天每日统计
final monthlyDailyStudyProvider = FutureProvider<List<DailyStats>>((ref) {
  final statsService = ref.watch(statisticsServiceProvider);
  return statsService.getMonthlyStats();
});

/// 最近 12 个月月度统计
final yearlyMonthlyStudyProvider = FutureProvider<List<MonthlyAggregate>>((
  ref,
) {
  final statsService = ref.watch(statisticsServiceProvider);
  return statsService.getYearlyStats();
});

/// 按科目统计学习时长分布（最近 30 天）
final subjectDistributionProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final repo = ref.watch(studyRepositoryProvider);
  final now = DateTime.now();
  final monthAgo = now.subtract(const Duration(days: 30));
  final records = await repo.getStudyRecordsByRange(monthAgo, now);

  final distribution = <String, int>{};
  for (final r in records) {
    final subject = r.subject ?? '未分类';
    distribution[subject] = (distribution[subject] ?? 0) + r.durationMinutes;
  }
  return distribution;
});

// =============================================================================
// 排序状态 Provider
// =============================================================================

/// 学习记录排序方式
final studySortProvider = StateProvider<SortOption>((ref) => SortOption.newest);

/// 按排序方式获取最近学习记录
final sortedRecentStudyRecordsProvider = FutureProvider<List<StudyRecord>>((
  ref,
) async {
  final repo = ref.watch(studyRepositoryProvider);
  final sort = ref.watch(studySortProvider);

  // 获取最近20条记录（足够排序）
  final records = await repo.getRecentStudyRecords(limit: 20);

  switch (sort) {
    case SortOption.newest:
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case SortOption.oldest:
      records.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case SortOption.highestExp:
      records.sort((a, b) => b.expGained.compareTo(a.expGained));
      break;
  }

  return records;
});
