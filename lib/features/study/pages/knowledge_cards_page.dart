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
    final reviewStats = ref.watch(knowledgeReviewStatsProvider);
    final knowledgeOverview = ref.watch(knowledgeBaseOverviewProvider);

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
            ref.invalidate(knowledgeReviewStatsProvider);
            ref.invalidate(knowledgeGoalSummariesProvider);
            ref.invalidate(knowledgeDeckSummariesProvider);
            ref.invalidate(knowledgeCustomTemplatesProvider);
            ref.invalidate(knowledgeBaseOverviewProvider);
                  },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              KnowledgeHeroSection(
                reviewStats: reviewStats,
                overview: knowledgeOverview,
                onReviewDue: () => context.push('/plan/study/knowledge/review'),
                onReviewAll: () =>
                    context.push('/plan/study/knowledge/review?all=1'),
                onImport: () => context.push('/plan/study/knowledge/import'),
                onAdd: () => context.push('/plan/study/knowledge/add'),
                onOpenSources: () =>
                    context.push('/plan/study/knowledge/sources'),
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
                    onEdit: _editCard,
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
      filtered = filtered
          .where((c) => c.goalKey == _selectedGoalFilter)
          .toList();
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
    ref.invalidate(knowledgeReviewStatsProvider);
    ref.invalidate(knowledgeBaseOverviewProvider);
    ref.invalidate(knowledgeGoalSummariesProvider);
    ref.invalidate(knowledgeDeckSummariesProvider);
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
              style: AppTextStyles.cardTitle.copyWith(
                color: colors.textPrimary,
              ),
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
            style: TextButton.styleFrom(
              foregroundColor: context.growthColors.danger,
            ),
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
            style: TextButton.styleFrom(
              foregroundColor: context.growthColors.danger,
            ),
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

  void _editCard(KnowledgeCard card) {
    context.push('/plan/study/knowledge/add?editCardId=${card.id}');
  }
}

enum KnowledgeMoreAction { export, archive }

// =============================================================================
// Hero / Stats Widgets
// =============================================================================

class KnowledgeHeroSection extends StatelessWidget {
  const KnowledgeHeroSection({
    super.key,
    required this.reviewStats,
    required this.overview,
    required this.onReviewDue,
    required this.onReviewAll,
    required this.onImport,
    required this.onAdd,
    required this.onOpenSources,
  });

  final AsyncValue<KnowledgeCardReviewStats> reviewStats;
  final AsyncValue<KnowledgeBaseOverview> overview;
  final VoidCallback onReviewDue;
  final VoidCallback onReviewAll;
  final VoidCallback onImport;
  final VoidCallback onAdd;
  final VoidCallback onOpenSources;

  @override
  Widget build(BuildContext context) {
    return reviewStats.when(
      data: (stats) => overview.when(
        data: (data) => KnowledgeReviewHero(
          stats: stats,
          overview: data,
          onReviewDue: onReviewDue,
          onReviewAll: onReviewAll,
          onImport: onImport,
          onAdd: onAdd,
          onOpenSources: onOpenSources,
        ),
        loading: () => const KnowledgeHeroSkeleton(),
        error: (_, _) => const KnowledgeHeroSkeleton(),
      ),
      loading: () => const KnowledgeHeroSkeleton(),
      error: (_, _) => const KnowledgeHeroSkeleton(),
    );
  }
}

class KnowledgeReviewHero extends StatelessWidget {
  const KnowledgeReviewHero({
    super.key,
    required this.stats,
    required this.overview,
    required this.onReviewDue,
    required this.onReviewAll,
    required this.onImport,
    required this.onAdd,
    required this.onOpenSources,
  });

