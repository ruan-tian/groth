import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/focus/focus_page.dart';
import 'package:growth_os/features/focus/pages/focus_session_page.dart';
import 'package:growth_os/features/plan/services/reminder_notification_service.dart';
import 'package:growth_os/shared/providers/focus_audio_provider.dart';
import 'package:growth_os/features/focus/providers/focus_provider.dart';
import 'package:growth_os/features/focus/widgets/focus_sound_panel.dart';

FocusSession _focusSession({
  int id = 1,
  String title = 'Math review',
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
  return ProviderScope(
    overrides: [
      focusCycleProvider.overrideWith((_) => _StaticFocusCycleNotifier()),
      focusAudioStateProvider.overrideWith(_NoopFocusAudioNotifier.new),
    ],
    child: const MaterialApp(
      home: FocusSessionPage(
        durationMinutes: 1,
        type: 'pomodoro',
        title: 'English reading',
        subject: 'English',
        totalRounds: 2,
      ),
    ),
  );
}

Widget _sessionPageWithSound(String soundType) {
  return ProviderScope(
    overrides: [
      focusCycleProvider.overrideWith((_) => _StaticFocusCycleNotifier()),
      focusAudioStateProvider.overrideWith(_NoopFocusAudioNotifier.new),
    ],
    child: MaterialApp(
      home: FocusSessionPage(
        durationMinutes: 1,
        type: 'pomodoro',
        title: 'English reading',
        subject: 'English',
        soundType: soundType,
        totalRounds: 2,
      ),
    ),
  );
}

Widget _soundPanel({
  required String initialSoundType,
  required ValueChanged<String?> onSoundChanged,
}) {
  return ProviderScope(
    overrides: [
      focusAudioStateProvider.overrideWith(_NoopFocusAudioNotifier.new),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: FocusSoundPanel(
          initialSoundType: initialSoundType,
          onSoundChanged: onSoundChanged,
        ),
      ),
    ),
  );
}

class _StaticFocusCycleNotifier extends FocusCycleNotifier {
  _StaticFocusCycleNotifier() : super(ReminderNotificationService());

  @override
  void start({
    required int focusMinutes,
    required int totalRounds,
    required String type,
    String title = '',
    String subject = '',
    String? soundType,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
  }) {
    final now = DateTime.now();
    state = FocusCycleState(
      sessionGroupId: 'test-session',
      currentRound: 1,
      totalRounds: totalRounds,
      phase: FocusPhase.focus,
      phaseStartAt: now,
      phaseEndAt: now.add(Duration(minutes: focusMinutes)),
      remainingSeconds: focusMinutes * 60,
      isRunning: true,
      focusSeconds: focusMinutes * 60,
      shortBreakSeconds: shortBreakMinutes * 60,
      longBreakSeconds: longBreakMinutes * 60,
      title: title,
      subject: subject,
      soundType: soundType,
      type: type,
    );
  }

  @override
  void pause() {
    state = state.copyWith(isRunning: false);
  }

  @override
  void resume() {
    state = state.copyWith(isRunning: true);
  }
}

class _NoopFocusAudioNotifier extends FocusAudioStateNotifier {
  _NoopFocusAudioNotifier(super.ref);

  @override
  Future<void> startNoise(String soundType) async {
    state = state.copyWith(currentSoundType: soundType, isPlaying: true);
  }

  @override
  Future<void> pauseNoise() async {
    state = state.copyWith(isPlaying: false);
  }

  @override
  Future<void> resumeNoise() async {
    state = state.copyWith(isPlaying: true);
  }

  @override
  Future<void> stopNoise() async {
    state = state.copyWith(currentSoundType: null, isPlaying: false);
  }

  @override
  Future<void> playBell(String bellType) async {}
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

  Future<void> pumpFocusPage(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 500));
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
      await pumpFocusPage(tester);

      expect(find.byType(FocusPage), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('renders landscape setup sections', (tester) async {
      await setViewport(tester, 1366, 768);
      await tester.pumpWidget(
        _focusPage(
          overrides: [
            todayFocusMinutesProvider.overrideWith((_) async => 138),
            recentFocusSessionsProvider.overrideWith(
              (_) async => [_focusSession(title: 'Calculus review')],
            ),
          ],
        ),
      );
      await pumpFocusPage(tester);

      expect(find.byType(FocusPage), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('FocusSessionPage responsive session', () {
    testWidgets('renders portrait timer core controls', (tester) async {
      await setViewport(tester, 390, 844);
      await tester.pumpWidget(_sessionPage());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('English reading'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
    });

    testWidgets('renders landscape timer core controls', (tester) async {
      await setViewport(tester, 1366, 768);
      await tester.pumpWidget(_sessionPage());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('English reading'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
    });

    testWidgets('renders compact phone landscape without overflow', (
      tester,
    ) async {
      await setViewport(tester, 812, 375);
      await tester.pumpWidget(_sessionPage());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('English reading'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
    });

    testWidgets('keeps selected white noise when session starts', (
      tester,
    ) async {
      await setViewport(tester, 390, 844);
      await tester.pumpWidget(_sessionPageWithSound('white_noise'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('白噪音播放中'), findsOneWidget);
      expect(find.text('安静模式'), findsNothing);
    });

    testWidgets('noise mode switch restores noise instead of quiet mode', (
      tester,
    ) async {
      String? selected;
      await setViewport(tester, 390, 844);
      await tester.pumpWidget(
        _soundPanel(
          initialSoundType: 'none',
          onSoundChanged: (value) => selected = value,
        ),
      );

      await tester.tap(find.text('白噪音').first);
      await tester.pump();

      expect(selected, 'white_noise');
    });
  });
}
