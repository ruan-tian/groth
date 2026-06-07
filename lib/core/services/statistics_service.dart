import 'package:drift/drift.dart';

import '../database/app_database.dart';

// =============================================================================
// 数据模型
// =============================================================================

/// 今日统计概览
class TodayStats {
  const TodayStats({
    required this.studyMinutes,
    required this.fitnessMinutes,
    required this.journalCount,
    required this.totalExp,
  });

  final int studyMinutes;
  final int fitnessMinutes;
  final int journalCount;
  final int totalExp;
}

/// 每日统计（用于周 / 月视图）
class DailyStats {
  const DailyStats({
    required this.date,
    required this.studyMinutes,
    required this.fitnessMinutes,
    required this.expGained,
  });

  final DateTime date;
  final int studyMinutes;
  final int fitnessMinutes;
  final int expGained;
}

/// 月度统计（用于年度视图）
class MonthlyStats {
  const MonthlyStats({
    required this.month,
    required this.studyMinutes,
    required this.fitnessMinutes,
    required this.expGained,
  });

  /// 格式：YYYY-MM
  final String month;
  final int studyMinutes;
  final int fitnessMinutes;
  final int expGained;
}

// =============================================================================
// 统计服务
// =============================================================================

/// 统计服务
///
/// 提供今日 / 周 / 月 / 年维度的成长数据聚合查询。
class StatisticsService {
  StatisticsService(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // 今日统计
  // ---------------------------------------------------------------------------

  /// 获取今日概览：学习时长、健身时长、日记篇数、总经验。
  Future<TodayStats> getTodayStats() async {
    final now = DateTime.now();
    final range = _dayRange(now);

    // 学习总时长
    final studySum = _db.studyRecords.durationMinutes.sum();
    final studyQuery = _db.selectOnly(_db.studyRecords)
      ..addColumns([studySum])
      ..where(
        _db.studyRecords.createdAt.isBiggerOrEqualValue(range.start) &
            _db.studyRecords.createdAt.isSmallerThanValue(range.end),
      );
    final studyResult = await studyQuery.getSingle();
    final studyMinutes = studyResult.read(studySum) ?? 0;

    // 健身总时长
    final fitnessSum = _db.fitnessRecords.durationMinutes.sum();
    final fitnessQuery = _db.selectOnly(_db.fitnessRecords)
      ..addColumns([fitnessSum])
      ..where(
        _db.fitnessRecords.createdAt.isBiggerOrEqualValue(range.start) &
            _db.fitnessRecords.createdAt.isSmallerThanValue(range.end),
      );
    final fitnessResult = await fitnessQuery.getSingle();
    final fitnessMinutes = fitnessResult.read(fitnessSum) ?? 0;

    // 日记篇数
    final journalCountExp = _db.dailyJournals.id.count();
    final todayStr = _formatDate(now);
    final journalQuery = _db.selectOnly(_db.dailyJournals)
      ..addColumns([journalCountExp])
      ..where(_db.dailyJournals.journalDate.equals(todayStr));
    final journalResult = await journalQuery.getSingle();
    final journalCount = journalResult.read(journalCountExp) ?? 0;

    // 今日总经验
    final expSum = _db.growthExpLogs.expValue.sum();
    final expQuery = _db.selectOnly(_db.growthExpLogs)
      ..addColumns([expSum])
      ..where(
        _db.growthExpLogs.createdAt.isBiggerOrEqualValue(range.start) &
            _db.growthExpLogs.createdAt.isSmallerThanValue(range.end),
      );
    final expResult = await expQuery.getSingle();
    final totalExp = expResult.read(expSum) ?? 0;

    return TodayStats(
      studyMinutes: studyMinutes,
      fitnessMinutes: fitnessMinutes,
      journalCount: journalCount,
      totalExp: totalExp,
    );
  }

  // ---------------------------------------------------------------------------
  // 周统计（最近 7 天）
  // ---------------------------------------------------------------------------

  /// 获取最近 7 天的每日统计。
  Future<List<DailyStats>> getWeeklyStats() async {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    return _getDailyStatsForDays(days);
  }

  // ---------------------------------------------------------------------------
  // 月统计（最近 30 天）
  // ---------------------------------------------------------------------------

  /// 获取最近 30 天的每日统计。
  Future<List<DailyStats>> getMonthlyStats() async {
    final now = DateTime.now();
    final days =
        List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));
    return _getDailyStatsForDays(days);
  }

  // ---------------------------------------------------------------------------
  // 年统计（最近 12 个月）
  // ---------------------------------------------------------------------------

  /// 获取最近 12 个月的月度统计。
  Future<List<MonthlyStats>> getYearlyStats() async {
    final current = DateTime.now();
    final now = DateTime(current.year, current.month, 1);
    final months = List.generate(12, (i) {
      final m = now.month - (11 - i);
      final y = now.year + ((m - 1) ~/ 12);
      final mo = ((m - 1) % 12) + 1;
      return DateTime(y, mo, 1);
    });

    final results = <MonthlyStats>[];
    for (final monthStart in months) {
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
      final startMs = monthStart.millisecondsSinceEpoch;
      final endMs = monthEnd.millisecondsSinceEpoch;

      // 该月学习总时长
      final studySum = _db.studyRecords.durationMinutes.sum();
      final studyQuery = _db.selectOnly(_db.studyRecords)
        ..addColumns([studySum])
        ..where(
          _db.studyRecords.createdAt.isBiggerOrEqualValue(startMs) &
              _db.studyRecords.createdAt.isSmallerThanValue(endMs),
        );
      final studyResult = await studyQuery.getSingle();
      final studyMinutes = studyResult.read(studySum) ?? 0;

      // 该月健身总时长
      final fitnessSum = _db.fitnessRecords.durationMinutes.sum();
      final fitnessQuery = _db.selectOnly(_db.fitnessRecords)
        ..addColumns([fitnessSum])
        ..where(
          _db.fitnessRecords.createdAt.isBiggerOrEqualValue(startMs) &
              _db.fitnessRecords.createdAt.isSmallerThanValue(endMs),
        );
      final fitnessResult = await fitnessQuery.getSingle();
      final fitnessMinutes = fitnessResult.read(fitnessSum) ?? 0;

      // 该月总经验
      final expSum = _db.growthExpLogs.expValue.sum();
      final expQuery = _db.selectOnly(_db.growthExpLogs)
        ..addColumns([expSum])
        ..where(
          _db.growthExpLogs.createdAt.isBiggerOrEqualValue(startMs) &
              _db.growthExpLogs.createdAt.isSmallerThanValue(endMs),
        );
      final expResult = await expQuery.getSingle();
      final expGained = expResult.read(expSum) ?? 0;

      final label =
          '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}';
      results.add(MonthlyStats(
        month: label,
        studyMinutes: studyMinutes,
        fitnessMinutes: fitnessMinutes,
        expGained: expGained,
      ));
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------------

  /// 批量获取多天的每日统计。
  Future<List<DailyStats>> _getDailyStatsForDays(List<DateTime> days) async {
    final results = <DailyStats>[];
    for (final day in days) {
      final range = _dayRange(day);

      // 学习时长
      final studySum = _db.studyRecords.durationMinutes.sum();
      final studyQuery = _db.selectOnly(_db.studyRecords)
        ..addColumns([studySum])
        ..where(
          _db.studyRecords.createdAt.isBiggerOrEqualValue(range.start) &
              _db.studyRecords.createdAt.isSmallerThanValue(range.end),
        );
      final studyResult = await studyQuery.getSingle();
      final studyMinutes = studyResult.read(studySum) ?? 0;

      // 健身时长
      final fitnessSum = _db.fitnessRecords.durationMinutes.sum();
      final fitnessQuery = _db.selectOnly(_db.fitnessRecords)
        ..addColumns([fitnessSum])
        ..where(
          _db.fitnessRecords.createdAt.isBiggerOrEqualValue(range.start) &
              _db.fitnessRecords.createdAt.isSmallerThanValue(range.end),
        );
      final fitnessResult = await fitnessQuery.getSingle();
      final fitnessMinutes = fitnessResult.read(fitnessSum) ?? 0;

      // 经验值
      final expSum = _db.growthExpLogs.expValue.sum();
      final expQuery = _db.selectOnly(_db.growthExpLogs)
        ..addColumns([expSum])
        ..where(
          _db.growthExpLogs.createdAt.isBiggerOrEqualValue(range.start) &
              _db.growthExpLogs.createdAt.isSmallerThanValue(range.end),
        );
      final expResult = await expQuery.getSingle();
      final expGained = expResult.read(expSum) ?? 0;

      results.add(DailyStats(
        date: day,
        studyMinutes: studyMinutes,
        fitnessMinutes: fitnessMinutes,
        expGained: expGained,
      ));
    }
    return results;
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

  /// 将 [DateTime] 格式化为 YYYY-MM-DD 字符串（用于 DailyJournals 表）。
  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// 一天的毫秒时间戳区间 [start, end)。
class _DayRange {
  const _DayRange(this.start, this.end);
  final int start;
  final int end;
}
