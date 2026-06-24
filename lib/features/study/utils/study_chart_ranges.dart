import '../../../core/services/statistics_service.dart';

class StudyChartDateRange {
  const StudyChartDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class StudyChartRanges {
  const StudyChartRanges._();

  static StudyChartDateRange weekRange([DateTime? now]) {
    final today = _dateOnly(now ?? DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return StudyChartDateRange(
      start: monday,
      end: monday.add(const Duration(days: 6)),
    );
  }

  static StudyChartDateRange monthRange([DateTime? now]) {
    final today = _dateOnly(now ?? DateTime.now());
    return StudyChartDateRange(
      start: DateTime(today.year, today.month),
      end: DateTime(today.year, today.month + 1, 0),
    );
  }

  static StudyChartDateRange yearRange([DateTime? now]) {
    final today = _dateOnly(now ?? DateTime.now());
    return StudyChartDateRange(
      start: DateTime(today.year),
      end: DateTime(today.year, 12, 31),
    );
  }

  static List<MonthlyAggregate> monthlyAggregatesForYear(
    List<DailyStats> dailyStats,
    int year,
  ) {
    final byMonth = <int, List<DailyStats>>{};
    for (final stat in dailyStats) {
      if (stat.date.year != year) continue;
      (byMonth[stat.date.month] ??= []).add(stat);
    }

    return List.generate(12, (index) {
      final month = index + 1;
      final days = byMonth[month] ?? const <DailyStats>[];
      return MonthlyAggregate(
        month: '$year-${month.toString().padLeft(2, '0')}',
        studyMinutes: days.fold(0, (sum, day) => sum + day.studyMinutes),
        fitnessMinutes: days.fold(0, (sum, day) => sum + day.fitnessMinutes),
        journalCount: days.fold(0, (sum, day) => sum + day.journalCount),
        dietCount: days.fold(0, (sum, day) => sum + day.dietCount),
        sleepMinutes: days.fold(0, (sum, day) => sum + day.sleepMinutes),
        focusMinutes: days.fold(0, (sum, day) => sum + day.focusMinutes),
        expGained: days.fold(0, (sum, day) => sum + day.expGained),
        activeDays: days.where((day) => day.isActiveDay).length,
        taskTotal: days.fold(0, (sum, day) => sum + day.taskTotal),
        taskCompleted: days.fold(0, (sum, day) => sum + day.taskCompleted),
      );
    });
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
