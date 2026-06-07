import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 成长日记仓库
///
/// 封装每日成长日记表的 CRUD 操作与常用查询。
class JournalRepository {
  JournalRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// 插入一篇日记，返回自增 ID。
  Future<int> insertJournal(DailyJournalsCompanion journal) {
    return _db.into(_db.dailyJournals).insert(journal);
  }

  /// 更新一篇日记（以 companion 中的 id 为准）。
  Future<void> updateJournal(DailyJournalsCompanion journal) {
    return _db.update(_db.dailyJournals).replace(journal);
  }

  /// 根据 ID 删除一篇日记。
  Future<void> deleteJournal(int id) {
    return (_db.delete(_db.dailyJournals)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // 查询
  // ---------------------------------------------------------------------------

  /// 获取指定日期的日记列表。
  ///
  /// DailyJournals 使用 `journalDate`（YYYY-MM-DD 字符串）存储日期，
  /// 直接按字符串匹配即可。
  Future<List<DailyJournal>> getJournalsByDate(DateTime date) {
    final dateStr = _formatDate(date);
    return (_db.select(_db.dailyJournals)
          ..where((t) => t.journalDate.equals(dateStr))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取日期范围内的日记列表（包含 start 和 end 当天）。
  ///
  /// 由于 `journalDate` 是 YYYY-MM-DD 格式字符串，字典序等价于日期序，
  /// 可直接用字符串比较进行范围过滤。
  Future<List<DailyJournal>> getJournalsByRange(
    DateTime start,
    DateTime end,
  ) {
    final startStr = _formatDate(start);
    final endStr = _formatDate(end);
    return (_db.select(_db.dailyJournals)
          ..where(
            (t) =>
                t.journalDate.isBiggerOrEqualValue(startStr) &
                t.journalDate.isSmallerOrEqualValue(endStr),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 根据 ID 获取单篇日记。
  ///
  /// 若不存在则返回 `null`。
  Future<DailyJournal?> getJournalById(int id) {
    return (_db.select(_db.dailyJournals)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // 附件
  // ---------------------------------------------------------------------------

  /// 插入日记附件
  Future<int> insertJournalAsset(JournalAssetsCompanion asset) {
    return _db.into(_db.journalAssets).insert(asset);
  }

  /// 获取日记的所有附件
  Future<List<JournalAsset>> getJournalAssets(int journalId) {
    return (_db.select(_db.journalAssets)
          ..where((t) => t.journalId.equals(journalId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// 删除日记的所有附件
  Future<void> deleteJournalAssets(int journalId) {
    return (_db.delete(_db.journalAssets)
          ..where((t) => t.journalId.equals(journalId)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------------

  /// 将 [DateTime] 格式化为 YYYY-MM-DD 字符串。
  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
