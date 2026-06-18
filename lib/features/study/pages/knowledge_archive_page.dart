import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/knowledge_card_assets.dart';

class KnowledgeArchivePage extends ConsumerWidget {
  const KnowledgeArchivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final cards = ref.watch(archivedKnowledgeCardsProvider);

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: Text(
          '知识卡归档箱',
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
      ),
      body: ModulePageSurface(
        color: colors.study,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(archivedKnowledgeCardsProvider),
          child: cards.when(
            data: (items) {
              if (items.isEmpty) return const _EmptyArchivePanel();
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) => _ArchivedCardTile(
                  card: items[index],
                  onRestore: () => _restoreCard(context, ref, items[index]),
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CardSkeleton(height: 260),
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

  Future<void> _restoreCard(
    BuildContext context,
    WidgetRef ref,
    KnowledgeCard card,
  ) async {
    await ref.read(knowledgeCardRepositoryProvider).restoreCard(card.id);
    ref.invalidate(archivedKnowledgeCardsProvider);
    ref.invalidate(knowledgeCardsProvider);
    ref.invalidate(knowledgeGoalSummariesProvider);
    ref.invalidate(knowledgeDeckSummariesProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已恢复「${card.title}」')));
  }
}

class _ArchivedCardTile extends StatelessWidget {
  const _ArchivedCardTile({required this.card, required this.onRestore});

  final KnowledgeCard card;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final visual = KnowledgeCardAssets.visualForKey(card.deckKey);
    final goal = _goalNameForCard(card);
    final module = _moduleNameForCard(card);
    final chapter = card.subject?.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.asset(
              visual.asset,
              width: 72,
              height: 45,
              fit: BoxFit.cover,
              cacheWidth: 180,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    goal,
                    module,
                    if (chapter != null && chapter.isNotEmpty) chapter,
                    '掌握 ${card.masteryLevel}/5',
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary, height: 1.35),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.unarchive_rounded, size: 18),
                    label: const Text('恢复'),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '编辑',
            onPressed: () =>
                context.push('/plan/study/knowledge/edit/${card.id}'),
            icon: Icon(Icons.edit_rounded, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _EmptyArchivePanel extends StatelessWidget {
  const _EmptyArchivePanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl),
        EmptyStateWidget(
          icon: Icons.inventory_2_outlined,
          title: '归档箱是空的',
          subtitle: '归档的知识卡会暂时离开复习队列，并可以在这里恢复。',
          accentColor: colors.study,
        ),
      ],
    );
  }
}

String _goalNameForCard(KnowledgeCard card) {
  if (card.goalKey != 'custom') {
    return KnowledgeCardAssets.goalForKey(card.goalKey).name;
  }
  final customName = card.goalName?.trim();
  return customName == null || customName.isEmpty ? '自定义目标' : customName;
}

String _moduleNameForCard(KnowledgeCard card) {
  final module = KnowledgeCardAssets.moduleForKeys(
    card.goalKey,
    card.moduleKey,
  );
  if (module.deckKey != 'custom') return module.name;
  final customName = card.moduleName?.trim();
  return customName == null || customName.isEmpty ? module.name : customName;
}
