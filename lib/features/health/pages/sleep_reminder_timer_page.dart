import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../plan/services/reminder_notification_service.dart';
import '../models/sleep_plan_state.dart';
import '../providers/sleep_plan_provider.dart';
import '../utils/health_timer_assets.dart';

part '../widgets/sleep_reminder_timer_widgets.dart';

class SleepReminderTimerPage extends ConsumerStatefulWidget {
  const SleepReminderTimerPage({super.key});

  @override
  ConsumerState<SleepReminderTimerPage> createState() =>
      _SleepReminderTimerPageState();
}

class _SleepReminderTimerPageState
    extends ConsumerState<SleepReminderTimerPage> {
  static const _sleepReminderNotificationId = 5204;

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(sleepPlanProvider);

    return Scaffold(
      backgroundColor: _SleepColors.background,
      body: SafeArea(
        child: plan.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _SleepColors.primary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Column(
                  children: [
                    _TopBar(
                      title: '睡眠计划',
                      onBack: () => context.pop(),
                      onSettings: _showSettingsSheet,
                    ),
                    const SizedBox(height: 20),
                    _TargetCard(
                      plan: plan,
                      onEditSleep: () => _pickTime(_SleepTimeField.sleep),
                      onEditWake: () => _pickTime(_SleepTimeField.wake),
                    ),
                    const SizedBox(height: 16),
                    _ReminderCard(
                      plan: plan,
                      onTap: _showSettingsSheet,
                      onToggle: _toggleReminder,
                    ),
                    const SizedBox(height: 16),
                    _TodayCheckInCard(
                      plan: plan,
                      onReady: _checkInReady,
                      onWake: _checkInWake,
                    ),
                    const SizedBox(height: 16),
                    _SleepRecordCard(record: plan.displayRecord),
                    const SizedBox(height: 16),
                    _HabitStatsCard(plan: plan),
                    const SizedBox(height: 16),
                    _CompanionBubble(text: plan.companionMessage),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _pickTime(_SleepTimeField field) async {
    final plan = ref.read(sleepPlanProvider);
    final current = field == _SleepTimeField.sleep
        ? plan.sleepTime
        : plan.wakeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTimeOfDay(current),
      helpText: field == _SleepTimeField.sleep ? '设置入睡目标' : '设置起床目标',
    );
    if (picked == null) return;

    final value = _formatTimeOfDay(picked);
    final controller = ref.read(sleepPlanProvider.notifier);
    if (field == _SleepTimeField.sleep) {
      await controller.setSleepTime(value);
    } else {
      await controller.setWakeTime(value);
    }
    await _syncReminder();
  }

  Future<void> _toggleReminder(bool enabled) async {
    await ref.read(sleepPlanProvider.notifier).setReminderEnabled(enabled);
    await _syncReminder();
  }

  Future<void> _editLeadMinutes() async {
    final plan = ref.read(sleepPlanProvider);
    final value = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LeadMinutesSheet(currentValue: plan.leadMinutes),
    );
    if (value == null) return;
    await ref.read(sleepPlanProvider.notifier).setLeadMinutes(value);
    await _syncReminder();
  }

  Future<void> _showSettingsSheet() async {
    final plan = ref.read(sleepPlanProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SheetFrame(
        title: '睡眠设置',
        child: Column(
          children: [
            _SheetAction(
              icon: Icons.nightlight_round,
              title: '入睡目标',
              value: plan.sleepTime,
              onTap: () {
                Navigator.pop(context);
                _pickTime(_SleepTimeField.sleep);
              },
            ),
            _SheetAction(
              icon: Icons.wb_sunny_rounded,
              title: '起床目标',
              value: plan.wakeTime,
              onTap: () {
                Navigator.pop(context);
                _pickTime(_SleepTimeField.wake);
              },
            ),
            _SheetAction(
              icon: Icons.notifications_none_rounded,
              title: '提前提醒',
              value: '${plan.leadMinutes} 分钟',
              onTap: () {
                Navigator.pop(context);
                _editLeadMinutes();
              },
            ),
            _SheetSwitchAction(
              title: '睡前提醒',
              value: plan.reminderEnabled,
              onChanged: _toggleReminder,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkInReady() async {
    HapticFeedback.lightImpact();
    await ref.read(sleepPlanProvider.notifier).checkInReady();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已记录准备睡觉时间，晚安。')));
  }

  Future<void> _checkInWake() async {
    HapticFeedback.lightImpact();
    final saved = await ref.read(sleepPlanProvider.notifier).checkInWake();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? '睡眠记录已保存。' : '已记录起床时间，今晚从准备睡觉开始即可自动生成记录。'),
      ),
    );
  }

  Future<void> _syncReminder() async {
    final plan = ref.read(sleepPlanProvider);
    final service = ref.read(reminderNotificationServiceProvider);
    if (!plan.reminderEnabled) {
      await service.cancel(_sleepReminderNotificationId);
      return;
    }

    await service.requestPermissions();
    await service.scheduleReminder(
      id: _sleepReminderNotificationId,
      scheduledAt: _nextTimeFor(plan.reminderTime),
      title: '睡前准备时间到啦',
      body: '离 ${plan.sleepTime} 入睡目标还有 ${plan.leadMinutes} 分钟，可以慢慢收心了。',
      payload: 'sleep_plan_reminder',
    );
  }

  DateTime _nextTimeFor(String hhmm) {
    final now = DateTime.now();
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts.first) ?? 22;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }
}
