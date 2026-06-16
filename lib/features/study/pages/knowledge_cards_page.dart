import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repositories/knowledge_card_repository.dart';
import '../../../core/repositories/knowledge_source_repository.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/knowledge_source_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/knowledge_card_assets.dart';

class KnowledgeCardsPage extends ConsumerStatefulWidget {
  const KnowledgeCardsPage({super.key});

  @override
  ConsumerState<KnowledgeCardsPage> createState() => _KnowledgeCardsPageState();
}

class _KnowledgeCardsPageState extends ConsumerState<KnowledgeCardsPage> {
  String _query = '';
  String? _selectedGoalFilter;
  bool _bulkMode = false;
  final Set<int> _selectedCardIds = <int>{};
  bool _onboardingChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_onboardingChecked) {
        _onboardingChecked = true;
        _checkOnboarding();
      }
    });
  }

  Future<void> _checkOnboarding() async {
    final done = await ref.read(knowledgeOnboardingDoneProvider.future);
    if (!done && mounted) {
      await context.push('/plan/study/knowledge/onboarding');
      ref.invalidate(filteredKnowledgeGoalSummariesProvider);
      ref.invalidate(knowledgeGoalSummariesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final summaries = ref.watch(filteredKnowledgeGoalSummariesProvider);
    final cards = ref.watch(knowledgeCardsProvider);

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: Text(
          '知识抽卡',
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: '本地知识库',
            onPressed: () => context.push('/plan/study/knowledge/sources'),
            icon: Icon(Icons.library_books_rounded, color: colors.study),
          ),
          IconButton(
            tooltip: '自定义模板',
            onPressed: () => context.push('/plan/study/knowledge/templates'),
            icon: Icon(Icons.dashboard_customize_rounded, color: colors.study),
          ),
          IconButton(
            tooltip: '批量导入',
            onPressed: () => context.push('/plan/study/knowledge/import'),
            icon: Icon(Icons.upload_file_rounded, color: colors.study),
          ),
          IconButton(
            tooltip: '添加知识卡',
            onPressed: () => context.push('/plan/study/knowledge/add'),
            icon: Icon(Icons.add_card_rounded, color: colors.study),
          ),
          PopupMenuButton<KnowledgeMoreAction>(
            tooltip: '更多',
            color: colors.card,
            surfaceTintColor: colors.card,
            icon: Icon(Icons.more_horiz_rounded, color: colors.study),
            onSelected: (action) {
              switch (action) {
                case KnowledgeMoreAction.export:
                  context.push('/plan/study/knowledge/export');
                  break;
                case KnowledgeMoreAction.archive:
                  context.push('/plan/study/knowledge/archive');
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: KnowledgeMoreAction.export,
                child: KnowledgeMoreActionRow(
                  icon: Icons.file_download_outlined,
                  label: '导出知识卡',
                ),
              ),
              PopupMenuItem(
                value: KnowledgeMoreAction.archive,
                child: KnowledgeMoreActionRow(
                  icon: Icons.inventory_2_outlined,
                  label: '归档箱',
                ),
              ),
            ],
          ),
        ],
      ),
      body: ModulePageSurface(
        color: colors.study,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(knowledgeCardsProvider);
            ref.invalidate(knowledgeGoalSummariesProvider);
            ref.invalidate(knowledgeDeckSummariesProvider);
            ref.invalidate(knowledgeCustomTemplatesProvider);
            ref.invalidate(dueKnowledgeCardsCountProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              summaries.when(
                data: (items) {
                  final total = items.fold<int>(
                    0,
                    (sum, item) => sum + item.totalCards,
                  );
                  final due = items.fold<int>(
                    0,
                    (sum, item) => sum + item.dueCards,
                  );
                  return KnowledgeReviewHero(totalCards: total, dueCards: due);
                },
                loading: () => const KnowledgeHeroSkeleton(),
                error: (_, _) =>
                    KnowledgeReviewHero(totalCards: 0, dueCards: 0),
              ),
              cards.when(
                data: (items) => items.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Column(
                          children: [
                            ReviewHealthSummary(
                              stats: KnowledgeCardReviewStats.fromCards(
                                items,
                                DateTime.now().millisecondsSinceEpoch,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            WeakReviewShortcut(cards: items),
                          ],
                        ),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionTitleRow(
                title: '复习目标模板',
                action: '管理目标',
                onActionTap: () async {
                  await context.push('/plan/study/knowledge/onboarding');
                  ref.invalidate(filteredKnowledgeGoalSummariesProvider);
                  ref.invalidate(knowledgeGoalSummariesProvider);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              summaries.when(
                data: (items) => GoalGrid(summaries: items),
                loading: () => const CardSkeleton(height: 360),
                error: (_, _) => const ErrorRetryWidget(),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionTitleRow(
                title: '管理知识卡',
                action: _bulkMode ? '退出批量' : '批量管理',
                onActionTap: _toggleBulkMode,
              ),
              const SizedBox(height: AppSpacing.md),
              cards.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyKnowledgeCardsPanel();
                  }
                  return KnowledgeCardLibrary(
                    allCards: items,
                    cards: _filterCards(items),
                    query: _query,
                    selectedGoalFilter: _selectedGoalFilter,
                    bulkMode: _bulkMode,
                    selectedCardIds: _selectedCardIds,
                    onQueryChanged: (value) => setState(() {
                      _query = value;
                      _selectedCardIds.clear();
                    }),
                    onGoalSelected: (value) => setState(() {
                      _selectedGoalFilter = value;
                      _selectedCardIds.clear();
                    }),
                    onSelectAllVisible: _selectAllVisible,
                    onClearSelected: _clearSelectedCards,
                    onToggleSelected: _toggleSelectedCard,
                    onArchiveSelected: _archiveSelectedCards,
                    onEditSubjectSelected: _editSelectedCardsSubject,
                    onMoveSelected: _moveSelectedCards,
                    onArchive: _archiveCard,
                    onPreview: _showCardPreview,
                  );
                },
                loading: () => const CardSkeleton(height: 220),
                error: (_, _) => const ErrorRetryWidget(),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      floatingActionButton: _bulkMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/plan/study/knowledge/add'),
              backgroundColor: colors.study,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加知识卡'),
            ),
    );
  }

  List<KnowledgeCard> _filterCards(List<KnowledgeCard> cards) {
    var filtered = cards;
    if (_selectedGoalFilter != null) {
      filtered = filtered.where((c) => c.goalKey == _selectedGoalFilter).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered.where((c) {
        return c.title.toLowerCase().contains(q) ||
            c.question.toLowerCase().contains(q) ||
            c.answer.toLowerCase().contains(q);
      }).toList();
    }
    return filtered;
  }

  void _toggleBulkMode() {
    setState(() {
      _bulkMode = !_bulkMode;
      if (!_bulkMode) _selectedCardIds.clear();
    });
  }

  void _selectAllVisible() {
    setState(() {
      final cards = ref.read(knowledgeCardsProvider).valueOrNull ?? [];
      final filtered = _filterCards(cards);
      _selectedCardIds.addAll(filtered.map((c) => c.id));
    });
  }

  void _clearSelectedCards() {
    setState(_selectedCardIds.clear);
  }

  void _toggleSelectedCard(int cardId) {
    setState(() {
      if (_selectedCardIds.contains(cardId)) {
        _selectedCardIds.remove(cardId);
      } else {
        _selectedCardIds.add(cardId);
      }
    });
  }

  void _invalidateKnowledgeCardLists() {
    ref.invalidate(knowledgeCardsProvider);
    ref.invalidate(knowledgeGoalSummariesProvider);
    ref.invalidate(knowledgeDeckSummariesProvider);
    ref.invalidate(dueKnowledgeCardsCountProvider);
  }

  void _showCardPreview(KnowledgeCard card) {
    final colors = context.growthColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              card.title,
              style: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '问题',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              card.question,
              style: AppTextStyles.body.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '答案',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              card.answer,
              style: AppTextStyles.body.copyWith(color: colors.textPrimary),
            ),
            if (card.explanation != null && card.explanation!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '解释',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                card.explanation!,
                style: AppTextStyles.body.copyWith(color: colors.textPrimary),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            CardSourceReferences(cardId: card.id),
          ],
        ),
      ),
    );
  }
  Future<void> _archiveCard(KnowledgeCard card) async {
    final colors = context.growthColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        surfaceTintColor: colors.card,
        title: const Text('归档知识卡'),
        content: Text('确定要归档「${card.title}」吗？归档后不会再进入抽卡队列。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.growthColors.danger),
            child: const Text('归档'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(knowledgeCardRepositoryProvider).archiveCard(card.id);
    _invalidateKnowledgeCardLists();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('知识卡已归档')));
  }

  Future<void> _archiveSelectedCards() async {
    if (_selectedCardIds.isEmpty) return;
    final count = _selectedCardIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.growthColors.card,
        surfaceTintColor: context.growthColors.card,
        title: const Text('批量归档知识卡'),
        content: Text('确定要归档 $count 张知识卡吗？归档后可在归档箱恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.growthColors.danger),
            child: const Text('归档'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ids = _selectedCardIds.toList(growable: false);
    await ref.read(knowledgeCardRepositoryProvider).archiveCards(ids);
    _invalidateKnowledgeCardLists();

    if (!mounted) return;
    setState(() {
      _bulkMode = false;
      _selectedCardIds.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已归档 $count 张知识卡')));
  }

  Future<void> _editSelectedCardsSubject() async {
    if (_selectedCardIds.isEmpty) return;
    var input = '';
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.growthColors.card,
        surfaceTintColor: context.growthColors.card,
        title: const Text('修改章节 / 知识单元'),
        content: TextField(
          autofocus: true,
          onChanged: (value) => input = value,
          decoration: const InputDecoration(
            labelText: '章节 / 知识单元',
            hintText: '例如：操作系统 第 3 章',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, input),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final subject = result.trim().isEmpty ? null : result.trim();
    final ids = _selectedCardIds.toList(growable: false);
    await ref
        .read(knowledgeCardRepositoryProvider)
        .updateCardsSubject(ids, subject);
    _invalidateKnowledgeCardLists();

    if (!mounted) return;
    final count = ids.length;
    setState(_selectedCardIds.clear);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已更新 $count 张知识卡的章节/单元')));
  }

  Future<void> _moveSelectedCards() async {
    if (_selectedCardIds.isEmpty) return;
    final templates = ref.read(knowledgeCustomTemplatesProvider).valueOrNull;
    final result = await showDialog<BulkMoveTarget>(
      context: context,
      builder: (ctx) => BulkMoveTargetDialog(customTemplates: templates),
    );
    if (result == null) return;

    final ids = _selectedCardIds.toList(growable: false);
    await ref
        .read(knowledgeCardRepositoryProvider)
        .moveCardsToModule(
          ids,
          deckKey: result.deckKey,
          goalKey: result.goalKey,
          goalName: result.goalName,
          moduleKey: result.moduleKey,
          moduleName: result.moduleName,
        );
    _invalidateKnowledgeCardLists();

    if (!mounted) return;
    final count = ids.length;
    setState(_selectedCardIds.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已移动 $count 张知识卡到「${result.displayName}」')),
    );
  }
}

enum KnowledgeMoreAction { export, archive }

// =============================================================================
// Hero / Stats Widgets
// =============================================================================

class KnowledgeReviewHero extends StatelessWidget {
  const KnowledgeReviewHero({
    super.key,
    required this.totalCards,
    required this.dueCards,
  });

  final int totalCards;
  final int dueCards;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.study,
            colors.study.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '知识抽卡',
            style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            totalCards == 0
                ? '还没有知识卡，从导入资料开始吧'
                : dueCards > 0
                    ? '今天有 $dueCards 张卡片待复习'
                    : '所有卡片已复习完毕',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          if (totalCards > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _HeroStat(label: '总计', value: '$totalCards'),
                const SizedBox(width: AppSpacing.xl),
                _HeroStat(label: '待复习', value: '$dueCards'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.sectionTitle.copyWith(
            color: Colors.white,
            fontSize: 28,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class KnowledgeHeroSkeleton extends StatelessWidget {
  const KnowledgeHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      height: 160,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 24,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewHealthSummary extends StatelessWidget {
  const ReviewHealthSummary({super.key, required this.stats});

  final KnowledgeCardReviewStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '学习健康度',
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: HealthMetricTile(
                  icon: Icons.local_fire_department_rounded,
                  label: '已掌握',
                  value: '${stats.masteredCards}',
                  color: colors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HealthMetricTile(
                  icon: Icons.warning_amber_rounded,
                  label: '薄弱点',
                  value: '${stats.weakCards}',
                  color: colors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HealthMetricTile(
                  icon: Icons.schedule_rounded,
                  label: '待复习',
                  value: '${stats.dueCards}',
                  color: colors.study,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MasteryDistributionBar(stats: stats),
        ],
      ),
    );
  }
}

class MasteryDistributionBar extends StatelessWidget {
  const MasteryDistributionBar({super.key, required this.stats});

  final KnowledgeCardReviewStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final mastered = stats.ratio(stats.masteredCards);
    final reviewed = stats.ratio(stats.reviewedCards - stats.masteredCards);
    final weak = stats.ratio(stats.weakCards);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '掌握度分布',
          style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: mastered + reviewed + weak,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation(colors.success),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class HealthMetricTile extends StatelessWidget {
  const HealthMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.sectionTitle.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class WeakReviewShortcut extends StatelessWidget {
  const WeakReviewShortcut({super.key, required this.cards});

  final List<KnowledgeCard> cards;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final weakCards = cards.where((c) => isWeakKnowledgeCard(c)).toList();
    if (weakCards.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/plan/study/knowledge/review?weak=1'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weakCards.length} 张薄弱卡片',
                    style: AppTextStyles.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '点击立即复习薄弱知识点',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: colors.warning, size: 16),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Goal Grid Widgets
// =============================================================================

class SectionTitleRow extends StatelessWidget {
  const SectionTitleRow({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
  });

  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.sectionTitle.copyWith(
            color: colors.textPrimary,
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(
              action!,
              style: TextStyle(color: colors.study),
            ),
          ),
      ],
    );
  }
}

class GoalGrid extends StatelessWidget {
  const GoalGrid({super.key, required this.summaries});

  final List<KnowledgeGoalSummary> summaries;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.2,
      ),
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        return GoalCard(summary: summaries[index]);
      },
    );
  }
}

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.summary});

  final KnowledgeGoalSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final visual = summary.visual;

    return GestureDetector(
      onTap: () => context.push(
        '/plan/study/knowledge/goal?goalKey=${visual.key}&goalName=${summary.displayName}',
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.asset(
                    visual.asset,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const Spacer(),
                if (summary.dueCards > 0)
                  DueBadge(count: summary.dueCards),
              ],
            ),
            const Spacer(),
            Text(
              summary.displayName,
              style: AppTextStyles.body.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${summary.totalCards} 张卡片',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DueBadge extends StatelessWidget {
  const DueBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.warning,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// Card Library Widgets
// =============================================================================

class KnowledgeCardLibrary extends StatelessWidget {
  const KnowledgeCardLibrary({
    super.key,
    required this.allCards,
    required this.cards,
    required this.query,
    this.selectedGoalFilter,
    required this.bulkMode,
    required this.selectedCardIds,
    required this.onQueryChanged,
    required this.onGoalSelected,
    required this.onSelectAllVisible,
    required this.onClearSelected,
    required this.onToggleSelected,
    required this.onArchiveSelected,
    required this.onEditSubjectSelected,
    required this.onMoveSelected,
    required this.onArchive,
    this.onPreview,
  });

  final List<KnowledgeCard> allCards;
  final List<KnowledgeCard> cards;
  final String query;
  final String? selectedGoalFilter;
  final bool bulkMode;
  final Set<int> selectedCardIds;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onGoalSelected;
  final VoidCallback onSelectAllVisible;
  final VoidCallback onClearSelected;
  final ValueChanged<int> onToggleSelected;
  final VoidCallback onArchiveSelected;
  final VoidCallback onEditSubjectSelected;
  final VoidCallback onMoveSelected;
  final ValueChanged<KnowledgeCard> onArchive;
  final ValueChanged<KnowledgeCard>? onPreview;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Column(
      children: [
        // Search bar
        TextField(
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: '搜索知识卡...',
            prefixIcon: Icon(Icons.search_rounded, color: colors.textTertiary),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Goal filter chips
        GoalFilterChips(
          selectedGoal: selectedGoalFilter,
          onSelected: onGoalSelected,
        ),
        // Bulk manage bar
        if (bulkMode)
          BulkManageBar(
            selectedCount: selectedCardIds.length,
            onSelectAll: onSelectAllVisible,
            onClear: onClearSelected,
            onArchive: onArchiveSelected,
            onEditSubject: onEditSubjectSelected,
            onMove: onMoveSelected,
          ),
        const SizedBox(height: AppSpacing.md),
        // Card list
        if (cards.isEmpty)
          const EmptyKnowledgeCardsPanel()
        else
          for (final card in cards)
            KnowledgeCardManageTile(
              card: card,
              bulkMode: bulkMode,
              selected: selectedCardIds.contains(card.id),
              onToggle: () => onToggleSelected(card.id),
              onArchive: () => onArchive(card),
              onPreview: onPreview != null ? () => onPreview!(card) : null,
            ),
      ],
    );
  }
}

class GoalFilterChips extends StatelessWidget {
  const GoalFilterChips({
    super.key,
    this.selectedGoal,
    required this.onSelected,
  });

  final String? selectedGoal;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChipButton(
            label: '全部',
            selected: selectedGoal == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          for (final goal in KnowledgeCardAssets.goalTemplates)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChipButton(
                label: goal.name,
                selected: selectedGoal == goal.key,
                onTap: () => onSelected(goal.key),
              ),
            ),
        ],
      ),
    );
  }
}

