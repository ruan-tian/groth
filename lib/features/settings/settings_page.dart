import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../shared/providers/dashboard_provider.dart'
    hide settingRepositoryProvider;
import '../../shared/providers/repository_providers.dart';
import '../../shared/providers/pet_diary_provider.dart';
import '../../shared/providers/settings_provider.dart';
import 'widgets/settings_page_sections.dart';

part 'widgets/settings_page_sheets.dart';

// =============================================================================
// AI 连接状态 Provider
// =============================================================================

final aiConnectionStatusProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(aiConfigRepositoryProvider);
  final config = await repo.getEnabledAiConfig();
  return config != null;
});

// =============================================================================
// 最后备份时间 Provider
// =============================================================================

final lastBackupTimeProvider = FutureProvider<DateTime?>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('last_backup_time');
  if (value != null) {
    final timestamp = int.tryParse(value);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
  }
  return null;
});

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

    return Scaffold(
      backgroundColor: AppColors.softGold,
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
                  color: const Color(0xFFB0A09A).withValues(alpha: 0.6),
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
    if (level < 5) return '成长新手';
    if (level < 10) return '习惯探索者';
    if (level < 20) return '成长实践家';
    if (level < 30) return '成长探索家';
    if (level < 50) return '长期主义者';
    return '成长大师';
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
  void _showAiAnalysisToggle(BuildContext context, WidgetRef ref) {
    final current = ref.read(autoAiAnalysisProvider);
    if (current) {
      // 关闭
      ref.read(autoAiAnalysisProvider.notifier).state = false;
      ref
          .read(settingRepositoryProvider)
          .setSetting('auto_ai_analysis', 'false');
      // 同时关闭日记上传
      ref.read(journalUploadProvider.notifier).state = false;
      ref.read(settingRepositoryProvider).setSetting('journal_upload', 'false');
    } else {
      // 开启 - 显示隐私提醒
      _showPrivacyDialog(
        context,
        title: '🤖 开启 AI 自动分析',
        content:
            '开启后，每次打开 app 会自动分析你的学习、健身、饮食、睡眠数据。\n\n'
            '⚠️ 数据将会发送到你配置的 AI 服务商服务器（如 DeepSeek、OpenAI 等）。\n\n'
            '📝 日记内容默认不会被上传。如需上传日记，请在开启后单独设置。',
        onConfirm: () {
          ref.read(autoAiAnalysisProvider.notifier).state = true;
          ref
              .read(settingRepositoryProvider)
              .setSetting('auto_ai_analysis', 'true');
        },
      );
    }
  }

  /// 日记上传开关
  void _showJournalUploadToggle(BuildContext context, WidgetRef ref) {
    final current = ref.read(journalUploadProvider);
    if (current) {
      // 关闭
      ref.read(journalUploadProvider.notifier).state = false;
      ref.read(settingRepositoryProvider).setSetting('journal_upload', 'false');
    } else {
      // 开启 - 显示隐私提醒
      _showPrivacyDialog(
        context,
        title: '📔 开启日记上传分析',
        content:
            '开启后，AI 会分析你的日记内容，为你提供更个性化的成长建议。\n\n'
            '⚠️ 日记内容将会发送到你配置的 AI 服务商服务器。请确保你信任该服务商。\n\n'
            '💡 建议：不要在日记中记录密码、银行卡等敏感信息。',
        onConfirm: () {
          ref.read(journalUploadProvider.notifier).state = true;
          ref
              .read(settingRepositoryProvider)
              .setSetting('journal_upload', 'true');
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
      content:
          '开启后，每天早上 6 点后首次打开 App 时，甜甜会检查今天是否已有小日记。\n\n'
          '只会发送昨天的本地统计摘要，例如学习时长、健身时长、睡眠/饮食摘要、经验变化、任务完成情况、天气和日期。\n\n'
          '不会发送你的完整日记正文，也不会把小猫日记计入成长经验。',
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
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Color(0xFF8B6F5E))),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4A574),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('确认开启'),
          ),
        ],
      ),
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
          decoration: const BoxDecoration(
            color: Colors.white,
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
                  color: const Color(0xFFB0A09A).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '主题模式',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5C3D2E),
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
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(themeModeProvider.notifier).state = mode;
        ref.read(settingRepositoryProvider).setSetting('theme_mode', mode.name);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1DF) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4A574)
                : const Color(0xFFE8C9A0).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFD4A574)
                  : const Color(0xFF8B6F5E),
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
                          ? const Color(0xFF5C3D2E)
                          : const Color(0xFF8B6F5E),
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB0A09A),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFD4A574),
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
              ? const Color(0xFF5D68F2)
              : g.name == '健身'
              ? const Color(0xFF35C976)
              : const Color(0xFFFF8A3D),
          value: g.target,
          unit: g.unit,
        ),
      _GoalItem(
        category: '短期目标',
        key: 'weekly_fitness_goal',
        label: '每周健身次数',
        icon: Icons.event_repeat_rounded,
        color: const Color(0xFF35C976),
        value: weeklyFitnessGoal,
        unit: '次/周',
      ),
      _GoalItem(
        category: '短期目标',
        key: 'daily_calorie_goal',
        label: '每日摄入热量',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF6B6B),
        value: ref.read(dailyCalorieGoalProvider),
        unit: 'kcal',
      ),
      _GoalItem(
        category: '短期目标',
        key: 'daily_water_goal',
        label: '每日饮水量',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF4FC3F7),
        value: ref.read(dailyWaterGoalProvider),
        unit: 'ml',
      ),
      _GoalItem(
        category: '短期目标',
        key: 'daily_sleep_goal',
        label: '每日睡眠时长',
        icon: Icons.bedtime_rounded,
        color: const Color(0xFF7E57C2),
        value: ref.read(sleepGoalProvider),
        unit: '小时',
      ),
      // ── 长期目标（占位） ──
      _GoalItem(
        category: '长期目标',
        key: 'target_weight',
        label: '目标体重',
        icon: Icons.monitor_weight_outlined,
        color: const Color(0xFFE8A87C),
        value: 65,
        unit: 'kg',
      ),
      _GoalItem(
        category: '长期目标',
        key: 'total_study_hours',
        label: '累计学习目标',
        icon: Icons.school_rounded,
        color: const Color(0xFF5D68F2),
        value: 1000,
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
    final repo = ref.read(settingRepositoryProvider);

    // Rebuild daily goals list (学习 / 健身 / 写日记)
    final newDailyGoals = <DailyGoal>[];
    for (final g in updatedGoals) {
      switch (g.key) {
        case 'daily_study_goal':
          newDailyGoals.add(DailyGoal(name: '学习', target: g.value, unit: '分钟'));
          break;
        case 'daily_fitness_goal':
          newDailyGoals.add(DailyGoal(name: '健身', target: g.value, unit: '分钟'));
          break;
        case 'daily_journal_goal':
          newDailyGoals.add(DailyGoal(name: '写日记', target: g.value, unit: '篇'));
          break;
      }
    }

    if (newDailyGoals.isNotEmpty) {
      ref.read(dailyGoalsProvider.notifier).state = newDailyGoals;
      await repo.setSetting(
        'daily_goals',
        jsonEncode(newDailyGoals.map((g) => g.toJson()).toList()),
      );
    }

    // Weekly fitness goal
    final weeklyItem = updatedGoals
        .where((g) => g.key == 'weekly_fitness_goal')
        .firstOrNull;
    if (weeklyItem != null) {
      ref.read(weeklyFitnessGoalProvider.notifier).state = weeklyItem.value;
      await repo.setSetting('weekly_fitness_goal', weeklyItem.value.toString());
    }

    // Persist remaining goals individually
    final otherKeys = {
      'target_weight',
      'total_study_hours',
    };
    for (final g in updatedGoals) {
      if (otherKeys.contains(g.key)) {
        await repo.setSetting(g.key, g.value.toString());
      }
      // 更新全局 Provider
      if (g.key == 'daily_sleep_goal') {
        ref.read(sleepGoalProvider.notifier).state = g.value;
        await repo.setSetting('sleep_goal_hours', g.value.toString());
      }
      if (g.key == 'daily_calorie_goal') {
        ref.read(dailyCalorieGoalProvider.notifier).state = g.value;
        await repo.setSetting('daily_calorie_goal', g.value.toString());
      }
      if (g.key == 'daily_water_goal') {
        ref.read(dailyWaterGoalProvider.notifier).state = g.value;
        await repo.setSetting('daily_water_goal', g.value.toString());
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🐱', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            const Text(
              'Growth OS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C3D2E),
              ),
            ),
          ],
        ),
        content: const Text(
          'Growth OS 是一款陪伴你持续成长的操作系统。\n\n通过数据记录、智能分析与温暖陪伴，帮你把每一天都活成进步的版本。',
          style: TextStyle(fontSize: 14, color: Color(0xFF8B6F5E), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定', style: TextStyle(color: Color(0xFFD4A574))),
          ),
        ],
      ),
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
