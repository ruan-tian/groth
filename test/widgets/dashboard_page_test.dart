import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/services/statistics_service.dart';
import 'package:growth_os/features/dashboard/dashboard_page.dart';
import 'package:growth_os/shared/providers/dashboard_provider.dart';
import 'package:growth_os/shared/providers/task_provider.dart';

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
          (i) => DailyStats(
            date: DateTime(2026, 6, 1).add(Duration(days: i)),
            studyMinutes: 60 + i * 10,
            fitnessMinutes: 20 + i * 5,
            expGained: 10 + i * 2,
          ),
        ),
  );
}

Widget _buildTestableWidget({required List<Override> overrides}) {
  return ProviderScope(
    overrides: [
      todayTasksProvider.overrideWith((_) async => <DailyTask>[]),
      todayIncompleteTaskCountProvider.overrideWith((_) async => 0),
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
      expect(find.text('90 分钟'), findsOneWidget);
      expect(find.text('45 分钟'), findsOneWidget);
      expect(find.text('1 篇'), findsOneWidget);
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

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('快速记录'), findsOneWidget);
      expect(find.text('添加学习'), findsOneWidget);
      expect(find.text('添加健身'), findsOneWidget);
      expect(find.text('写复盘'), findsOneWidget);
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
