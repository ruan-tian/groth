import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../pet/repositories/exp_repository.dart';
import '../../../core/utils/date_utils.dart';

/// 饮食记录仓库
///
/// 封装饮食记录表的 CRUD 操作与常用查询。
class DietRepository {
  DietRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // 饮食记录 CRUD
  // ---------------------------------------------------------------------------

  /// 插入一条饮食记录，返回自增 ID。
  Future<int> insertDietRecord(DietRecordsCompanion record) {
    return _db.into(_db.dietRecords).insert(record);
  }

  Future<int> saveDietRecordWithExp({
    required DietRecordsCompanion record,
    required int exp,
    required String reason,
    required int createdAt,
  }) {
    return _db.transaction(() async {
      final recordId = await insertDietRecord(record);
      if (exp > 0) {
        await ExpRepository(_db).insertExpLog(
          GrowthExpLogsCompanion.insert(
            sourceType: 'diet',
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

  /// 更新一条饮食记录。
  Future<void> updateDietRecord(DietRecordsCompanion record) {
    return _db.update(_db.dietRecords).replace(record);
  }

  /// 根据 ID 删除一条饮食记录。
  Future<void> deleteDietRecord(int id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.dietRecords)..where((t) => t.id.equals(id))).go();
      await ExpRepository(_db).deleteExpLogsForSource('diet', id);
    });
  }

  // ---------------------------------------------------------------------------
  // 饮食记录查询
  // ---------------------------------------------------------------------------

  /// 获取指定日期的饮食记录（按创建时间倒序）。
  Future<List<DietRecord>> getDietRecordsByDate(DateTime date) {
    final dateStr = GrowthDateUtils.formatDateKey(date);
    return (_db.select(_db.dietRecords)
          ..where((t) => t.mealDate.equals(dateStr))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取最近 [limit] 条饮食记录（按创建时间倒序）。
  Future<List<DietRecord>> getRecentDietRecords({int limit = 10}) {
    return (_db.select(_db.dietRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 获取指定日期范围内的饮食记录（按日期正序）。
  Future<List<DietRecord>> getDietRecordsByRange(DateTime start, DateTime end) {
    final startStr = GrowthDateUtils.formatDateKey(start);
    final endStr = GrowthDateUtils.formatDateKey(end);
    return (_db.select(_db.dietRecords)
          ..where(
            (t) =>
                t.mealDate.isBiggerOrEqualValue(startStr) &
                t.mealDate.isSmallerOrEqualValue(endStr),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.mealDate)]))
        .get();
  }

  /// 根据 ID 获取单条饮食记录。
  Future<DietRecord?> getDietRecordById(int id) {
    return (_db.select(
      _db.dietRecords,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // 统计查询
  // ---------------------------------------------------------------------------

  /// 获取指定日期的饮食次数。
  Future<int> getDietCountByDate(DateTime date) async {
    final dateStr = GrowthDateUtils.formatDateKey(date);
    final result =
        await (_db.selectOnly(_db.dietRecords)
              ..addColumns([_db.dietRecords.id.count()])
              ..where(_db.dietRecords.mealDate.equals(dateStr)))
            .getSingle();
    return result.read(_db.dietRecords.id.count()) ?? 0;
  }

  /// 获取指定日期的平均健康评分。
  Future<double?> getAvgHealthScoreByDate(DateTime date) async {
    final dateStr = GrowthDateUtils.formatDateKey(date);
    final result =
        await (_db.selectOnly(_db.dietRecords)
              ..addColumns([_db.dietRecords.healthScore.avg()])
              ..where(_db.dietRecords.mealDate.equals(dateStr)))
            .getSingle();
    return result.read(_db.dietRecords.healthScore.avg());
  }

  /// 获取最近 [days] 天的每日平均健康评分。
  ///
  /// 返回 Map<日期字符串, 平均评分>。
  Future<Map<String, double>> getDailyAvgHealthScore(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    final startStr = GrowthDateUtils.formatDateKey(start);
    final endStr = GrowthDateUtils.formatDateKey(now);

    final query = _db.selectOnly(_db.dietRecords)
      ..addColumns([
        _db.dietRecords.mealDate,
        _db.dietRecords.healthScore.avg(),
      ])
      ..where(
        _db.dietRecords.mealDate.isBiggerOrEqualValue(startStr) &
            _db.dietRecords.mealDate.isSmallerOrEqualValue(endStr),
      )
      ..groupBy([_db.dietRecords.mealDate])
      ..orderBy([OrderingTerm.asc(_db.dietRecords.mealDate)]);

    final results = await query.get();
    final map = <String, double>{};
    for (final row in results) {
      final date = row.read(_db.dietRecords.mealDate)!;
      final avg = row.read(_db.dietRecords.healthScore.avg());
      if (avg != null) {
        map[date] = avg;
      }
    }
    return map;
  }

  /// 获取今日饮食记录。
  Future<List<DietRecord>> getTodayDietRecords() {
    return getDietRecordsByDate(DateTime.now());
  }

  /// 获取今日饮食次数。
  Future<int> getTodayDietCount() {
    return getDietCountByDate(DateTime.now());
  }
}
