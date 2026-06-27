import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:growth_os/app/app.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/services/statistics_service.dart';
import 'package:growth_os/core/domain/pet/pet_display_intent.dart';
import 'package:growth_os/core/domain/pet/pet_priority.dart';
import 'package:growth_os/core/constants/pet_assets.dart';
import 'package:growth_os/features/dashboard/providers/dashboard_provider.dart';
import 'package:growth_os/features/pet/providers/pet_orchestrator_provider.dart';
import 'package:growth_os/features/pet/providers/pet_projection_provider.dart';
import 'package:growth_os/features/plan/providers/task_provider.dart';
import 'package:growth_os/features/health/providers/weather_provider.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase(NativeDatabase.memory());
            ref.onDispose(() => unawaited(db.close()));
            return db;
          }),
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
          todayWeatherProvider.overrideWith((_) async => null),
          weatherExtraAutoProvider.overrideWith((_) async => null),
          dashboardPetIntentProvider.overrideWith(
            (_) async => PetDisplayIntent(
              id: 'test_dashboard_pet',
              type: 'life_session',
              priority: PetPriority.life,
              imagePath: PetAssets.commonHappy,
              messages: const ['Tiantian is here'],
              startedAt: DateTime(2026, 6, 9),
            ),
          ),
          dashboardPetViewProvider.overrideWithValue(
            const PetViewState(
              imagePath: PetAssets.commonHappy,
              bubbleText: 'Tiantian is here',
              isBubbleVisible: true,
            ),
          ),
        ],
        child: const GrowthOSApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Growth OS'), findsOneWidget);
  });
}
