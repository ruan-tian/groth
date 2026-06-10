import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/plan/models/reminder_timer_state.dart';
import 'package:growth_os/features/plan/providers/reminder_timer_provider.dart';

void main() {
  test('ReminderTimerController supports pause, resume, and complete', () {
    final controller = ReminderTimerController(ReminderKind.water);

    controller.start(const Duration(minutes: 1));
    expect(controller.state.isRunning, isTrue);
    expect(controller.state.remaining, const Duration(minutes: 1));

    controller.pause();
    expect(controller.state.isPaused, isTrue);

    controller.resume();
    expect(controller.state.isPaused, isFalse);

    controller.complete();
    expect(controller.state.isRunning, isFalse);
    expect(controller.state.remaining, Duration.zero);
    expect(controller.state.completedCount, 1);

    controller.dispose();
  });
}
