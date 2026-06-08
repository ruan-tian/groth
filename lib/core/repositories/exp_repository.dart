import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 经验值仓库
///
/// 封装所有与经验值日志（GrowthExpLogs）相关的数据库操作。
class ExpRepository {
  ExpRepository(this._db);

  final AppDatabase _db;

  /// 插入一条经验日志，返回自增 ID。
  Future<int> insertExpLog(GrowthExpLogsCompanion log) {
    return _db.into(_db.growthExpLogs).insert(log);
  }

  /// 获取全部经验值总和。
  Future<int> getTotalExp() async {
    final expSum = _db.growthExpLogs.expValue.sum();
    final query = _db.selectOnly(_db.growthExpLogs)..addColumns([expSum]);
    final result = await query.getSingle();
    return result.read(expSum) ?? 0;
  }

  /// 按来源类型（study / fitness / journal / focus）获取经验值总和。
  Future<int> getTotalExpBySource(String sourceType) async {
    final expSum = _db.growthExpLogs.expValue.sum();
    final query = _db.selectOnly(_db.growthExpLogs)
      ..addColumns([expSum])
      ..where(_db.growthExpLogs.sourceType.equals(sourceType));
    final result = await query.getSingle();
    return result.read(expSum) ?? 0;
  }

  /// 获取指定日期的经验值总和。
  ///
  /// [date] 会被归一化到当天 00:00:00 ~ 23:59:59.999 的毫秒时间戳范围。
  Future<int> getTotalExpByDate(DateTime date) async {
    final range = _dayRange(date);
    final expSum = _db.growthExpLogs.expValue.sum();
    final query = _db.selectOnly(_db.growthExpLogs)
      ..addColumns([expSum])
      ..where(
        _db.growthExpLogs.createdAt.isBiggerOrEqualValue(range.$1) &
            _db.growthExpLogs.createdAt.isSmallerOrEqualValue(range.$2),
      );
    final result = await query.getSingle();
    return result.read(expSum) ?? 0;
  }

  /// 获取指定日期的全部经验日志。
  Future<List<GrowthExpLog>> getExpLogsByDate(DateTime date) {
    final range = _dayRange(date);
    return (_db.select(_db.growthExpLogs)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(range.$1) &
                t.createdAt.isSmallerOrEqualValue(range.$2),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取日期范围 [start, end] 内的全部经验日志。
  ///
  /// [start] 和 [end] 均会被归一化到当天的起止毫秒时间戳。
  Future<List<GrowthExpLog>> getExpLogsByRange(
    DateTime start,
    DateTime end,
  ) {
    final startRange = _dayRange(start);
    final endRange = _dayRange(end);
    return (_db.select(_db.growthExpLogs)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(startRange.$1) &
                t.createdAt.isSmallerOrEqualValue(endRange.$2),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 将 [date] 归一化为当天 00:00:00.000 和 23:59:59.999 的毫秒时间戳。
  (int startMs, int endMs) _dayRange(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
  }

  /// 获取最近连续活跃天数（从昨天开始往前数，直到中断）
  Future<int> getConsecutiveActiveDays() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    int count = 0;
    for (int i = 0; i < 365; i++) {
      final date = yesterday.subtract(Duration(days: i));
      final total = await getTotalExpByDate(date);
      if (total > 0) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }
}
