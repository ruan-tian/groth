import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growth_os/shared/providers/focus_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('recalculate stops an expired running phase and marks completion', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(focusCycleProvider.notifier);
    notifier.start(focusMinutes: 0, totalRounds: 1, type: 'pomodoro');
    notifier.recalculate();

    final state = container.read(focusCycleProvider);
    expect(state.remainingSeconds, 0);
    expect(state.isRunning, isFalse);
    expect(state.phaseCompleted, isTrue);
  });
}
