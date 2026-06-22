import 'package:drift/drift.dart';

import '../database/app_database.dart';

// =============================================================================
// 数据模型
// =============================================================================

/// 每日统计概览
class DailyStats {
  const DailyStats({
    required this.date,
    required this.studyMinutes,
    required this.studySessions,
    required this.fitnessMinutes,
    required this.fitnessSessions,
    required this.journalCount,
    required this.journalWordCount,
    required this.dietCount,
    required this.sleepMinutes,
    this.sleepQuality,
    required this.focusMinutes,
    required this.focusSessions,
    required this.expGained,
    required this.taskTotal,
    required this.taskCompleted,
  });

  final DateTime date;
  final int studyMinutes;
  final int studySessions;
  final int fitnessMinutes;
  final int fitnessSessions;
  final int journalCount;
  final int journalWordCount;
  final int dietCount;
  final int sleepMinutes;
  final double? sleepQuality;
  final int focusMinutes;
  final int focusSessions;
  final int expGained;
  final int taskTotal;
  final int taskCompleted;

  double get completionRate => taskTotal > 0 ? taskCompleted / taskTotal : 0.0;

  int get activeModules {
    int count = 0;
    if (studyMinutes > 0) count++;
    if (fitnessMinutes > 0) count++;
    if (journalCount > 0) count++;
    if (dietCount > 0) count++;
    if (sleepMinutes > 0) count++;
    if (focusMinutes > 0) count++;
    return count;
  }

  bool get isActiveDay => activeModules > 0;

  /// 零值占位实例，用于日期无数据时返回
  factory DailyStats.empty(DateTime date) => DailyStats(
    date: date,
    studyMinutes: 0,
    studySessions: 0,
    fitnessMinutes: 0,
    fitnessSessions: 0,
    journalCount: 0,
    journalWordCount: 0,
    dietCount: 0,
    sleepMinutes: 0,
    focusMinutes: 0,
    focusSessions: 0,
    expGained: 0,
    taskTotal: 0,
    taskCompleted: 0,
  );
}

/// 月度聚合统计
class MonthlyAggregate {
  const MonthlyAggregate({
    required this.month,
    required this.studyMinutes,
    required this.fitnessMinutes,
    required this.journalCount,
    required this.dietCount,
    required this.sleepMinutes,
    required this.focusMinutes,
    required this.expGained,
    required this.activeDays,
    required this.taskTotal,
    required this.taskCompleted,
  });

  /// 格式：YYYY-MM
  final String month;
  final int studyMinutes;
  final int fitnessMinutes;
  final int journalCount;
  final int dietCount;
  final int sleepMinutes;
  final int focusMinutes;
  final int expGained;
  final int activeDays;
  final int taskTotal;
  final int taskCompleted;
}

// =============================================================================
// 统计服务
// =============================================================================

/// 统计服务
///
/// 提供今日 / 周 / 月 / 年维度的成长数据聚合查询。
/// 核心方法 [getDailyStatsRange] 通过少量批量查询 + Dart 层分组合并，
/// 避免逐天循环查询带来的 N+1 性能问题。
class StatisticsService {
  StatisticsService(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // 公共 API
  // ---------------------------------------------------------------------------

  /// 获取今日统计。
  Future<DailyStats> getTodayStats() async {
    final now = DateTime.now();
    final list = await getDailyStatsRange(now, now);
    return list.first;
  }

  /// 获取最近 7 天的每日统计（含今天）。
  Future<List<DailyStats>> getWeeklyStats() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    return getDailyStatsRange(start, now);
  }