class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.study : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? colors.study : colors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class BulkManageBar extends StatelessWidget {
  const BulkManageBar({
    super.key,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onClear,
    required this.onArchive,
    required this.onEditSubject,
    required this.onMove,
  });

  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final VoidCallback onArchive;
  final VoidCallback onEditSubject;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: onSelectAll,
            child: const Text('全选'),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('清除'),
          ),
          const Spacer(),
          Text('$selectedCount 项'),
          const Spacer(),
          TextButton(
            onPressed: selectedCount > 0 ? onArchive : null,
            child: const Text('归档所选'),
          ),
          TextButton(
            onPressed: selectedCount > 0 ? onEditSubject : null,
            child: const Text('改章节/单元'),
          ),
          TextButton(
            onPressed: selectedCount > 0 ? onMove : null,
            child: const Text('移动目标/模块'),
          ),
        ],
      ),
    );
  }
}

class KnowledgeCardManageTile extends StatelessWidget {
  const KnowledgeCardManageTile({
    super.key,
    required this.card,
    required this.bulkMode,
    required this.selected,
    required this.onToggle,
    required this.onArchive,
    this.onPreview,
  });

  final KnowledgeCard card;
  final bool bulkMode;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onArchive;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Container(
      key: ValueKey('knowledge-card-manage-tile-${card.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected ? colors.study : colors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: bulkMode ? onToggle : onPreview,
        leading: bulkMode
            ? Checkbox(
                value: selected,
                onChanged: (_) => onToggle(),
              )
            : null,
        title: Text(
          card.title,
          style: AppTextStyles.body.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          card.question,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: colors.textSecondary,
          ),
        ),
        trailing: bulkMode
            ? null
            : IconButton(
                onPressed: onArchive,
                icon: Icon(
                  Icons.archive_rounded,
                  color: colors.textTertiary,
                ),
              ),
      ),
    );
  }
}

