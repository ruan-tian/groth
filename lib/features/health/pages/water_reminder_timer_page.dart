import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../plan/models/reminder_timer_state.dart';
import '../../plan/providers/reminder_timer_provider.dart';
import '../../plan/services/reminder_notification_service.dart';
import '../../plan/widgets/notification_permission_dialog.dart';
import '../models/health_reminder_schedule_status.dart';
import '../models/water_plan_state.dart';
import '../providers/water_plan_provider.dart';
import '../services/health_reminder_scheduler.dart';
import '../utils/health_timer_assets.dart';

part '../widgets/water_reminder_timer_widgets.dart';

class WaterReminderTimerPage extends ConsumerStatefulWidget {
  const WaterReminderTimerPage({super.key});

  @override
  ConsumerState<WaterReminderTimerPage> createState() =>
      _WaterReminderTimerPageState();
}

class _WaterReminderTimerPageState
    extends ConsumerState<WaterReminderTimerPage> {
  static const _amounts = [200, 300, 500];

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(waterPlanProvider);
    final reminder = ref.watch(reminderTimerProvider(ReminderKind.water));

    ref.listen(reminderTimerProvider(ReminderKind.water), (previous, next) {
      if ((previous?.completedCount ?? 0) < next.completedCount && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('喝水提醒到啦，记录一杯水吧。')));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAEC),
      body: SafeArea(
        child: plan.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _WaterColors.primary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Column(
                  children: [
                    _TopBar(
                      title: '喝水计划',
                      onBack: () => context.pop(),
                      onSettings: _showSettingsSheet,
                    ),
                    const SizedBox(height: 20),
                    _ProgressCard(plan: plan),
                    const SizedBox(height: 16),
                    _QuickCheckCard(
                      selectedAmount: plan.selectedAmountMl,
                      amounts: _amounts,
                      onAmountSelected: (amount) => ref
                          .read(waterPlanProvider.notifier)
                          .selectAmount(amount),
                      onCheckIn: _recordDrink,
                    ),
                    const SizedBox(height: 16),
                    _ReminderSettingsCard(
                      plan: plan,
                      reminder: reminder,
                      onToggle: _toggleReminder,
                      onEditGoal: _editGoal,
                      onEditDefaultAmount: _editDefaultAmount,
                      onEditInterval: _editInterval,
                      onEditWindow: _editWindow,
                    ),
                    const SizedBox(height: 16),
                    _TodayRecordsCard(records: plan.records),
                    const SizedBox(height: 16),
                    _CompanionBubble(text: plan.message),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _recordDrink() async {
    HapticFeedback.lightImpact();
    final planController = ref.read(waterPlanProvider.notifier);
    await planController.recordDrink();
    final plan = ref.read(waterPlanProvider);

    // 如果达标，取消今天剩余提醒
    if (plan.currentWaterMl >= plan.goalMl && plan.goalMl > 0) {
      final scheduler = ref.read(healthReminderSchedulerProvider);
      await scheduler.cancelWaterRemindersForToday();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('今日饮水目标已达成！')),
        );
      }
      return; // 不再调度新提醒
    }

    if (plan.reminderEnabled) {
      await _scheduleNextReminder(plan);
    }
  }

  Future<void> _toggleReminder(bool enabled) async {
    await ref.read(waterPlanProvider.notifier).setReminderEnabled(enabled);
    final plan = ref.read(waterPlanProvider);
    if (enabled) {
      await _scheduleNextReminder(plan);
    } else {
      final status = await ref
          .read(healthReminderSchedulerProvider)
          .cancelWaterRemindersWithStatus();
      ref.read(waterPlanProvider.notifier).setReminderScheduleStatus(status);
      ref
          .read(reminderTimerProvider(ReminderKind.water).notifier)
          .reset(duration: Duration(minutes: plan.intervalMinutes));
    }
  }

  Future<HealthReminderScheduleStatus> _scheduleNextReminder(
    WaterPlanState plan,
  ) async {
    final duration = Duration(minutes: plan.intervalMinutes);
    final service = ref.read(reminderNotificationServiceProvider);
    final scheduler = ref.read(healthReminderSchedulerProvider);
    final permissionsGranted = await service.requestPermissions(
      requestExactAlarm: true,
    );
    if (!permissionsGranted) {
      const status = HealthReminderScheduleStatus(
        code: HealthReminderScheduleCode.permissionDenied,
      );
      ref.read(waterPlanProvider.notifier).setReminderScheduleStatus(status);
      if (!mounted) return status;
      final opened = await showNotificationPermissionGuide(context);
      if (opened) {
        final retry = await service.requestPermissions(requestExactAlarm: true);
        if (!retry) {
          if (!mounted) return status;
          _showNotificationSnack(
            '\u901a\u77e5\u6743\u9650\u4ecd\u672a\u5f00\u542f\uff0c'
            '\u65e0\u6cd5\u53d1\u9001\u559d\u6c34\u63d0\u9192\u3002',
          );
          return status;
        }
      } else {
        if (!mounted) return status;
        _showNotificationSnack(
          '\u9700\u8981\u901a\u77e5\u6743\u9650\u624d\u80fd'
          '\u53d1\u9001\u559d\u6c34\u63d0\u9192\u3002',
        );
        return status;
      }
    }

    final status = await scheduler.scheduleWaterRemindersWithStatus(
      amountMl: plan.defaultAmountMl,
      intervalMinutes: plan.intervalMinutes,
      startHour: plan.startHour,
      endHour: plan.endHour,
      requestPermissions: false,
    );
    ref.read(waterPlanProvider.notifier).setReminderScheduleStatus(status);
    if (!status.isScheduled) {
      _showNotificationSnack(_scheduleStatusSnack(status, 'water'));
      ref
          .read(reminderTimerProvider(ReminderKind.water).notifier)
          .reset(duration: duration);
      return status;
    }

    ref
        .read(reminderTimerProvider(ReminderKind.water).notifier)
        .start(duration);
    if (status.isDelayedBySystemAlarmLimit) {
      _showNotificationSnack(
        '\u7cfb\u7edf\u95f9\u949f\u6743\u9650\u53d7\u9650\uff0c'
        '\u63d0\u9192\u5df2\u964d\u7ea7\u5b89\u6392\uff0c'
        '\u53ef\u80fd\u4f1a\u5ef6\u8fdf\u3002',
      );
    }
    return status;
  }

  void _showNotificationSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editGoal() async {
    final plan = ref.read(waterPlanProvider);
    final value = await _showNumberSheet(
      title: '每日目标',
      subtitle: '建议每天 1500-2500 ml',
      currentValue: plan.goalMl,
      unit: 'ml',
      min: 500,
      max: 5000,
      step: 100,
    );
    if (value != null) {
      await ref.read(waterPlanProvider.notifier).setGoal(value);
    }
  }

  Future<void> _editDefaultAmount() async {
    final plan = ref.read(waterPlanProvider);
    final value = await _showNumberSheet(
      title: '每次默认',
      subtitle: '快速打卡默认饮水量',
      currentValue: plan.defaultAmountMl,
      unit: 'ml',
      min: 50,
      max: 2000,
      step: 50,
    );
    if (value != null) {
      await ref.read(waterPlanProvider.notifier).setDefaultAmount(value);
      await _rescheduleIfEnabled();
    }
  }

  Future<void> _editInterval() async {
    final plan = ref.read(waterPlanProvider);
    final value = await _showNumberSheet(
      title: '提醒间隔',
      subtitle: '建议 45-90 分钟提醒一次',
      currentValue: plan.intervalMinutes,
      unit: '分钟',
      min: 5,
      max: 720,
      step: 5,
    );
    if (value != null) {
      await ref.read(waterPlanProvider.notifier).setInterval(value);
      await _rescheduleIfEnabled();
    }
  }

  Future<void> _editWindow() async {
    final plan = ref.read(waterPlanProvider);
    final result = await showModalBottomSheet<({int start, int end})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WindowEditSheet(plan: plan),
    );
    if (result != null) {
      await ref
          .read(waterPlanProvider.notifier)
          .setReminderWindow(startHour: result.start, endHour: result.end);
      await _rescheduleIfEnabled();
    }
  }

  Future<void> _rescheduleIfEnabled() async {
    final plan = ref.read(waterPlanProvider);
    if (plan.reminderEnabled) {
      await _scheduleNextReminder(plan);
    }
  }

  Future<int?> _showNumberSheet({
    required String title,
    required String subtitle,
    required int currentValue,
    required String unit,
    required int min,
    required int max,
    required int step,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NumberEditSheet(
        title: title,
        subtitle: subtitle,
        currentValue: currentValue,
        unit: unit,
        min: min,
        max: max,
        step: step,
      ),
    );
  }

  Future<void> _showSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SheetFrame(
        title: '喝水设置',
        child: Column(
          children: [
            _SheetAction(
              icon: Icons.local_drink_outlined,
              title: '每日目标',
              onTap: () {
                Navigator.pop(context);
                _editGoal();
              },
            ),
            _SheetAction(
              icon: Icons.water_drop_outlined,
              title: '每次默认',
              onTap: () {
                Navigator.pop(context);
                _editDefaultAmount();
              },
            ),
            _SheetAction(
              icon: Icons.schedule_rounded,
              title: '提醒间隔',
              onTap: () {
                Navigator.pop(context);
                _editInterval();
              },
            ),
            _SheetAction(
              icon: Icons.access_time_rounded,
              title: '提醒时段',
              onTap: () {
                Navigator.pop(context);
                _editWindow();
              },
            ),
            _SheetAction(
              icon: Icons.notifications_active_outlined,
              title: '立即测试通知',
              onTap: () {
                Navigator.pop(context);
                _sendImmediateTestNotification();
              },
            ),
            _SheetAction(
              icon: Icons.alarm_add_outlined,
              title: '1 分钟后测试提醒',
              onTap: () {
                Navigator.pop(context);
                _scheduleOneMinuteTestReminder();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendImmediateTestNotification() async {
    final ok = await ref
        .read(reminderNotificationServiceProvider)
        .showTestNotification();
    _showNotificationSnack(ok ? '测试通知已发送。' : '测试通知发送失败，请检查通知权限。');
  }

  Future<void> _scheduleOneMinuteTestReminder() async {
    final ok = await ref
        .read(reminderNotificationServiceProvider)
        .scheduleTestReminder();
    _showNotificationSnack(ok ? '已安排 1 分钟后测试提醒。' : '测试提醒安排失败，请检查权限。');
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
