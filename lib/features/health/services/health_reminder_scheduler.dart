import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/repository_providers.dart';
import '../../../shared/services/settings_write_queue.dart';
import '../models/health_reminder_schedule_status.dart';
import '../../plan/services/reminder_notification_service.dart';

final healthReminderSchedulerProvider = Provider<HealthReminderScheduler>((
  ref,
) {
  final writer = SettingsWriteQueue(
    write: ref.read(settingRepositoryProvider).setSetting,
  );
  ref.onDispose(() {
    unawaited(writer.dispose());
  });
  return HealthReminderScheduler(
    notificationService: ref.watch(reminderNotificationServiceProvider),
    readSetting: (key) => ref.read(settingRepositoryProvider).getSetting(key),
    writeSetting: writer.writeNow,
  );
});

final healthReminderBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(healthReminderSchedulerProvider).restoreEnabledReminders();
});

typedef SettingReader = Future<String?> Function(String key);
typedef SettingWriter = Future<void> Function(String key, String value);

class HealthReminderScheduler {
  const HealthReminderScheduler({
    required ReminderNotificationGateway notificationService,
    required SettingReader readSetting,
    SettingWriter? writeSetting,
  }) : _notificationService = notificationService,
       _readSetting = readSetting,
       _writeSetting = writeSetting;

  static const waterLegacyNotificationId = 5202;
  static const waterNotificationBaseId = 520200;
  static const maxWaterNotifications = 96;
  static const sleepReminderNotificationId = 5204;

  static const _waterAmountKey = 'water_reminder_amount_ml';
  static const _waterIntervalKey = 'water_reminder_interval_minutes';
  static const _waterEnabledKey = 'water_reminder_enabled';
  static const _waterStartHourKey = 'water_reminder_start_hour';
  static const _waterEndHourKey = 'water_reminder_end_hour';
  static const waterScheduleStatusKey = 'water_reminder_schedule_status';
  static const waterPendingCountKey = 'water_reminder_pending_count';
  static const waterUsesExactAlarmKey = 'water_reminder_uses_exact_alarm';
  static const _sleepTimeKey = 'sleep_reminder_time';
  static const _sleepLeadMinutesKey = 'sleep_reminder_lead_minutes';
  static const _sleepEnabledKey = 'sleep_reminder_enabled';
  static const sleepScheduleStatusKey = 'sleep_reminder_schedule_status';
  static const sleepPendingCountKey = 'sleep_reminder_pending_count';
  static const sleepUsesExactAlarmKey = 'sleep_reminder_uses_exact_alarm';

  final ReminderNotificationGateway _notificationService;
  final SettingReader _readSetting;
  final SettingWriter? _writeSetting;

  Future<void> restoreEnabledReminders() async {
    final waterEnabled = await _readBool(_waterEnabledKey, fallback: true);
    if (waterEnabled) {
      await scheduleWaterRemindersWithStatus(requestPermissions: false);
    }

    final sleepEnabled = await _readBool(_sleepEnabledKey, fallback: false);
    if (sleepEnabled) {
      await scheduleSleepReminderWithStatus(requestPermissions: false);
    }
  }

  Future<bool> scheduleWaterReminders({
    int? amountMl,
    int? intervalMinutes,
    int? startHour,
    int? endHour,
    bool requestPermissions = true,
  }) async {
    final status = await scheduleWaterRemindersWithStatus(
      amountMl: amountMl,
      intervalMinutes: intervalMinutes,
      startHour: startHour,
      endHour: endHour,
      requestPermissions: requestPermissions,
    );
    return status.isScheduled;
  }