class EmptyKnowledgeCardsPanel extends StatelessWidget {
  const EmptyKnowledgeCardsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return EmptyStateWidget(
      icon: Icons.style_rounded,
      title: '还没有知识卡',
      subtitle: '从导入资料开始，AI 会帮你生成知识卡',
      accentColor: colors.study,
    );
  }
}

class KnowledgeMoreActionRow extends StatelessWidget {
  const KnowledgeMoreActionRow({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.textPrimary),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.body.copyWith(color: colors.textPrimary)),
      ],
    );
  }
}

// =============================================================================
// Card Source Reference Widgets
// =============================================================================

class CardSourceReferences extends ConsumerWidget {
  const CardSourceReferences({super.key, required this.cardId});

  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final references = ref.watch(knowledgeCardSourceReferencesProvider(cardId));

    return references.when(
      data: (refs) {
        if (refs.isEmpty) return const SizedBox.shrink();
        return SourceReferencePanel(references: refs);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class SourceReferencePanel extends StatelessWidget {
  const SourceReferencePanel({super.key, required this.references});

  final List<KnowledgeCardSourceReference> references;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '知识来源',
            style: AppTextStyles.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final ref in references)
            SourceReferenceTile(reference: ref),
        ],
      ),
    );
  }
}

class SourceReferenceTile extends StatelessWidget {
  const SourceReferenceTile({super.key, required this.reference});

