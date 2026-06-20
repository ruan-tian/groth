import 'health_reminder_schedule_status.dart';

class WaterDrinkRecord {
  const WaterDrinkRecord({required this.amountMl, required this.recordedAt});

  factory WaterDrinkRecord.fromJson(Map<String, dynamic> json) {
    return WaterDrinkRecord(
      amountMl: (json['amountMl'] as num?)?.toInt() ?? 0,
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final int amountMl;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
    'amountMl': amountMl,
    'recordedAt': recordedAt.toIso8601String(),
  };

  String get timeLabel {
    return '${recordedAt.hour.toString().padLeft(2, '0')}:'
        '${recordedAt.minute.toString().padLeft(2, '0')}';
  }
}

class WaterPlanState {
  const WaterPlanState({
    this.isLoading = true,
    this.currentWaterMl = 0,
    this.goalMl = 2000,
    this.selectedAmountMl = 300,
    this.defaultAmountMl = 300,
    this.intervalMinutes = 60,
    this.reminderEnabled = true,
    this.reminderScheduleStatus = const HealthReminderScheduleStatus.unknown(),
    this.startHour = 8,
    this.endHour = 22,
    this.records = const [],
    this.message = '甜甜：再喝一杯水，今天也清清爽爽。',
  });

  final bool isLoading;
  final int currentWaterMl;
  final int goalMl;
  final int selectedAmountMl;
  final int defaultAmountMl;
  final int intervalMinutes;
  final bool reminderEnabled;
  final HealthReminderScheduleStatus reminderScheduleStatus;
  final int startHour;
  final int endHour;
  final List<WaterDrinkRecord> records;
  final String message;

  double get progress {
    if (goalMl <= 0) return 0;
    return (currentWaterMl / goalMl).clamp(0.0, 1.0);
  }

  int get progressPercent => (progress * 100).round();

  String get reminderWindowLabel {
    return '${startHour.toString().padLeft(2, '0')}:00 - '
        '${endHour.toString().padLeft(2, '0')}:00';
  }

  WaterPlanState copyWith({
    bool? isLoading,
    int? currentWaterMl,
    int? goalMl,
    int? selectedAmountMl,
    int? defaultAmountMl,
    int? intervalMinutes,
    bool? reminderEnabled,
    HealthReminderScheduleStatus? reminderScheduleStatus,
    int? startHour,
    int? endHour,
    List<WaterDrinkRecord>? records,
    String? message,
  }) {
    return WaterPlanState(
      isLoading: isLoading ?? this.isLoading,
      currentWaterMl: currentWaterMl ?? this.currentWaterMl,
      goalMl: goalMl ?? this.goalMl,
      selectedAmountMl: selectedAmountMl ?? this.selectedAmountMl,
      defaultAmountMl: defaultAmountMl ?? this.defaultAmountMl,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderScheduleStatus:
          reminderScheduleStatus ?? this.reminderScheduleStatus,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      records: records ?? this.records,
      message: message ?? this.message,
    );
  }
}
