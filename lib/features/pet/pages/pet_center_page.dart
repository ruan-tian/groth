import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/pet_projection_provider.dart';
import '../../../shared/providers/pet_provider.dart';
import '../widgets/pet_scene_hero.dart';
import '../widgets/today_growth_card.dart';
import '../widgets/pet_journal_section.dart';

class PetCenterPage extends ConsumerWidget {
  const PetCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(petProfileProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final ageDays = ref.watch(petAgeDaysProvider);
    final title = ref.watch(petTitleProvider);
    final appearance = ref.watch(petAppearanceProvider);

    final name = profileAsync.valueOrNull?.name ?? '甜甜';
    final level = profileAsync.valueOrNull?.level ?? 1;

    return Scaffold(
      backgroundColor: AppColors.softOrange,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
        ),
        title: Text('$name的小窝',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(petProfileProvider);
          ref.invalidate(petStateProvider);
          ref.invalidate(dashboardProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── 宠物场景 Hero 区 ──
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: PetSceneHero(level: level, petName: name),
            ),

            // ── 内容区 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // ── 个人档案卡 ──
                  _ProfileCard(
                    name: name,
                    level: level,
                    title: title,
                    appearance: appearance,
                    ageDays: ageDays,
                    dashboardAsync: dashboardAsync,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── 今日成长卡 ──
                  const TodayGrowthCard(),

                  const SizedBox(height: AppSpacing.md),

                  // ── 甜甜的悄悄话 ──
                  const PetJournalSection(),

                  const SizedBox(height: AppSpacing.md),

                  // ── 操作入口 ──
                  _ActionButtons(),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _ProfileCard — 个人档案卡（无边框，柔背景）
// =============================================================================

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.level,
    required this.title,
    required this.appearance,
    required this.ageDays,
    required this.dashboardAsync,
  });

  final String name;
  final int level;
  final String title;
  final String appearance;
  final int ageDays;
  final AsyncValue<DashboardData?> dashboardAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // 名字 + 等级
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D68F2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Lv.$level',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D68F2))),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // 称号 + 外观 + 陪伴天数
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoChip(label: title, icon: Icons.stars_rounded),
              const SizedBox(width: AppSpacing.sm),
              _InfoChip(label: appearance, icon: Icons.pets_rounded),
              const SizedBox(width: AppSpacing.sm),
              _InfoChip(label: '陪伴 $ageDays 天', icon: Icons.favorite_rounded),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // EXP 进度条
          _ExpBar(dashboardAsync: dashboardAsync),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softOrange,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFD4A574)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ExpBar extends StatelessWidget {
  const _ExpBar({required this.dashboardAsync});

  final AsyncValue<DashboardData?> dashboardAsync;

  @override
  Widget build(BuildContext context) {
    return dashboardAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (dashboard) {
        if (dashboard == null) return const SizedBox.shrink();

        final nextLevelExp = _expForLevel(dashboard.currentLevel + 1);
        final currentLevelExp = _expForLevel(dashboard.currentLevel);
        final needed = nextLevelExp - currentLevelExp;
        final progress = needed > 0 ? dashboard.expProgress / needed : 0.0;

        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: const Color(0xFF5D68F2).withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5D68F2)),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${dashboard.totalExp} EXP',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5D68F2))),
                Text('${dashboard.expProgress} / $needed 到下一级',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ],
        );
      },
    );
  }

  static int _expForLevel(int level) {
    return (level - 1) * (level - 1) * 100;
  }
}

// =============================================================================
// _ActionButtons — 底部操作入口
// =============================================================================

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.emoji_events_rounded,
            label: '成长档案',
            subtitle: '查看历史轨迹',
            color: const Color(0xFFFFD700),
            onTap: () => context.push('/pet-history'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionButton(
            icon: Icons.auto_awesome_rounded,
            label: 'AI 分析',
            subtitle: '智能洞察',
            color: const Color(0xFF5D68F2),
            onTap: () => context.push('/settings/pet-ai-analysis'),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(label,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
