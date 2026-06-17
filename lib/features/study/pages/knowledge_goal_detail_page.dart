import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/knowledge_card_assets.dart';

class KnowledgeGoalDetailPage extends ConsumerWidget {
  const KnowledgeGoalDetailPage({
    super.key,
    required this.goalKey,
    this.goalName,
  });

  final String goalKey;
  final String? goalName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final cards = ref.watch(knowledgeCardsProvider);
    final goal = KnowledgeCardAssets.goalForKey(goalKey);
    final displayName = _displayGoalName(goal, goalName);

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: Text(
          displayName,
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
      ),
      body: ModulePageSurface(
        color: colors.study,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(knowledgeCardsProvider);
            ref.invalidate(knowledgeGoalSummariesProvider);
          },
          child: cards.when(
            data: (items) {
              final goalCards = _cardsForGoal(items);
              final nowMs = DateTime.now().millisecondsSinceEpoch;
              final modules = _moduleStats(goal, goalCards, nowMs);
              final stats = KnowledgeCardReviewStats.fromCards(
                goalCards,
                nowMs,
              );

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _GoalDetailHero(
                    goal: goal,
                    displayName: displayName,
                    totalCards: stats.totalCards,
                    dueCards: stats.dueCards,
                    weakCards: stats.weakCards,
                    reviewedCards: stats.reviewedCards,
                    averageMastery: stats.averageMastery,
                    onReview: goalCards.isEmpty
                        ? null
                        : () => context.push(_reviewGoalPath(includeAll: true)),
                    onWeakReview: stats.weakCards == 0
                        ? null
                        : () => context.push(_weakGoalPath()),
                    onAdd: () => context.push(_addGoalPath(goal)),
                    onImport: () => context.push(_importGoalPath(goal)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GoalMasteryDistribution(stats: stats),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionTitle(
                    title: '模块管理',
                    subtitle: goalCards.isEmpty
                        ? '先从一个模块开始创建知识卡'
                        : '${modules.length} 个模块，${stats.dueCards} 张待复习',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (modules.isEmpty)
                    _EmptyGoalModulesPanel(
                      onAdd: () => context.push(_addGoalPath(goal)),
                      onImport: () => context.push(_importGoalPath(goal)),
                    )
                  else
                    for (final module in modules) ...[
                      _ModuleStatsCard(
                        goal: goal,
                        goalName: goalName,
                        module: module,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CardSkeleton(height: 360),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: ErrorRetryWidget(),
            ),
          ),
        ),
      ),
    );
  }

  List<KnowledgeCard> _cardsForGoal(List<KnowledgeCard> cards) {
    return cards
        .where((card) {
          if (card.goalKey != goalKey) return false;
          final name = goalName?.trim();
          if (goalKey == 'custom' && name != null && name.isNotEmpty) {
            return card.goalName?.trim() == name;
          }
          if (goalKey == 'custom' && (name == null || name.isEmpty)) {
            return card.goalName == null || card.goalName!.trim().isEmpty;
          }
          return true;
        })
        .toList(growable: false);
  }

  String _reviewGoalPath({bool includeAll = false}) {
    final params = <String, String>{'goalKey': goalKey};
    final name = goalName?.trim();
    if (name != null && name.isNotEmpty) params['goalName'] = name;
    if (includeAll) params['all'] = '1';
    return '/plan/study/knowledge/review?${Uri(queryParameters: params).query}';
  }

  String _weakGoalPath() {
    final params = <String, String>{'goalKey': goalKey, 'weak': '1'};
    final name = goalName?.trim();
    if (name != null && name.isNotEmpty) params['goalName'] = name;
    return '/plan/study/knowledge/review?${Uri(queryParameters: params).query}';
  }

  String _addGoalPath(KnowledgeGoalVisual goal) {
    final params = <String, String>{'goalKey': goal.key};
    final name = goalName?.trim();
    if (name != null && name.isNotEmpty) params['goalName'] = name;
    return '/plan/study/knowledge/add?${Uri(queryParameters: params).query}';
  }

  String _importGoalPath(KnowledgeGoalVisual goal) {
    final module = goal.modules.first;
    final params = <String, String>{
      'goalKey': goal.key,
      'moduleKey': module.key,
      'deckKey': module.deckKey,
    };
    final name = goalName?.trim();
    if (name != null && name.isNotEmpty) params['goalName'] = name;
    return '/plan/study/knowledge/import?${Uri(queryParameters: params).query}';
  }
}

class _GoalDetailHero extends StatelessWidget {
  const _GoalDetailHero({
    required this.goal,
    required this.displayName,
    required this.totalCards,
    required this.dueCards,
    required this.weakCards,
    required this.reviewedCards,
    required this.averageMastery,
    required this.onReview,
    required this.onWeakReview,
    required this.onAdd,
    required this.onImport,
  });

