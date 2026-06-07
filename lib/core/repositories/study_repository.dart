import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 学习记录仓库
///
/// 封装学习记录表的 CRUD 操作与常用查询。
class StudyRepository {
  StudyRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// 插入一条学习记录，返回自增 ID。
  Future<int> insertStudyRecord(StudyRecordsCompanion record) {
    return _db.into(_db.studyRecords).insert(record);
  }

  /// 更新一条学习记录（以 companion 中的 id 为准）。
  Future<void> updateStudyRecord(StudyRecordsCompanion record) {
    return _db.update(_db.studyRecords).replace(record);
  }

  /// 更新指定学习记录的经验值。
  Future<void> updateStudyRecordExp(int id, int expGained) {
    return (_db.update(_db.studyRecords)..where((t) => t.id.equals(id))).write(
      StudyRecordsCompanion(expGained: Value(expGained)),
    );
  }

  /// 根据 ID 删除一条学习记录。
  Future<void> deleteStudyRecord(int id) {
    return (_db.delete(_db.studyRecords)..where((t) => t.id.equals(id))).go();
  }

  // ---------------------------------------------------------------------------
  // 查询
  // ---------------------------------------------------------------------------

  /// 获取指定日期的学习记录（按 createdAt 毫秒时间戳范围过滤）。
  Future<List<StudyRecord>> getStudyRecordsByDate(DateTime date) {
    final range = _dayRange(date);
    return (_db.select(_db.studyRecords)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(range.start) &
                t.createdAt.isSmallerThanValue(range.end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取日期范围内的学习记录（包含 start 和 end 当天）。
  Future<List<StudyRecord>> getStudyRecordsByRange(
    DateTime start,
    DateTime end,
  ) {
    final startMs = _startOfDay(start).millisecondsSinceEpoch;
    final endMs = _endOfDay(end).millisecondsSinceEpoch;
    return (_db.select(_db.studyRecords)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(startMs) &
                t.createdAt.isSmallerThanValue(endMs),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取最近的 [limit] 条学习记录（按创建时间倒序）。
  Future<List<StudyRecord>> getRecentStudyRecords({int limit = 5}) {
    return (_db.select(_db.studyRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 获取指定日期的学习总时长（分钟）。
  ///
  /// 若当天无记录则返回 0。
  Future<int> getTotalStudyMinutesByDate(DateTime date) async {
    final range = _dayRange(date);
    final result = await (_db.selectOnly(_db.studyRecords)
          ..addColumns([_db.studyRecords.durationMinutes.sum()])
          ..where(
            _db.studyRecords.createdAt.isBiggerOrEqualValue(range.start) &
                _db.studyRecords.createdAt.isSmallerThanValue(range.end),
          ))
        .getSingle();
    return result.read(_db.studyRecords.durationMinutes.sum()) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------------

  /// 获取最近30天的科目分布
  Future<Map<String, int>> getSubjectDistribution() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final startMs = _startOfDay(thirtyDaysAgo).millisecondsSinceEpoch;
    final endMs = _endOfDay(now).millisecondsSinceEpoch;

    final records = await (_db.select(_db.studyRecords)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(startMs) &
                t.createdAt.isSmallerThanValue(endMs),
          ))
        .get();

    final dist = <String, int>{};
    for (final record in records) {
      final subject = record.subject ?? '未分类';
      dist[subject] = (dist[subject] ?? 0) + record.durationMinutes;
    }
    return dist;
  }

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
