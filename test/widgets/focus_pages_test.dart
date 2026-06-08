import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/focus/focus_page.dart';
import 'package:growth_os/features/focus/pages/focus_session_page.dart';
import 'package:growth_os/shared/providers/focus_provider.dart';

FocusSession _focusSession({
  int id = 1,
  String title = '数学复习',
  int durationMinutes = 25,
  bool completed = true,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return FocusSession(
    id: id,
    type: 'pomodoro',
    title: title,
    startTime: now - durationMinutes * 60 * 1000,
    endTime: now,
    durationMinutes: durationMinutes,
    completed: completed,
    roundIndex: 1,
    createdAt: now,
  );
}

Widget _focusPage({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: FocusPage()),
  );
}

Widget _sessionPage() {
  return const ProviderScope(
    child: MaterialApp(
      home: FocusSessionPage(
        durationMinutes: 1,
        type: 'pomodoro',
        title: '英语阅读理解练习',
        subject: '英语',
        totalRounds: 2,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> setViewport(
    WidgetTester tester,
    double width,
    double height,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('FocusPage responsive setup', () {
    testWidgets('renders portrait setup sections', (tester) async {
      await setViewport(tester, 390, 844);
      await tester.pumpWidget(
        _focusPage(
          overrides: [
            todayFocusMinutesProvider.overrideWith((_) async => 138),
            recentFocusSessionsProvider.overrideWith(
              (_) async => [_focusSession()],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('番茄钟'), findsOneWidget);
      expect(find.text('学习科目'), findsOneWidget);
      expect(find.text('白噪音'), findsOneWidget);
      expect(find.text('开始专注'), findsOneWidget);
      expect(find.text('最近专注记录'), findsOneWidget);
    });

    testWidgets('renders landscape setup sections', (tester) async {
      await setViewport(tester, 1366, 768);
      await tester.pumpWidget(
        _focusPage(
          overrides: [
            todayFocusMinutesProvider.overrideWith((_) async => 138),
            recentFocusSessionsProvider.overrideWith(
              (_) async => [_focusSession(title: '高数复习')],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('自律一点点，进步看得见'), findsOneWidget);
      expect(find.text('学习科目'), findsOneWidget);
      expect(find.text('白噪音'), findsWidgets);
      expect(find.text('开始专注'), findsOneWidget);
      expect(find.text('高数复习'), findsOneWidget);
    });
  });

  group('FocusSessionPage responsive session', () {
    testWidgets('renders portrait timer core controls', (tester) async {
      await setViewport(tester, 390, 844);
      await tester.pumpWidget(_sessionPage());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('英语阅读理解练习'), findsOneWidget);
      expect(find.text('英语'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
      expect(find.text('白噪音'), findsOneWidget);
      expect(find.text('暂停专注'), findsOneWidget);
    });

    testWidgets('renders landscape timer core controls', (tester) async {
      await setViewport(tester, 1366, 768);
      await tester.pumpWidget(_sessionPage());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('英语阅读理解练习'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
      expect(find.text('白噪音'), findsOneWidget);
      expect(find.text('暂停专注'), findsOneWidget);
      expect(find.text('下一阶段：短休息'), findsOneWidget);
    });
  });
}