  final KnowledgeGoalVisual goal;
  final String displayName;
  final int totalCards;
  final int dueCards;
  final int weakCards;
  final int reviewedCards;
  final double averageMastery;
  final VoidCallback? onReview;
  final VoidCallback? onWeakReview;
  final VoidCallback onAdd;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxxl),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                goal.asset,
                fit: BoxFit.cover,
                cacheWidth: 900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.pageTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  goal.subtitle,
                  style: TextStyle(color: colors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _MetricPill(
                      icon: Icons.style_rounded,
                      text: '$totalCards 张卡',
                    ),
                    _MetricPill(
                      icon: Icons.alarm_rounded,
                      text: '$dueCards 待复习',
                    ),
                    _MetricPill(
                      icon: Icons.local_fire_department_rounded,
                      text: '$weakCards 薄弱',
                    ),
                    _MetricPill(
                      icon: Icons.done_all_rounded,
                      text: '$reviewedCards 已复习',
                    ),
                    _MetricPill(
                      icon: Icons.insights_rounded,
                      text: '掌握 ${averageMastery.toStringAsFixed(1)}/5',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.study,
                          foregroundColor: colors.textOnAccent,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.mlg),
                          ),
                        ),
                        icon: const Icon(Icons.style_rounded),
                        label: const Text('复习目标'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAdd,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.mlg),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('添加卡片'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onWeakReview,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.mlg),
                          ),
                        ),
                        icon: const Icon(Icons.local_fire_department_rounded),
                        label: Text(
                          weakCards == 0 ? '暂无薄弱点' : '薄弱复习 $weakCards',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onImport,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.mlg),
                          ),
                        ),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('批量导入'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.study),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: colors.study,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalMasteryDistribution extends StatelessWidget {
  const _GoalMasteryDistribution({required this.stats});

  final KnowledgeCardReviewStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.donut_large_rounded, color: colors.study),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '掌握分布',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Text(
                '均值 ${stats.averageMastery.toStringAsFixed(1)}/5',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DistributionBar(stats: stats),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _DistributionPill(
                label: '已掌握',
                value: stats.masteredCards,
                color: colors.success,
              ),
              _DistributionPill(
                label: '薄弱',
                value: stats.weakCards,
                color: colors.danger,
              ),
              _DistributionPill(
                label: '待复习',
                value: stats.dueCards,
                color: colors.warning,
              ),
              _DistributionPill(
                label: '未复习',
                value: stats.unreviewedCards,
                color: colors.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.stats});

  final KnowledgeCardReviewStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    if (stats.totalCards == 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Container(height: 10, color: colors.border),
      );
    }
    final unreviewed = stats.unreviewedCards;
    final weak = stats.weakCards > unreviewed
        ? stats.weakCards - unreviewed
        : 0;
    final other = stats.totalCards - stats.masteredCards - weak - unreviewed;

    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            _BarPart(value: stats.masteredCards, color: colors.success),
            _BarPart(value: weak, color: colors.danger),
            _BarPart(value: unreviewed, color: colors.textTertiary),
            _BarPart(
              value: other > 0 ? other : 0,
              color: colors.study.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarPart extends StatelessWidget {
  const _BarPart({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (value <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: value,
      child: ColoredBox(color: color),
    );
  }
}

class _DistributionPill extends StatelessWidget {
  const _DistributionPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: colors.textSecondary)),
      ],
    );
  }
}

class _ModuleStatsCard extends StatelessWidget {
  const _ModuleStatsCard({
    required this.goal,
    required this.goalName,
    required this.module,
  });

