import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/calendar_service.dart';
import '../../core/services/statistics_service.dart';
import 'service_providers.dart';

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return const CalendarService();
});

class CalendarStatsRequest {
  const CalendarStatsRequest({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  DateTime get normalizedStart => DateTime(start.year, start.month, start.day);
  DateTime get normalizedEnd => DateTime(end.year, end.month, end.day);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CalendarStatsRequest &&
            normalizedStart == other.normalizedStart &&
            normalizedEnd == other.normalizedEnd;
  }

  @override
  int get hashCode => Object.hash(normalizedStart, normalizedEnd);
}

final calendarStatsProvider =
    FutureProvider.family<List<DailyStats>, CalendarStatsRequest>((
      ref,
      request,
    ) {
      final statisticsService = ref.watch(statisticsServiceProvider);
      return statisticsService.getDailyStatsRange(
        request.normalizedStart,
        request.normalizedEnd,
      );
    });
