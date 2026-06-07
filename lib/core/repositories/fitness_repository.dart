import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 健身记录仓库
///
/// 封装健身记录 & 健身动作表的 CRUD 操作与常用查询。
class FitnessRepository {
  FitnessRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // 健身记录 CRUD
  // ---------------------------------------------------------------------------

  /// 插入一条健身记录，返回自增 ID。
  Future<int> insertFitnessRecord(FitnessRecordsCompanion record) {
    return _db.into(_db.fitnessRecords).insert(record);
  }

  /// 更新一条健身记录（以 companion 中的 id 为准）。
  Future<void> updateFitnessRecord(FitnessRecordsCompanion record) {
    return _db.update(_db.fitnessRecords).replace(record);
  }

  /// 根据 ID 删除一条健身记录。
  Future<void> deleteFitnessRecord(int id) {
    return (_db.delete(_db.fitnessRecords)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // 健身记录查询
  // ---------------------------------------------------------------------------

  /// 获取指定日期的健身记录（按 createdAt 毫秒时间戳范围过滤）。
  Future<List<FitnessRecord>> getFitnessRecordsByDate(DateTime date) {
    final range = _dayRange(date);
    return (_db.select(_db.fitnessRecords)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(range.start) &
                t.createdAt.isSmallerThanValue(range.end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取日期范围内的健身记录（包含 start 和 end 当天）。
  Future<List<FitnessRecord>> getFitnessRecordsByRange(
    DateTime start,
    DateTime end,
  ) {
    final startMs = _startOfDay(start).millisecondsSinceEpoch;
    final endMs = _endOfDay(end).millisecondsSinceEpoch;
    return (_db.select(_db.fitnessRecords)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(startMs) &
                t.createdAt.isSmallerThanValue(endMs),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取指定日期的健身总时长（分钟）。
  ///
  /// 若当天无记录则返回 0。
  Future<int> getTotalFitnessMinutesByDate(DateTime date) async {
    final range = _dayRange(date);
    final result = await (_db.selectOnly(_db.fitnessRecords)
          ..addColumns([_db.fitnessRecords.durationMinutes.sum()])
          ..where(
            _db.fitnessRecords.createdAt.isBiggerOrEqualValue(range.start) &
                _db.fitnessRecords.createdAt.isSmallerThanValue(range.end),
          ))
        .getSingle();
    return result.read(_db.fitnessRecords.durationMinutes.sum()) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // 健身动作 CRUD
  // ---------------------------------------------------------------------------

  /// 插入一条健身动作，返回自增 ID。
  Future<int> insertFitnessExercise(FitnessExercisesCompanion exercise) {
    return _db.into(_db.fitnessExercises).insert(exercise);
  }

  /// 删除指定健身记录下的所有动作。
  Future<void> deleteFitnessExercisesByRecordId(int recordId) {
    return (_db.delete(_db.fitnessExercises)
          ..where((t) => t.fitnessRecordId.equals(recordId)))
        .go();
  }

  /// 获取指定健身记录下的所有动作。
  Future<List<FitnessExercise>> getFitnessExercisesByRecordId(int recordId) {
    return (_db.select(_db.fitnessExercises)
          ..where((t) => t.fitnessRecordId.equals(recordId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  /// 获取最近的 [limit] 条健身记录（按创建时间倒序）。
  Future<List<FitnessRecord>> getRecentFitnessRecords({int limit = 5}) {
    return (_db.select(_db.fitnessRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 更新指定健身记录的经验值。
  Future<void> updateFitnessRecordExp(int id, int expGained) {
    return (_db.update(_db.fitnessRecords)..where((t) => t.id.equals(id))).write(
      FitnessRecordsCompanion(expGained: Value(expGained)),
    );
  }

  /// 获取指定日期的健身记录条数。
  Future<int> getFitnessRecordCountByDate(DateTime date) async {
    final range = _dayRange(date);
    final result = await (_db.selectOnly(_db.fitnessRecords)
          ..addColumns([_db.fitnessRecords.id.count()])
          ..where(
            _db.fitnessRecords.createdAt.isBiggerOrEqualValue(range.start) &
                _db.fitnessRecords.createdAt.isSmallerThanValue(range.end),
          ))
        .getSingle();
    return result.read(_db.fitnessRecords.id.count()) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // 身体数据 CRUD
  // ---------------------------------------------------------------------------

  /// 插入一条身体数据，返回自增 ID。
  Future<int> insertBodyMetric(BodyMetricsCompanion metric) {
    return _db.into(_db.bodyMetrics).insert(metric);
  }

  /// 更新一条身体数据。
  Future<void> updateBodyMetric(BodyMetricsCompanion metric) {
    return _db.update(_db.bodyMetrics).replace(metric);
  }

  /// 根据 ID 删除一条身体数据。
  Future<void> deleteBodyMetric(int id) {
    return (_db.delete(_db.bodyMetrics)..where((t) => t.id.equals(id))).go();
  }

  /// 获取所有身体数据（按日期倒序）。
  Future<List<BodyMetric>> getAllBodyMetrics() {
    return (_db.select(_db.bodyMetrics)
          ..orderBy([(t) => OrderingTerm.desc(t.recordDate)]))
        .get();
  }

  /// 获取最近 [limit] 条身体数据（按日期倒序）。
  Future<List<BodyMetric>> getRecentBodyMetrics({int limit = 10}) {
    return (_db.select(_db.bodyMetrics)
          ..orderBy([(t) => OrderingTerm.desc(t.recordDate)])
          ..limit(limit))
        .get();
  }

  /// 获取指定日期范围内的身体数据（按日期正序，适合画图）。
  Future<List<BodyMetric>> getBodyMetricsByRange(
    DateTime start,
    DateTime end,
  ) {
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    return (_db.select(_db.bodyMetrics)
          ..where(
            (t) =>
                t.recordDate.isBiggerOrEqualValue(startStr) &
                t.recordDate.isSmallerOrEqualValue(endStr),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.recordDate)]))
        .get();
  }

  /// 根据 ID 获取单条身体数据。
  Future<BodyMetric?> getBodyMetricById(int id) {
    return (_db.select(_db.bodyMetrics)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------------

  /// 返回当天 [startMs, endMs) 的毫秒时间戳范围。
  _DayRange _dayRange(DateTime date) {
    final start = _startOfDay(date).millisecondsSinceEpoch;
    final end = _endOfDay(date).millisecondsSinceEpoch;
    return _DayRange(start, end);
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day + 1);
}

/// 一天的毫秒时间戳区间 [start, end)。
class _DayRange {
  const _DayRange(this.start, this.end);
  final int start;
  final int end;
}
