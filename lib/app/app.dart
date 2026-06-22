import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'design/design.dart';
import '../features/health/services/health_reminder_scheduler.dart';
import '../shared/providers/settings_provider.dart';
import 'launch_intro_overlay.dart';

/// Growth OS 应用根 Widget
/// - ProviderScope 由 main.dart 提供
/// - MaterialApp.router + GoRouter + Material 3 主题
class GrowthOSApp extends ConsumerWidget {
  const GrowthOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeInitProvider); // 从数据库加载已保存的主题
    ref.watch(healthReminderBootstrapProvider);
    ref.watch(dailyWaterGoalInitProvider); // 启动时加载饮水目标
    ref.watch(todayWaterIntakeInitProvider); // 启动时加载今日饮水量
    ref.watch(sleepGoalInitProvider); // 启动时加载睡眠目标
    ref.watch(dashboardCardIdsInitProvider); // 启动时加载首页卡片配置
    ref.watch(recordModeInitProvider); // 启动时加载记录模式
    ref.watch(dailyGoalsInitProvider); // 启动时加载每日目标
    ref.watch(dailyCalorieGoalInitProvider); // 启动时加载卡路里目标
    ref.watch(weeklyFitnessGoalInitProvider); // 启动时加载每周健身目标
    final themeMode = ref.watch(themeModeProvider);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: LaunchIntroOverlay(
        child: MaterialApp.router(
        title: 'Growth OS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: goRouter,
        ),
      ),
    );
  }
}