import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../pet/repositories/exp_repository.dart';

/// 专注记录仓库
///
/// 封装专注记录表的 CRUD 操作与常用查询。
class FocusRepository {
  FocusRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// 插入一条专注记录，返回自增 ID。
  Future<int> insertFocusSession(FocusSessionsCompanion session) {
    return _db.into(_db.focusSessions).insert(session);
  }

  Future<FocusRoundSaveResult> saveFocusRound({
    required FocusSessionsCompanion session,
    required StudyRecordsCompanion studyRecord,
    int? expValue,
    String? expReason,
    required int createdAt,
  }) {
    return _db.transaction(() async {
      final groupId = session.sessionGroupId.value;
      final roundIndex = session.roundIndex.value;
      final completed = session.completed.value;

      if (groupId != null && roundIndex != null) {
        final existing = await getFocusSessionByGroupRound(
          groupId: groupId,
          roundIndex: roundIndex,
          completed: completed,
        );
        if (existing != null) {
          return FocusRoundSaveResult(sessionId: existing.id, inserted: false);
        }
      }

      final sessionId = await _db.into(_db.focusSessions).insert(session);
      if (expValue != null && expValue > 0) {
        await _db
            .into(_db.growthExpLogs)
            .insert(
              GrowthExpLogsCompanion(
                sourceType: const Value('focus'),
                sourceId: Value(sessionId),
                expValue: Value(expValue),
                reason: Value(expReason ?? ''),
                createdAt: Value(createdAt),
              ),
            );
      }

      final studyId = await _db.into(_db.studyRecords).insert(studyRecord);
      await updateFocusSessionStudyLink(sessionId, studyId);
      return FocusRoundSaveResult(sessionId: sessionId, inserted: true);
    });
  }

  /// 更新指定专注记录关联的学习记录 ID。
  Future<void> updateFocusSessionStudyLink(int id, int studyId) {
    return (_db.update(_db.focusSessions)..where((t) => t.id.equals(id))).write(
      FocusSessionsCompanion(relatedStudyId: Value(studyId)),
    );
  }

  /// 根据 ID 删除一条专注记录。
  Future<void> deleteFocusSession(int id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.focusSessions)..where((t) => t.id.equals(id))).go();
      await ExpRepository(_db).deleteExpLogsForSource('focus', id);
    });
  }

  // ---------------------------------------------------------------------------
  // 查询
  // ---------------------------------------------------------------------------

  /// 获取指定日期的专注记录（按 startTime 毫秒时间戳范围过滤）。
  Future<List<FocusSession>> getFocusSessionsByDate(DateTime date) {
    final range = _dayRange(date);
    return (_db.select(_db.focusSessions)
          ..where(
            (t) =>
                t.startTime.isBiggerOrEqualValue(range.start) &
                t.startTime.isSmallerThanValue(range.end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
        .get();
  }

  /// 获取最近的 [limit] 条专注记录（按创建时间倒序）。
  Future<List<FocusSession>> getRecentFocusSessions({int limit = 10}) {
    return (_db.select(_db.focusSessions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 获取指定日期的专注总时长（分钟）。
  ///
  /// 若当天无记录则返回 0。
  Future<int> getTotalFocusMinutesByDate(DateTime date) async {
    final range = _dayRange(date);
    final result =
        await (_db.selectOnly(_db.focusSessions)
              ..addColumns([_db.focusSessions.durationMinutes.sum()])
              ..where(
                _db.focusSessions.startTime.isBiggerOrEqualValue(range.start) &
                    _db.focusSessions.startTime.isSmallerThanValue(range.end),
              ))
            .getSingle();
    return result.read(_db.focusSessions.durationMinutes.sum()) ?? 0;
  }

  /// 获取同一 cycle 的所有专注记录（按轮次排序）。
  Future<List<FocusSession>> getFocusSessionsByGroupId(String groupId) {
    return (_db.select(_db.focusSessions)
          ..where((t) => t.sessionGroupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm.asc(t.roundIndex)]))
        .get();
  }

  Future<FocusSession?> getFocusSessionByGroupRound({
    required String groupId,
    required int roundIndex,
    required bool completed,
  }) {
    return (_db.select(_db.focusSessions)
          ..where(
            (t) =>
                t.sessionGroupId.equals(groupId) &
                t.roundIndex.equals(roundIndex) &
                t.completed.equals(completed),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------------

  /// 返回当天 [startMs, endMs) 的毫秒时间戳范围。
  _DayRange _dayRange(DateTime date) {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch;
    final end = DateTime(
      date.year,
      date.month,
      date.day + 1,
    ).millisecondsSinceEpoch;
    return _DayRange(start, end);
  }
}

/// 一天的毫秒时间戳区间 [start, end)。
class _DayRange {
  const _DayRange(this.start, this.end);
  final int start;
  final int end;
}

class FocusRoundSaveResult {
  const FocusRoundSaveResult({required this.sessionId, required this.inserted});

  final int sessionId;
  final bool inserted;
}
