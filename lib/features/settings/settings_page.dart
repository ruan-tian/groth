import 'dart:convert';
import 'dart:io';

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
            _buildProfileCard(context, ref, dashboard),
            const SizedBox(height: 24),

            // ── 快捷操作 ──
            _buildQuickActions(context, aiStatus, lastBackup),
            const SizedBox(height: 24),

            // ── 偏好设置 ──
            _buildSectionTitle('偏好设置'),
            const SizedBox(height: 12),
            _buildSettingsGroup(context, ref, themeMode),
            const SizedBox(height: 24),

            // ── 关于 ──
            _buildSectionTitle('关于'),
            const SizedBox(height: 12),
            _buildAboutSection(context),
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
  // 用户信息卡片（大卡片）
  // ---------------------------------------------------------------------------

  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<DashboardData> dashboard,
  ) {
    final nickname = ref.watch(userNicknameProvider);
    final avatarPath = ref.watch(userAvatarPathProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C3D2E), Color(0xFF8B6F5E), Color(0xFFD4A574)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C3D2E).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头像 + 用户信息
          GestureDetector(
            onTap: () => context.push('/settings/profile'),
            child: Row(
              children: [
                // 头像
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: avatarPath != null && File(avatarPath).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(avatarPath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Text('🐱', style: TextStyle(fontSize: 40)),
                            ),
                          ),
                        )
                      : const Center(
                          child: Text('🐱', style: TextStyle(fontSize: 40)),
                        ),
                ),
                const SizedBox(width: 16),

                // 用户名 + 等级
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 等级标签（点击跳转到等级梯队页面）
                      dashboard.when(
                        data: (data) => GestureDetector(
                          onTap: () => _showLevelDetailSheet(context, data),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lv.${data.currentLevel} · ${_getLevelName(data.currentLevel)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                // 箭头
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 经验条
          dashboard.when(
            data: (data) {
              final progress =
                  data.expProgress / (_calcNextLevelExp(data.currentLevel));
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EXP ${data.totalExp}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${_calcNextLevelExp(data.currentLevel)} EXP',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
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
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 快捷操作
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions(
    BuildContext context,
    AsyncValue<bool> aiStatus,
    AsyncValue<DateTime?> lastBackup,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('快捷操作'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.smart_toy_outlined,
                label: 'AI 配置',
                status: aiStatus.when(
                  data: (connected) => connected ? '已连接' : '未连接',
                  loading: () => '检查中',
                  error: (_, _) => '未连接',
                ),
                color: const Color(0xFF5D68F2),
                onTap: () => context.push('/settings/ai-config'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.backup_outlined,
                label: '数据备份',
                status: lastBackup.when(
                  data: (time) => time != null ? '已备份' : '未备份',
                  loading: () => '检查中',
                  error: (_, _) => '未备份',
                ),
                color: const Color(0xFF35C976),
                onTap: () => context.push('/settings/backup'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.analytics_outlined,
                label: 'AI 分析',
                status: '报告',
                color: const Color(0xFFFF8A3D),
                onTap: () => context.push('/settings/ai-analysis'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required String status,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
          ),
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C3D2E),
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
    );
  }

  // ---------------------------------------------------------------------------
  // 偏好设置
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF5C3D2E),
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.brightness_6_outlined,
            iconColor: const Color(0xFF5D68F2),
            title: '主题模式',
            subtitle: _themeModeLabel(themeMode),
            onTap: () => _showThemeModePicker(context, ref, themeMode),
          ),
          _buildDivider(),
          _buildSettingTile(
            icon: Icons.flag_outlined,
            iconColor: const Color(0xFFFF8A3D),
            title: '今日目标',
            subtitle: '学习/健身/饮食/睡眠',
            onTap: () => _showDailyGoalsEditor(context, ref),
          ),
          _buildDivider(),
          _buildSettingTile(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF8B6F5E),
            title: '个人资料',
            subtitle: '昵称、头像、身高',
            onTap: () => context.push('/settings/profile'),
          ),
          _buildDivider(),
          _buildSettingTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: const Color(0xFF5D68F2),
            title: 'AI 自动分析',
            subtitle: ref.watch(autoAiAnalysisProvider) ? '已开启' : '已关闭',
            onTap: () => _showAiAnalysisToggle(context, ref),
          ),
          _buildDivider(),
          _buildSettingTile(
            icon: Icons.book_rounded,
            iconColor: const Color(0xFFE8A0BF),
            title: '日记上传分析',
            subtitle: ref.watch(autoAiAnalysisProvider)
                ? (ref.watch(journalUploadProvider) ? '已开启' : '已关闭')
                : '需先开启 AI 分析',
            onTap: ref.watch(autoAiAnalysisProvider)
                ? () => _showJournalUploadToggle(context, ref)
                : null,
          ),
          _buildDivider(),
          _buildSettingTile(
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFFE889B5),
            title: '甜甜自动写日记',
            subtitle: ref.watch(petDiaryAutoEnabledProvider)
                ? '已开启，仅发送摘要'
                : '已关闭',
            onTap: () => _showPetDiaryAutoToggle(context, ref),
          ),
          _buildDivider(),
          _buildSettingTile(
            icon: Icons.restore_outlined,
            iconColor: const Color(0xFF35C976),
            title: '数据恢复',
            subtitle: '从本地文件恢复数据',
            onTap: () => context.push('/settings/restore'),
          ),
          _buildDivider(),
          _buildSettingTile(
            icon: Icons.wb_sunny_outlined,
            iconColor: const Color(0xFFFFB13D),
            title: '天气设置',
            subtitle: '查看天气、刷新数据',
            onTap: () => context.push('/settings/weather'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5C3D2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB0A09A),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: const Color(0xFFB0A09A).withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 64,
      color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
    );
  }

  // ---------------------------------------------------------------------------
  // 关于
  // ---------------------------------------------------------------------------

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      child: _buildSettingTile(
        icon: Icons.info_outline_rounded,
        iconColor: const Color(0xFF8B6F5E),
        title: '关于 Growth OS',
        subtitle: '版本 0.1.0',
        onTap: () => _showAboutDialog(context),
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
        value: 2000,
        unit: 'kcal',
      ),
      _GoalItem(
        category: '短期目标',
        key: 'daily_water_goal',
        label: '每日饮水量',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF4FC3F7),
        value: 2000,
        unit: 'ml',
      ),
      _GoalItem(
        category: '短期目标',
        key: 'daily_sleep_goal',
        label: '每日睡眠时长',
        icon: Icons.bedtime_rounded,
        color: const Color(0xFF7E57C2),
        value: 8,
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
      'daily_calorie_goal',
      'daily_water_goal',
      'daily_sleep_goal',
      'target_weight',
      'total_study_hours',
    };
    for (final g in updatedGoals) {
      if (otherKeys.contains(g.key)) {
        await repo.setSetting(g.key, g.value.toString());
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

// =============================================================================
// _GoalItem — 每条目标的数据模型
// =============================================================================

class _GoalItem {
  _GoalItem({
    required this.category,
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
  });

  final String category;
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  int value;
  final String unit;

  _GoalItem copy() => _GoalItem(
    category: category,
    key: key,
    label: label,
    icon: icon,
    color: color,
    value: value,
    unit: unit,
  );
}

// =============================================================================
// _DailyGoalsSheet — 今日目标编辑 Bottom Sheet
// =============================================================================

class _DailyGoalsSheet extends StatefulWidget {
  const _DailyGoalsSheet({required this.goals});

  final List<_GoalItem> goals;

  @override
  State<_DailyGoalsSheet> createState() => _DailyGoalsSheetState();
}

class _DailyGoalsSheetState extends State<_DailyGoalsSheet> {
  late final List<_GoalItem> _goals;

  @override
  void initState() {
    super.initState();
    _goals = widget.goals.map((g) => g.copy()).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Group by category
    final categories = <String, List<_GoalItem>>{};
    for (final g in _goals) {
      categories.putIfAbsent(g.category, () => []).add(g);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── 拖拽条 + 标题 ──
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB0A09A).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '今日目标',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5C3D2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '点击目标项可修改数值',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFFB0A09A).withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),

              // ── 目标列表 ──
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categories.length,
                  itemBuilder: (ctx, index) {
                    final catName = categories.keys.elementAt(index);
                    final items = categories[catName]!;
                    return _buildCategory(catName, items);
                  },
                ),
              ),

              // ── 保存按钮 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _goals),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C3D2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '保存目标',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategory(String name, List<_GoalItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A574),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5C3D2E),
                ),
              ),
            ],
          ),
        ),
        ...items.map((g) => _buildGoalTile(g)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGoalTile(_GoalItem goal) {
    return GestureDetector(
      onTap: () => _showGoalEditDialog(goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.softGold,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE8C9A0).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: goal.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(goal.icon, color: goal.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5C3D2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${goal.value} ${goal.unit}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB0A09A),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: goal.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${goal.value}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: goal.color,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit_rounded,
              size: 16,
              color: const Color(0xFFB0A09A).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGoalEditDialog(_GoalItem goal) async {
    final controller = TextEditingController(text: goal.value.toString());
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: goal.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(goal.icon, color: goal.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C3D2E),
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '目标值',
                    suffixText: goal.unit,
                    suffixStyle: const TextStyle(
                      color: Color(0xFFB0A09A),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE8C9A0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: goal.color, width: 2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '请输入目标值';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return '请输入正整数';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '当前设定：${goal.value} ${goal.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB0A09A),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                '取消',
                style: TextStyle(color: Color(0xFFB0A09A)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, int.parse(controller.text));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: goal.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        goal.value = result;
      });
    }
  }
}

