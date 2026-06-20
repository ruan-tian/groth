import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/health/models/health_reminder_schedule_status.dart';
import 'package:growth_os/features/health/services/health_reminder_scheduler.dart';
import 'package:growth_os/features/plan/services/reminder_notification_service.dart';

void main() {
  test('water reminder slots respect window and interval', () {
    final slots = HealthReminderScheduler.waterReminderSlots(
      startHour: 8,
      endHour: 12,
      intervalMinutes: 90,
    );

    expect(slots.map((slot) => '${slot.hour}:${slot.minute}'), [
      '8:0',
      '9:30',
      '11:0',
    ]);
  });

  test('sleep reminder slot subtracts lead minutes across midnight', () {
    final slot = HealthReminderScheduler.sleepReminderSlot(
      sleepTime: '00:15',
      leadMinutes: 30,
    );

    expect(slot.hour, 23);
    expect(slot.minute, 45);
  });

  test(
    'water scheduling reports permission denied before pretending enabled',
    () async {
      final scheduler = _scheduler(
        _FakeNotificationGateway(notificationsEnabled: false),
      );

      final status = await scheduler.scheduleWaterRemindersWithStatus(
        requestPermissions: false,
      );

      expect(status.code, HealthReminderScheduleCode.permissionDenied);
      expect(status.isScheduled, isFalse);
    },
  );

  test('water scheduling verifies pending reminder ids', () async {
    final gateway = _FakeNotificationGateway(addPendingOnSchedule: true);
    final scheduler = _scheduler(gateway);

    final status = await scheduler.scheduleWaterRemindersWithStatus(
      startHour: 8,
      endHour: 10,
      intervalMinutes: 60,
      requestPermissions: false,
    );

    expect(status.code, HealthReminderScheduleCode.scheduled);
    expect(status.pendingCount, 2);
    expect(
      gateway.cancelledIds,
      contains(HealthReminderScheduler.waterLegacyNotificationId),
    );
  });

  test(
    'water scheduling reports no pending notifications when plugin lies',
    () async {
      final scheduler = _scheduler(_FakeNotificationGateway());

      final status = await scheduler.scheduleWaterRemindersWithStatus(
        startHour: 8,
        endHour: 10,
        intervalMinutes: 60,
        requestPermissions: false,
      );

      expect(status.code, HealthReminderScheduleCode.noPendingNotifications);
      expect(status.pendingCount, 0);
    },
  );

  test('sleep scheduling verifies fixed pending id 5204', () async {
    final scheduler = _scheduler(
      _FakeNotificationGateway(addPendingOnSchedule: true),
    );

    final status = await scheduler.scheduleSleepReminderWithStatus(
      sleepTime: '00:15',
      leadMinutes: 30,
      requestPermissions: false,
    );

    expect(status.code, HealthReminderScheduleCode.scheduled);
    expect(status.pendingCount, 1);
  });

  test('scheduled status records inexact alarm fallback', () async {
    final scheduler = _scheduler(
      _FakeNotificationGateway(
        addPendingOnSchedule: true,
        canScheduleExact: false,
      ),
    );

    final status = await scheduler.scheduleSleepReminderWithStatus(
      requestPermissions: false,
    );

    expect(status.code, HealthReminderScheduleCode.scheduled);
    expect(status.usesExactAlarm, isFalse);
    expect(status.isDelayedBySystemAlarmLimit, isTrue);
  });
}

HealthReminderScheduler _scheduler(_FakeNotificationGateway gateway) {
  final settings = <String, String>{};
  return HealthReminderScheduler(
    notificationService: gateway,
    readSetting: (key) async => settings[key],
    writeSetting: (key, value) async => settings[key] = value,
  );
}

class _FakeNotificationGateway implements ReminderNotificationGateway {
  _FakeNotificationGateway({
    this.notificationsEnabled = true,
    this.canScheduleExact = true,
    this.addPendingOnSchedule = false,
  });

  final bool notificationsEnabled;
  final bool canScheduleExact;
  final bool addPendingOnSchedule;
  final pendingIds = <int>{};
  final cancelledIds = <int>[];

  @override
  Future<bool> areNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<bool> canScheduleExactAlarms() async => canScheduleExact;

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
    pendingIds.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    pendingIds.clear();
  }

  @override
  Future<bool> hasPendingNotification(int id) async => pendingIds.contains(id);

  @override
  Future<int> pendingCountWhere(bool Function(int id) test) async {
    return pendingIds.where(test).length;
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return pendingIds
        .map((id) => PendingNotificationRequest(id, 'title', 'body', 'payload'))
        .toList();
  }

  @override
  Future<bool> requestPermissions({bool requestExactAlarm = false}) async {
    return notificationsEnabled;
  }

  @override
  Future<bool> scheduleReminder({
    required int id,
    required DateTime scheduledAt,
    required String title,
    required String body,
    String? payload,
    bool requestPermissionsIfNeeded = true,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (addPendingOnSchedule) pendingIds.add(id);
    return true;
  }

  @override
  Future<bool> scheduleTestReminder({
    Duration delay = const Duration(minutes: 1),
  }) async {
    return true;
  }

  @override
  Future<bool> showImmediate({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    return notificationsEnabled;
  }

  @override
  Future<bool> showTestNotification() async => notificationsEnabled;
}
