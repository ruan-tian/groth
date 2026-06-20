import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/exp_repository.dart';
import 'package:growth_os/core/repositories/pet_repository.dart';
import 'package:growth_os/core/services/statistics_service.dart';
import 'package:growth_os/features/pet/services/pet_orchestrator.dart';
import 'package:growth_os/features/plan/widgets/plan_module_visuals.dart';
import 'package:growth_os/features/study/study_page.dart';
import 'package:growth_os/shared/providers/pet_ai_result_provider.dart';
import 'package:growth_os/shared/providers/pet_orchestrator_provider.dart';
import 'package:growth_os/shared/providers/pet_projection_provider.dart';
import 'package:growth_os/shared/providers/knowledge_v3_provider.dart';
import 'package:growth_os/shared/providers/settings_provider.dart';
import 'package:growth_os/shared/providers/study_provider.dart';

class _TestPetOrchestrator extends PetOrchestrator {
  static AppDatabase? _sharedDb;

  factory _TestPetOrchestrator() {
    final db = _sharedDb ??= AppDatabase();
    return _TestPetOrchestrator._(db);
  }

  _TestPetOrchestrator._(AppDatabase db)
    : super(expRepository: ExpRepository(db), petRepository: PetRepository(db));

  @override
  void init() {}

  @override
  void setModuleAmbient(
    String module,
    String imagePath,
    List<String> messages,
  ) {
    // Keep StudyPage widget tests local-only: no SharedPreferences, timers, or
    // repository work from the real pet orchestrator.
  }
}

