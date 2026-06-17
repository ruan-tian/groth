import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/services/statistics_service.dart';
import 'package:growth_os/features/dashboard/dashboard_page.dart';
import 'package:growth_os/core/domain/pet/pet_display_intent.dart';
import 'package:growth_os/core/domain/pet/pet_priority.dart';
import 'package:growth_os/core/constants/pet_assets.dart';
import 'package:growth_os/shared/providers/dashboard_provider.dart';
import 'package:growth_os/shared/providers/pet_orchestrator_provider.dart';
import 'package:growth_os/shared/providers/pet_projection_provider.dart';
import 'package:growth_os/shared/providers/task_provider.dart';
import 'package:growth_os/shared/providers/weather_provider.dart';

DashboardData _mockDashboardData({
  int todayStudyMinutes = 90,
  int todayFitnessMinutes = 30,
  int todayJournalCount = 1,
  int totalExp = 500,
  int currentLevel = 3,
  int expProgress = 100,
  List<DailyStats>? weeklyStats,
}) {
  return DashboardData(
    todayStudyMinutes: todayStudyMinutes,
    todayFitnessMinutes: todayFitnessMinutes,
    todayJournalCount: todayJournalCount,
    totalExp: totalExp,
    currentLevel: currentLevel,
    expProgress: expProgress,
    weeklyStats:
        weeklyStats ??
        List.generate(
          7,
          (i) => DailyStats.empty(DateTime(2026, 6, 1).add(Duration(days: i))),
        ),
  );
}

Widget _buildTestableWidget({required List<Override> overrides}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase(NativeDatabase.memory());
        ref.onDispose(() => unawaited(db.close()));
        return db;
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
          messages: const ['甜甜在这里陪你～'],
          startedAt: DateTime(2026, 6, 9),
        ),
      ),
      dashboardPetViewProvider.overrideWithValue(
        const PetViewState(
          imagePath: PetAssets.commonHappy,
          bubbleText: '甜甜在这里陪你～',
          isBubbleVisible: true,
        ),
      ),
      ...overrides,
    ],
    child: const MaterialApp(home: DashboardPage()),
  );
}

void main() {
  group('DashboardPage data state', () {
    testWidgets('renders the AppBar title "Growth OS"', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            dashboardProvider.overrideWith((_) async => _mockDashboardData()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Growth OS'), findsOneWidget);
    });

    testWidgets('renders redesigned hero and dashboard sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            dashboardProvider.overrideWith(
              (_) async => _mockDashboardData(
                currentLevel: 5,
                todayStudyMinutes: 90,
                todayFitnessMinutes: 45,
                todayJournalCount: 1,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('你的成长，由你掌控'), findsOneWidget);
      expect(find.textContaining('Lv.5'), findsWidgets);
      expect(find.text('今日概览'), findsOneWidget);
      // Default cards are now "study" and "focus" in compact mode
      expect(find.text('90分钟'), findsOneWidget);  // study
    });

    testWidgets('shows quick action sheet from FAB', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            dashboardProvider.overrideWith((_) async => _mockDashboardData()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Find the FAB by its tooltip
      final fabFinder = find.byTooltip('快速开始');
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      expect(find.text('快速开始'), findsOneWidget);
      expect(find.text('开始学习'), findsOneWidget);
      expect(find.text('开始运动'), findsOneWidget);
      expect(find.text('喝水打卡'), findsOneWidget);
      expect(find.text('记录睡眠'), findsOneWidget);
      expect(find.text('开始日记'), findsOneWidget);
    });

    testWidgets('shows and expands the music floating capsule', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            dashboardProvider.overrideWith((_) async => _mockDashboardData()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('collapsed_music_capsule')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('collapsed_music_capsule')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('expanded_music_card')), findsOneWidget);
      expect(find.text('甜甜音乐'), findsOneWidget);
      expect(find.text('音乐库'), findsOneWidget);
      expect(find.text('播放列表'), findsOneWidget);
      expect(find.text('收藏'), findsOneWidget);
    });

    testWidgets('music floating card fits common phone widths', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final width in <double>[360, 390, 430]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          _buildTestableWidget(
            overrides: [
              dashboardProvider.overrideWith((_) async => _mockDashboardData()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('collapsed_music_capsule')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('expanded_music_card')),
          findsOneWidget,
          reason: 'width $width',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
  });

  group('DashboardPage loading state', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      final completer = Completer<DashboardData>();

      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [dashboardProvider.overrideWith((_) => completer.future)],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show data widgets while loading', (tester) async {
      final completer = Completer<DashboardData>();

      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [dashboardProvider.overrideWith((_) => completer.future)],
        ),
      );
      await tester.pump();

      expect(find.textContaining('Lv.'), findsNothing);
    });
  });

  group('DashboardPage error state', () {
    testWidgets('shows error message when provider fails', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            dashboardProvider.overrideWith((_) async {
              throw Exception('网络异常');
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('加载失败'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            dashboardProvider.overrideWith((_) async {
              throw Exception('测试错误');
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('重试'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  group('DashboardPage refresh', () {
    testWidgets('pull-to-refresh is available', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            dashboardProvider.overrideWith((_) async => _mockDashboardData()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('scroll view is scrollable', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            dashboardProvider.overrideWith((_) async => _mockDashboardData()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
    });
  });
}
