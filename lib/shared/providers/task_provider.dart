import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/repositories/task_repository.dart';
import '../../core/utils/date_utils.dart';
import 'database_provider.dart';

// =============================================================================
// Repository Providers
// =============================================================================

/// 每日任务仓库 Provider
final dailyTaskRepositoryProvider = Provider<DailyTaskRepository>((ref) {
  return DailyTaskRepository(ref.watch(databaseProvider));
});

/// 任务模板仓库 Provider
final taskTemplateRepositoryProvider = Provider<TaskTemplateRepository>((ref) {
  return TaskTemplateRepository(ref.watch(databaseProvider));
});

// =============================================================================
// 任务数据 Providers
// =============================================================================

/// 将 DateTime 格式化为 YYYY-MM-DD 字符串
String formatDateKey(DateTime date) => GrowthDateUtils.formatDateKey(date);

/// 今天日期 Provider
final todayDateProvider = Provider<String>((ref) {
  return GrowthDateUtils.formatDateKey(DateTime.now());
});

/// 今天的任务列表 Provider
final todayTasksProvider = FutureProvider<List<DailyTask>>((ref) async {
  final repo = ref.watch(dailyTaskRepositoryProvider);
  final today = ref.watch(todayDateProvider);
  return repo.getTasksByDate(today);
});

/// 按日期查询任务列表 Provider
///
/// 用法：`ref.watch(tasksByDateProvider('2026-06-11'))`
final tasksByDateProvider = FutureProvider.family<List<DailyTask>, String>((
  ref,
  date,
) async {
  final repo = ref.watch(dailyTaskRepositoryProvider);
  return repo.getTasksByDate(date);
});

/// 指定日期未完成任务数量 Provider
final incompleteTaskCountByDateProvider = FutureProvider.family<int, String>((
  ref,
  date,
) async {
  final repo = ref.watch(dailyTaskRepositoryProvider);
  return repo.getIncompleteTaskCount(date);
});

/// 今天未完成任务数量 Provider
final todayIncompleteTaskCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(dailyTaskRepositoryProvider);
  final today = ref.watch(todayDateProvider);
  return repo.getIncompleteTaskCount(today);
});

/// 所有任务 Provider（用于历史页面）
final allTasksProvider = FutureProvider<List<DailyTask>>((ref) async {
  final db = ref.watch(databaseProvider);
  final tasks =
      await (db.select(db.dailyTasks)..orderBy([
            (t) => OrderingTerm.desc(t.taskDate),
            (t) => OrderingTerm.asc(t.startHour),
            (t) => OrderingTerm.asc(t.startMinute),
          ]))
          .get();
  return tasks;
});

/// 任务模板列表 Provider
final taskTemplatesProvider = FutureProvider<List<TaskTemplate>>((ref) async {
  final repo = ref.watch(taskTemplateRepositoryProvider);
  return repo.getAllTemplates();
});

/// 常用任务模板 Provider（Top 5）
final popularTemplatesProvider = FutureProvider<List<TaskTemplate>>((
  ref,
) async {
  final repo = ref.watch(taskTemplateRepositoryProvider);
  return repo.getPopularTemplates(limit: 5);
});

// =============================================================================
// 任务状态管理
// =============================================================================

/// 任务展开状态 Provider
final taskExpandedProvider = StateProvider<bool>((ref) {
  return false;
});

/// 当前选中的日期（用于查看历史任务）
final selectedTaskDateProvider = StateProvider<String>((ref) {
  return GrowthDateUtils.formatDateKey(DateTime.now());
});

// NOTE: DailyGoal, defaultDailyGoals, dailyGoalsProvider are defined in
// settings_provider.dart. Import from there if needed.
