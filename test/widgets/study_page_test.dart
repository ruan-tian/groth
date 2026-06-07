import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/study/study_page.dart';
import 'package:growth_os/shared/providers/study_provider.dart';

StudyRecord _mockStudyRecord({
  int id = 1,
  String mode = 'simple',
  String title = 'Flutter 学习',
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

void main() {
  group('StudyPage data state', () {
    testWidgets('renders the AppBar title and module hero', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            todayStudyMinutesProvider.overrideWith((_) async => 90),
            weeklyStudyMinutesProvider.overrideWith((_) async => 420),
            recentStudyRecordsProvider.overrideWith(
              (_) async => [_mockStudyRecord(id: 1, title: 'Dart 基础')],
            ),
            subjectDistributionProvider.overrideWith(
              (_) async => {'Flutter': 120, 'Dart': 60},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('学习'), findsOneWidget);
      expect(find.text('学习模块 / Study'), findsOneWidget);
    });

    testWidgets('renders stats with formatted today and weekly minutes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            todayStudyMinutesProvider.overrideWith((_) async => 90),
            weeklyStudyMinutesProvider.overrideWith((_) async => 420),
            recentStudyRecordsProvider.overrideWith((_) async => []),
            subjectDistributionProvider.overrideWith((_) async => {}),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('今日学习'), findsOneWidget);
      expect(find.text('本周学习'), findsOneWidget);
      expect(find.text('1小时30分'), findsOneWidget);
      expect(find.text('7.0 小时'), findsOneWidget);
    });

    testWidgets('renders stats with minutes format when under 60', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            todayStudyMinutesProvider.overrideWith((_) async => 45),
            weeklyStudyMinutesProvider.overrideWith((_) async => 30),
            recentStudyRecordsProvider.overrideWith((_) async => []),
            subjectDistributionProvider.overrideWith((_) async => {}),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('45 分钟'), findsWidgets);
      expect(find.text('30 分钟'), findsOneWidget);
    });

    testWidgets('renders quick action buttons', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            todayStudyMinutesProvider.overrideWith((_) async => 60),
            weeklyStudyMinutesProvider.overrideWith((_) async => 300),
            recentStudyRecordsProvider.overrideWith((_) async => []),
            subjectDistributionProvider.overrideWith((_) async => {}),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('开始番茄钟'), findsOneWidget);
      expect(find.text('添加学习记录'), findsOneWidget);
    });

    testWidgets('renders subject distribution section', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            todayStudyMinutesProvider.overrideWith((_) async => 60),
            weeklyStudyMinutesProvider.overrideWith((_) async => 300),
            recentStudyRecordsProvider.overrideWith((_) async => []),
            subjectDistributionProvider.overrideWith(
              (_) async => {'Flutter': 120, '算法': 80},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('科目分布'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('算法'), findsOneWidget);
    });
  });

  group('StudyPage record list', () {
    testWidgets('renders recent records list with record tiles', (
      tester,
    ) async {
      final records = [
        _mockStudyRecord(id: 1, title: 'Dart 基础', subject: 'Dart'),
        _mockStudyRecord(id: 2, title: 'Flutter Widget', subject: 'Flutter'),
        _mockStudyRecord(id: 3, title: '算法复习', subject: '算法'),
      ];

      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            todayStudyMinutesProvider.overrideWith((_) async => 135),
            weeklyStudyMinutesProvider.overrideWith((_) async => 500),
            recentStudyRecordsProvider.overrideWith((_) async => records),
            subjectDistributionProvider.overrideWith((_) async => {}),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('最近记录'), findsOneWidget);
      expect(find.text('Dart 基础'), findsOneWidget);
      expect(find.text('Flutter Widget'), findsOneWidget);
      expect(find.text('算法复习'), findsOneWidget);
    });

    testWidgets('shows empty state when no records', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            todayStudyMinutesProvider.overrideWith((_) async => 0),
            weeklyStudyMinutesProvider.overrideWith((_) async => 0),
            recentStudyRecordsProvider.overrideWith((_) async => []),
            subjectDistributionProvider.overrideWith((_) async => {}),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.textContaining('还没有学习记录'), findsOneWidget);
    });

    testWidgets('shows record duration and exp on record tile', (tester) async {
      final records = [
        _mockStudyRecord(id: 1, title: 'Flutter 入门', durationMinutes: 90),
        _mockStudyRecord(id: 2, title: 'Dart', expGained: 12),
      ];

      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            todayStudyMinutesProvider.overrideWith((_) async => 90),
            weeklyStudyMinutesProvider.overrideWith((_) async => 90),
            recentStudyRecordsProvider.overrideWith((_) async => records),
            subjectDistributionProvider.overrideWith((_) async => {}),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.textContaining('90 分钟'), findsOneWidget);
      expect(find.text('+12 EXP'), findsOneWidget);
    });

    testWidgets('shows empty subject distribution message', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            todayStudyMinutesProvider.overrideWith((_) async => 0),
            weeklyStudyMinutesProvider.overrideWith((_) async => 0),
            recentStudyRecordsProvider.overrideWith((_) async => []),
            subjectDistributionProvider.overrideWith((_) async => {}),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('暂无学习记录'), findsOneWidget);
    });

    testWidgets('renders loading state for stats', (tester) async {
      final todayCompleter = Completer<int>();
      final weeklyCompleter = Completer<int>();

      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            todayStudyMinutesProvider.overrideWith(
              (_) => todayCompleter.future,
            ),
            weeklyStudyMinutesProvider.overrideWith(
              (_) => weeklyCompleter.future,
            ),
            recentStudyRecordsProvider.overrideWith((_) async => []),
            subjectDistributionProvider.overrideWith((_) async => {}),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
