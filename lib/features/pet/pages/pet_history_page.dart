import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/pet_provider.dart';
import '../../../core/constants/pet_assets.dart';
import '../widgets/pet_floating_asset.dart';

final _petHistoryDataProvider = FutureProvider.autoDispose<PetHistoryData>((
  ref,
) async {
  final expRepo = ref.watch(expRepositoryProvider);
  final now = DateTime.now();
  final logs = await expRepo.getExpLogsByRange(
    now.subtract(const Duration(days: 30)),
    now,
  );
  final streak = await expRepo.getConsecutiveActiveDays();
  final sources = <String, int>{
    'study': await expRepo.getTotalExpBySource('study'),
    'fitness': await expRepo.getTotalExpBySource('fitness'),
    'journal': await expRepo.getTotalExpBySource('journal'),
    'focus': await expRepo.getTotalExpBySource('focus'),
  };
  return PetHistoryData(
    sourceExp: sources,
    recentLogs: logs.take(12).toList(),
    consecutiveDays: streak,
  );
});

class PetHistoryData {
  const PetHistoryData({
    required this.sourceExp,
    required this.recentLogs,
    required this.consecutiveDays,
  });

  final Map<String, int> sourceExp;
  final List<GrowthExpLog> recentLogs;
  final int consecutiveDays;
}

class PetHistoryPage extends ConsumerWidget {
  const PetHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final dashboardAsync = ref.watch(dashboardProvider);
    final profileAsync = ref.watch(petProfileProvider);
    final historyAsync = ref.watch(_petHistoryDataProvider);
    final dashboard = dashboardAsync.valueOrNull;
    final profile = profileAsync.valueOrNull;
    final name = normalizePetName(profile?.name);
    final level = dashboard?.currentLevel ?? 1;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('成长档案'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        color: colors.accent,
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(_petHistoryDataProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _ArchiveHero(name: name, level: level, dashboard: dashboard),
            const SizedBox(height: 16),
            historyAsync.when(
              data: (history) => Column(
                children: [
                  _ContributionCard(history: history),
                  const SizedBox(height: 16),
                  _MilestoneCard(level: level),
                  const SizedBox(height: 16),
                  _RecentLogsCard(logs: history.recentLogs),
                ],
              ),
              loading: () => const _LoadingCard(),
              error: (error, _) =>
                  _EmptyCard(title: '档案暂时打不开', subtitle: error.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveHero extends StatelessWidget {
  const _ArchiveHero({
    required this.name,
    required this.level,
    required this.dashboard,
  });

  final String name;
  final int level;
  final DashboardData? dashboard;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final totalExp = dashboard?.totalExp ?? 0;
    return _PaperCard(
      child: Stack(
        children: [
          Positioned(
            right: -4,
            top: -8,
            child: Opacity(
              opacity: 0.16,
              child: Image.asset(PetCenterAssets.decoStar, width: 82),
            ),
          ),
          Row(
            children: [
              _ImageBadge(asset: PetAssets.eventLevelUp, size: 76),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name 的成长档案',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Lv.$level · ${petTitleForLevel(level)} · $totalExp EXP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '这里展示的是你的个人成长经验，宠物等级从这套系统自然派生。',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
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

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({required this.history});

  final PetHistoryData history;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final maxExp = math.max(1, history.sourceExp.values.fold<int>(0, math.max));
    return _PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(
            asset: PetAssets.eventExpGain,
            title: '模块贡献',
            subtitle: '每一类记录都在共同喂养这套成长等级',
          ),
          const SizedBox(height: 16),
          _SourceBar(
            label: '学习',
            exp: history.sourceExp['study'] ?? 0,
            maxExp: maxExp,
            color: colors.study,
          ),
          _SourceBar(
            label: '健身',
            exp: history.sourceExp['fitness'] ?? 0,
            maxExp: maxExp,
            color: colors.fitness,
          ),
          _SourceBar(
            label: '日记',
            exp: history.sourceExp['journal'] ?? 0,
            maxExp: maxExp,
            color: colors.journal,
          ),
          _SourceBar(
            label: '专注',
            exp: history.sourceExp['focus'] ?? 0,
            maxExp: maxExp,
            color: colors.focus,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: colors.accent,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                '连续活跃 ${history.consecutiveDays} 天',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final milestones = const [
      (1, '萌芽小窝', PetCenterAssets.decoPlant),
      (6, '稳定成长', PetCenterAssets.decoBook),
      (11, '进阶陪伴', PetCenterAssets.decoPencil),
      (21, '高手节奏', PetCenterAssets.decoTarget),
      (36, '大师小窝', PetCenterAssets.decoTrophy),
      (51, '传说同行', PetCenterAssets.decoStar),
    ];
    return _PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(
            asset: PetAssets.eventStreak7,
            title: '升级里程碑',
            subtitle: '等级来自个人成长总经验，不是独立宠物经验',
          ),
          const SizedBox(height: 14),
          ...milestones.map((item) {
            final reached = level >= item.$1;
            return _MilestoneRow(
              level: item.$1,
              title: item.$2,
              asset: item.$3,
              reached: reached,
            );
          }),
        ],
      ),
    );
  }
}

class _RecentLogsCard extends StatelessWidget {
  const _RecentLogsCard({required this.logs});

  final List<GrowthExpLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const _EmptyCard(
        title: '还没有经验记录',
        subtitle: '完成学习、健身、日记或专注后，甜甜会把成长痕迹收进这里。',
      );
    }
    return _PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(
            asset: PetAssets.eventTaskDone,
            title: '最近经验记录',
            subtitle: '近 30 天里最新的成长痕迹',
          ),
          const SizedBox(height: 12),
          ...logs.map((log) => _LogRow(log: log)),
        ],
      ),
    );
  }
}

class _SourceBar extends StatelessWidget {
  const _SourceBar({
    required this.label,
    required this.exp,
    required this.maxExp,
    required this.color,
  });

  final String label;
  final int exp;
  final int maxExp;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final value = math.min(1.0, exp / maxExp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$exp EXP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.level,
    required this.title,
    required this.asset,
    required this.reached,
  });

  final int level;
  final String title;
  final String asset;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: reached
            ? colors.softOrange.withValues(alpha: 0.72)
            : colors.surfaceVariant.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: reached ? 1 : 0.42,
            child: _ImageBadge(asset: asset),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: reached ? colors.textPrimary : colors.textTertiary,
              ),
            ),
          ),
          Text(
            'Lv.$level',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: reached ? colors.accent : colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log});

  final GrowthExpLog log;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final source = switch (log.sourceType) {
      'study' => '学习',
      'fitness' => '健身',
      'journal' => '日记',
      'focus' => '专注',
      _ => '成长',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const _ImageBadge(asset: PetAssets.eventExpGain),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(log.createdAt),
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '+${log.expValue}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: colors.accent,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

class _Header extends StatelessWidget {
  const _Header({
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
        _ImageBadge(asset: asset),
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return _PaperCard(
      child: Column(
        children: [
          Image.asset(PetAssets.commonEmpty, width: 96, height: 96),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return _PaperCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(color: colors.accent),
        ),
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

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({required this.asset, this.size = 42});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PetFloatingAsset(
      asset: asset,
      size: size,
      padding: size > 50 ? 3 : 2,
    );
  }
}
