import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../core/services/exp_service.dart';
import '../dashboard/providers/dashboard_provider.dart';
import '../pet/providers/pet_diary_provider.dart';
import '../../shared/providers/settings_facade.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/widgets/common/growth_confirm_dialog.dart';
import 'widgets/settings_page_sections.dart';

part 'widgets/settings_page_sheets.dart';

// =============================================================================
// AI 连接状态 Provider
// =============================================================================

// =============================================================================
// 最后备份时间 Provider
// =============================================================================

// =============================================================================
// SettingsPage（褐色渐变风格）
// =============================================================================

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final dashboard = ref.watch(dashboardProvider);
    final aiStatus = ref.watch(aiConnectionStatusProvider);
    final lastBackup = ref.watch(lastBackupTimeProvider);
    final nickname = ref.watch(userNicknameProvider);
    final avatarPath = ref.watch(userAvatarPathProvider);
    final autoAiAnalysisEnabled = ref.watch(autoAiAnalysisProvider);
    final journalUploadEnabled = ref.watch(journalUploadProvider);
    final petDiaryAutoEnabled = ref.watch(petDiaryAutoEnabledProvider);

    // 初始化用户资料Provider
    ref.watch(userNicknameInitProvider);
    ref.watch(userAvatarInitProvider);
    ref.watch(userHeightInitProvider);

    // 初始化 AI 分析 & 日记上传 Provider
    ref.watch(autoAiAnalysisInitProvider);
    ref.watch(journalUploadInitProvider);
    ref.watch(petDiaryAutoEnabledInitProvider);

    // 初始化长期目标 Provider
    ref.watch(targetWeightInitProvider);
    ref.watch(totalStudyHoursInitProvider);

    return Scaffold(
      backgroundColor: context.growthColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 用户信息卡片（大卡片） ──
            SettingsProfileCard(
              nickname: nickname,
              avatarPath: avatarPath,
              dashboard: dashboard,
              levelNameFor: _getLevelName,
              nextLevelExpFor: _calcNextLevelExp,
              onProfileTap: () => context.push('/settings/profile'),
              onLevelTap: (data) => _showLevelDetailSheet(context, data),
            ),
            const SizedBox(height: 24),

            // ── 快捷操作 ──
            SettingsQuickActions(
              aiStatus: aiStatus,
              lastBackup: lastBackup,
              onAiConfigTap: () => context.push('/settings/ai-config'),
              onBackupTap: () => context.push('/settings/backup'),
              onAiAnalysisTap: () => context.push('/settings/ai-analysis'),
            ),
            const SizedBox(height: 24),

            // ── 偏好设置 ──
            const SettingsSectionTitle('偏好设置'),
            const SizedBox(height: 12),
            SettingsGroup(
              themeModeLabel: _themeModeLabel(themeMode),
              autoAiAnalysisEnabled: autoAiAnalysisEnabled,
              journalUploadEnabled: journalUploadEnabled,
              petDiaryAutoEnabled: petDiaryAutoEnabled,
              onThemeTap: () => _showThemeModePicker(context, ref, themeMode),
              onGoalsTap: () => _showDailyGoalsEditor(context, ref),
              onProfileTap: () => context.push('/settings/profile'),
              onAiAnalysisTap: () => _showAiAnalysisToggle(context, ref),
              onJournalUploadTap: autoAiAnalysisEnabled
                  ? () => _showJournalUploadToggle(context, ref)
                  : null,
              onPetDiaryAutoTap: () => _showPetDiaryAutoToggle(context, ref),
              onRestoreTap: () => context.push('/settings/restore'),
              onWeatherTap: () => context.push('/settings/weather'),
            ),
            const SizedBox(height: 24),

            // ── 关于 ──
            const SettingsSectionTitle('关于'),
            const SizedBox(height: 12),
            SettingsAboutSection(onTap: () => _showAboutDialog(context)),
            const SizedBox(height: 40),

            // ── 版本信息 ──
            Center(
              child: Text(
                'Growth OS v0.1.0',
                style: TextStyle(
                  fontSize: 12,
                  color: context.growthColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 辅助方法
  // ---------------------------------------------------------------------------

  String _getLevelName(int level) {
    if (level < 5) return '萌新';
    if (level < 10) return '探索者';
    if (level < 15) return '实践者';
    if (level < 20) return '进阶者';
    if (level < 30) return '精英';
    if (level < 50) return '大师';
    if (level < 80) return '传奇';
    if (level < 100) return '神话';
    return '永恒';
  }

  int _calcNextLevelExp(int currentLevel) {
    return currentLevel * currentLevel * 100;
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '亮色模式';
      case ThemeMode.dark:
        return '暗色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  // ---------------------------------------------------------------------------
  // AI 分析 & 日记上传开关
  // ---------------------------------------------------------------------------

  /// AI 自动分析开关
  Future<void> _showAiAnalysisToggle(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final current = ref.read(autoAiAnalysisProvider);
    if (current) {
      // 关闭
      await ref.read(settingsFacadeProvider).setAutoAiAnalysisEnabled(false);
      // 同时关闭日记上传
    } else {
      // 开启 - 显示隐私提醒
      _showPrivacyDialog(
        context,
        title: '开启 AI 自动分析',
        content: '开启后，每次打开 app 会自动分析你的学习、健身、饮食、睡眠数据。',
        privacyNotice:
            '数据将会发送到你配置的 AI 服务商服务器（如 DeepSeek、OpenAI 等）。\n\n日记内容默认不会被上传。如需上传日记，请在开启后单独设置。',
        image: 'assets/images/dialogs/ai_privacy.webp',
        onConfirm: () async {
          await ref.read(settingsFacadeProvider).setAutoAiAnalysisEnabled(true);
        },
      );
    }
  }

  /// 日记上传开关
  Future<void> _showJournalUploadToggle(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final current = ref.read(journalUploadProvider);
    if (current) {
      // 关闭
      await ref.read(settingsFacadeProvider).setJournalUploadEnabled(false);
    } else {
      // 开启 - 显示隐私提醒
      _showPrivacyDialog(
        context,
        title: '开启日记上传分析',
        content: '开启后，AI 会分析你的日记内容，为你提供更个性化的成长建议。',
        privacyNotice:
            '日记内容将会发送到你配置的 AI 服务商服务器。请确保你信任该服务商。\n\n建议：不要在日记中记录密码、银行卡等敏感信息。',
        image: 'assets/images/dialogs/journal_writing.webp',
        onConfirm: () async {
          await ref.read(settingsFacadeProvider).setJournalUploadEnabled(true);
        },
      );
    }
  }

  /// 甜甜自动写日记开关。
  void _showPetDiaryAutoToggle(BuildContext context, WidgetRef ref) {
    final current = ref.read(petDiaryAutoEnabledProvider);
    if (current) {
      savePetDiaryAutoEnabled(ref, false);
      return;
    }

    _showPrivacyDialog(
      context,
      title: '开启甜甜自动写日记',
      content: '开启后，每天早上 6 点后首次打开 App 时，甜甜会检查今天是否已有小日记。',
      privacyNotice:
          '只会发送昨天的本地统计摘要，例如学习时长、健身时长、睡眠/饮食摘要、经验变化、任务完成情况、天气和日期。\n\n不会发送你的完整日记正文，也不会把小猫日记计入成长经验。',
      image: 'assets/images/dialogs/common_happy.webp',
      onConfirm: () async {
        final service = ref.read(petDiaryServiceProvider);
        await service.markPrivacyConfirmed();
        await savePetDiaryAutoEnabled(ref, true);
      },
    );
  }

  /// 隐私提醒弹窗
  void _showPrivacyDialog(
    BuildContext context, {
    required String title,
    required String content,
    required GrowthConfirmCallback onConfirm,
    String? image,
    String? privacyNotice,
  }) {
    GrowthConfirmDialog.show(
      context: context,
      image: image ?? 'assets/images/dialogs/ai_privacy.webp',
      title: title,
      message: content,
      privacyNotice: privacyNotice ?? '数据将会发送到你配置的 AI 服务商服务器，请确保你信任该服务商。',
      primaryText: '确认开启',
      secondaryText: '取消',
      onPrimary: onConfirm,
      mode: GrowthConfirmMode.normal,
    );
  }

  // ---------------------------------------------------------------------------
  // 弹窗
  // ---------------------------------------------------------------------------

  void _showThemeModePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: context.growthColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽条
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.growthColors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '主题模式',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.growthColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildThemeOption(
                ctx,
                ref,
                icon: Icons.light_mode_rounded,
                label: '亮色模式',
                description: '使用明亮清新的界面',
                mode: ThemeMode.light,
                isSelected: current == ThemeMode.light,
              ),
              const SizedBox(height: 12),
              _buildThemeOption(
                ctx,
                ref,
                icon: Icons.dark_mode_rounded,
                label: '暗色模式',
                description: '使用低亮度护眼界面',
                mode: ThemeMode.dark,
                isSelected: current == ThemeMode.dark,
              ),
              const SizedBox(height: 12),
              _buildThemeOption(
                ctx,
                ref,
                icon: Icons.settings_brightness_rounded,
                label: '跟随系统',
                description: '与系统外观保持一致',
                mode: ThemeMode.system,
                isSelected: current == ThemeMode.system,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required String description,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await ref.read(settingsFacadeProvider).setThemeMode(mode);
        if (context.mounted) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? context.growthColors.softBlue
              : context.growthColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? context.growthColors.primary
                : context.growthColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? context.growthColors.primary
                  : context.growthColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? context.growthColors.textPrimary
                          : context.growthColors.textSecondary,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.growthColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: context.growthColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showDailyGoalsEditor(BuildContext context, WidgetRef ref) {
    final dailyGoals = ref.read(dailyGoalsProvider);
    final weeklyFitnessGoal = ref.read(weeklyFitnessGoalProvider);

    // Build a mutable copy of all goals for editing
    final goals = <_GoalItem>[
      // ── 短期目标：每日/每周 ──
      for (final g in dailyGoals)
        _GoalItem(
          category: '短期目标',
          key: g.name == '学习'
              ? 'daily_study_goal'
              : g.name == '健身'
              ? 'daily_fitness_goal'
              : 'daily_journal_goal',
          label: g.name == '学习'
              ? '每日学习时长'
              : g.name == '健身'
              ? '每日健身时长'
              : '每日日记篇数',
          icon: g.name == '学习'
              ? Icons.menu_book_rounded
              : g.name == '健身'
              ? Icons.fitness_center_rounded
              : Icons.edit_note_rounded,
          color: g.name == '学习'
              ? context.growthColors.study
              : g.name == '健身'
              ? context.growthColors.fitness
              : context.growthColors.journal,
          value: g.target,
          unit: g.unit,
        ),
      _GoalItem(
        category: '短期目标',
        key: 'weekly_fitness_goal',
        label: '每周健身次数',
        icon: Icons.event_repeat_rounded,
        color: context.growthColors.fitness,
        value: weeklyFitnessGoal,
        unit: '次/周',
      ),
      _GoalItem(
        category: '短期目标',
        key: 'daily_calorie_goal',
        label: '每日摄入热量',
        icon: Icons.local_fire_department_rounded,
        color: context.growthColors.danger,
        value: ref.read(dailyCalorieGoalProvider),
        unit: 'kcal',
      ),
      _GoalItem(
        category: '短期目标',
        key: 'daily_water_goal',
        label: '每日饮水量',
        icon: Icons.water_drop_rounded,
        color: context.growthColors.softBlue,
        value: ref.read(dailyWaterGoalProvider),
        unit: 'ml',
      ),
      _GoalItem(
        category: '短期目标',
        key: 'sleep_goal_hours',
        label: '每日睡眠时长',
        icon: Icons.bedtime_rounded,
        color: context.growthColors.sleep,
        value: ref.read(sleepGoalProvider),
        unit: '小时',
      ),
      // ── 长期目标 ──
      _GoalItem(
        category: '长期目标',
        key: 'target_weight',
        label: '目标体重',
        icon: Icons.monitor_weight_outlined,
        color: context.growthColors.fitness,
        value: ref.read(targetWeightProvider).round(),
        unit: 'kg',
      ),
      _GoalItem(
        category: '长期目标',
        key: 'total_study_hours',
        label: '累计学习目标',
        icon: Icons.school_rounded,
        color: context.growthColors.study,
        value: ref.read(totalStudyHoursProvider),
        unit: '小时',
      ),
    ];

    showModalBottomSheet<List<_GoalItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _DailyGoalsSheet(goals: goals);
      },
    ).then((updatedGoals) {
      if (updatedGoals == null) return;
      _persistGoals(ref, updatedGoals);
    });
  }

  Future<void> _persistGoals(
    WidgetRef ref,
    List<_GoalItem> updatedGoals,
  ) async {
    int valueFor(String key, int fallback) {
      return updatedGoals
              .where((goal) => goal.key == key)
              .map((goal) => goal.value)
              .firstOrNull ??
          fallback;
    }

    final newDailyGoals = <DailyGoal>[];
    for (final goal in updatedGoals) {
      switch (goal.key) {
        case 'daily_study_goal':
          newDailyGoals.add(
            DailyGoal(
              name: '\u5b66\u4e60',
              target: goal.value,
              unit: '\u5206\u949f',
            ),
          );
          break;
        case 'daily_fitness_goal':
          newDailyGoals.add(
            DailyGoal(
              name: '\u5065\u8eab',
              target: goal.value,
              unit: '\u5206\u949f',
            ),
          );
          break;
        case 'daily_journal_goal':
          newDailyGoals.add(
            DailyGoal(
              name: '\u5199\u65e5\u8bb0',
              target: goal.value,
              unit: '\u7bc7',
            ),
          );
          break;
      }
    }

    await ref
        .read(settingsFacadeProvider)
        .saveGoals(
          SettingsGoalSnapshot(
            dailyGoals: newDailyGoals.isEmpty
                ? ref.read(dailyGoalsProvider)
                : newDailyGoals,
            weeklyFitnessGoal: valueFor(
              'weekly_fitness_goal',
              ref.read(weeklyFitnessGoalProvider),
            ),
            sleepGoalHours: valueFor(
              'sleep_goal_hours',
              ref.read(sleepGoalProvider),
            ),
            dailyCalorieGoal: valueFor(
              'daily_calorie_goal',
              ref.read(dailyCalorieGoalProvider),
            ),
            dailyWaterGoal: valueFor(
              'daily_water_goal',
              ref.read(dailyWaterGoalProvider),
            ),
            targetWeightKg: valueFor(
              'target_weight',
              ref.read(targetWeightProvider).round(),
            ).toDouble(),
            totalStudyHours: valueFor(
              'total_study_hours',
              ref.read(totalStudyHoursProvider),
            ),
          ),
        );
  }

  void _showAboutDialog(BuildContext context) {
    GrowthConfirmDialog.show(
      context: context,
      image: 'assets/images/app_icon.webp',
      title: 'Growth OS',
      subtitle: '版本 0.1.0',
      message: 'Growth OS 是一款陪伴你持续成长的操作系统。\n\n通过数据记录、智能分析与温暖陪伴，帮你把每一天都活成进步的版本。',
      primaryText: '确定',
      onPrimary: () {},
      mode: GrowthConfirmMode.info,
    );
  }

  // ---------------------------------------------------------------------------
  // 等级详情弹窗
  // ---------------------------------------------------------------------------

  void _showLevelDetailSheet(BuildContext context, DashboardData data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LevelDetailSheet(
        currentLevel: data.currentLevel,
        totalExp: data.totalExp,
        expProgress: data.expProgress,
      ),
    );
  }
}
