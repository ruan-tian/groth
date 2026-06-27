import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/services/statistics_service.dart';
import 'package:growth_os/features/study/utils/study_chart_ranges.dart';

void main() {
  test('week range is Monday to Sunday', () {
    final range = StudyChartRanges.weekRange(DateTime(2026, 6, 24));

    expect(range.start, DateTime(2026, 6, 22));
    expect(range.end, DateTime(2026, 6, 28));
  });

  test('month and year ranges use calendar boundaries', () {
    final month = StudyChartRanges.monthRange(DateTime(2024, 2, 15));
    final year = StudyChartRanges.yearRange(DateTime(2026, 6, 24));

    expect(month.start, DateTime(2024, 2));
    expect(month.end, DateTime(2024, 2, 29));
    expect(year.start, DateTime(2026));
    expect(year.end, DateTime(2026, 12, 31));
  });

  test('monthly aggregates always return January through December', () {
    final aggregates = StudyChartRanges.monthlyAggregatesForYear([
      _daily(DateTime(2026, 1, 5), studyMinutes: 45, focusMinutes: 30),
      _daily(DateTime(2026, 1, 20), studyMinutes: 15, expGained: 8),
      _daily(DateTime(2026, 3, 1), studyMinutes: 90),
      _daily(DateTime(2025, 12, 31), studyMinutes: 999),
    ], 2026);

    expect(aggregates, hasLength(12));
    expect(aggregates.first.month, '2026-01');
    expect(aggregates.last.month, '2026-12');
    expect(aggregates[0].studyMinutes, 60);
    expect(aggregates[0].focusMinutes, 30);
    expect(aggregates[0].expGained, 8);
    expect(aggregates[2].studyMinutes, 90);
    expect(aggregates[11].studyMinutes, 0);
  });
}

DailyStats _daily(
  DateTime date, {
  int studyMinutes = 0,
  int focusMinutes = 0,
  int expGained = 0,
}) {
  return DailyStats(
    date: date,
    studyMinutes: studyMinutes,
    studySessions: studyMinutes > 0 ? 1 : 0,
    fitnessMinutes: 0,
    fitnessSessions: 0,
    journalCount: 0,
    journalWordCount: 0,
    dietCount: 0,
    sleepMinutes: 0,
    focusMinutes: focusMinutes,
    focusSessions: focusMinutes > 0 ? 1 : 0,
    expGained: expGained,
    taskTotal: 0,
    taskCompleted: 0,
  );
}
