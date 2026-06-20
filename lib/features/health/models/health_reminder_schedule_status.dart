enum HealthReminderScheduleCode {
  off,
  scheduled,
  permissionDenied,
  @Deprecated('从未被赋值，UI 分支不可达，待移除')
  exactAlarmDenied,
  scheduleFailed,
  noPendingNotifications,
  unknown,
}

class HealthReminderScheduleStatus {
  const HealthReminderScheduleStatus({
    required this.code,
    this.pendingCount = 0,
    this.usesExactAlarm = true,
  });

  const HealthReminderScheduleStatus.off()
    : code = HealthReminderScheduleCode.off,
      pendingCount = 0,
      usesExactAlarm = true;

  const HealthReminderScheduleStatus.unknown()
    : code = HealthReminderScheduleCode.unknown,
      pendingCount = 0,
      usesExactAlarm = true;

  final HealthReminderScheduleCode code;
  final int pendingCount;
  final bool usesExactAlarm;

  bool get isScheduled => code == HealthReminderScheduleCode.scheduled;

  bool get needsNotificationPermission =>
      code == HealthReminderScheduleCode.permissionDenied;

  bool get isDelayedBySystemAlarmLimit =>
      code == HealthReminderScheduleCode.scheduled && !usesExactAlarm;

  String get storageValue => code.name;

  HealthReminderScheduleStatus copyWith({
    HealthReminderScheduleCode? code,
    int? pendingCount,
    bool? usesExactAlarm,
  }) {
    return HealthReminderScheduleStatus(
      code: code ?? this.code,
      pendingCount: pendingCount ?? this.pendingCount,
      usesExactAlarm: usesExactAlarm ?? this.usesExactAlarm,
    );
  }

  static HealthReminderScheduleStatus fromStorage(
    String? value, {
    int pendingCount = 0,
    bool usesExactAlarm = true,
  }) {
    HealthReminderScheduleCode? code;
    for (final item in HealthReminderScheduleCode.values) {
      if (item.name == value) {
        code = item;
        break;
      }
    }
    if (code == null) {
      return HealthReminderScheduleStatus(
        code: pendingCount > 0
            ? HealthReminderScheduleCode.scheduled
            : HealthReminderScheduleCode.unknown,
        pendingCount: pendingCount,
        usesExactAlarm: usesExactAlarm,
      );
    }
    return HealthReminderScheduleStatus(
      code: code,
      pendingCount: pendingCount,
      usesExactAlarm: usesExactAlarm,
    );
  }
}
