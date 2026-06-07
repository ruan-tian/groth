import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:growth_os/app/app.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/services/statistics_service.dart';
import 'package:growth_os/shared/providers/dashboard_provider.dart';
import 'package:growth_os/shared/providers/task_provider.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardProvider.overrideWith((_) async {
            return DashboardData(
              todayStudyMinutes: 0,
              todayFitnessMinutes: 0,
              todayJournalCount: 0,
              totalExp: 0,
              currentLevel: 1,
              expProgress: 0,
              weeklyStats: <DailyStats>[],
            );
          }),
          todayTasksProvider.overrideWith((_) async => <DailyTask>[]),
          todayIncompleteTaskCountProvider.overrideWith((_) async => 0),
        ],
        child: const GrowthOSApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Growth OS'), findsOneWidget);
  });
}
