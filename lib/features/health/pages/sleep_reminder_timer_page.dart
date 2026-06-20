import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../plan/services/reminder_notification_service.dart';
import '../../plan/widgets/notification_permission_dialog.dart';
import '../models/health_reminder_schedule_status.dart';
import '../models/sleep_plan_state.dart';
import '../providers/sleep_plan_provider.dart';
import '../services/health_reminder_scheduler.dart';
import '../../../shared/widgets/common/growth_time_picker.dart';
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
    final picked = await showGrowthTimePicker(
      context: context,
      initialTime: _parseTimeOfDay(current),
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
    final scheduler = ref.read(healthReminderSchedulerProvider);
    if (!plan.reminderEnabled) {
      final status = await scheduler.cancelSleepReminderWithStatus();
      ref.read(sleepPlanProvider.notifier).setReminderScheduleStatus(status);
      return;
    }

    final permissionsGranted = await service.requestPermissions(
      requestExactAlarm: true,
    );
    if (!permissionsGranted) {
      const status = HealthReminderScheduleStatus(
        code: HealthReminderScheduleCode.permissionDenied,
      );
      ref.read(sleepPlanProvider.notifier).setReminderScheduleStatus(status);
      if (!mounted) return;
      final opened = await showNotificationPermissionGuide(context);
      if (opened) {
        final retry = await service.requestPermissions(requestExactAlarm: true);
        if (!retry) {
          _showNotificationSnack(
            '\u901a\u77e5\u6743\u9650\u4ecd\u672a\u5f00\u542f\uff0c'
            '\u65e0\u6cd5\u53d1\u9001\u7761\u524d\u63d0\u9192\u3002',
          );
          return;
        }
      } else {
        _showNotificationSnack(
          '\u9700\u8981\u901a\u77e5\u6743\u9650\u624d\u80fd'
          '\u53d1\u9001\u7761\u524d\u63d0\u9192\u3002',
        );
        return;
      }
    }

    final status = await scheduler.scheduleSleepReminderWithStatus(
      sleepTime: plan.sleepTime,
      leadMinutes: plan.leadMinutes,
      requestPermissions: false,
    );
    ref.read(sleepPlanProvider.notifier).setReminderScheduleStatus(status);
    if (!status.isScheduled) {
      _showNotificationSnack(_scheduleStatusSnack(status, 'sleep'));
      return;
    }
    if (status.isDelayedBySystemAlarmLimit) {
      _showNotificationSnack(
        '\u7cfb\u7edf\u95f9\u949f\u6743\u9650\u53d7\u9650\uff0c'
        '\u63d0\u9192\u5df2\u964d\u7ea7\u5b89\u6392\uff0c'
        '\u53ef\u80fd\u4f1a\u5ef6\u8fdf\u3002',
      );
    }
  }

  void _showNotificationSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

String _scheduleStatusSnack(HealthReminderScheduleStatus status, String kind) {
  switch (status.code) {
    case HealthReminderScheduleCode.permissionDenied:
      return '通知权限未开启，无法发送提醒。';
    case HealthReminderScheduleCode.exactAlarmDenied:
      return '系统闹钟权限受限，提醒可能延迟。';
    case HealthReminderScheduleCode.noPendingNotifications:
      return '未检测到系统待投递提醒，请重新授权或重试。';
    case HealthReminderScheduleCode.scheduleFailed:
      return kind == 'sleep' ? '睡前提醒创建失败，请检查系统通知设置。' : '喝水提醒创建失败，请检查系统通知设置。';
    case HealthReminderScheduleCode.off:
      return '提醒已关闭。';
    case HealthReminderScheduleCode.scheduled:
      return status.isDelayedBySystemAlarmLimit
          ? '提醒已安排，但系统闹钟权限受限，可能延迟。'
          : '提醒已安排。';
    case HealthReminderScheduleCode.unknown:
      return '提醒状态未知，请重新打开提醒试试。';
  }
}
