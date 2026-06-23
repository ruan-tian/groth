import 'dart:io';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../utils/date_utils.dart';
import 'exp_repository.dart';

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

  Future<int> createJournalWithAssetsAndExp({
    required DailyJournalsCompanion journal,
    required List<String> assetPaths,
    required int exp,
    required String reason,
    required int createdAt,
  }) {
    return _db.transaction(() async {
      final journalId = await insertJournal(journal);
      final uniquePaths = assetPaths.toSet().toList(growable: false);
      for (var i = 0; i < uniquePaths.length; i++) {
        await insertJournalAsset(
          JournalAssetsCompanion.insert(
            journalId: journalId,
            localPath: uniquePaths[i],
            sortOrder: Value(i),
            createdAt: createdAt,
          ),
        );
      }
      if (exp > 0) {
        await ExpRepository(_db).insertExpLog(
          GrowthExpLogsCompanion.insert(
            sourceType: 'journal',
            sourceId: journalId,
            expValue: exp,
            reason: reason,
            createdAt: createdAt,
          ),
        );
      }
      return journalId;
    });
  }

  /// 更新一篇日记（以 companion 中的 id 为准）。
  Future<void> updateJournal(DailyJournalsCompanion journal) {
    return _db.update(_db.dailyJournals).replace(journal);
  }

  Future<void> updateJournalWithExp({
    required int journalId,
    required DailyJournalsCompanion journal,
    required int exp,
    required bool replaceExpLog,
    required String reason,
    required int createdAt,
  }) {
    return _db.transaction(() async {
      await updateJournal(journal);
      if (!replaceExpLog) return;
      final expRepo = ExpRepository(_db);
      await expRepo.deleteExpLogsForSource('journal', journalId);
      if (exp > 0) {
        await expRepo.insertExpLog(
          GrowthExpLogsCompanion.insert(
            sourceType: 'journal',
            sourceId: journalId,
            expValue: exp,
            reason: reason,
            createdAt: createdAt,
          ),
        );
      }
    });
  }

  /// 根据 ID 删除一篇日记（级联删除附件）。
  Future<void> deleteJournal(int id) async {
    await _db.transaction(() async {
      await deleteJournalAssets(id);
      await (_db.delete(_db.dailyJournals)..where((t) => t.id.equals(id))).go();
      await ExpRepository(_db).deleteExpLogsForSource('journal', id);
    });
  }

  // ---------------------------------------------------------------------------
  // 查询
  // ---------------------------------------------------------------------------

  /// 获取指定日期的日记列表。
  ///
  /// DailyJournals 使用 `journalDate`（YYYY-MM-DD 字符串）存储日期，
  /// 直接按字符串匹配即可。
  Future<List<DailyJournal>> getJournalsByDate(DateTime date) {
    final dateStr = GrowthDateUtils.formatDateKey(date);
    return (_db.select(_db.dailyJournals)
          ..where((t) => t.journalDate.equals(dateStr))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取日期范围内的日记列表（包含 start 和 end 当天）。
  ///
  /// 由于 `journalDate` 是 YYYY-MM-DD 格式字符串，字典序等价于日期序，
  /// 可直接用字符串比较进行范围过滤。
  Future<List<DailyJournal>> getJournalsByRange(DateTime start, DateTime end) {
    final startStr = GrowthDateUtils.formatDateKey(start);
    final endStr = GrowthDateUtils.formatDateKey(end);
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
    return (_db.select(
      _db.dailyJournals,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<DailyJournal>> getRecentJournals({int limit = 5}) {
    return (_db.select(_db.dailyJournals)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<int> getTotalJournalCount() async {
    final count = _db.dailyJournals.id.count();
    final query = _db.selectOnly(_db.dailyJournals)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<List<DailyJournal>> getJournalsByFolder({
    int? folderId,
    bool uncategorizedOnly = false,
  }) {
    final query = _db.select(_db.dailyJournals)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (uncategorizedOnly) {
      query.where((t) => t.folderId.isNull());
    } else if (folderId != null) {
      query.where((t) => t.folderId.equals(folderId));
    }
    return query.get();
  }

  // ---------------------------------------------------------------------------
  // 文件夹
  // ---------------------------------------------------------------------------

  Future<List<JournalFolder>> getFolders() {
    return (_db.select(_db.journalFolders)..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
        .get();
  }

  Future<int> createFolder({
    required String name,
    int colorValue = 0xFFEFA6BA,
    int iconCodePoint = 0xe2c7,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final countExp = _db.journalFolders.id.count();
    final countQuery = _db.selectOnly(_db.journalFolders)
      ..addColumns([countExp]);
    final count = (await countQuery.getSingle()).read(countExp) ?? 0;
    return _db
        .into(_db.journalFolders)
        .insert(
          JournalFoldersCompanion.insert(
            name: name.trim(),
            colorValue: Value(colorValue),
            iconCodePoint: Value(iconCodePoint),
            sortOrder: Value(count),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateFolder({
    required int id,
    required String name,
    int? colorValue,
    int? iconCodePoint,
  }) {
    return (_db.update(
      _db.journalFolders,
    )..where((t) => t.id.equals(id))).write(
      JournalFoldersCompanion(
        name: Value(name.trim()),
        colorValue: colorValue == null
            ? const Value.absent()
            : Value(colorValue),
        iconCodePoint: iconCodePoint == null
            ? const Value.absent()
            : Value(iconCodePoint),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> deleteFolder(int id) {
    return _db.transaction(() async {
      await (_db.update(_db.dailyJournals)..where((t) => t.folderId.equals(id)))
          .write(const DailyJournalsCompanion(folderId: Value(null)));
      await (_db.delete(
        _db.journalFolders,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> moveJournalToFolder(int journalId, int? folderId) {
    return (_db.update(
      _db.dailyJournals,
    )..where((t) => t.id.equals(journalId))).write(
      DailyJournalsCompanion(
        folderId: Value(folderId),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
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

  /// 删除日记的所有附件（包括物理文件）
  Future<void> deleteJournalAssets(int journalId) async {
    // First query all assets to get their file paths
    final assets = await (_db.select(
      _db.journalAssets,
    )..where((t) => t.journalId.equals(journalId))).get();
    // Delete physical files
    for (final asset in assets) {
      try {
        final file = File(asset.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore file deletion errors (file may already be missing)
      }
    }
    // Delete DB records
    await (_db.delete(
      _db.journalAssets,
    )..where((t) => t.journalId.equals(journalId))).go();
  }
}
