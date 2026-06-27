import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/sort_button.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/statistics_service.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/service_providers.dart';
import '../utils/study_chart_ranges.dart';

// =============================================================================
// 学习记录 Provider
// =============================================================================

/// 按日期获取学习记录（FutureProvider.family）
///
/// 用法：`ref.watch(studyRecordsProvider(date))`
final studyRecordByIdProvider = FutureProvider.family<StudyRecord, int>((
  ref,
  id,
) {
  final repo = ref.watch(studyRepositoryProvider);
  return repo.getStudyRecordById(id);
});

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

/// 本自然周每日统计（周一到周日）。
final weeklyDailyStudyProvider = FutureProvider<List<DailyStats>>((ref) {
  final statsService = ref.watch(statisticsServiceProvider);
  final range = StudyChartRanges.weekRange();
  return statsService.getDailyStatsRange(range.start, range.end);
});

/// 最近 5 条学习记录（按学习开始时间倒序）
final recentStudyRecordsProvider = FutureProvider<List<StudyRecord>>((ref) {
  final repo = ref.watch(studyRepositoryProvider);
  return repo.getRecentStudyRecords(limit: 5);
});

/// 本自然月每日统计。
final monthlyDailyStudyProvider = FutureProvider<List<DailyStats>>((ref) {
  final statsService = ref.watch(statisticsServiceProvider);
  final range = StudyChartRanges.monthRange();
  return statsService.getDailyStatsRange(range.start, range.end);
});

/// 本自然年月度统计（1月到12月）。
final yearlyMonthlyStudyProvider = FutureProvider<List<MonthlyAggregate>>((
  ref,
) async {
  final statsService = ref.watch(statisticsServiceProvider);
  final range = StudyChartRanges.yearRange();
  final dailyStats = await statsService.getDailyStatsRange(
    range.start,
    range.end,
  );
  return StudyChartRanges.monthlyAggregatesForYear(
    dailyStats,
    range.start.year,
  );
});

/// 按天数范围获取科目分布
final subjectDistributionByRangeProvider =
    FutureProvider.family<Map<String, int>, int>((ref, days) async {
      final repo = ref.watch(studyRepositoryProvider);
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      final records = await repo.getStudyRecordsByRange(start, now);

      final distribution = <String, int>{};
      for (final r in records) {
        final subject = r.subject ?? '未分类';
        distribution[subject] =
            (distribution[subject] ?? 0) + r.durationMinutes;
      }
      return distribution;
    });

// =============================================================================
// 学习概览数据模型
// =============================================================================

class StudyOverview {
  const StudyOverview({
    required this.totalMinutes,
    required this.activeDays,
    required this.dailyAverage,
    required this.distribution,
  });

  final int totalMinutes;
  final int activeDays;
  final int dailyAverage;
  final Map<String, int> distribution;
}

/// 按天数范围获取学习概览（含活跃天数、日均、科目分布）
final studyOverviewByRangeProvider =
    FutureProvider.family<StudyOverview, int>((ref, days) async {
      final repo = ref.watch(studyRepositoryProvider);
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      final records = await repo.getStudyRecordsByRange(start, now);

      final distribution = <String, int>{};
      final activeDates = <String>{};
      var totalMinutes = 0;

      for (final r in records) {
        final subject = r.subject ?? '未分类';
        distribution[subject] =
            (distribution[subject] ?? 0) + r.durationMinutes;
        totalMinutes += r.durationMinutes;
        final date = DateTime.fromMillisecondsSinceEpoch(r.startTime);
        activeDates.add('${date.year}-${date.month}-${date.day}');
      }

      final activeDays = activeDates.isEmpty ? 1 : activeDates.length;
      final dailyAverage = totalMinutes > 0 ? (totalMinutes / activeDays).round() : 0;

      return StudyOverview(
        totalMinutes: totalMinutes,
        activeDays: activeDays,
        dailyAverage: dailyAverage,
        distribution: distribution,
      );
    });

/// 按科目统计学习时长分布（最近 30 天，向后兼容）
final subjectDistributionProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(subjectDistributionByRangeProvider(30).future);
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
      records.sort((a, b) => b.startTime.compareTo(a.startTime));
      break;
    case SortOption.oldest:
      records.sort((a, b) => a.startTime.compareTo(b.startTime));
      break;
    case SortOption.highestExp:
      records.sort((a, b) => b.expGained.compareTo(a.expGained));
      break;
  }

  return records;
});
