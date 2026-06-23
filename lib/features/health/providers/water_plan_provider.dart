import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/services/settings_write_queue.dart';
import '../models/health_reminder_schedule_status.dart';
import '../models/water_plan_state.dart';

final waterPlanProvider =
    StateNotifierProvider<WaterPlanController, WaterPlanState>((ref) {
      final controller = WaterPlanController(ref);
      controller.initialize();
      return controller;
    });

class WaterPlanController extends StateNotifier<WaterPlanState> {
  WaterPlanController(this._ref) : super(const WaterPlanState()) {
    _ref.onDispose(() {
      unawaited(_settingsWriter.dispose());
    });
  }

  static const _dailyRecordsKey = 'daily_water_records';
  static const _amountKey = 'water_reminder_amount_ml';
  static const _intervalKey = 'water_reminder_interval_minutes';
  static const _enabledKey = 'water_reminder_enabled';
  static const _startHourKey = 'water_reminder_start_hour';
  static const _endHourKey = 'water_reminder_end_hour';

  final Ref _ref;
  late final SettingsWriteQueue _settingsWriter = SettingsWriteQueue(
    write: _ref.read(settingRepositoryProvider).setSetting,
  );

  Future<void> initialize() async {
    final repo = _ref.read(settingRepositoryProvider);
    final waterMap = await _loadWaterMap();
    final records = await _loadTodayRecords();
    final goal = int.tryParse(await repo.getSetting('daily_water_goal') ?? '');
    final amount = int.tryParse(await repo.getSetting(_amountKey) ?? '');
    final interval = int.tryParse(await repo.getSetting(_intervalKey) ?? '');
    final startHour = int.tryParse(await repo.getSetting(_startHourKey) ?? '');
    final endHour = int.tryParse(await repo.getSetting(_endHourKey) ?? '');
    final enabled = await repo.getSetting(_enabledKey);
    final scheduleStatus = await repo.getSetting(
      'water_reminder_schedule_status',
    );
    final pendingCount = int.tryParse(
      await repo.getSetting('water_reminder_pending_count') ?? '',
    );
    final usesExactAlarm = await repo.getSetting(
      'water_reminder_uses_exact_alarm',
    );

    final todayWater = getTodayWaterIntake(waterMap);
    final nextGoal = (goal != null && goal > 0) ? goal : state.goalMl;
    final nextAmount = _sanitizeAmount(amount ?? state.defaultAmountMl);

    if (!mounted) return;
    _ref.read(dailyWaterGoalProvider.notifier).state = nextGoal;
    _ref.read(dailyWaterIntakeProvider.notifier).state = waterMap;
    state = state.copyWith(
      isLoading: false,
      currentWaterMl: todayWater,
      goalMl: nextGoal,
      selectedAmountMl: nextAmount,
      defaultAmountMl: nextAmount,
      intervalMinutes: (interval != null && interval >= 5)
          ? interval
          : state.intervalMinutes,
      reminderEnabled: enabled == null ? false : enabled == 'true',
      reminderScheduleStatus: HealthReminderScheduleStatus.fromStorage(
        scheduleStatus,
        pendingCount: pendingCount ?? 0,
        usesExactAlarm: usesExactAlarm == null
            ? true
            : usesExactAlarm == 'true',
      ),
      startHour: _sanitizeHour(startHour ?? state.startHour),
      endHour: _sanitizeHour(endHour ?? state.endHour),
      records: records,
      message: _messageFor(todayWater, nextGoal),
    );
  }

  void selectAmount(int amountMl) {
    state = state.copyWith(selectedAmountMl: _sanitizeAmount(amountMl));
  }

  Future<void> setGoal(int goalMl) async {
    final next = goalMl.clamp(500, 5000);
    state = state.copyWith(
      goalMl: next,
      message: _messageFor(state.currentWaterMl, next),
    );
    _ref.read(dailyWaterGoalProvider.notifier).state = next;
    await _settingsWriter.writeNow('daily_water_goal', '$next');
  }

  Future<void> setDefaultAmount(int amountMl) async {
    final next = _sanitizeAmount(amountMl);
    state = state.copyWith(defaultAmountMl: next, selectedAmountMl: next);
    await _settingsWriter.writeNow(_amountKey, '$next');
  }

  Future<void> setInterval(int minutes) async {
    final next = minutes.clamp(5, 720);
    state = state.copyWith(intervalMinutes: next);
    await _settingsWriter.writeNow(_intervalKey, '$next');
  }

  Future<void> setReminderEnabled(bool enabled) async {
    state = state.copyWith(
      reminderEnabled: enabled,
      reminderScheduleStatus: enabled
          ? state.reminderScheduleStatus
          : const HealthReminderScheduleStatus.off(),
    );
    await _settingsWriter.writeNow(_enabledKey, enabled ? 'true' : 'false');
  }

  void setReminderScheduleStatus(HealthReminderScheduleStatus status) {
    state = state.copyWith(reminderScheduleStatus: status);
  }

