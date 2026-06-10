import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder_timer_state.dart';

final reminderTimerProvider =
    StateNotifierProvider.family<
      ReminderTimerController,
      ReminderTimerState,
      ReminderKind
    >((ref, kind) {
      return ReminderTimerController(kind);
    });

class ReminderTimerController extends StateNotifier<ReminderTimerState> {
  ReminderTimerController(ReminderKind kind)
    : super(ReminderTimerState.idle(kind));

  Timer? _ticker;

  void start(Duration duration) {
    _ticker?.cancel();
    state = ReminderTimerState(
      kind: state.kind,
      duration: duration,
      remaining: duration,
      isRunning: true,
      startedAt: DateTime.now(),
      completedCount: state.completedCount,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    if (!state.isRunning || state.isPaused) return;
    _ticker?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    if (!state.isRunning || !state.isPaused) return;
    state = state.copyWith(isPaused: false);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void togglePause() {
    state.isPaused ? resume() : pause();
  }

  void complete() {
    _ticker?.cancel();
    state = state.copyWith(
      remaining: Duration.zero,
      isRunning: false,
      isPaused: false,
      completedCount: state.completedCount + 1,
      completedAt: DateTime.now(),
    );
  }

  void reset({Duration? duration}) {
    _ticker?.cancel();
    final nextDuration = duration ?? state.duration;
    state = ReminderTimerState(
      kind: state.kind,
      duration: nextDuration,
      remaining: nextDuration,
      completedCount: state.completedCount,
    );
  }

  void skip() {
    complete();
  }

  void _tick() {
    if (!state.isRunning || state.isPaused) return;
    final next = state.remaining - const Duration(seconds: 1);
    if (next <= Duration.zero) {
      complete();
    } else {
      state = state.copyWith(remaining: next);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