  /// 获取最近 30 天的每日统计（含今天）。
  Future<List<DailyStats>> getMonthlyStats() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 29));
    return getDailyStatsRange(start, now);
  }

  /// 获取最近 12 个月的月度聚合统计。
  Future<List<MonthlyAggregate>> getYearlyStats() async {
    final now = DateTime.now();
    // 从 365 天前开始
    final start = now.subtract(const Duration(days: 364));
    final dailyList = await getDailyStatsRange(start, now);

    // 按月聚合
    final monthMap = <String, List<DailyStats>>{};
    for (final d in dailyList) {
      final key = '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}';
      (monthMap[key] ??= []).add(d);
    }

    // 生成最近 12 个月的标签（保证顺序）
    final months = <String>[];
    var cursor = DateTime(now.year, now.month, 1);
    for (int i = 0; i < 12; i++) {
      months.add('${cursor.year}-${cursor.month.toString().padLeft(2, '0')}');
      cursor = DateTime(cursor.year, cursor.month - 1, 1);
    }
    months.sort();

    return months.map((m) {
      final days = monthMap[m] ?? [];
      return MonthlyAggregate(
        month: m,
        studyMinutes: days.fold(0, (s, d) => s + d.studyMinutes),
        fitnessMinutes: days.fold(0, (s, d) => s + d.fitnessMinutes),
        journalCount: days.fold(0, (s, d) => s + d.journalCount),
        dietCount: days.fold(0, (s, d) => s + d.dietCount),
        sleepMinutes: days.fold(0, (s, d) => s + d.sleepMinutes),
        focusMinutes: days.fold(0, (s, d) => s + d.focusMinutes),
        expGained: days.fold(0, (s, d) => s + d.expGained),
        activeDays: days.where((d) => d.isActiveDay).length,
        taskTotal: days.fold(0, (s, d) => s + d.taskTotal),
        taskCompleted: days.fold(0, (s, d) => s + d.taskCompleted),
      );
    }).toList();
  }

  /// 计算连续打卡天数（从列表末尾往回数，遇到非活跃日停止）。
  ///
  /// 传入的 [stats] 应按日期升序排列（最早 → 最新）。
  int calculateStreak(List<DailyStats> stats) {
    if (stats.isEmpty) return 0;
    int streak = 0;
    for (int i = stats.length - 1; i >= 0; i--) {
      if (stats[i].isActiveDay) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// 获取指定日期范围内的每日统计（含 start 和 end 当天）。
  ///
  /// 核心查询策略：
  /// 1. 生成日期列表
  /// 2. 对每个数据源执行一次批量查询
  /// 3. 在 Dart 层按本地日期分组，合并为 DailyStats
  /// 4. 缺失日期用零值填充
  Future<List<DailyStats>> getDailyStatsRange(
    DateTime start,
    DateTime end,
  ) async {
    final startDate = _startOfDay(start);
    final endDate = _startOfDay(end);
    final startMs = startDate.millisecondsSinceEpoch;
    // end 当天 23:59:59.999 → 即 end+1 天 00:00:00
    final endExclusiveMs = endDate
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch;
    final startDateStr = _formatDate(startDate);
    final endDateStr = _formatDate(endDate);

    // ---- Step 1: 生成日期列表 ----
    final dateList = _generateDateRange(startDate, endDate);

    // ---- Steps 2-10: Parallel queries for all data sources ----
    final queryResults = await Future.wait([
      // Step 2: Study records
      (_db.select(_db.studyRecords)..where(
            (t) =>
                t.startTime.isBiggerOrEqualValue(startMs) &
                t.startTime.isSmallerThanValue(endExclusiveMs),
          ))
          .get(),
      // Step 3: Fitness records
      (_db.select(_db.fitnessRecords)..where(
            (t) =>
                t.startTime.isBiggerOrEqualValue(startMs) &
                t.startTime.isSmallerThanValue(endExclusiveMs),
          ))
          .get(),
      // Step 5: Journals
      (_db.select(_db.dailyJournals)..where(
            (t) =>
                t.journalDate.isBiggerOrEqualValue(startDateStr) &
                t.journalDate.isSmallerOrEqualValue(endDateStr),
          ))
          .get(),
      // Step 6: Diet records
      (_db.select(_db.dietRecords)..where(
            (t) =>
                t.mealDate.isBiggerOrEqualValue(startDateStr) &
                t.mealDate.isSmallerOrEqualValue(endDateStr),
          ))
          .get(),
      // Step 7: Sleep records
      (_db.select(_db.sleepRecords)..where(
            (t) =>
                t.sleepDate.isBiggerOrEqualValue(startDateStr) &
                t.sleepDate.isSmallerOrEqualValue(endDateStr),
          ))
          .get(),
      // Step 8: Focus sessions
      (_db.select(_db.focusSessions)..where(
            (t) =>
                t.startTime.isBiggerOrEqualValue(startMs) &
                t.startTime.isSmallerThanValue(endExclusiveMs),
          ))
          .get(),
      // Step 9: Exp logs
      (_db.select(_db.growthExpLogs)..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(startMs) &
                t.createdAt.isSmallerThanValue(endExclusiveMs),
          ))
          .get(),
      // Step 10: Daily tasks
      (_db.select(_db.dailyTasks)..where(
            (t) =>
                t.taskDate.isBiggerOrEqualValue(startDateStr) &
                t.taskDate.isSmallerOrEqualValue(endDateStr),
          ))
          .get(),
    ]);

    // Extract results from parallel query
    final studyRecords = queryResults[0] as List<StudyRecord>;
    final fitnessRecords = queryResults[1] as List<FitnessRecord>;
    final journalRows = queryResults[2] as List<DailyJournal>;
    final dietRows = queryResults[3] as List<DietRecord>;
    final sleepRows = queryResults[4] as List<SleepRecord>;
    final focusRows = queryResults[5] as List<FocusSession>;
    final expRows = queryResults[6] as List<GrowthExpLog>;
    final taskRows = queryResults[7] as List<DailyTask>;

    // Step 4: Fitness exercises (depends on fitness records)
    final fitnessRecordIds = fitnessRecords.map((r) => r.id).toList();
    final exercisesByRecordId = <int, int>{};
    if (fitnessRecordIds.isNotEmpty) {
      final exerciseRows = await (_db.select(
        _db.fitnessExercises,
      )..where((t) => t.fitnessRecordId.isIn(fitnessRecordIds))).get();
      for (final ex in exerciseRows) {
        exercisesByRecordId[ex.fitnessRecordId] =
            (exercisesByRecordId[ex.fitnessRecordId] ?? 0) + 1;
      }
    }
    // ---- Step 11: 在 Dart 层按日期分组合并 ----

    // 辅助：将毫秒时间戳转为本地日期 key
    String msToDateKey(int ms) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return _formatDate(dt);
    }

    // 学习：按日期聚合时长 + session 数
    final studyByDate = <String, _StudyAgg>{};
    for (final r in studyRecords) {
      final key = msToDateKey(r.startTime);
      final prev = studyByDate[key];
      studyByDate[key] = _StudyAgg(
        minutes: (prev?.minutes ?? 0) + r.durationMinutes,
        sessions: (prev?.sessions ?? 0) + 1,
      );
    }

    // 健身：按日期聚合时长 + session 数（以 fitnessRecord 为一个 session）
    final fitnessByDate = <String, _FitnessAgg>{};
    for (final r in fitnessRecords) {
      final key = msToDateKey(r.startTime);
      final prev = fitnessByDate[key];
      fitnessByDate[key] = _FitnessAgg(
        minutes: (prev?.minutes ?? 0) + r.durationMinutes,
        sessions: (prev?.sessions ?? 0) + 1,
      );
    }

    // 日记：按 journalDate 聚合
    final journalByDate = <String, _JournalAgg>{};
    for (final r in journalRows) {
      final key = r.journalDate;
      final prev = journalByDate[key];
      journalByDate[key] = _JournalAgg(
        count: (prev?.count ?? 0) + 1,
        wordCount: (prev?.wordCount ?? 0) + r.wordCount,
      );
    }

    // 饮食：按 mealDate 聚合
    final dietByDate = <String, int>{};
    for (final r in dietRows) {
      dietByDate[r.mealDate] = (dietByDate[r.mealDate] ?? 0) + 1;
    }

    // 睡眠：按 sleepDate 聚合（取最后一次记录的 qualityLevel 作为当天质量）
    final sleepByDate = <String, _SleepAgg>{};
    for (final r in sleepRows) {
      final key = r.sleepDate;
      final prev = sleepByDate[key];
      sleepByDate[key] = _SleepAgg(
        minutes: (prev?.minutes ?? 0) + r.durationMinutes,
        // 多条记录取平均质量
        qualitySum: (prev?.qualitySum ?? 0) + r.qualityLevel,
        count: (prev?.count ?? 0) + 1,
      );
    }

    // 专注：按日期聚合
    final focusByDate = <String, _FocusAgg>{};
    for (final r in focusRows) {
      final key = msToDateKey(r.startTime);
      final prev = focusByDate[key];
      focusByDate[key] = _FocusAgg(
        minutes: (prev?.minutes ?? 0) + r.durationMinutes,
        sessions: (prev?.sessions ?? 0) + 1,
      );
    }

    // 经验：按日期聚合
    final expByDate = <String, int>{};
    for (final r in expRows) {
      final key = msToDateKey(r.createdAt);
      expByDate[key] = (expByDate[key] ?? 0) + r.expValue;
    }

    // 任务：按 taskDate 聚合
    final taskByDate = <String, _TaskAgg>{};
    for (final r in taskRows) {
      final key = r.taskDate;
      final prev = taskByDate[key];
      taskByDate[key] = _TaskAgg(
        total: (prev?.total ?? 0) + 1,
        completed: (prev?.completed ?? 0) + (r.isCompleted ? 1 : 0),
      );
    }

    // ---- Step 12: 填充日期列表，生成最终 DailyStats ----
    return dateList.map((date) {
      final key = _formatDate(date);
      final study = studyByDate[key];
      final fitness = fitnessByDate[key];
      final journal = journalByDate[key];
      final sleep = sleepByDate[key];
      final focus = focusByDate[key];
      final task = taskByDate[key];

      return DailyStats(
        date: date,
        studyMinutes: study?.minutes ?? 0,
        studySessions: study?.sessions ?? 0,
        fitnessMinutes: fitness?.minutes ?? 0,
        fitnessSessions: fitness?.sessions ?? 0,
        journalCount: journal?.count ?? 0,
        journalWordCount: journal?.wordCount ?? 0,
        dietCount: dietByDate[key] ?? 0,
        sleepMinutes: sleep?.minutes ?? 0,
        sleepQuality: sleep != null && sleep.count > 0
            ? sleep.qualitySum / sleep.count
            : null,
        focusMinutes: focus?.minutes ?? 0,
        focusSessions: focus?.sessions ?? 0,
        expGained: expByDate[key] ?? 0,
        taskTotal: task?.total ?? 0,
        taskCompleted: task?.completed ?? 0,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------------

  /// 生成从 [start] 到 [end]（含两端）的日期列表。
  List<DateTime> _generateDateRange(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    return List.generate(days, (i) => start.add(Duration(days: i)));
  }

  /// 将 [DateTime] 格式化为 YYYY-MM-DD 字符串。
  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// 返回当天 00:00:00 的 DateTime。
  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

// =============================================================================
// 内部聚合辅助类
// =============================================================================

class _StudyAgg {
  const _StudyAgg({required this.minutes, required this.sessions});
  final int minutes;
  final int sessions;
}

class _FitnessAgg {
  const _FitnessAgg({required this.minutes, required this.sessions});
  final int minutes;
  final int sessions;
}

class _JournalAgg {
  const _JournalAgg({required this.count, required this.wordCount});
  final int count;
  final int wordCount;
}

class _SleepAgg {
  const _SleepAgg({
    required this.minutes,
    required this.qualitySum,
    required this.count,
  });
  final int minutes;
  final int qualitySum;
  final int count;
}

class _FocusAgg {
  const _FocusAgg({required this.minutes, required this.sessions});
  final int minutes;
  final int sessions;
}

class _TaskAgg {
  const _TaskAgg({required this.total, required this.completed});
  final int total;
  final int completed;
}
