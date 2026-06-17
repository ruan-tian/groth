import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import 'repository_providers.dart';

// =============================================================================
// 睡眠记录 Provider
// =============================================================================

/// 指定日期的睡眠记录
final sleepRecordByDateProvider = FutureProvider.family<SleepRecord?, DateTime>(
  (ref, date) async {
    final repo = ref.watch(sleepRepositoryProvider);
    return repo.getSleepRecordByDate(date);
  },
);

/// 昨晚睡眠记录
final lastNightSleepRecordProvider = FutureProvider<SleepRecord?>((ref) {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getLastNightSleepRecord();
});

/// 最近 [limit] 条睡眠记录
final recentSleepRecordsProvider =
    FutureProvider.family<List<SleepRecord>, int>((ref, limit) async {
      final repo = ref.watch(sleepRepositoryProvider);
      return repo.getRecentSleepRecords(limit: limit);
    });

/// 最近7天平均睡眠时长（分钟）
final weeklyAvgSleepDurationProvider = FutureProvider<double?>((ref) {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getAvgSleepDuration(7);
});

/// 最近30天平均睡眠时长（分钟）
final monthlyAvgSleepDurationProvider = FutureProvider<double?>((ref) {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getAvgSleepDuration(30);
});

/// 最近7天平均睡眠质量
final weeklyAvgSleepQualityProvider = FutureProvider<double?>((ref) {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getAvgSleepQuality(7);
});

/// 最近30天平均睡眠质量
final monthlyAvgSleepQualityProvider = FutureProvider<double?>((ref) {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getAvgSleepQuality(30);
});

/// 最近7天平均入睡时间
final weeklyAvgBedTimeProvider = FutureProvider<String?>((ref) {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getAvgBedTime(7);
});

/// 最近7天平均起床时间
final weeklyAvgWakeTimeProvider = FutureProvider<String?>((ref) {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getAvgWakeTime(7);
});

/// 最近7天每日睡眠时长
final weeklySleepDurationProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getDailySleepDuration(7);
});

/// 最近30天每日睡眠时长
final monthlySleepDurationProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final repo = ref.watch(sleepRepositoryProvider);
    return repo.getDailySleepDuration(30);
  },
);

/// 最近7天每日睡眠质量
final weeklySleepQualityProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getDailySleepQuality(7);
});

/// 最近30天每日睡眠质量
final monthlySleepQualityProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getDailySleepQuality(30);
});

/// 最近365天每日睡眠时长
final yearlySleepDurationProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getDailySleepDuration(365);
});

/// 最近365天每日睡眠质量
final yearlySleepQualityProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getDailySleepQuality(365);
});

/// 根据 ID 获取单条睡眠记录
final sleepRecordByIdProvider = FutureProvider.family<SleepRecord?, int>((
  ref,
  id,
) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.getSleepRecordById(id);
});
