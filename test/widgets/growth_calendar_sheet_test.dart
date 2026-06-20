import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:growth_os/core/services/statistics_service.dart';
import 'package:growth_os/shared/providers/calendar_provider.dart';
import 'package:growth_os/shared/widgets/common/growth_calendar_sheet.dart';

void main() {
  testWidgets('calendar sheet does not overflow on compact screens', (
    tester,
  ) async {
    final originalSize = tester.view.physicalSize;
    final originalPixelRatio = tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 640);
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalPixelRatio;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarStatsProvider.overrideWith((ref, request) async {
            final start = request.normalizedStart;
            final end = request.normalizedEnd;
            final days = end.difference(start).inDays + 1;
            return List.generate(
              days,
              (index) => DailyStats.empty(start.add(Duration(days: index))),
            );
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GrowthCalendarSheet(initialDate: DateTime(2026, 2, 17)),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