  final KnowledgeGoalVisual goal;
  final String? goalName;
  final _GoalModuleStats module;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final visual = KnowledgeCardAssets.visualForKey(module.deckKey);
    final weakCards = module.weakCards;
    return Container(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.asset(
              visual.asset,
              width: 58,
              height: 36,
              fit: BoxFit.cover,
              cacheWidth: 180,
            ),
          ),
          title: Text(
            module.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${module.totalCards} 张卡 · ${module.dueCards} 待复习 · 掌握 ${module.averageMastery.toStringAsFixed(1)}/5',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 6),
              _ModuleStatusBar(module: module),
            ],
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: module.cards.isEmpty
                        ? null
                        : () =>
                              context.push(_reviewModulePath(includeAll: true)),
                    icon: const Icon(Icons.style_rounded),
                    label: const Text('复习模块'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(_addModulePath()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.study,
                      foregroundColor: colors.textOnAccent,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('添加卡片'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(_importModulePath()),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('批量导入到此模块'),
              ),
            ),
            if (weakCards > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(_weakModulePath()),
                  icon: const Icon(Icons.local_fire_department_rounded),
                  label: Text('复习本模块薄弱点 $weakCards'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (module.cards.isEmpty)
              _EmptyModuleCards(moduleName: module.name)
            else
              for (final card in module.cards) _ModuleCardTile(card: card),
          ],
        ),
      ),
    );
  }

  String _reviewModulePath({bool includeAll = false}) {
    final params = <String, String>{
      'goalKey': goal.key,
      'moduleKey': module.key,
    };
    final name = goalName?.trim();
    if (name != null && name.isNotEmpty) params['goalName'] = name;
    final moduleName = module.moduleName?.trim();
    if (moduleName != null && moduleName.isNotEmpty) {
      params['moduleName'] = moduleName;
    }
    if (includeAll) params['all'] = '1';
    return '/plan/study/knowledge/review?${Uri(queryParameters: params).query}';
  }

  String _addModulePath() {
    final params = <String, String>{
      'goalKey': goal.key,
      'moduleKey': module.key,
      'deckKey': module.deckKey,
    };
    final name = goalName?.trim();
    if (name != null && name.isNotEmpty) params['goalName'] = name;
    final moduleName = module.moduleName?.trim();
    if (moduleName != null && moduleName.isNotEmpty) {
      params['moduleName'] = moduleName;
    }
    return '/plan/study/knowledge/add?${Uri(queryParameters: params).query}';
  }

  String _importModulePath() {
    final params = <String, String>{
      'goalKey': goal.key,
      'moduleKey': module.key,
      'deckKey': module.deckKey,
    };
    final name = goalName?.trim();
    if (name != null && name.isNotEmpty) params['goalName'] = name;
    final moduleName = module.moduleName?.trim();
    if (moduleName != null && moduleName.isNotEmpty) {
      params['moduleName'] = moduleName;
    }
    return '/plan/study/knowledge/import?${Uri(queryParameters: params).query}';
  }

  String _weakModulePath() {
    final params = <String, String>{
      'goalKey': goal.key,
      'moduleKey': module.key,
      'deckKey': module.deckKey,
      'weak': '1',
    };
    final name = goalName?.trim();
    if (name != null && name.isNotEmpty) params['goalName'] = name;
    final moduleName = module.moduleName?.trim();
    if (moduleName != null && moduleName.isNotEmpty) {
      params['moduleName'] = moduleName;
    }
    return '/plan/study/knowledge/review?${Uri(queryParameters: params).query}';
  }
}

class _ModuleStatusBar extends StatelessWidget {
  const _ModuleStatusBar({required this.module});

  final _GoalModuleStats module;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    if (module.totalCards == 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Container(height: 6, color: colors.border),
      );
    }
    final unreviewed = module.unreviewedCards;
    final weak = module.weakCards > unreviewed
        ? module.weakCards - unreviewed
        : 0;
    final other = module.totalCards - module.masteredCards - weak - unreviewed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                _BarPart(value: module.masteredCards, color: colors.success),
                _BarPart(value: weak, color: colors.danger),
                _BarPart(value: unreviewed, color: colors.textTertiary),
                _BarPart(
                  value: other > 0 ? other : 0,
                  color: colors.study.withValues(alpha: 0.38),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '薄弱 ${module.weakCards} · 掌握 ${module.masteredCards} · 未复习 ${module.unreviewedCards}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colors.textTertiary, fontSize: 11),
        ),
      ],
    );
  }
}

class _ModuleCardTile extends StatelessWidget {
  const _ModuleCardTile({required this.card});

