import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart'
    show dashboardProvider;
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/sleep_provider.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../../../core/services/pet_event_bus.dart';
import '../models/health_reminder_schedule_status.dart';
import '../models/sleep_plan_state.dart';

final sleepPlanProvider =
    StateNotifierProvider<SleepPlanController, SleepPlanState>((ref) {
      final controller = SleepPlanController(ref);
      controller.initialize();
      return controller;
    });

class SleepPlanController extends StateNotifier<SleepPlanState> {
  SleepPlanController(this._ref) : super(const SleepPlanState());

  static const _sleepTimeKey = 'sleep_reminder_time';
  static const _wakeTimeKey = 'sleep_wake_time';
  static const _leadMinutesKey = 'sleep_reminder_lead_minutes';
  static const _enabledKey = 'sleep_reminder_enabled';
  static const _readyAtKey = 'sleep_ready_check_in_at';
  static const _wokeAtKey = 'sleep_wakeup_check_in_at';

  final Ref _ref;

  Future<void> initialize() async {
    final settings = _ref.read(settingRepositoryProvider);
    final sleep = await settings.getSetting(_sleepTimeKey);
    final wake = await settings.getSetting(_wakeTimeKey);
    final lead = int.tryParse(await settings.getSetting(_leadMinutesKey) ?? '');
    final enabled = await settings.getSetting(_enabledKey);
    final scheduleStatus = await settings.getSetting(
      'sleep_reminder_schedule_status',
    );
    final pendingCount = int.tryParse(
      await settings.getSetting('sleep_reminder_pending_count') ?? '',
    );
    final usesExactAlarm = await settings.getSetting(
      'sleep_reminder_uses_exact_alarm',
    );
    final readyAt = _activeTimestamp(
      await settings.getSetting(_readyAtKey),
      DateTime.now(),
    );
    final wokeAt = _activeTimestamp(
      await settings.getSetting(_wokeAtKey),
      DateTime.now(),
    );
    final cleanWokeAt =
        readyAt != null && wokeAt != null && wokeAt.isBefore(readyAt)
        ? null
        : wokeAt;

    final sleepRepo = _ref.read(sleepRepositoryProvider);
    final lastRecord = await sleepRepo.getLastNightSleepRecord();
    final recentRecords = await sleepRepo.getRecentSleepRecords(limit: 7);

    if (!mounted) return;
    state = state.copyWith(
      isLoading: false,
      sleepTime: _sanitizeTime(sleep, state.sleepTime),
      wakeTime: _sanitizeTime(wake, state.wakeTime),
      leadMinutes: _sanitizeLeadMinutes(lead ?? state.leadMinutes),
      reminderEnabled: enabled == null ? true : enabled == 'true',
      reminderScheduleStatus: HealthReminderScheduleStatus.fromStorage(
        scheduleStatus,
        pendingCount: pendingCount ?? 0,
        usesExactAlarm: usesExactAlarm == null
            ? true
            : usesExactAlarm == 'true',
      ),
      readyAt: readyAt,
      clearReadyAt: readyAt == null,
      wokeAt: cleanWokeAt,
      clearWokeAt: cleanWokeAt == null,
      lastRecord: lastRecord,
      clearLastRecord: lastRecord == null,
      recentRecords: recentRecords,
    );
  }

  Future<void> setSleepTime(String value) async {
    final next = _sanitizeTime(value, state.sleepTime);
    state = state.copyWith(sleepTime: next);
    await _ref.read(settingRepositoryProvider).setSetting(_sleepTimeKey, next);
  }

  Future<void> setWakeTime(String value) async {
    final next = _sanitizeTime(value, state.wakeTime);
    state = state.copyWith(wakeTime: next);
    await _ref.read(settingRepositoryProvider).setSetting(_wakeTimeKey, next);
  }

  Future<void> setLeadMinutes(int minutes) async {
    final next = _sanitizeLeadMinutes(minutes);
    state = state.copyWith(leadMinutes: next);
    await _ref
        .read(settingRepositoryProvider)
        .setSetting(_leadMinutesKey, '$next');
  }

  Future<void> setReminderEnabled(bool enabled) async {
    state = state.copyWith(
      reminderEnabled: enabled,
      reminderScheduleStatus: enabled
          ? state.reminderScheduleStatus
          : const HealthReminderScheduleStatus.off(),
    );
    await _ref
        .read(settingRepositoryProvider)
        .setSetting(_enabledKey, enabled ? 'true' : 'false');
  }