StudyRecord _mockStudyRecord({
  int id = 1,
  String mode = 'simple',
  String title = 'Flutter study',
  String? subject = 'Flutter',
  int durationMinutes = 60,
  int expGained = 8,
  int? createdAtMs,
}) {
  final now = createdAtMs ?? DateTime.now().millisecondsSinceEpoch;
  return StudyRecord(
    id: id,
    mode: mode,
    title: title,
    subject: subject,
    startTime: now - durationMinutes * 60 * 1000,
    endTime: now,
    durationMinutes: durationMinutes,
    expGained: expGained,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildTestableWidget({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: StudyPage()),
  );
}

Future<void> _pumpStudyPage(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(_buildTestableWidget(overrides: overrides));
  await _pumpStableFrames(tester);
}

Future<void> _pumpStableFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
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

List<Override> _studyPageOverrides({
  Future<int> Function()? todayMinutes,
  Future<int> Function()? weeklyMinutes,
  List<StudyRecord> todayRecords = const [],
  List<StudyRecord> recentRecords = const [],
  Map<String, int> subjectDistribution = const {},
  KnowledgeWorkspaceOverviewV3 knowledgeOverview =
      const KnowledgeWorkspaceOverviewV3(
        spaceCount: 1,
        materialCount: 0,
        cardCount: 0,
        dueCount: 0,
        weakCount: 0,
      ),
}) {
  return [
    petOrchestratorProvider.overrideWith((ref) => _TestPetOrchestrator()),
    modulePetViewProvider('study').overrideWithValue(
      const PetViewState(
        bubbleText: 'Study with Tiantian',
        isBubbleVisible: true,
        module: 'study',
      ),
    ),
    latestPetAnalysisProvider('study').overrideWith((_) async => null),
    dailyGoalsProvider.overrideWith(
      (_) => const [DailyGoal(name: '瀛︿範', target: 120, unit: '鍒嗛挓')],
    ),
    todayStudyMinutesProvider.overrideWith(
      (_) => todayMinutes?.call() ?? Future.value(0),
    ),
    weeklyStudyMinutesProvider.overrideWith(
      (_) => weeklyMinutes?.call() ?? Future.value(0),
    ),
    todayStudyRecordsProvider.overrideWith((_) async => todayRecords),
    recentStudyRecordsProvider.overrideWith((_) async => recentRecords),
    knowledgeWorkspaceOverviewV3Provider.overrideWith(
      (_) async => knowledgeOverview,
    ),
    subjectDistributionProvider.overrideWith((_) async => subjectDistribution),
    subjectDistributionByRangeProvider(
      1,
    ).overrideWith((_) async => subjectDistribution),
    subjectDistributionByRangeProvider(
      7,
    ).overrideWith((_) async => subjectDistribution),
    subjectDistributionByRangeProvider(
      30,
    ).overrideWith((_) async => subjectDistribution),
    weeklyDailyStudyProvider.overrideWith((_) async => _dailyStats(7)),
    monthlyDailyStudyProvider.overrideWith((_) async => _dailyStats(30)),
    yearlyMonthlyStudyProvider.overrideWith((_) async => _monthlyStats()),
  ];
}

void main() {
  group('StudyPage data state', () {
    testWidgets('renders the page shell and module visuals', (tester) async {
      await _pumpStudyPage(
        tester,
        overrides: _studyPageOverrides(
          todayMinutes: () async => 90,
          weeklyMinutes: () async => 420,
          recentRecords: [_mockStudyRecord(id: 1, title: 'Dart basics')],
          subjectDistribution: {'Flutter': 120, 'Dart': 60},
        ),
      );

      expect(find.byType(StudyPage), findsOneWidget);
      expect(find.byType(PlanModuleVisualHeader), findsOneWidget);
      expect(find.byType(PlanModuleActionImageCard), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('知识空间'), findsOneWidget);
      expect(find.text('导入资料，让甜甜帮你生成知识卡'), findsOneWidget);
    });

    testWidgets('renders today summary without hitting the real database', (
      tester,
    ) async {
      await _pumpStudyPage(
        tester,
        overrides: _studyPageOverrides(
          todayMinutes: () async => 90,
          weeklyMinutes: () async => 420,
          todayRecords: [
            _mockStudyRecord(id: 1, expGained: 8, subject: 'Flutter'),
            _mockStudyRecord(id: 2, expGained: 12, subject: 'Dart'),
          ],
        ),
      );

      expect(find.textContaining('+20'), findsOneWidget);
      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('renders subject distribution section', (tester) async {
      await _pumpStudyPage(
        tester,
        overrides: _studyPageOverrides(
          todayMinutes: () async => 60,
          weeklyMinutes: () async => 300,
          subjectDistribution: {'Flutter': 120, 'Algorithms': 80},
        ),
      );

      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Algorithms'), findsOneWidget);
    });
  });

  group('StudyPage record list', () {
    testWidgets('renders recent records list with record tiles', (
      tester,
    ) async {
      final records = [
        _mockStudyRecord(id: 1, title: 'Dart basics', subject: 'Dart'),
        _mockStudyRecord(id: 2, title: 'Flutter Widget', subject: 'Flutter'),
        _mockStudyRecord(id: 3, title: 'Algorithm review', subject: 'CS'),
      ];

      await _pumpStudyPage(
        tester,
        overrides: _studyPageOverrides(
          todayMinutes: () async => 135,
          weeklyMinutes: () async => 500,
          recentRecords: records,
        ),
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await _pumpStableFrames(tester);

      expect(find.text('Dart basics'), findsOneWidget);
      expect(find.text('Flutter Widget'), findsOneWidget);
      expect(find.text('Algorithm review'), findsOneWidget);
    });

    testWidgets('shows record duration and exp on record tile', (tester) async {
      final records = [
        _mockStudyRecord(id: 1, title: 'Flutter intro', durationMinutes: 90),
        _mockStudyRecord(id: 2, title: 'Dart', expGained: 12),
      ];

      await _pumpStudyPage(
        tester,
        overrides: _studyPageOverrides(
          todayMinutes: () async => 90,
          weeklyMinutes: () async => 90,
          recentRecords: records,
        ),
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await _pumpStableFrames(tester);

      expect(find.textContaining('90'), findsWidgets);
      expect(find.text('+12 EXP'), findsOneWidget);
    });

    testWidgets('renders loading state for stats', (tester) async {
      final todayCompleter = Completer<int>();
      final weeklyCompleter = Completer<int>();

      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: _studyPageOverrides(
            todayMinutes: () => todayCompleter.future,
            weeklyMinutes: () => weeklyCompleter.future,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Complete the futures to avoid pending timers
      todayCompleter.complete(0);
      weeklyCompleter.complete(0);
      await tester.pump();
    });
  });

  group('StudyPage knowledge space entry', () {
    testWidgets('shows import as the empty-state primary action', (
      tester,
    ) async {
      await _pumpStudyPage(tester, overrides: _studyPageOverrides());

      expect(find.text('知识空间'), findsOneWidget);
      expect(find.text('导入资料，让甜甜帮你生成知识卡'), findsOneWidget);
      expect(find.text('导入资料'), findsOneWidget);
    });

    testWidgets('shows generate when materials exist but no cards', (
      tester,
    ) async {
      await _pumpStudyPage(
        tester,
        overrides: _studyPageOverrides(
          knowledgeOverview: const KnowledgeWorkspaceOverviewV3(
            spaceCount: 1,
            materialCount: 2,
            cardCount: 0,
            dueCount: 0,
            weakCount: 0,
          ),
        ),
      );

      expect(find.text('知识空间'), findsOneWidget);
      expect(find.text('2 份资料已导入，可生成知识卡'), findsOneWidget);
      expect(find.text('生成知识卡'), findsOneWidget);
    });

    testWidgets('shows enter space when cards exist but none are due', (
      tester,
    ) async {
      await _pumpStudyPage(
        tester,
        overrides: _studyPageOverrides(
          knowledgeOverview: const KnowledgeWorkspaceOverviewV3(
            spaceCount: 1,
            materialCount: 2,
            cardCount: 16,
            dueCount: 0,
            weakCount: 3,
          ),
        ),
      );

      expect(find.text('知识空间'), findsOneWidget);
      expect(find.text('共 16 张知识卡，3 张薄弱卡'), findsOneWidget);
      expect(find.text('进入空间'), findsOneWidget);
    });

    testWidgets('shows start review when cards are due', (tester) async {
      await _pumpStudyPage(
        tester,
        overrides: _studyPageOverrides(
          knowledgeOverview: const KnowledgeWorkspaceOverviewV3(
            spaceCount: 1,
            materialCount: 3,
            cardCount: 24,
            dueCount: 7,
            weakCount: 2,
          ),
        ),
      );

      expect(find.text('继续抽卡复习'), findsOneWidget);
      expect(find.text('今日 7 张待复习，共 24 张知识卡'), findsOneWidget);
      expect(find.text('开始抽卡'), findsOneWidget);
    });
  });
}
