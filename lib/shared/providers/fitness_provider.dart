import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sort_button.dart';

import '../../core/constants/fitness_constants.dart';
import '../../core/database/app_database.dart';
import 'repository_providers.dart';

// =============================================================================
// 健身记录 Provider
// =============================================================================

/// 按日期获取健身记录（FutureProvider.family）
///
/// 用法：`ref.watch(fitnessRecordsProvider(date))`
final fitnessRecordsProvider =
    FutureProvider.family<List<FitnessRecord>, DateTime>((ref, date) async {
      final repo = ref.watch(fitnessRepositoryProvider);
      return repo.getFitnessRecordsByDate(date);
    });

/// 今日健身记录
final todayFitnessRecordsProvider = FutureProvider<List<FitnessRecord>>((ref) {
  final repo = ref.watch(fitnessRepositoryProvider);
  return repo.getFitnessRecordsByDate(DateTime.now());
});

/// 今日健身总时长（分钟）
final todayFitnessMinutesProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(fitnessRepositoryProvider);
  return repo.getTotalFitnessMinutesByDate(DateTime.now());
});

/// 本周健身次数
final weeklyFitnessCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(fitnessRepositoryProvider);
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 6));
  final records = await repo.getFitnessRecordsByRange(weekAgo, now);
  return records.length;
});

/// 最近 5 条健身记录（按创建时间倒序）
final recentFitnessRecordsProvider = FutureProvider<List<FitnessRecord>>((ref) {
  final repo = ref.watch(fitnessRepositoryProvider);
  return repo.getRecentFitnessRecords(limit: 5);
});

/// 根据 ID 获取单条健身记录
final fitnessRecordByIdProvider = FutureProvider.family<FitnessRecord, int>((
  ref,
  id,
) async {
  final repo = ref.watch(fitnessRepositoryProvider);
  return repo.getFitnessRecordById(id);
});

/// 获取指定健身记录的动作列表
final fitnessExercisesByRecordIdProvider =
    FutureProvider.family<List<FitnessExercise>, int>((ref, recordId) async {
      final repo = ref.watch(fitnessRepositoryProvider);
      return repo.getFitnessExercisesByRecordId(recordId);
    });

final fitnessWorkoutTemplatesProvider =
    FutureProvider<List<FitnessWorkoutTemplate>>((ref) async {
      final repo = ref.watch(fitnessRepositoryProvider);
      await repo.ensureBuiltInWorkoutTemplates();
      return repo.getWorkoutTemplates();
    });

final fitnessWorkoutTemplateExercisesProvider =
    FutureProvider.family<List<FitnessWorkoutTemplateExercise>, int>((
      ref,
      templateId,
    ) {
      final repo = ref.watch(fitnessRepositoryProvider);
      return repo.getWorkoutTemplateExercises(templateId);
    });

// =============================================================================
// 排序状态 Provider
// =============================================================================

/// 健身记录排序方式
final fitnessSortProvider = StateProvider<SortOption>(
  (ref) => SortOption.newest,
);

/// 按排序方式获取最近健身记录
final sortedRecentFitnessRecordsProvider = FutureProvider<List<FitnessRecord>>((
  ref,
) async {
  final repo = ref.watch(fitnessRepositoryProvider);
  final sort = ref.watch(fitnessSortProvider);

  // 获取最近20条记录（足够排序）
  final records = await repo.getRecentFitnessRecords(limit: 20);

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

// =============================================================================
// 身体数据 Provider
// =============================================================================

/// 所有身体数据（按日期倒序）
final allBodyMetricsProvider = FutureProvider<List<BodyMetric>>((ref) {
  final repo = ref.watch(fitnessRepositoryProvider);
  return repo.getAllBodyMetrics();
});

/// 最近 [limit] 条身体数据
final recentBodyMetricsProvider = FutureProvider<List<BodyMetric>>((ref) {
  final repo = ref.watch(fitnessRepositoryProvider);
  return repo.getRecentBodyMetrics(limit: 10);
});

/// 最新一条身体数据
final latestBodyMetricProvider = FutureProvider<BodyMetric?>((ref) async {
  final repo = ref.watch(fitnessRepositoryProvider);
  final metrics = await repo.getRecentBodyMetrics(limit: 1);
  return metrics.isNotEmpty ? metrics.first : null;
});

/// 指定天数内的身体数据（用于趋势图）
final bodyMetricsTrendProvider = FutureProvider.family<List<BodyMetric>, int>((
  ref,
  days,
) async {
  final repo = ref.watch(fitnessRepositoryProvider);
  final now = DateTime.now();
  final start = now.subtract(Duration(days: days));
  return repo.getBodyMetricsByRange(start, now);
});

/// 根据 ID 获取单条身体数据
final bodyMetricByIdProvider = FutureProvider.family<BodyMetric?, int>((
  ref,
  id,
) async {
  final repo = ref.watch(fitnessRepositoryProvider);
  return repo.getBodyMetricById(id);
});

// =============================================================================
// 健身图表数据 Provider
// =============================================================================

/// 健身图表数据
class FitnessChartData {
  const FitnessChartData({
    required this.date,
    required this.minutes,
    required this.calories,
    required this.weight,
  });

  final DateTime date;
  final int minutes;
  final int calories;
  final double? weight;
}

/// 最近 [days] 天的健身图表数据（每日聚合）
final fitnessChartDataProvider = FutureProvider.family<List<FitnessChartData>, int>((
  ref,
  days,
) async {
  final repo = ref.watch(fitnessRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: days - 1));

  // 获取健身记录和身体数据（并行查询）
  final results = await Future.wait([
    repo.getFitnessRecordsByRange(start, now),
    repo.getBodyMetricsByRange(start, now),
  ]);
  final records = results[0] as List<FitnessRecord>;
  final metrics = results[1] as List<BodyMetric>;

  // 按日期聚合健身数据
  final Map<String, FitnessChartData> dateMap = {};

  for (final r in records) {
    final date = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final existing = dateMap[key];
    final minutes = (existing?.minutes ?? 0) + r.durationMinutes;
    final calories =
        (existing?.calories ?? 0) +
        FitnessConstants.estimateCalories(r.durationMinutes);

    dateMap[key] = FitnessChartData(
      date: DateTime(date.year, date.month, date.day),
      minutes: minutes,
      calories: calories,
      weight: existing?.weight,
    );
  }

  // 添加体重数据
  for (final m in metrics) {
    if (m.weight == null) continue;
    final date = DateTime.parse(m.recordDate);
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final existing = dateMap[key];
    if (existing != null) {
      dateMap[key] = FitnessChartData(
        date: existing.date,
        minutes: existing.minutes,
        calories: existing.calories,
        weight: m.weight,
      );
    } else {
      dateMap[key] = FitnessChartData(
        date: DateTime(date.year, date.month, date.day),
        minutes: 0,
        calories: 0,
        weight: m.weight,
      );
    }
  }

  // 转换为列表并排序
  final result = dateMap.values.toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return result;
});
