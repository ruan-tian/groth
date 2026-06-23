import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/services/exp_service.dart';
import '../../dashboard/providers/dashboard_provider.dart'
    hide expServiceProvider;
import '../providers/pet_provider.dart';
import '../../../shared/providers/service_providers.dart';
import '../../../core/constants/pet_assets.dart';
import '../widgets/pet_floating_asset.dart';
import '../widgets/pet_journal_section.dart';
import '../widgets/pet_scene_hero.dart';

class PetCenterPage extends ConsumerWidget {
  const PetCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final profileAsync = ref.watch(petProfileProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final ageDays = ref.watch(petAgeDaysProvider);

    final dashboard = dashboardAsync.valueOrNull;
    final profile = profileAsync.valueOrNull;
    final expService = ref.watch(expServiceProvider);
    final name = normalizePetName(profile?.name);
    final level = dashboard?.currentLevel ?? 1;
    final levelProgress = dashboard == null
        ? null
        : expService.calculateLevelProgress(dashboard.totalExp);
    final title = petTitleForLevel(level);
    final appearance = petAppearanceForLevel(level);
    final heroHeight = math.min(
      460.0,
      math.max(360.0, MediaQuery.sizeOf(context).height * 0.46),
    );

    return Scaffold(
      backgroundColor: colors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '$name的小窝',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          _RoundIconButton(
            icon: Icons.tune_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/pet-settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: colors.accent,
        onRefresh: () async {
          ref.invalidate(petProfileProvider);
          ref.invalidate(petStateProvider);
          ref.invalidate(dashboardProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: heroHeight,
              child: PetSceneHero(level: level, petName: name),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.background, colors.surfaceTint],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GrowthIdentityCard(
                    name: name,
                    level: level,
                    title: title,
                    appearance: appearance,
                    ageDays: ageDays,
                    dashboard: dashboard,
                    levelProgress: levelProgress,
                    loading: dashboardAsync.isLoading,
                  ),
                  const SizedBox(height: 16),
                  _TodaySummaryCard(dashboard: dashboard),
                  const SizedBox(height: 16),
                  const PetJournalSection(),
                  const SizedBox(height: 16),
                  const _PetActionGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthIdentityCard extends StatelessWidget {
  const _GrowthIdentityCard({
    required this.name,
    required this.level,
    required this.title,
    required this.appearance,
    required this.ageDays,
    required this.dashboard,
    required this.levelProgress,
    required this.loading,
  });

  final String name;
  final int level;
  final String title;
  final String appearance;
  final int ageDays;
  final DashboardData? dashboard;
  final GrowthLevelProgress? levelProgress;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final progress = levelProgress?.progressRatio ?? 0;
    final expRemaining = levelProgress?.expRemaining ?? 0;

    return _PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AssetBadge(asset: PetAssets.eventLevelUp, size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        _LevelPill(level: level),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '陪伴你的个人成长，不单独计算宠物经验',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: colors.textSecondary.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _SoftChip(icon: Icons.auto_awesome_rounded, label: title),
              const SizedBox(width: 8),
              _SoftChip(icon: Icons.pets_rounded, label: appearance),
              const SizedBox(width: 8),
              _SoftChip(icon: Icons.favorite_rounded, label: '陪伴 $ageDays 天'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const _AssetMini(asset: PetAssets.eventExpGain),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '成长经验',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          loading ? '加载中' : '${dashboard?.totalExp ?? 0} EXP',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        backgroundColor: colors.softOrange,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '距离 Lv.${level + 1} 还差 $expRemaining EXP',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.dashboard});

  final DashboardData? dashboard;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final data = dashboard;
    return _PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            asset: PetCenterAssets.decoBook,
            title: '今日成长摘要',
            subtitle: '甜甜只记录你真实完成的成长痕迹',
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.45,
            children: [
              _MetricTile(
                icon: Icons.menu_book_rounded,
                color: colors.study,
                label: '学习',
                value: '${data?.todayStudyMinutes ?? 0} 分钟',
              ),
              _MetricTile(
                icon: Icons.fitness_center_rounded,
                color: colors.fitness,
                label: '健身',
                value: '${data?.todayFitnessMinutes ?? 0} 分钟',
              ),
              _MetricTile(
                icon: Icons.edit_note_rounded,
                color: colors.journal,
                label: '日记',
                value: '${data?.todayJournalCount ?? 0} 篇',
              ),
              _MetricTile(
                icon: Icons.timer_rounded,
                color: colors.focus,
                label: '专注',
                value: '${data?.todayFocusMinutes ?? 0} 分钟',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PetActionGrid extends StatelessWidget {
  const _PetActionGrid();

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            asset: PetCenterAssets.decoTarget,
            title: '小窝行动',
            subtitle: '档案、分析和设置都在这里',
          ),
          const SizedBox(height: 14),
          _ActionRow(
            asset: PetAssets.eventLevelUp,
            title: '成长档案',
            subtitle: '查看模块贡献、经验记录和升级里程碑',
            onTap: () => context.push('/pet-history'),
          ),
          const SizedBox(height: 10),
          _ActionRow(
            asset: PetAssets.aiThinking,
            title: 'AI 成长分析',
            subtitle: '确认数据预览后，再让甜甜帮你分析',
            onTap: () => context.push('/pet-ai-analysis'),
          ),
          const SizedBox(height: 10),
          _ActionRow(
            asset: PetCenterAssets.decoLamp,
            title: '小窝设置',
            subtitle: '宠物名称、日记自动化和隐私说明',
            onTap: () => context.push('/pet-settings'),
          ),
        ],
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.asset,
    required this.title,
    required this.subtitle,
  });

  final String asset;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      children: [
        _AssetMini(asset: asset),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String asset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceVariant.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.72)),
        ),
        child: Row(
          children: [
            _AssetBadge(asset: asset, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: colors.softOrange.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: colors.accent),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Lv.$level',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: colors.primaryDark,
        ),
      ),
    );
  }
}

class _AssetBadge extends StatelessWidget {
  const _AssetBadge({required this.asset, this.size = 54});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PetFloatingAsset(asset: asset, size: size, padding: 3);
  }
}

class _AssetMini extends StatelessWidget {
  const _AssetMini({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return PetFloatingAsset(asset: asset, size: 36, padding: 2);
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Semantics(
      button: true,
      label: icon == Icons.arrow_back_rounded ? '返回' : '设置',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.86),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: colors.textPrimary, size: 20),
        ),
      ),
    );
  }
}
