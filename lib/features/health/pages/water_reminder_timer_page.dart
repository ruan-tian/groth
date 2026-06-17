import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../plan/models/reminder_timer_state.dart';
import '../../plan/providers/reminder_timer_provider.dart';
import '../../plan/services/reminder_notification_service.dart';
import '../../plan/widgets/notification_permission_dialog.dart';
import '../models/water_plan_state.dart';
import '../providers/water_plan_provider.dart';
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
  static const _notificationId = 5202;
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
    if (plan.reminderEnabled) {
      final scheduled = await _scheduleNextReminder(plan);
      if (!scheduled) {
        await planController.setReminderEnabled(false);
      }
    }
  }

  Future<void> _toggleReminder(bool enabled) async {
    await ref.read(waterPlanProvider.notifier).setReminderEnabled(enabled);
    final plan = ref.read(waterPlanProvider);
    if (enabled) {
      final scheduled = await _scheduleNextReminder(plan);
      if (!scheduled) {
        await ref.read(waterPlanProvider.notifier).setReminderEnabled(false);
        ref
            .read(reminderTimerProvider(ReminderKind.water).notifier)
            .reset(duration: Duration(minutes: plan.intervalMinutes));
      }
    } else {
      await ref
          .read(reminderNotificationServiceProvider)
          .cancel(_notificationId);
      ref
          .read(reminderTimerProvider(ReminderKind.water).notifier)
          .reset(duration: Duration(minutes: plan.intervalMinutes));
    }
  }

  Future<bool> _scheduleNextReminder(WaterPlanState plan) async {
    final duration = Duration(minutes: plan.intervalMinutes);
    final service = ref.read(reminderNotificationServiceProvider);
    final permissionsGranted = await service.requestPermissions();
    if (!permissionsGranted) {
      if (!mounted) return false;
      final opened = await showNotificationPermissionGuide(context);
      if (opened) {
        final retry = await service.requestPermissions();
        if (!retry) {
          if (!mounted) return false;
          _showNotificationSnack('通知权限仍未开启，无法发送提醒。');
          return false;
        }
      } else {
        if (!mounted) return false;
        _showNotificationSnack('需要通知权限才能发送喝水提醒。');
        return false;
      }
    }

    final scheduled = await service.scheduleReminder(
      id: _notificationId,
      scheduledAt: DateTime.now().add(duration),
      title: '该喝水啦',
      body: '喝 ${plan.defaultAmountMl} ml，保持清爽状态。',
      payload: 'water_reminder',
    );
    if (!scheduled) {
      _showNotificationSnack('喝水提醒创建失败，请检查系统通知设置。');
      return false;
    }

    ref
        .read(reminderTimerProvider(ReminderKind.water).notifier)
        .start(duration);
    return true;
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
          ],
        ),
      ),
    );
  }
}
