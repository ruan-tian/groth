import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 每日任务仓库
class DailyTaskRepository {
  DailyTaskRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// 插入一个任务，返回自增 ID。
  Future<int> insertTask(DailyTasksCompanion task) {
    return _db.into(_db.dailyTasks).insert(task);
  }

  /// 更新任务。
  Future<void> updateTask(DailyTasksCompanion task) {
    return _db.update(_db.dailyTasks).replace(task);
  }

  /// 根据 ID 删除任务。
  Future<void> deleteTask(int id) {
    return (_db.delete(_db.dailyTasks)..where((t) => t.id.equals(id))).go();
  }

  /// 切换任务完成状态。
  Future<void> toggleTaskCompletion(int id, bool isCompleted) async {
    await (_db.update(_db.dailyTasks)..where((t) => t.id.equals(id))).write(
      DailyTasksCompanion(
        isCompleted: Value(isCompleted),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// 更新任务优先级。
  Future<void> updateTaskPriority(int id, int priority) async {
    await (_db.update(_db.dailyTasks)..where((t) => t.id.equals(id))).write(
      DailyTasksCompanion(
        priority: Value(priority),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 查询
  // ---------------------------------------------------------------------------

  /// 获取指定日期的任务列表。
  Future<List<DailyTask>> getTasksByDate(String date) {
    return (_db.select(_db.dailyTasks)
          ..where((t) => t.taskDate.equals(date))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.asc(t.startHour),
            (t) => OrderingTerm.asc(t.startMinute),
          ]))
        .get();
  }

  /// 获取今天的任务列表。
  Future<List<DailyTask>> getTodayTasks() {
    final today = _formatDate(DateTime.now());
    return getTasksByDate(today);
  }

  /// 获取任务详情。
  Future<DailyTask?> getTaskById(int id) {
    return (_db.select(_db.dailyTasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 获取未完成的任务数量。
  Future<int> getIncompleteTaskCount(String date) async {
    final count = _db.dailyTasks.id.count();
    final query = _db.selectOnly(_db.dailyTasks)
      ..addColumns([count])
      ..where(
        _db.dailyTasks.taskDate.equals(date) &
            _db.dailyTasks.isCompleted.equals(false),
      );
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// 任务模板仓库
class TaskTemplateRepository {
  TaskTemplateRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// 插入模板，返回自增 ID。
  Future<int> insertTemplate(TaskTemplatesCompanion template) {
    return _db.into(_db.taskTemplates).insert(template);
  }

  /// 更新模板。
  Future<void> updateTemplate(TaskTemplatesCompanion template) {
    return _db.update(_db.taskTemplates).replace(template);
  }

  /// 删除模板。
  Future<void> deleteTemplate(int id) {
    return (_db.delete(_db.taskTemplates)..where((t) => t.id.equals(id))).go();
  }

  /// 增加模板使用次数。
  Future<void> incrementUsageCount(int id) async {
    final template = await getTemplateById(id);
    if (template != null) {
      await (_db.update(_db.taskTemplates)..where((t) => t.id.equals(id))).write(
        TaskTemplatesCompanion(
          usageCount: Value(template.usageCount + 1),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 查询
  // ---------------------------------------------------------------------------

  /// 获取所有模板，按使用次数倒序排列。
  Future<List<TaskTemplate>> getAllTemplates() {
    return (_db.select(_db.taskTemplates)
          ..orderBy([(t) => OrderingTerm.desc(t.usageCount)]))
        .get();
  }

  /// 获取模板详情。
  Future<TaskTemplate?> getTemplateById(int id) {
    return (_db.select(_db.taskTemplates)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 获取最常用的模板（Top N）。
  Future<List<TaskTemplate>> getPopularTemplates({int limit = 5}) {
    return (_db.select(_db.taskTemplates)
          ..orderBy([(t) => OrderingTerm.desc(t.usageCount)])
          ..limit(limit))
        .get();
  }
}
