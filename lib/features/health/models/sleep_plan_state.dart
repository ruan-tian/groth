import '../../../core/database/app_database.dart';

class SleepPlanState {
  const SleepPlanState({
    this.isLoading = true,
    this.sleepTime = '22:30',
    this.wakeTime = '07:00',
    this.leadMinutes = 30,
    this.reminderEnabled = true,
    this.readyAt,
    this.wokeAt,
    this.lastRecord,
    this.recentRecords = const [],
  });

  final bool isLoading;
  final String sleepTime;
  final String wakeTime;
  final int leadMinutes;
  final bool reminderEnabled;
  final DateTime? readyAt;
  final DateTime? wokeAt;
  final SleepRecord? lastRecord;
  final List<SleepRecord> recentRecords;

  int get targetDurationMinutes => _diffMinutes(sleepTime, wakeTime);

  String get targetDurationLabel => _formatDuration(targetDurationMinutes);

  String get reminderTime =>
      _formatMinutes((_minutesFromTime(sleepTime) - leadMinutes) % (24 * 60));

  SleepRecord? get displayRecord =>
      lastRecord ?? (recentRecords.isEmpty ? null : recentRecords.first);

  int? get averageSleepMinutes {
    if (recentRecords.isEmpty) return null;
    final total = recentRecords.fold<int>(
      0,
      (sum, record) => sum + record.durationMinutes,
    );
    return (total / recentRecords.length).round();
  }

  int get earlyWakeDays {
    final target = _minutesFromTime(wakeTime);
    return recentRecords
        .where((record) => _minutesFromTime(record.wakeTime) <= target)
        .length;
  }

  int get consecutiveEarlySleepDays {
    final target = _nightMinutes(sleepTime);
    final sorted = [...recentRecords]
      ..sort((a, b) => b.sleepDate.compareTo(a.sleepDate));
    var count = 0;
    for (final record in sorted) {
      if (_nightMinutes(record.sleepTime) <= target) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  String get companionMessage {
    if (wokeAt != null && readyAt != null) {
      return '甜甜：早睡早起身体好，今天也轻轻地开始吧。';
    }
    if (readyAt != null) {
      return '甜甜：晚安，我陪你一起安静下来。';
    }
    if (wokeAt != null) {
      return '甜甜：早上好，今晚从准备睡觉开始打卡，就能自动生成睡眠记录。';
    }
    final record = displayRecord;
    if (record != null) {
      return '甜甜：昨晚睡了 ${_formatDuration(record.durationMinutes)}，今晚继续照顾好自己。';
    }
    return '甜甜：今晚也早点休息呀，睡前慢慢放下手机。';
  }

  SleepPlanState copyWith({
    bool? isLoading,
    String? sleepTime,
    String? wakeTime,
    int? leadMinutes,
    bool? reminderEnabled,
    DateTime? readyAt,
    bool clearReadyAt = false,
    DateTime? wokeAt,
    bool clearWokeAt = false,
    SleepRecord? lastRecord,
    bool clearLastRecord = false,
    List<SleepRecord>? recentRecords,
  }) {
    return SleepPlanState(
      isLoading: isLoading ?? this.isLoading,
      sleepTime: sleepTime ?? this.sleepTime,
      wakeTime: wakeTime ?? this.wakeTime,
      leadMinutes: leadMinutes ?? this.leadMinutes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      readyAt: clearReadyAt ? null : readyAt ?? this.readyAt,
      wokeAt: clearWokeAt ? null : wokeAt ?? this.wokeAt,
      lastRecord: clearLastRecord ? null : lastRecord ?? this.lastRecord,
      recentRecords: recentRecords ?? this.recentRecords,
    );
  }
}

int _diffMinutes(String start, String end) {
  final startMinutes = _minutesFromTime(start);
  final endMinutes = _minutesFromTime(end);
  final raw = endMinutes - startMinutes;
  return raw > 0 ? raw : raw + 24 * 60;
}

int _minutesFromTime(String value) {
  final parts = value.split(':');
  final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return hour.clamp(0, 23) * 60 + minute.clamp(0, 59);
}

int _nightMinutes(String value) {
  final minutes = _minutesFromTime(value);
  return minutes < 12 * 60 ? minutes + 24 * 60 : minutes;
}

String _formatMinutes(int totalMinutes) {
  final normalized = totalMinutes % (24 * 60);
  final hour = normalized ~/ 60;
  final minute = normalized % 60;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '$hours 小时';
  return '$hours 小时 $rest 分钟';
}