  final KnowledgeCardReviewStats stats;
  final KnowledgeBaseOverview overview;
  final VoidCallback onReviewDue;
  final VoidCallback onReviewAll;
  final VoidCallback onImport;
  final VoidCallback onAdd;
  final VoidCallback onOpenSources;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final totalCards = stats.totalCards;
    final primaryAction = _heroPrimaryAction();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final isMedium = constraints.maxWidth < 560;
        final heroRatio = isCompact ? 1.0 : (isMedium ? 1.18 : 16 / 9);
        final horizontalPadding = isCompact ? AppSpacing.md : AppSpacing.lg;
        final contentWidth = isCompact ? constraints.maxWidth : 360.0;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.12),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
            child: AspectRatio(
              aspectRatio: heroRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    KnowledgeCardAssets.entryWide,
                    fit: BoxFit.cover,
                    cacheWidth: 1400,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
                  ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          colors.card.withValues(alpha: 0.98),
                          colors.card.withValues(alpha: 0.88),
                          colors.card.withValues(alpha: 0.18),
                        ],
                      ),
                      border: Border.all(color: colors.border),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '知识抽卡',
                              style: AppTextStyles.pageTitle.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _heroSubtitle(),
                              style: AppTextStyles.body.copyWith(
                                color: colors.textSecondary,
                                height: 1.42,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                _HeroMetricChip(
                                  label: '总卡片',
                                  value: '$totalCards',
                                  asset: KnowledgeCardAssets.badgeMastered,
                                ),
                                _HeroMetricChip(
                                  label: '待复习',
                                  value: '${stats.dueCards}',
                                  asset: KnowledgeCardAssets.badgeDueCards,
                                ),
                                _HeroMetricChip(
                                  label: '薄弱点',
                                  value: '${stats.weakCards}',
                                  asset: KnowledgeCardAssets.badgeWeakPoints,
                                ),
                                _HeroMetricChip(
                                  label: '资料',
                                  value: overview.sourceCount.toString(),
                                  icon: Icons.auto_stories_rounded,
                                  tint: colors.study,
                                ),
                                if (overview.pendingChunkCount > 0)
                                  _HeroMetricChip(
                                    label: '待沉淀',
                                    value: '${overview.pendingChunkCount}',
                                    icon: Icons.auto_awesome_rounded,
                                    tint: colors.warning,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FilledButton.icon(
                              onPressed: primaryAction.onTap,
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.study,
                                foregroundColor: colors.textOnAccent,
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                              icon: Icon(primaryAction.icon, size: 18),
                              label: Text(primaryAction.label),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                _HeroGhostAction(
                                  icon: Icons.library_books_rounded,
                                  label: '本地知识库',
                                  onTap: onOpenSources,
                                ),
                                _HeroGhostAction(
                                  icon: Icons.upload_file_rounded,
                                  label: '导入资料',
                                  onTap: onImport,
                                ),
                                _HeroGhostAction(
                                  icon: Icons.add_card_rounded,
                                  label: '添加知识卡',
                                  onTap: onAdd,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _HeroPrimaryAction _heroPrimaryAction() {
    if (stats.totalCards == 0) {
      return _HeroPrimaryAction(
        label: '从资料开始建卡',
        icon: Icons.upload_file_rounded,
        onTap: onImport,
      );
    }
    if (stats.dueCards > 0) {
      return _HeroPrimaryAction(
        label: '复习 ${stats.dueCards} 张卡片',
        icon: Icons.style_rounded,
        onTap: onReviewDue,
      );
    }
    return _HeroPrimaryAction(
      label: '开始一轮总复习',
      icon: Icons.play_arrow_rounded,
      onTap: onReviewAll,
    );
  }

  String _heroSubtitle() {
    if (stats.totalCards == 0) {
      return '先把资料留在本地知识库，AI 只读取你确认过的片段来生成知识卡。';
    }
    if (stats.dueCards > 0) {
      return '今天有 ${stats.dueCards} 张卡片待复习，当前知识库共关联 ${overview.sourceCount} 份资料。';
    }
    if (overview.pendingChunkCount > 0) {
      return '卡片复习节奏已经稳定，还有 ${overview.pendingChunkCount} 个片段可以继续沉淀成新卡。';
    }
    return '目前没有到期卡片，继续补充资料或做一轮总复习都很合适。';
  }
}

class _HeroPrimaryAction {
  const _HeroPrimaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _HeroMetricChip extends StatelessWidget {
  const _HeroMetricChip({
    required this.label,
    required this.value,
    this.asset,
    this.icon,
    this.tint,
  });

  final String label;
  final String value;
  final String? asset;
  final IconData? icon;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final accent = tint ?? colors.study;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asset != null)
            Image.asset(asset!, width: 20, height: 20, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined, size: 16, color: Colors.grey),
            ),
          )
          else if (icon != null)
            Icon(icon, size: 18, color: accent),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HeroGhostAction extends StatelessWidget {
  const _HeroGhostAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: colors.border.withValues(alpha: 0.75)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.study),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KnowledgeHeroSkeleton extends StatelessWidget {
  const KnowledgeHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      height: 220,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 28,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 260,
            height: 16,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: List.generate(
              4,
              (_) => Container(
                width: 88,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
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
    final weakExcludingUnreviewed = stats.weakCards > stats.unreviewedCards
        ? stats.weakCards - stats.unreviewedCards
        : 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '学习健康度',
                style: AppTextStyles.sectionTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '均值 ${stats.averageMastery.toStringAsFixed(1)}/5',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            weakExcludingUnreviewed > 0
                ? '$weakExcludingUnreviewed 张卡片已经暴露薄弱点，建议先做一轮薄弱复习。'
                : stats.unreviewedCards > 0
                ? '还有 ${stats.unreviewedCards} 张卡片尚未开始复习，先抽几张熟悉一下。'
                : '当前卡片状态稳定，继续保持复习节奏就好。',
            style: AppTextStyles.caption.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: HealthMetricTile(
                  asset: KnowledgeCardAssets.badgeMastered,
                  label: '已掌握',
                  value: '${stats.masteredCards}',
                  color: colors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HealthMetricTile(
                  asset: KnowledgeCardAssets.badgeWeakPoints,
                  label: '薄弱点',
                  value: '${stats.weakCards}',
                  color: colors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HealthMetricTile(
                  asset: KnowledgeCardAssets.badgeDueCards,
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
    final unreviewed = stats.unreviewedCards;
    final weak = stats.weakCards > unreviewed
        ? stats.weakCards - unreviewed
        : 0;
    final learning = stats.totalCards - stats.masteredCards - weak - unreviewed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '掌握度分布',
          style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 10,
            child: stats.totalCards == 0
                ? ColoredBox(color: colors.border)
                : Row(
                    children: [
                      _DistributionBarPart(
                        value: stats.masteredCards,
                        color: colors.success,
                      ),
                      _DistributionBarPart(value: weak, color: colors.warning),
                      _DistributionBarPart(
                        value: unreviewed,
                        color: colors.textTertiary,
                      ),
                      _DistributionBarPart(
                        value: learning > 0 ? learning : 0,
                        color: colors.study.withValues(alpha: 0.45),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            _DistributionLegend(
              label: '已掌握 ${stats.masteredCards}',
              color: colors.success,
            ),
            _DistributionLegend(
              label: '薄弱 ${stats.weakCards}',
              color: colors.warning,
            ),
            _DistributionLegend(
              label: '未复习 ${stats.unreviewedCards}',
              color: colors.textTertiary,
            ),
          ],
        ),
      ],
    );
  }
}

class _DistributionBarPart extends StatelessWidget {
  const _DistributionBarPart({required this.value, required this.color});

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

class _DistributionLegend extends StatelessWidget {
  const _DistributionLegend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: context.growthColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class HealthMetricTile extends StatelessWidget {
  const HealthMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.asset,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final String? asset;
  final IconData? icon;

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
          if (asset != null)
            Image.asset(asset!, width: 24, height: 24, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined, size: 16, color: Colors.grey),
            ),
          )
          else if (icon != null)
            Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.sectionTitle.copyWith(color: color)),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.warning.withValues(alpha: 0.18),
              colors.card.withValues(alpha: 0.88),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: colors.warning.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(
              color: colors.warning.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  KnowledgeCardAssets.badgeWeakPoints,
                  fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
                ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weakCards.length} 张薄弱卡片',
                    style: AppTextStyles.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '建议优先清掉已经暴露的薄弱点，先做一轮针对性复习。',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '立即复习',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colors.warning,
                    size: 14,
                  ),
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
          style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary),
        ),
        if (action != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(action!, style: TextStyle(color: colors.study)),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 760 ? 2 : 1;
        if (crossAxisCount == 1) {
          return Column(
            children: [
              for (var index = 0; index < summaries.length; index++) ...[
                GoalCard(summary: summaries[index]),
                if (index != summaries.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.92,
          ),
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            return GoalCard(summary: summaries[index]);
          },
        );
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
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xxl),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  visual.asset,
                  fit: BoxFit.cover,
                  cacheWidth: 900,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
                ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          summary.displayName,
                          style: AppTextStyles.body.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (summary.dueCards > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        DueBadge(count: summary.dueCards),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    visual.subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _GoalMetaPill(
                        icon: Icons.style_rounded,
                        text: '${summary.totalCards} 张卡片',
                      ),
                      _GoalMetaPill(
                        icon: Icons.dashboard_customize_rounded,
                        text: '${summary.moduleCount} 个模块',
                      ),
                      _GoalMetaPill(
                        icon: Icons.psychology_rounded,
                        text:
                            '掌握 ${summary.averageMastery.toStringAsFixed(1)}/5',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalMetaPill extends StatelessWidget {
  const _GoalMetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.study),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
        ],
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
    required this.onEdit,
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
  final ValueChanged<KnowledgeCard> onEdit;
  final ValueChanged<KnowledgeCard> onArchive;
  final ValueChanged<KnowledgeCard>? onPreview;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  hintText: '搜索知识卡...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colors.textTertiary,
                  ),
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text(
                    '共 ${allCards.length} 张卡片',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    query.isEmpty && selectedGoalFilter == null
                        ? '当前显示全部'
                        : '当前筛出 ${cards.length} 张',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GoalFilterChips(
          selectedGoal: selectedGoalFilter,
          onSelected: onGoalSelected,
        ),
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
        if (cards.isEmpty)
          const EmptyKnowledgeCardsPanel()
        else
          for (final card in cards)
            KnowledgeCardManageTile(
              card: card,
              bulkMode: bulkMode,
              selected: selectedCardIds.contains(card.id),
              onToggle: () => onToggleSelected(card.id),
              onEdit: () => onEdit(card),
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
          border: Border.all(color: selected ? colors.study : colors.border),
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
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.study.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_rounded, size: 18, color: colors.study),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '已选择 $selectedCount 张',
                style: AppTextStyles.body.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onSelectAll, child: const Text('全选')),
              TextButton(onPressed: onClear, child: const Text('清除')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _BulkActionButton(
                label: '归档所选',
                icon: Icons.archive_outlined,
                enabled: selectedCount > 0,
                onTap: onArchive,
              ),
              _BulkActionButton(
                label: '改章节/单元',
                icon: Icons.edit_note_rounded,
                enabled: selectedCount > 0,
                onTap: onEditSubject,
              ),
              _BulkActionButton(
                label: '移动目标/模块',
                icon: Icons.swap_horiz_rounded,
                enabled: selectedCount > 0,
                onTap: onMove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  const _BulkActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(99),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: enabled ? colors.card : colors.card.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled ? colors.study : colors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: enabled ? colors.textPrimary : colors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
    required this.onEdit,
    required this.onArchive,
    this.onPreview,
  });

  final KnowledgeCard card;
  final bool bulkMode;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isDue = card.dueAt <= nowMs;
    final statusColor = isMasteredKnowledgeCard(card)
        ? colors.success
        : isWeakKnowledgeCard(card)
        ? colors.warning
        : colors.study;
    final subjectText = _subjectText();

    return Container(
      key: ValueKey('knowledge-card-manage-tile-${card.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: selected ? colors.study : colors.border,
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: bulkMode ? onToggle : onPreview,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bulkMode) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => onToggle(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: AppTextStyles.body.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      card.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (subjectText != null)
                          _CardMetaPill(
                            icon: Icons.bookmark_outline_rounded,
                            label: subjectText,
                          ),
                        _CardMetaPill(
                          icon: isDue
                              ? Icons.schedule_rounded
                              : Icons.event_available_rounded,
                          label: isDue ? '待复习' : '未到期',
                          tint: isDue ? colors.warning : colors.success,
                        ),
                        _CardMetaPill(
                          icon: Icons.psychology_rounded,
                          label: card.reviewCount == 0
                              ? '未复习'
                              : '掌握 ${card.masteryLevel}/5',
                          tint: statusColor,
                        ),
                      ],
                    ),
                    if (!bulkMode) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _InlineActionChip(
                            icon: Icons.visibility_outlined,
                            label: '预览',
                            onTap: onPreview,
                          ),
                          _InlineActionChip(
                            icon: Icons.edit_outlined,
                            label: '编辑',
                            onTap: onEdit,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!bulkMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onArchive,
                      icon: Icon(
                        Icons.archive_outlined,
                        color: colors.textTertiary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.textTertiary,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _subjectText() {
    final candidates = [
      card.subject,
      card.moduleName,
      card.goalName,
      card.moduleKey,
    ];
    for (final value in candidates) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }
}

class _InlineActionChip extends StatelessWidget {
  const _InlineActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colors.study),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardMetaPill extends StatelessWidget {
  const _CardMetaPill({required this.icon, required this.label, this.tint});

  final IconData icon;
  final String label;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final chipTint = tint ?? colors.study;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: chipTint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: chipTint.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipTint),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyKnowledgeCardsPanel extends StatelessWidget {
  const EmptyKnowledgeCardsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                KnowledgeCardAssets.emptyCards,
                fit: BoxFit.cover,
                cacheWidth: 900,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
              ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '还没有知识卡',
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '从导入资料开始，AI 会先生成草稿，你确认后再进入本地知识卡片库。',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => context.push('/plan/study/knowledge/import'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.study,
                  foregroundColor: colors.textOnAccent,
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('导入资料'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/plan/study/knowledge/add'),
                icon: const Icon(Icons.add_card_rounded, size: 18),
                label: const Text('手动添加'),
              ),
            ],
          ),
        ],
      ),
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
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: colors.textPrimary),
        ),
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
          for (final ref in references) SourceReferenceTile(reference: ref),
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
                          _selectedModuleKey = modules.isNotEmpty
                              ? modules.first.key
                              : null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                  final goal = KnowledgeCardAssets.goalForKey(
                    _selectedGoalKey!,
                  );
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