// =============================================================================
// _DailyGoalsSheet — 目标编辑弹窗
// =============================================================================
// 等级详情弹窗
// =============================================================================

class _LevelDetailSheet extends StatelessWidget {
  const _LevelDetailSheet({
    required this.currentLevel,
    required this.totalExp,
    required this.expProgress,
  });

  final int currentLevel;
  final int totalExp;
  final int expProgress;

  @override
  Widget build(BuildContext context) {
    final nextLevelExp = currentLevel * currentLevel * 100;
    final progress = nextLevelExp > 0
        ? (expProgress / nextLevelExp).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖拽条
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 20),

          // 当前等级信息
          _buildCurrentLevel(context, progress, nextLevelExp),
          const SizedBox(height: 24),

          // 等级梯队
          Expanded(child: _buildLevelTiers()),
        ],
      ),
    );
  }

  Widget _buildCurrentLevel(
    BuildContext context,
    double progress,
    int nextLevelExp,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 等级图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD4A574), Color(0xFFE8C9A0)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4A574).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Lv.$currentLevel',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 等级名称
          Text(
            _getLevelName(currentLevel),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C3D2E),
            ),
          ),
          const SizedBox(height: 8),

          // 经验值
          Text(
            'EXP $totalExp / $nextLevelExp',
            style: const TextStyle(fontSize: 14, color: Color(0xFF8B6F5E)),
          ),
          const SizedBox(height: 12),

          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFD4A574),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 距下一级
          Text(
            '距下一级还需 ${nextLevelExp - expProgress} EXP',
            style: const TextStyle(fontSize: 12, color: Color(0xFFB0A09A)),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTiers() {
    final tiers = [
      _LevelTier(
        level: 1,
        name: '萌新',
        minExp: 0,
        color: const Color(0xFF9E9E9E),
      ),
      _LevelTier(
        level: 5,
        name: '探索者',
        minExp: 1600,
        color: const Color(0xFF4CAF50),
      ),
      _LevelTier(
        level: 10,
        name: '实践者',
        minExp: 8100,
        color: const Color(0xFF2196F3),
      ),
      _LevelTier(
        level: 15,
        name: '进阶者',
        minExp: 20000,
        color: const Color(0xFF9C27B0),
      ),
      _LevelTier(
        level: 20,
        name: '精英',
        minExp: 38000,
        color: const Color(0xFFFF9800),
      ),
      _LevelTier(
        level: 30,
        name: '大师',
        minExp: 85000,
        color: const Color(0xFFE91E63),
      ),
      _LevelTier(
        level: 50,
        name: '传奇',
        minExp: 250000,
        color: const Color(0xFFFF5722),
      ),
      _LevelTier(
        level: 80,
        name: '神话',
        minExp: 640000,
        color: const Color(0xFF673AB7),
      ),
      _LevelTier(
        level: 100,
        name: '永恒',
        minExp: 1000000,
        color: const Color(0xFF1A237E),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: tiers.length,
      itemBuilder: (context, index) {
        final tier = tiers[index];
        final isUnlocked = currentLevel >= tier.level;
        final isCurrent =
            currentLevel >= tier.level &&
            (index == tiers.length - 1 ||
                currentLevel < tiers[index + 1].level);

        return _buildTierItem(tier, isUnlocked, isCurrent);
      },
    );
  }

  Widget _buildTierItem(_LevelTier tier, bool isUnlocked, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? tier.color.withValues(alpha: 0.1)
            : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(color: tier.color, width: 2)
            : Border.all(color: const Color(0xFFE8C9A0).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // 等级图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? tier.color.withValues(alpha: 0.15)
                  : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'Lv.${tier.level}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isUnlocked ? tier.color : const Color(0xFFB0A09A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // 等级信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked
                        ? const Color(0xFF5C3D2E)
                        : const Color(0xFFB0A09A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tier.minExp} EXP',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked
                        ? const Color(0xFF8B6F5E)
                        : const Color(0xFFC9CDD4),
                  ),
                ),
              ],
            ),
          ),

          // 状态
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tier.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '当前',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          else if (isUnlocked)
            Icon(Icons.check_circle_rounded, size: 20, color: tier.color)
          else
            Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: const Color(0xFFC9CDD4),
            ),
        ],
      ),
    );
  }

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
}

class _LevelTier {
  const _LevelTier({
    required this.level,
    required this.name,
    required this.minExp,
    required this.color,
  });

  final int level;
  final String name;
  final int minExp;
  final Color color;
}
