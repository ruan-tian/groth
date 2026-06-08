import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/pet_provider.dart';
import '../utils/pet_assets.dart';
import '../widgets/pet_floating_asset.dart';
import '../widgets/pet_journal_section.dart';
import '../widgets/pet_scene_hero.dart';

class PetCenterPage extends ConsumerWidget {
  const PetCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(petProfileProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final ageDays = ref.watch(petAgeDaysProvider);

    final dashboard = dashboardAsync.valueOrNull;
    final profile = profileAsync.valueOrNull;
    final name = normalizePetName(profile?.name);
    final level = dashboard?.currentLevel ?? profile?.level ?? 1;
    final title = petTitleForLevel(level);
    final appearance = petAppearanceForLevel(level);
    final heroHeight = math.min(
      460.0,
      math.max(360.0, MediaQuery.sizeOf(context).height * 0.46),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EF),
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
        title: Text(
          '$name的小窝',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
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
        color: const Color(0xFFE89B68),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF3E8), Color(0xFFFFFBF6)],
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
    required this.loading,
  });

  final String name;
  final int level;
  final String title;
  final String appearance;
  final int ageDays;
  final DashboardData? dashboard;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final expBase = (level - 1) * (level - 1) * 100;
    final expNext = level * level * 100;
    final expNeeded = math.max(1, expNext - expBase);
    final expProgress = dashboard?.expProgress ?? 0;
    final progress = math.min(1.0, math.max(0.0, expProgress / expNeeded));

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
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
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
                        color: AppColors.textSecondary.withValues(alpha: 0.88),
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
                        const Text(
                          '成长经验',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          loading ? '加载中' : '${dashboard?.totalExp ?? 0} EXP',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE08B55),
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
                        backgroundColor: const Color(0xFFFFE6D6),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFEFA26D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '距离 Lv.${level + 1} 还差 ${math.max(0, expNeeded - expProgress)} EXP',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
                color: AppColors.study,
                label: '学习',
                value: '${data?.todayStudyMinutes ?? 0} 分钟',
              ),
              _MetricTile(
                icon: Icons.fitness_center_rounded,
                color: AppColors.fitness,
                label: '健身',
                value: '${data?.todayFitnessMinutes ?? 0} 分钟',
              ),
              _MetricTile(
                icon: Icons.edit_note_rounded,
                color: const Color(0xFFE49772),
                label: '日记',
                value: '${data?.todayJournalCount ?? 0} 篇',
              ),
              _MetricTile(
                icon: Icons.timer_rounded,
                color: const Color(0xFF7AA6A1),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB97A52).withValues(alpha: 0.10),
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
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary,
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7EF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE6D6)),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCA9877)),
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2E9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: const Color(0xFFD79466)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF6F74E8).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Lv.$level',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF5F66D6),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}