  Future<HealthReminderScheduleStatus> scheduleWaterRemindersWithStatus({
    int? amountMl,
    int? intervalMinutes,
    int? startHour,
    int? endHour,
    bool requestPermissions = true,
  }) async {
    final notificationsGranted = requestPermissions
        ? await _notificationService.requestPermissions(requestExactAlarm: true)
        : await _notificationService.areNotificationsEnabled();
    if (!notificationsGranted) {
      final status = const HealthReminderScheduleStatus(
        code: HealthReminderScheduleCode.permissionDenied,
      );
      await _persistWaterStatus(status);
      return status;
    }

    final usesExactAlarm = await _notificationService.canScheduleExactAlarms();
    final amount = amountMl ?? await _readInt(_waterAmountKey, fallback: 300);
    final interval =
        intervalMinutes ?? await _readInt(_waterIntervalKey, fallback: 60);
    final start = startHour ?? await _readInt(_waterStartHourKey, fallback: 8);
    final end = endHour ?? await _readInt(_waterEndHourKey, fallback: 22);
    final slots = waterReminderSlots(
      startHour: start,
      endHour: end,
      intervalMinutes: interval,
    );

    await cancelWaterReminders();
    if (slots.isEmpty) {
      final status = HealthReminderScheduleStatus(
        code: HealthReminderScheduleCode.scheduleFailed,
        usesExactAlarm: usesExactAlarm,
      );
      await _persistWaterStatus(status);
      return status;
    }

    var allScheduled = true;
    for (var index = 0; index < slots.length; index++) {
      final slot = slots[index];
      final scheduled = await _notificationService.scheduleReminder(
        id: waterNotificationBaseId + index,
        scheduledAt: _nextTimeFor(slot.hour, slot.minute),
        title: '该喝水啦',
        body: '喝 $amount ml，保持清爽状态。',
        payload: 'water_reminder',
        requestPermissionsIfNeeded: requestPermissions,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      allScheduled = allScheduled && scheduled;
      if (!scheduled && requestPermissions) break;
    }
    final pendingCount = await pendingWaterReminderCount();
    final status = _statusFromScheduleResult(
      allScheduled: allScheduled,
      pendingCount: pendingCount,
      usesExactAlarm: usesExactAlarm,
    );
    await _persistWaterStatus(status);
    return status;
  }

  Future<void> cancelWaterReminders() async {
    await _notificationService.cancel(waterLegacyNotificationId);
    for (var index = 0; index < maxWaterNotifications; index++) {
      await _notificationService.cancel(waterNotificationBaseId + index);
    }
  }

  /// 取消今天剩余的喝水提醒（达标后调用）
  Future<void> cancelWaterRemindersForToday() async {
    final pending = await _notificationService.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= waterNotificationBaseId &&
          p.id < waterNotificationBaseId + maxWaterNotifications) {
        await _notificationService.cancel(p.id);
      }
    }
  }

  Future<HealthReminderScheduleStatus> cancelWaterRemindersWithStatus() async {
    await cancelWaterReminders();
    const status = HealthReminderScheduleStatus.off();
    await _persistWaterStatus(status);
    return status;
  }

  Future<int> pendingWaterReminderCount() {
    return _notificationService.pendingCountWhere(_isWaterReminderId);
  }

  Future<bool> scheduleSleepReminder({
    String? sleepTime,
    int? leadMinutes,
    bool requestPermissions = true,
  }) async {
    final status = await scheduleSleepReminderWithStatus(
      sleepTime: sleepTime,
      leadMinutes: leadMinutes,
      requestPermissions: requestPermissions,
    );
    return status.isScheduled;
  }

  Future<HealthReminderScheduleStatus> scheduleSleepReminderWithStatus({
    String? sleepTime,
    int? leadMinutes,
    bool requestPermissions = true,
  }) async {
    final notificationsGranted = requestPermissions
        ? await _notificationService.requestPermissions(requestExactAlarm: true)
        : await _notificationService.areNotificationsEnabled();
    if (!notificationsGranted) {
      final status = const HealthReminderScheduleStatus(
        code: HealthReminderScheduleCode.permissionDenied,
      );
      await _persistSleepStatus(status);
      return status;
    }

    final usesExactAlarm = await _notificationService.canScheduleExactAlarms();
    final targetSleepTime =
        sleepTime ?? await _readString(_sleepTimeKey, fallback: '22:30');
    final lead =
        leadMinutes ?? await _readInt(_sleepLeadMinutesKey, fallback: 30);
    final reminder = sleepReminderSlot(
      sleepTime: targetSleepTime,
      leadMinutes: lead,
    );

    await _notificationService.cancel(sleepReminderNotificationId);
    final scheduled = await _notificationService.scheduleReminder(
      id: sleepReminderNotificationId,
      scheduledAt: _nextTimeFor(reminder.hour, reminder.minute),
      title: '睡前准备时间到啦',
      body: '离 $targetSleepTime 入睡目标还有 $lead 分钟，可以慢慢收心了。',
      payload: 'sleep_plan_reminder',
      requestPermissionsIfNeeded: requestPermissions,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    final pendingCount = await pendingSleepReminderCount();
    final status = _statusFromScheduleResult(
      allScheduled: scheduled,
      pendingCount: pendingCount,
      usesExactAlarm: usesExactAlarm,
    );
    await _persistSleepStatus(status);
    return status;
  }

  Future<void> cancelSleepReminder() {
    return _notificationService.cancel(sleepReminderNotificationId);
  }

  Future<HealthReminderScheduleStatus> cancelSleepReminderWithStatus() async {
    await cancelSleepReminder();
    const status = HealthReminderScheduleStatus.off();
    await _persistSleepStatus(status);
    return status;
  }

  Future<int> pendingSleepReminderCount() async {
    final hasPending = await _notificationService.hasPendingNotification(
      sleepReminderNotificationId,
    );
    return hasPending ? 1 : 0;
  }

  static List<ReminderTimeSlot> waterReminderSlots({
    required int startHour,
    required int endHour,
    required int intervalMinutes,
  }) {
    final start = startHour.clamp(0, 23) * 60;
    var end = endHour.clamp(0, 24) * 60;
    if (end <= start) end = 24 * 60;
    final interval = intervalMinutes.clamp(5, 720);
    final slots = <ReminderTimeSlot>[];

    for (
      var minuteOfDay = start;
      minuteOfDay < end && slots.length < maxWaterNotifications;
      minuteOfDay += interval
    ) {
      slots.add(
        ReminderTimeSlot(
          hour: (minuteOfDay ~/ 60) % 24,
          minute: minuteOfDay % 60,
        ),
      );
    }
    return slots;
  }

  static ReminderTimeSlot sleepReminderSlot({
    required String sleepTime,
    required int leadMinutes,
  }) {
    final sleepMinutes = _minutesFromTime(sleepTime);
    final reminderMinutes =
        (sleepMinutes - leadMinutes.clamp(0, 180)) % (24 * 60);
    return ReminderTimeSlot(
      hour: reminderMinutes ~/ 60,
      minute: reminderMinutes % 60,
    );
  }

  static DateTime _nextTimeFor(int hour, int minute) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
    return target;
  }

  static bool _isWaterReminderId(int id) {
    return id >= waterNotificationBaseId &&
        id < waterNotificationBaseId + maxWaterNotifications;
  }

  static HealthReminderScheduleStatus _statusFromScheduleResult({
    required bool allScheduled,
    required int pendingCount,
    required bool usesExactAlarm,
  }) {
    if (pendingCount > 0) {
      return HealthReminderScheduleStatus(
        code: HealthReminderScheduleCode.scheduled,
        pendingCount: pendingCount,
        usesExactAlarm: usesExactAlarm,
      );
    }
    return HealthReminderScheduleStatus(
      code: allScheduled
          ? HealthReminderScheduleCode.noPendingNotifications
          : HealthReminderScheduleCode.scheduleFailed,
      pendingCount: pendingCount,
      usesExactAlarm: usesExactAlarm,
    );
  }

  Future<void> _persistWaterStatus(HealthReminderScheduleStatus status) async {
    final write = _writeSetting;
    if (write == null) return;
    await write(waterScheduleStatusKey, status.storageValue);
    await write(waterPendingCountKey, '${status.pendingCount}');
    await write(
      waterUsesExactAlarmKey,
      status.usesExactAlarm ? 'true' : 'false',
    );
  }

  Future<void> _persistSleepStatus(HealthReminderScheduleStatus status) async {
    final write = _writeSetting;
    if (write == null) return;
    await write(sleepScheduleStatusKey, status.storageValue);
    await write(sleepPendingCountKey, '${status.pendingCount}');
    await write(
      sleepUsesExactAlarmKey,
      status.usesExactAlarm ? 'true' : 'false',
    );
  }

  Future<bool> _readBool(String key, {required bool fallback}) async {
    final value = await _readSetting(key);
    if (value == null) return fallback;
    return value == 'true';
  }

  Future<int> _readInt(String key, {required int fallback}) async {
    final value = await _readSetting(key);
    return int.tryParse(value ?? '') ?? fallback;
  }

  Future<String> _readString(String key, {required String fallback}) async {
    final value = await _readSetting(key);
    if (value == null || value.isEmpty) return fallback;
    return value;
  }

  static int _minutesFromTime(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return hour.clamp(0, 23) * 60 + minute.clamp(0, 59);
  }
}

class ReminderTimeSlot {
  const ReminderTimeSlot({required this.hour, required this.minute});

  final int hour;
  final int minute;
}