  void setReminderScheduleStatus(HealthReminderScheduleStatus status) {
    state = state.copyWith(reminderScheduleStatus: status);
  }

  Future<void> checkInReady({DateTime? checkedAt}) async {
    final now = checkedAt ?? DateTime.now();
    state = state.copyWith(readyAt: now, clearWokeAt: true);
    final settings = _ref.read(settingRepositoryProvider);
    await settings.setSetting(_readyAtKey, now.toIso8601String());
    await settings.deleteSetting(_wokeAtKey);
  }

  Future<bool> checkInWake({DateTime? checkedAt}) async {
    final now = checkedAt ?? DateTime.now();
    final readyAt = state.readyAt;
    await _ref
        .read(settingRepositoryProvider)
        .setSetting(_wokeAtKey, now.toIso8601String());

    if (readyAt == null) {
      state = state.copyWith(wokeAt: now);
      return false;
    }

    final durationMinutes = now.difference(readyAt).inMinutes.clamp(1, 24 * 60);
    final timestamp = now.millisecondsSinceEpoch;
    final record = SleepRecordsCompanion(
      sleepDate: Value(_dateKey(_sleepDateFor(readyAt))),
      bedTime: Value(_timeLabel(readyAt)),
      sleepTime: Value(_timeLabel(readyAt)),
      wakeTime: Value(_timeLabel(now)),
      durationMinutes: Value(durationMinutes),
      qualityLevel: const Value(4),
      fallAsleepMinutes: const Value(0),
      wakeCount: const Value(0),
      energyLevel: const Value(3),
      note: const Value('由睡眠计划打卡自动生成'),
      createdAt: Value(timestamp),
      updatedAt: Value(timestamp),
    );
    await _ref.read(sleepRepositoryProvider).insertSleepRecord(record);

    _emitSleepCompletedEvent(durationMinutes);
    _invalidateSleepData();
    final sleepRepo = _ref.read(sleepRepositoryProvider);
    final lastRecord = await sleepRepo.getLastNightSleepRecord();
    final recentRecords = await sleepRepo.getRecentSleepRecords(limit: 7);

    if (!mounted) return true;
    state = state.copyWith(
      wokeAt: now,
      lastRecord: lastRecord,
      clearLastRecord: lastRecord == null,
      recentRecords: recentRecords,
    );
    return true;
  }

  void _invalidateSleepData() {
    _ref.invalidate(lastNightSleepRecordProvider);
    _ref.invalidate(recentSleepRecordsProvider(5));
    _ref.invalidate(weeklyAvgSleepDurationProvider);
    _ref.invalidate(monthlyAvgSleepDurationProvider);
    _ref.invalidate(weeklyAvgSleepQualityProvider);
    _ref.invalidate(monthlyAvgSleepQualityProvider);
    _ref.invalidate(weeklyAvgBedTimeProvider);
    _ref.invalidate(weeklyAvgWakeTimeProvider);
    _ref.invalidate(weeklySleepDurationProvider);
    _ref.invalidate(monthlySleepDurationProvider);
    _ref.invalidate(yearlySleepDurationProvider);
    _ref.invalidate(weeklySleepQualityProvider);
    _ref.invalidate(monthlySleepQualityProvider);
    _ref.invalidate(yearlySleepQualityProvider);
    _ref.invalidate(dashboardProvider);
  }

  void _emitSleepCompletedEvent(int durationMinutes) {
    PetEventBus.instance.emit(
      PetEvent.moduleCompleted(
        eventId: 'sleep_plan_${DateTime.now().millisecondsSinceEpoch}',
        type: PetEventType.sleepCompleted,
        module: 'sleep',
        payload: {'durationMinutes': durationMinutes},
      ),
    );
  }

  DateTime? _activeTimestamp(String? value, DateTime now) {
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    final age = now.difference(parsed);
    if (age.inHours > 36 || age.inHours < -1) return null;
    return parsed;
  }

  String _sanitizeTime(String? value, String fallback) {
    if (value == null) return fallback;
    final parts = value.split(':');
    if (parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return fallback;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  int _sanitizeLeadMinutes(int minutes) => minutes.clamp(0, 180);

  DateTime _sleepDateFor(DateTime readyAt) {
    if (readyAt.hour < 12) {
      return readyAt.subtract(const Duration(days: 1));
    }
    return readyAt;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _timeLabel(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
