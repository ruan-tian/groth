import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/knowledge_source_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../widgets/flash_review_widgets.dart';

/// 知识 Tab —— 卡片管理
class FlashKnowledgeTab extends ConsumerStatefulWidget {
  const FlashKnowledgeTab({super.key});

  @override
  ConsumerState<FlashKnowledgeTab> createState() => _FlashKnowledgeTabState();
}

class _FlashKnowledgeTabState extends ConsumerState<FlashKnowledgeTab> {
  String _debounceQuery = '';
  Timer? _debounceTimer;
  String _statusFilter = 'all';
  int _pageLimit = 30;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _debounceQuery = value;
        _pageLimit = 30;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final cards = ref.watch(knowledgeCardsProvider);
    final archivedCards = ref.watch(archivedKnowledgeCardsProvider);
    final sources = ref.watch(knowledgeSourcesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(knowledgeCardsProvider);
          ref.invalidate(archivedKnowledgeCardsProvider);
          ref.invalidate(knowledgeSourcesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── 搜索栏 ──
            TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '搜索知识卡...',
                prefixIcon: Icon(Icons.search_rounded, color: colors.textTertiary),
                filled: true, fillColor: colors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 资料入口 ──
            sources.when(
              data: (items) => InkWell(
                onTap: () => context.push('/plan/study/knowledge/sources'),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(Icons.library_books_outlined, size: 16, color: colors.study),
                      const SizedBox(width: AppSpacing.sm),
                      Text('本地资料库 · ${items.length} 份资料', style: AppTextStyles.caption.copyWith(color: colors.study, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, size: 16, color: colors.textTertiary),
                    ],
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── 状态过滤 Chips ──
            _buildStatusFilterChips(colors),
            const SizedBox(height: AppSpacing.md),

            // ── 卡片列表 ──
            _statusFilter == 'archived'
                ? archivedCards.when(
                    data: (items) => _buildCardList(items, colors, isArchived: true),
                    loading: () => const CardSkeleton(height: 220),
                    error: (_, _) => const ErrorRetryWidget(),
                  )
                : cards.when(
                    data: (items) => _buildCardList(_filterCards(items), colors),
                    loading: () => const CardSkeleton(height: 220),
                    error: (_, _) => const ErrorRetryWidget(),
                  ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plan/study/knowledge/add'),
        backgroundColor: colors.study,
        foregroundColor: colors.textOnAccent,
        child: const Icon(Icons.add_card_rounded),
      ),
    );
  }

  Widget _buildStatusFilterChips(AppThemeColors colors) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _statusChip('全部', 'all', colors),
          const SizedBox(width: AppSpacing.sm),
          _statusChip('待复习', 'due', colors),
          const SizedBox(width: AppSpacing.sm),
          _statusChip('薄弱', 'weak', colors),
          const SizedBox(width: AppSpacing.sm),
          _statusChip('已掌握', 'mastered', colors),
          const SizedBox(width: AppSpacing.sm),
          _statusChip('已归档', 'archived', colors),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String key, AppThemeColors colors) {
    final selected = _statusFilter == key;
    return GestureDetector(
      onTap: () => setState(() { _statusFilter = key; _pageLimit = 30; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? colors.study : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: selected ? colors.study : colors.border),
        ),
        child: Text(label, style: AppTextStyles.caption.copyWith(color: selected ? Colors.white : colors.textPrimary)),
      ),
    );
  }

  List<KnowledgeCard> _filterCards(List<KnowledgeCard> cards) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    var filtered = cards.where((c) => !c.archived).toList();

    switch (_statusFilter) {
      case 'due':
        filtered = filtered.where((c) => c.dueAt <= nowMs).toList();
        break;
      case 'weak':
        filtered = filtered.where(isWeakKnowledgeCard).toList();
        break;
      case 'mastered':
        filtered = filtered.where(isMasteredKnowledgeCard).toList();
        break;
    }

    if (_debounceQuery.isNotEmpty) {
      final q = _debounceQuery.toLowerCase();
      filtered = filtered.where((c) =>
        c.title.toLowerCase().contains(q) ||
        c.question.toLowerCase().contains(q) ||
        c.answer.toLowerCase().contains(q)
      ).toList();
    }

    return filtered.take(_pageLimit).toList();
  }

  Widget _buildCardList(List<KnowledgeCard> cards, AppThemeColors colors, {bool isArchived = false}) {
    if (cards.isEmpty) {
      return EmptyStateWidget(
        icon: isArchived ? Icons.inventory_2_outlined : Icons.style_outlined,
        title: isArchived ? '没有归档卡片' : '还没有知识卡',
        subtitle: isArchived ? '归档的卡片会出现在这里' : '从导入资料开始，AI 会自动生成知识卡。',
        accentColor: colors.study,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('共 ${cards.length} 张', style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: KnowledgeCardSlimTile(
                card: card,
                onTap: () => _showPreview(card),
                onLongPress: () => _showCardActions(card, isArchived),
              ),
            );
          },
        ),
        if (cards.length >= _pageLimit)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Center(
              child: TextButton(
                onPressed: () => setState(() => _pageLimit += 30),
                child: Text('加载更多', style: TextStyle(color: colors.study)),
              ),
            ),
          ),
      ],
    );
  }

  void _showCardActions(KnowledgeCard card, bool isArchived) {
    final colors = context.growthColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_outlined, color: colors.study),
              title: const Text('编辑'),
              onTap: () { Navigator.pop(ctx); context.push('/plan/study/knowledge/edit/${card.id}'); },
            ),
            ListTile(
              leading: Icon(isArchived ? Icons.restore_rounded : Icons.archive_outlined, color: colors.warning),
              title: Text(isArchived ? '恢复' : '归档'),
              onTap: () { Navigator.pop(ctx); isArchived ? _restoreCard(card) : _archiveCard(card); },
            ),
          ],
        ),
      ),
    );
  }

  void _showPreview(KnowledgeCard card) {
    final colors = context.growthColors;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.9, expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: AppSpacing.md), decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)))),
            Text(card.title, style: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            Text('问题', style: AppTextStyles.caption.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Text(card.question, style: AppTextStyles.body.copyWith(color: colors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            Text('答案', style: AppTextStyles.caption.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Text(card.answer, style: AppTextStyles.body.copyWith(color: colors.textPrimary)),
            if (card.explanation != null && card.explanation!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('解释', style: AppTextStyles.caption.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              Text(card.explanation!, style: AppTextStyles.body.copyWith(color: colors.textPrimary)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _archiveCard(KnowledgeCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.growthColors.card,
        surfaceTintColor: context.growthColors.card,
        title: const Text('归档知识卡'),
        content: Text('确定要归档「${card.title}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: context.growthColors.danger), child: const Text('归档')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(knowledgeCardRepositoryProvider).archiveCard(card.id);
    ref.invalidate(knowledgeCardsProvider);
    ref.invalidate(archivedKnowledgeCardsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('知识卡已归档')));
  }

  Future<void> _restoreCard(KnowledgeCard card) async {
    await ref.read(knowledgeCardRepositoryProvider).restoreCard(card.id);
    ref.invalidate(knowledgeCardsProvider);
    ref.invalidate(archivedKnowledgeCardsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('知识卡已恢复')));
  }
}
