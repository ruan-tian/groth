import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/widgets/common/error_retry_widget.dart';
import '../../../features/fitness/utils/fitness_timer_assets.dart';

class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({
    required this.nickname,
    required this.avatarPath,
    required this.dashboard,
    required this.levelNameFor,
    required this.nextLevelExpFor,
    required this.onProfileTap,
    required this.onLevelTap,
    super.key,
  });

  final String nickname;
  final String? avatarPath;
  final AsyncValue<DashboardData> dashboard;
  final String Function(int level) levelNameFor;
  final int Function(int currentLevel) nextLevelExpFor;
  final VoidCallback onProfileTap;
  final ValueChanged<DashboardData> onLevelTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.paper, colors.surfaceTint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.border.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Semantics(
            button: true,
            label: '查看个人资料',
            child: GestureDetector(
              onTap: onProfileTap,
              child: Row(
                children: [
                  _SettingsAvatar(avatarPath: avatarPath),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        dashboard.when(
                          data: (data) => Semantics(
                            button: true,
                            label: '查看等级详情',
                            child: GestureDetector(
                              onTap: () => onLevelTap(data),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lv.${data.currentLevel} · ${levelNameFor(data.currentLevel)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: colors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 14,
                                      color: colors.primary.withValues(
                                        alpha: 0.76,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const ErrorRetryWidget(),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          dashboard.when(
            data: (data) {
              final nextLevelExp = nextLevelExpFor(data.currentLevel);
              final progress = data.expProgress / nextLevelExp;
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EXP ${data.totalExp}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textTertiary,
                        ),
                      ),
                      Text(
                        '$nextLevelExp EXP',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: colors.primary.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.primary,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const ErrorRetryWidget(),
          ),
        ],
      ),
    );
  }
}

class SettingsQuickActions extends StatelessWidget {
  const SettingsQuickActions({
    required this.aiStatus,
    required this.lastBackup,
    required this.onAiConfigTap,
    required this.onBackupTap,
    required this.onAiAnalysisTap,
    super.key,
  });

  final AsyncValue<bool> aiStatus;
  final AsyncValue<DateTime?> lastBackup;
  final VoidCallback onAiConfigTap;
  final VoidCallback onBackupTap;
  final VoidCallback onAiAnalysisTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle('快捷操作'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.smart_toy_outlined,
                label: 'AI 配置',
                status: aiStatus.when(
                  data: (connected) => connected ? '已连接' : '未连接',
                  loading: () => '检查中',
                  error: (_, _) => '未连接',
                ),
                color: colors.primary,
                onTap: onAiConfigTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.backup_outlined,
                label: '数据备份',
                status: lastBackup.when(
                  data: (time) => time != null ? '已备份' : '未备份',
                  loading: () => '检查中',
                  error: (_, _) => '未备份',
                ),
                color: colors.success,
                onTap: onBackupTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.analytics_outlined,
                label: 'AI 分析',
                status: '报告',
                color: colors.fitness,
                onTap: onAiAnalysisTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    required this.themeModeLabel,
    required this.autoAiAnalysisEnabled,
    required this.journalUploadEnabled,
    required this.petDiaryAutoEnabled,
    required this.onThemeTap,
    required this.onGoalsTap,
    required this.onProfileTap,
    required this.onAiAnalysisTap,
    required this.onJournalUploadTap,
    required this.onPetDiaryAutoTap,
    required this.onRestoreTap,
    required this.onWeatherTap,
    super.key,
  });

  final String themeModeLabel;
  final bool autoAiAnalysisEnabled;
  final bool journalUploadEnabled;
  final bool petDiaryAutoEnabled;
  final VoidCallback onThemeTap;
  final VoidCallback onGoalsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onAiAnalysisTap;
  final VoidCallback? onJournalUploadTap;
  final VoidCallback onPetDiaryAutoTap;
  final VoidCallback onRestoreTap;
  final VoidCallback onWeatherTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          SettingsTile(
            icon: Icons.brightness_6_outlined,
            iconColor: colors.primary,
            title: '主题模式',
            subtitle: themeModeLabel,
            onTap: onThemeTap,
          ),
          const _SettingsDivider(),
          SettingsTile(
            icon: Icons.flag_outlined,
            iconColor: colors.fitness,
            title: '今日目标',
            subtitle: '学习/健身/饮食/睡眠',
            onTap: onGoalsTap,
          ),
          const _SettingsDivider(),
          SettingsTile(
            icon: Icons.person_outline_rounded,
            iconColor: colors.textSecondary,
            title: '个人资料',
            subtitle: '昵称、头像、身高',
            onTap: onProfileTap,
          ),
          const _SettingsDivider(),
          SettingsTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: colors.primary,
            title: 'AI 自动分析',
            subtitle: autoAiAnalysisEnabled ? '已开启' : '已关闭',
            onTap: onAiAnalysisTap,
          ),
          const _SettingsDivider(),
          SettingsTile(
            icon: Icons.book_rounded,
            iconColor: colors.journal,
            title: '日记上传分析',
            subtitle: autoAiAnalysisEnabled
                ? (journalUploadEnabled ? '已开启' : '已关闭')
                : '需先开启 AI 分析',
            onTap: onJournalUploadTap,
          ),
          const _SettingsDivider(),
          SettingsTile(
            icon: Icons.menu_book_rounded,
            iconColor: colors.journal,
            title: '甜甜自动写日记',
            subtitle: petDiaryAutoEnabled ? '已开启，仅发送摘要' : '已关闭',
            onTap: onPetDiaryAutoTap,
          ),
          const _SettingsDivider(),
          SettingsTile(
            icon: Icons.restore_outlined,
            iconColor: colors.success,
            title: '数据恢复',
            subtitle: '从本地文件恢复数据',
            onTap: onRestoreTap,
          ),
          const _SettingsDivider(),
          SettingsTile(
            icon: Icons.wb_sunny_outlined,
            iconColor: colors.warning,
            title: '天气设置',
            subtitle: '查看天气、刷新数据',
            onTap: onWeatherTap,
          ),
        ],
      ),
    );
  }
}

class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: SettingsTile(
        icon: Icons.info_outline_rounded,
        iconColor: colors.textSecondary,
        title: '关于 Growth OS',
        subtitle: '版本 0.1.0',
        onTap: onTap,
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsAvatar extends StatelessWidget {
  const _SettingsAvatar({required this.avatarPath});

  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final path = normalizeUserAvatarPath(avatarPath);

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: path != null && File(path).existsSync()
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    FitnessTimerAssets.catAvatarDefault,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                FitnessTimerAssets.catAvatarDefault,
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.status,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String status;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Semantics(
      button: true,
      label: '$label，$status',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Divider(height: 1, indent: 64, color: colors.divider);
  }
}