  final KnowledgeCard card;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final chapter = card.subject?.trim();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        card.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        [
          if (chapter != null && chapter.isNotEmpty) '单元：$chapter',
          '掌握 ${card.masteryLevel}/5',
          '复习 ${card.reviewCount} 次',
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.textSecondary),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
      onTap: () => context.push('/plan/study/knowledge/edit/${card.id}'),
    );
  }
}

class _EmptyModuleCards extends StatelessWidget {
  const _EmptyModuleCards({required this.moduleName});

  final String moduleName;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        '「$moduleName」还没有知识卡。',
        style: TextStyle(color: colors.textSecondary),
      ),
    );
  }
}

class _EmptyGoalModulesPanel extends StatelessWidget {
  const _EmptyGoalModulesPanel({required this.onAdd, required this.onImport});

  final VoidCallback onAdd;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xxxl),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              KnowledgeCardAssets.emptyGoalModules,
              fit: BoxFit.cover,
              cacheWidth: 900,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        EmptyStateWidget(
          icon: Icons.view_module_outlined,
          title: '这个目标还没有模块卡片',
          subtitle: '先添加一张知识卡，系统会按模块帮你归档。',
          accentColor: colors.study,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: onAdd,
          style: FilledButton.styleFrom(
            backgroundColor: colors.study,
            foregroundColor: colors.textOnAccent,
            minimumSize: const Size.fromHeight(52),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('添加知识卡'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onImport,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('批量导入'),
        ),
      ],
    );
  }
}

List<_GoalModuleStats> _moduleStats(
  KnowledgeGoalVisual goal,
  List<KnowledgeCard> cards,
  int nowMs,
) {
  if (goal.key == 'custom') {
    final grouped = <String?, List<KnowledgeCard>>{};
    for (final card in cards) {
      final name = card.moduleName?.trim();
      grouped
          .putIfAbsent(
            name == null || name.isEmpty ? null : name,
            () => <KnowledgeCard>[],
          )
          .add(card);
    }
    return grouped.entries
        .map((entry) {
          final moduleCards = entry.value;
          return _GoalModuleStats.fromCards(
            key: 'custom',
            name: entry.key ?? '自定义模块',
            moduleName: entry.key,
            deckKey: moduleCards.isEmpty ? 'custom' : moduleCards.first.deckKey,
            cards: moduleCards,
            nowMs: nowMs,
          );
        })
        .toList(growable: false);
  }

  return goal.modules
      .map((module) {
        final moduleCards = cards
            .where((card) => card.moduleKey == module.key)
            .toList(growable: false);
        return _GoalModuleStats.fromCards(
          key: module.key,
          name: module.name,
          moduleName: null,
          deckKey: module.deckKey,
          cards: moduleCards,
          nowMs: nowMs,
        );
      })
      .toList(growable: false);
}

String _displayGoalName(KnowledgeGoalVisual goal, String? goalName) {
  if (goal.key != 'custom') return goal.name;
  final name = goalName?.trim();
  return name == null || name.isEmpty ? goal.name : name;
}

class _GoalModuleStats {
  const _GoalModuleStats({
    required this.key,
    required this.name,
    required this.moduleName,
    required this.deckKey,
    required this.cards,
    required this.totalCards,
    required this.dueCards,
    required this.weakCards,
    required this.masteredCards,
    required this.unreviewedCards,
    required this.averageMastery,
  });

  factory _GoalModuleStats.fromCards({
    required String key,
    required String name,
    required String? moduleName,
    required String deckKey,
    required List<KnowledgeCard> cards,
    required int nowMs,
  }) {
    final stats = KnowledgeCardReviewStats.fromCards(cards, nowMs);
    return _GoalModuleStats(
      key: key,
      name: name,
      moduleName: moduleName,
      deckKey: deckKey,
      cards: cards,
      totalCards: stats.totalCards,
      dueCards: stats.dueCards,
      weakCards: stats.weakCards,
      masteredCards: stats.masteredCards,
      unreviewedCards: stats.unreviewedCards,
      averageMastery: stats.averageMastery,
    );
  }

  final String key;
  final String name;
  final String? moduleName;
  final String deckKey;
  final List<KnowledgeCard> cards;
  final int totalCards;
  final int dueCards;
  final int weakCards;
  final int masteredCards;
  final int unreviewedCards;
  final double averageMastery;
}
