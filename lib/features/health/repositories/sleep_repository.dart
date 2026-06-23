import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../pet/repositories/exp_repository.dart';

/// 睡眠记录仓库
///
/// 封装睡眠记录表的 CRUD 操作与常用查询。
class SleepRepository {
  SleepRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // 睡眠记录 CRUD
  // ---------------------------------------------------------------------------

  /// 插入一条睡眠记录，返回自增 ID。
  Future<int> insertSleepRecord(SleepRecordsCompanion record) {
    return _db.into(_db.sleepRecords).insert(record);
  }

  Future<int> saveSleepRecordWithExp({
    required SleepRecordsCompanion record,
    required int exp,
    required String reason,
    required int createdAt,
  }) {
    return _db.transaction(() async {
      final recordId = await insertSleepRecord(record);
      if (exp > 0) {
        await ExpRepository(_db).insertExpLog(
          GrowthExpLogsCompanion.insert(
            sourceType: 'sleep',
            sourceId: recordId,
            expValue: exp,
            reason: reason,
            createdAt: createdAt,
          ),
        );
      }
      return recordId;
    });
  }

  /// 更新一条睡眠记录。
  Future<void> updateSleepRecord(SleepRecordsCompanion record) {
    return _db.update(_db.sleepRecords).replace(record);
  }

  /// 根据 ID 删除一条睡眠记录。
  Future<void> deleteSleepRecord(int id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.sleepRecords)..where((t) => t.id.equals(id))).go();
      await ExpRepository(_db).deleteExpLogsForSource('sleep', id);
    });
  }

  // ---------------------------------------------------------------------------
  // 睡眠记录查询
  // ---------------------------------------------------------------------------

  /// 获取指定日期的睡眠记录。
  ///
  /// 如果同一天有多条记录，返回最新的一条。
  Future<SleepRecord?> getSleepRecordByDate(DateTime date) {
    final dateStr = GrowthDateUtils.formatDateKey(date);
    return (_db.select(_db.sleepRecords)
          ..where((t) => t.sleepDate.equals(dateStr))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// 获取最近 [limit] 条睡眠记录（按日期倒序）。
  Future<List<SleepRecord>> getRecentSleepRecords({int limit = 10}) {
    return (_db.select(_db.sleepRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.sleepDate)])
          ..limit(limit))
        .get();
  }

  /// 获取指定日期范围内的睡眠记录（按日期正序）。
  Future<List<SleepRecord>> getSleepRecordsByRange(
    DateTime start,
    DateTime end,
  ) {
    final startStr = GrowthDateUtils.formatDateKey(start);
    final endStr = GrowthDateUtils.formatDateKey(end);
    return (_db.select(_db.sleepRecords)
          ..where(
            (t) =>
                t.sleepDate.isBiggerOrEqualValue(startStr) &
                t.sleepDate.isSmallerOrEqualValue(endStr),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.sleepDate)]))
        .get();
  }

  /// 根据 ID 获取单条睡眠记录。
  Future<SleepRecord?> getSleepRecordById(int id) {
    return (_db.select(
      _db.sleepRecords,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // 统计查询
  // ---------------------------------------------------------------------------

  /// 获取最近 [days] 天的平均睡眠时长（分钟）。
  Future<double?> getAvgSleepDuration(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    final startStr = GrowthDateUtils.formatDateKey(start);
    final endStr = GrowthDateUtils.formatDateKey(now);

    final result =
        await (_db.selectOnly(_db.sleepRecords)
              ..addColumns([_db.sleepRecords.durationMinutes.avg()])
              ..where(
                _db.sleepRecords.sleepDate.isBiggerOrEqualValue(startStr) &
                    _db.sleepRecords.sleepDate.isSmallerOrEqualValue(endStr),
              ))
            .getSingle();
    return result.read(_db.sleepRecords.durationMinutes.avg());
  }

  /// 获取最近 [days] 天的平均睡眠质量。
  Future<double?> getAvgSleepQuality(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    final startStr = GrowthDateUtils.formatDateKey(start);
    final endStr = GrowthDateUtils.formatDateKey(now);

    final result =
        await (_db.selectOnly(_db.sleepRecords)
              ..addColumns([_db.sleepRecords.qualityLevel.avg()])
              ..where(
                _db.sleepRecords.sleepDate.isBiggerOrEqualValue(startStr) &
                    _db.sleepRecords.sleepDate.isSmallerOrEqualValue(endStr),
              ))
            .getSingle();
    return result.read(_db.sleepRecords.qualityLevel.avg());
  }

  /// 获取最近 [days] 天的平均入睡时间（返回 HH:mm 格式）。
  Future<String?> getAvgBedTime(int days) async {
    final records = await getRecentSleepRecords(limit: days);
    if (records.isEmpty) return null;

    final times = records.map((r) => r.bedTime).toList();
    return _circularMean(times);
  }

  /// 获取最近 [days] 天的平均起床时间（返回 HH:mm 格式）。
  Future<String?> getAvgWakeTime(int days) async {
    final records = await getRecentSleepRecords(limit: days);
    if (records.isEmpty) return null;

    final times = records.map((r) => r.wakeTime).toList();
    return _circularMean(times);
  }

  /// 使用圆形均值算法计算平均时间（正确处理跨午夜时间）。
  String _circularMean(List<String> times) {
    if (times.isEmpty) return '--:--';

    double sinSum = 0;
    double cosSum = 0;

    for (final time in times) {
      final parts = time.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final minutes = hour * 60 + minute;
      final radians = minutes * 2 * pi / (24 * 60);
      sinSum += sin(radians);
      cosSum += cos(radians);
    }

    final avgRadians = atan2(sinSum, cosSum);
    var avgMinutes = (avgRadians * 24 * 60 / (2 * pi)).round();
    if (avgMinutes < 0) avgMinutes += 24 * 60;

    final h = avgMinutes ~/ 60;
    final m = avgMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// 获取最近 [days] 天的每日睡眠时长。
  ///
  /// Returns a list of maps with 'date' and 'duration' keys.
  Future<List<Map<String, dynamic>>> getDailySleepDuration(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    final startStr = GrowthDateUtils.formatDateKey(start);
    final endStr = GrowthDateUtils.formatDateKey(now);

    final records =
        await (_db.select(_db.sleepRecords)
              ..where(
                (t) =>
                    t.sleepDate.isBiggerOrEqualValue(startStr) &
                    t.sleepDate.isSmallerOrEqualValue(endStr),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.sleepDate)]))
            .get();

    return records
        .map((r) => {'date': r.sleepDate, 'duration': r.durationMinutes})
        .toList();
  }

  /// 获取最近 [days] 天的每日睡眠质量。
  ///
  /// Returns a list of maps with 'date' and 'quality' keys.
  Future<List<Map<String, dynamic>>> getDailySleepQuality(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    final startStr = GrowthDateUtils.formatDateKey(start);
    final endStr = GrowthDateUtils.formatDateKey(now);

    final records =
        await (_db.select(_db.sleepRecords)
              ..where(
                (t) =>
                    t.sleepDate.isBiggerOrEqualValue(startStr) &
                    t.sleepDate.isSmallerOrEqualValue(endStr),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.sleepDate)]))
            .get();

    return records
        .map((r) => {'date': r.sleepDate, 'quality': r.qualityLevel})
        .toList();
  }

  /// 获取昨晚的睡眠记录。
  Future<SleepRecord?> getLastNightSleepRecord() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return getSleepRecordByDate(yesterday);
  }
}
