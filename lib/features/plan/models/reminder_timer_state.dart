enum ReminderKind { fitness, water, sleep }

class ReminderConfig {
  const ReminderConfig({
    required this.kind,
    required this.duration,
    this.amountMl,
    this.label,
  });

  final ReminderKind kind;
  final Duration duration;
  final int? amountMl;
  final String? label;
}

class ReminderTimerState {
  const ReminderTimerState({
    required this.kind,
    required this.duration,
    required this.remaining,
    this.isRunning = false,
    this.isPaused = false,
    this.completedCount = 0,
    this.startedAt,
    this.completedAt,
  });

  factory ReminderTimerState.idle(ReminderKind kind) {
    return ReminderTimerState(
      kind: kind,
      duration: Duration.zero,
      remaining: Duration.zero,
    );
  }

  final ReminderKind kind;
  final Duration duration;
  final Duration remaining;
  final bool isRunning;
  final bool isPaused;
  final int completedCount;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isIdle => !isRunning && remaining == Duration.zero;
  bool get isCompleted => completedAt != null && remaining == Duration.zero;
  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    final elapsed = duration.inMilliseconds - remaining.inMilliseconds;
    return (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  ReminderTimerState copyWith({
    Duration? duration,
    Duration? remaining,
    bool? isRunning,
    bool? isPaused,
    int? completedCount,
    DateTime? startedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return ReminderTimerState(
      kind: kind,
      duration: duration ?? this.duration,
      remaining: remaining ?? this.remaining,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      completedCount: completedCount ?? this.completedCount,
      startedAt: startedAt ?? this.startedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}
