import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/services/calendar_service.dart';

void main() {
  group('CalendarService', () {
    const service = CalendarService();

    test('detects solar festivals', () {
      final info = service.getDayInfo(DateTime(2026, 1, 1));

      expect(info.lunar.month, 11);
      expect(info.lunar.day, 13);
      expect(info.festivals.map((festival) => festival.name), contains('元旦'));
    });

    test('detects Chinese New Year', () {
      final info = service.getDayInfo(DateTime(2026, 2, 17));

      expect(info.lunar.year, 2026);
      expect(info.lunar.month, 1);
      expect(info.lunar.day, 1);
      expect(info.lunar.fullLabel, '正月初一');
      expect(info.primarySubLabel, '春节');
      expect(info.festivals.map((festival) => festival.name), contains('春节'));
    });

    test('detects lunar new year eve by last day of lunar December', () {
      final info = service.getDayInfo(DateTime(2026, 2, 16));

      expect(info.lunar.year, 2025);
      expect(info.lunar.month, 12);
      expect(info.lunar.fullLabel, '腊月廿九');
      expect(info.festivals.map((festival) => festival.name), contains('除夕'));
    });

    test('returns inclusive calendar ranges', () {
      final days = service.getRange(DateTime(2026, 2, 1), DateTime(2026, 2, 3));

      expect(days, hasLength(3));
      expect(days.first.date, DateTime(2026, 2, 1));
      expect(days.last.date, DateTime(2026, 2, 3));
    });
  });
}
