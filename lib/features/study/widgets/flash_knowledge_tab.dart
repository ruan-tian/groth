import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/knowledge_source_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/knowledge_card_assets.dart';

/// 知识 Tab —— 原材料仓库，弱化
class FlashKnowledgeTab extends ConsumerStatefulWidget {
  const FlashKnowledgeTab({super.key});

  @override
  ConsumerState<FlashKnowledgeTab> createState() => _FlashKnowledgeTabState();
}

class _FlashKnowledgeTabState extends ConsumerState<FlashKnowledgeTab> {
  String _query = '';
  String? _selectedGoalFilter;
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final cards = ref.watch(knowledgeCardsProvider);
    final archivedCards = ref.watch(archivedKnowledgeCardsProvider);
    final sources = ref.watch(knowledgeSourcesWithProgressProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(knowledgeCardsProvider);
        ref.invalidate(archivedKnowledgeCardsProvider);
        ref.invalidate(knowledgeSourcesWithProgressProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── 搜索栏 ──
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: '搜索知识卡...',
              prefixIcon: Icon(Icons.search_rounded, color: colors.textTertiary),
              filled: true, fillColor: colors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 分类过滤 Chips ──
          _buildFilterChips(colors),
          const SizedBox(height: AppSpacing.md),

          // ── 卡片列表 ──
          _showArchived
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
          const SizedBox(height: AppSpacing.md),

          // ── 折叠区：原始资料 ──
          _buildSourcesSection(colors, sources),
          const SizedBox(height: AppSpacing.md),

          // ── 底部操作栏 ──
          _buildBottomActions(colors),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppThemeColors colors) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('全部', null, colors),
          const SizedBox(width: AppSpacing.sm),
          for (final goal in KnowledgeCardAssets.goalTemplates) ...[
            _chip(goal.name, goal.key, colors),
            const SizedBox(width: AppSpacing.sm),
          ],
          _chip('归档箱', '__archived__', colors),
        ],
      ),
    );
  }

  Widget _chip(String label, String? key, AppThemeColors colors) {
    final selected = key == '__archived__' ? _showArchived : _selectedGoalFilter == key && !_showArchived;
    return GestureDetector(
      onTap: () => setState(() {
        if (key == '__archived__') { _showArchived = true; _selectedGoalFilter = null; }
        else { _showArchived = false; _selectedGoalFilter = key; }
      }),
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
    var filtered = cards;
    if (_selectedGoalFilter != null) filtered = filtered.where((c) => c.goalKey == _selectedGoalFilter).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered.where((c) => c.title.toLowerCase().contains(q) || c.question.toLowerCase().contains(q) || c.answer.toLowerCase().contains(q)).toList();
    }
    return filtered;
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
      children: [
        Row(children: [Text('共 ${cards.length} 张', style: AppTextStyles.caption.copyWith(color: colors.textSecondary))]),
        const SizedBox(height: AppSpacing.sm),
        for (final card in cards)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _KnowledgeCardTile(
              card: card,
              isArchived: isArchived,
              onEdit: isArchived ? null : () => context.push('/plan/study/knowledge/edit/${card.id}'),
              onArchive: isArchived ? () => _restoreCard(card) : () => _archiveCard(card),
              onPreview: () => _showPreview(card),
            ),
          ),
      ],
    );
  }

  Widget _buildSourcesSection(AppThemeColors colors, AsyncValue<List<KnowledgeSourceWithProgress>> sources) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          leading: Icon(Icons.library_books_rounded, color: colors.study),
          title: Text('原始资料', style: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary)),
          subtitle: sources.when(
            data: (items) => Text('${items.length} 份资料', style: AppTextStyles.caption),
            loading: () => const Text('加载中...'),
            error: (_, _) => const Text('加载失败'),
          ),
          children: [
            sources.when(
              data: (items) {
                if (items.isEmpty) return Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), child: Text('还没有导入资料', style: TextStyle(color: colors.textSecondary)));
                return Column(
                  children: [
                    for (final item in items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.article_outlined, color: colors.study, size: 20),
                        title: Text(item.source.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${item.progress.convertedChunkCount}/${item.progress.chunkCount} 片段已转卡', style: AppTextStyles.caption),
                        trailing: Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
                        onTap: () => context.push('/plan/study/knowledge/sources/${item.source.id}'),
                      ),
                  ],
                );
              },
              loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: CircularProgressIndicator())),
              error: (_, _) => const ErrorRetryWidget(),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/plan/study/knowledge/sources'),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('查看全部资料'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(AppThemeColors colors) {
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
          Text('快捷操作', style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ActionChip(icon: Icons.add_card_rounded, label: '手动添加', onTap: () => context.push('/plan/study/knowledge/add'), color: colors.study),
              _ActionChip(icon: Icons.upload_file_rounded, label: '批量导入', onTap: () => context.push('/plan/study/knowledge/import'), color: colors.study),
              _ActionChip(icon: Icons.file_download_outlined, label: '导出', onTap: () => context.push('/plan/study/knowledge/export'), color: colors.study),
              _ActionChip(icon: Icons.dashboard_customize_rounded, label: '自定义模板', onTap: () => context.push('/plan/study/knowledge/templates'), color: colors.study),
            ],
          ),
        ],
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
}

// =============================================================================
// Knowledge Card Tile
// =============================================================================

class _KnowledgeCardTile extends StatelessWidget {
  const _KnowledgeCardTile({required this.card, required this.isArchived, required this.onEdit, required this.onArchive, required this.onPreview});
  final KnowledgeCard card; final bool isArchived; final VoidCallback? onEdit; final VoidCallback? onArchive; final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isDue = card.dueAt <= nowMs;
    final statusColor = isMasteredKnowledgeCard(card) ? colors.success : isWeakKnowledgeCard(card) ? colors.warning : colors.study;

    return Container(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.border),
        boxShadow: [BoxShadow(color: colors.shadow.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: InkWell(
        onTap: onPreview,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.title, style: AppTextStyles.body.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              Text(card.question, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: colors.textSecondary, height: 1.4)),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: card.masteryLevel / 5, minHeight: 4, backgroundColor: colors.border, valueColor: AlwaysStoppedAnimation(statusColor)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm, runSpacing: AppSpacing.xs,
                children: [
                  _MetaPill(icon: isDue ? Icons.schedule_rounded : Icons.event_available_rounded, label: isDue ? '待复习' : '未到期', tint: isDue ? colors.warning : colors.success),
                  _MetaPill(icon: Icons.psychology_rounded, label: card.reviewCount == 0 ? '未复习' : '掌握 ${card.masteryLevel}/5', tint: statusColor),
                  _MetaPill(icon: Icons.replay_rounded, label: '复习 ${card.reviewCount} 次', tint: colors.textTertiary),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (onEdit != null) _InlineAction(icon: Icons.edit_outlined, label: '编辑', onTap: onEdit!),
                  const SizedBox(width: AppSpacing.sm),
                  _InlineAction(icon: isArchived ? Icons.restore_rounded : Icons.archive_outlined, label: isArchived ? '恢复' : '归档', onTap: onArchive),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, this.tint});
  final IconData icon; final String label; final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final chipTint = tint ?? colors.study;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: chipTint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: chipTint.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: chipTint),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(99), border: Border.all(color: colors.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: colors.study),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap, required this.color});
  final IconData icon; final String label; final VoidCallback onTap; final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}