  Future<void> setReminderWindow({
    required int startHour,
    required int endHour,
  }) async {
    final start = _sanitizeHour(startHour);
    final end = _sanitizeHour(endHour);
    state = state.copyWith(
      startHour: start,
      endHour: end <= start ? start + 1 : end,
    );
    _settingsWriter.schedule(_startHourKey, '${state.startHour}');
    await _settingsWriter.writeNow(_endHourKey, '${state.endHour}');
  }

  Future<void> recordDrink({DateTime? recordedAt}) {
    return recordDrinkAmount(state.selectedAmountMl, recordedAt: recordedAt);
  }

  Future<void> recordDrinkAmount(int amountMl, {DateTime? recordedAt}) async {
    final now = recordedAt ?? DateTime.now();
    final amount = _sanitizeAmount(amountMl);
    final waterMap = await _loadWaterMap();
    final todayKey = _dateKey(now);
    final previousMl = waterMap[todayKey] ?? 0;
    waterMap[todayKey] = previousMl + amount;
    final todayTotal = waterMap[todayKey]!;
    final nextRecords = [
      ...state.records,
      WaterDrinkRecord(amountMl: amount, recordedAt: now),
    ];

    _ref.read(dailyWaterIntakeProvider.notifier).state = waterMap;
    final repo = _ref.read(settingRepositoryProvider);
    await repo.setSetting('daily_water_intake', jsonEncode(waterMap));
    await _saveTodayRecords(nextRecords, now);
    _ref.invalidate(dashboardProvider);

    // 计算并写入饮水经验值
    final expService = _ref.read(expServiceProvider);
    final expRepo = _ref.read(expRepositoryProvider);
    final oldTotal = await expRepo.getTotalExp();
    final oldLevel = expService.calculateLevel(oldTotal);
    final reachedGoal = todayTotal >= state.goalMl && state.goalMl > 0;
    final drinkCount = nextRecords.length;
    final waterExp = expService.calculateWaterExp(
      drinkCount: drinkCount,
      reachedGoal: reachedGoal,
    );
    // 计算今天已发放的饮水 EXP
    final todayExpLogs = await expRepo.getExpLogsByDate(now);
    final todayWaterExp = todayExpLogs
        .where((log) => log.sourceType == 'water')
        .fold<int>(0, (sum, log) => sum + log.expValue);
    final delta = waterExp - todayWaterExp;
    if (delta > 0) {
      await expRepo.insertExpLog(
        GrowthExpLogsCompanion.insert(
          sourceType: 'water',
          sourceId: 0,
          expValue: delta,
          reason: '饮水: ${todayTotal}ml / ${state.goalMl}ml',
          createdAt: now.millisecondsSinceEpoch,
        ),
      );
      final newLevel = expService.calculateLevel(oldTotal + delta);
      if (newLevel > oldLevel) {
        // Water plan runs outside widget tree, so we skip level-up event here.
        // The dashboard will pick up the level change on next refresh.
      }
    }

    state = state.copyWith(
      currentWaterMl: todayTotal,
      records: nextRecords,
      message: _messageFor(todayTotal, state.goalMl),
    );
  }

  Future<Map<String, int>> _loadWaterMap() async {
    final repo = _ref.read(settingRepositoryProvider);
    final value = await repo.getSetting('daily_water_intake');
    if (value == null) return {};
    try {
      return (jsonDecode(value) as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<List<WaterDrinkRecord>> _loadTodayRecords() async {
    final repo = _ref.read(settingRepositoryProvider);
    final value = await repo.getSetting(_dailyRecordsKey);
    if (value == null) return const [];
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      final list =
          decoded[_dateKey(DateTime.now())] as List<dynamic>? ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(WaterDrinkRecord.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveTodayRecords(
    List<WaterDrinkRecord> records,
    DateTime day,
  ) async {
    final repo = _ref.read(settingRepositoryProvider);
    final value = await repo.getSetting(_dailyRecordsKey);
    Map<String, dynamic> decoded;
    try {
      decoded = value == null ? {} : jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('daily_water_records parse failed: $e');
      return; // Skip this write to preserve existing data
    }
    decoded[_dateKey(day)] = records.map((record) => record.toJson()).toList();
    await repo.setSetting(_dailyRecordsKey, jsonEncode(decoded));
  }

  int _sanitizeAmount(int amount) {
    if (amount <= 0) return 300;
    return amount.clamp(50, 2000);
  }

  int _sanitizeHour(int hour) => hour.clamp(0, 23);

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _messageFor(int current, int goal) {
    if (current >= goal && goal > 0) {
      return '甜甜：今日补水目标完成啦，继续保持清爽状态。';
    }
    if (current == 0) {
      return '甜甜：先喝一杯水，身体会慢慢醒过来。';
    }
    return '甜甜：补水节奏很好，再来一点点就更棒。';
  }
}
