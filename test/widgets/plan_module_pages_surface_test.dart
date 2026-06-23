import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:growth_os/core/constants/pet_assets.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/pet/repositories/exp_repository.dart';
import 'package:growth_os/features/pet/repositories/pet_repository.dart';
import 'package:growth_os/core/services/statistics_service.dart';
import 'package:growth_os/features/fitness/fitness_page.dart';
import 'package:growth_os/features/health/diet_page.dart';
import 'package:growth_os/features/health/sleep_page.dart';
import 'package:growth_os/features/pet/services/pet_orchestrator.dart';
import 'package:growth_os/features/plan/widgets/plan_module_visuals.dart';
import 'package:growth_os/features/study/study_page.dart';
import 'package:growth_os/shared/providers/database_provider.dart';
import 'package:growth_os/features/health/providers/diet_provider.dart';
import 'package:growth_os/features/fitness/providers/fitness_provider.dart';
import 'package:growth_os/features/pet/providers/pet_ai_result_provider.dart';
import 'package:growth_os/features/pet/providers/pet_orchestrator_provider.dart';
import 'package:growth_os/features/pet/providers/pet_projection_provider.dart';
import 'package:growth_os/shared/providers/settings_provider.dart';
import 'package:growth_os/features/health/providers/sleep_provider.dart';
import 'package:growth_os/features/study/providers/study_provider.dart';
import 'package:growth_os/shared/widgets/common/common_widgets.dart';

class _NoopPetOrchestrator extends PetOrchestrator {
  _NoopPetOrchestrator(AppDatabase db)
    : super(expRepository: ExpRepository(db), petRepository: PetRepository(db));

  @override
  void init() {}

  @override
  void setModuleAmbient(
    String module,
    String imagePath,
    List<String> messages,
  ) {}
}

List<DailyStats> _dailyStats(int count) {
  final today = DateTime.now();
  return List.generate(
    count,
    (index) =>
        DailyStats.empty(today.subtract(Duration(days: count - index - 1))),
  );
}

List<MonthlyAggregate> _monthlyStats() {
  final today = DateTime.now();
  return List.generate(12, (index) {
    final month = DateTime(today.year, today.month - 11 + index);
    return MonthlyAggregate(
      month: '${month.year}-${month.month.toString().padLeft(2, '0')}',
      studyMinutes: 0,
      fitnessMinutes: 0,
      journalCount: 0,
      dietCount: 0,
      sleepMinutes: 0,
      focusMinutes: 0,
      expGained: 0,
      activeDays: 0,
      taskTotal: 0,
      taskCompleted: 0,
    );
  });
}

List<Override> _pageOverrides(AppDatabase db) {
  PetViewState petView(String module) {
    return PetViewState(
      imagePath: PetAssets.commonHappy,
      bubbleText: 'Tiantian is here',
      isBubbleVisible: true,
      module: module,
    );
  }

  return [
    appDatabaseProvider.overrideWithValue(db),
    petOrchestratorProvider.overrideWith((_) => _NoopPetOrchestrator(db)),
    for (final module in ['study', 'fitness', 'diet', 'sleep']) ...[
      modulePetViewProvider(module).overrideWithValue(petView(module)),
      latestPetAnalysisProvider(module).overrideWith((_) async => null),
    ],
    dailyGoalsProvider.overrideWith(
      (_) => const [
        DailyGoal(name: '学习', target: 120, unit: '分钟'),
        DailyGoal(name: '健身', target: 45, unit: '分钟'),
      ],
    ),
    todayStudyMinutesProvider.overrideWith((_) async => 60),
    weeklyStudyMinutesProvider.overrideWith((_) async => 180),
    todayStudyRecordsProvider.overrideWith((_) async => const []),
    recentStudyRecordsProvider.overrideWith((_) async => const []),
    subjectDistributionProvider.overrideWith((_) async => const {}),
    weeklyDailyStudyProvider.overrideWith((_) async => _dailyStats(7)),
    monthlyDailyStudyProvider.overrideWith((_) async => _dailyStats(30)),
    yearlyMonthlyStudyProvider.overrideWith((_) async => _monthlyStats()),
    todayFitnessMinutesProvider.overrideWith((_) async => 30),
    weeklyFitnessCountProvider.overrideWith((_) async => 2),
    recentFitnessRecordsProvider.overrideWith((_) async => const []),
    weeklyFitnessGoalProvider.overrideWith((_) => 4),
    fitnessChartDataProvider(30).overrideWith((_) async => const []),
    dailyCalorieGoalInitProvider.overrideWith((_) async {}),
    dailyWaterGoalInitProvider.overrideWith((_) async {}),
    todayWaterIntakeInitProvider.overrideWith((_) async {}),
    dailyCalorieGoalProvider.overrideWith((_) => 2000),
    dailyWaterGoalProvider.overrideWith((_) => 2000),
    dailyWaterIntakeProvider.overrideWith((_) => const {}),
    todayDietRecordsProvider.overrideWith((_) async => const []),
    todayDietCountProvider.overrideWith((_) async => 0),
    todayAvgHealthScoreProvider.overrideWith((_) async => null),
    recentDietRecordsProvider(10).overrideWith((_) async => const []),
    dailyCalorieWaterProvider(7).overrideWith(
      (_) async => const DailyNutritionData(calorieMap: {}, waterMap: {}),
    ),
    lastNightSleepRecordProvider.overrideWith((_) async => null),
    weeklyAvgSleepDurationProvider.overrideWith((_) async => null),
    weeklyAvgSleepQualityProvider.overrideWith((_) async => null),
    weeklySleepDurationProvider.overrideWith((_) async => const []),
    weeklySleepQualityProvider.overrideWith((_) async => const []),
    monthlySleepDurationProvider.overrideWith((_) async => const []),
    monthlySleepQualityProvider.overrideWith((_) async => const []),
    yearlySleepDurationProvider.overrideWith((_) async => const []),
    yearlySleepQualityProvider.overrideWith((_) async => const []),
    recentSleepRecordsProvider(5).overrideWith((_) async => const []),
  ];
}

void main() {
  testWidgets('plan module pages share surface and fit phone widths', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final pages = <Widget>[
      const StudyPage(isEmbedded: true),
      const FitnessPage(isEmbedded: true),
      const DietPage(isEmbedded: true),
      const SleepPage(isEmbedded: true),
    ];
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    for (final width in <double>[360, 390, 430]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;

      for (final page in pages) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: _pageOverrides(db),
            child: MaterialApp(home: Scaffold(body: page)),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byType(ModulePageSurface), findsOneWidget);
        expect(find.byType(PlanModuleVisualHeader), findsOneWidget);
        expect(find.byType(PlanModuleActionImageCard), findsOneWidget);
        if (page is DietPage) {
          expect(find.text('今天想喝点什么'), findsOneWidget);
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });
}