  final KnowledgeCardSourceReference reference;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, size: 14, color: colors.study),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  reference.source.title,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              reference.chunk.content,
              style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class PreviewBlock extends StatelessWidget {
  const PreviewBlock({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: MarkdownBody(
        data: content,
        styleSheet: MarkdownStyleSheet(
          p: AppTextStyles.caption.copyWith(color: colors.textPrimary),
        ),
        extensionSet: md.ExtensionSet.gitHubFlavored,
      ),
    );
  }
}

// =============================================================================
// Bulk Move Dialog
// =============================================================================

class BulkMoveTargetDialog extends StatefulWidget {
  const BulkMoveTargetDialog({super.key, this.customTemplates});

  final List<KnowledgeCustomTemplateBundle>? customTemplates;

  @override
  State<BulkMoveTargetDialog> createState() => _BulkMoveTargetDialogState();
}

class _BulkMoveTargetDialogState extends State<BulkMoveTargetDialog> {
  String? _selectedGoalKey;
  String? _selectedModuleKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return AlertDialog(
      title: const Text('移动到...'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择目标',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final goal in KnowledgeCardAssets.goalTemplates)
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    child: GestureDetector(
                      onTap: () {
                        final modules = goal.modules.toList();
                        setState(() {
                          _selectedGoalKey = goal.key;
                          _selectedModuleKey = modules.isNotEmpty ? modules.first.key : null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedGoalKey == goal.key
                              ? colors.study.withValues(alpha: 0.15)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: _selectedGoalKey == goal.key
                                ? colors.study
                                : colors.border,
                          ),
                        ),
                        child: Text(
                          goal.name,
                          style: AppTextStyles.caption.copyWith(
                            color: _selectedGoalKey == goal.key
                                ? colors.study
                                : colors.textPrimary,
                            fontWeight: _selectedGoalKey == goal.key
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_selectedGoalKey != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '选择模块',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final module in _getModules())
                    Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedModuleKey = module.key);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedModuleKey == module.key
                                ? colors.study.withValues(alpha: 0.15)
                                : colors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: _selectedModuleKey == module.key
                                  ? colors.study
                                  : colors.border,
                            ),
                          ),
                          child: Text(
                            module.name,
                            style: AppTextStyles.caption.copyWith(
                              color: _selectedModuleKey == module.key
                                  ? colors.study
                                  : colors.textPrimary,
                              fontWeight: _selectedModuleKey == module.key
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _selectedGoalKey != null && _selectedModuleKey != null
              ? () {
                  final goal = KnowledgeCardAssets.goalForKey(_selectedGoalKey!);
                  final module = _getModules().firstWhere(
                    (m) => m.key == _selectedModuleKey,
                  );
                  Navigator.pop(
                    context,
                    BulkMoveTarget(
                      deckKey: module.deckKey,
                      goalKey: _selectedGoalKey!,
                      moduleKey: _selectedModuleKey!,
                      displayName: '${goal.name} / ${module.name}',
                    ),
                  );
                }
              : null,
          child: const Text('确认移动'),
        ),
      ],
    );
  }

  List<KnowledgeGoalModuleVisual> _getModules() {
    if (_selectedGoalKey == null) return [];
    final goal = KnowledgeCardAssets.goalForKey(_selectedGoalKey!);
    return goal.modules.toList();
  }
}

class BulkMoveTarget {
  const BulkMoveTarget({
    required this.deckKey,
    required this.goalKey,
    required this.moduleKey,
    required this.displayName,
    this.goalName,
    this.moduleName,
  });

  final String deckKey;
  final String goalKey;
  final String? goalName;
  final String moduleKey;
  final String? moduleName;
  final String displayName;
}
