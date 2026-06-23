import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../knowledge/providers/knowledge_source_provider.dart';

/// Dashboard 知识库摘要卡片
///
/// 在首页展示知识库的关键指标：总卡片数、待复习、待沉淀片段。
/// 点击可跳转到知识库页面。
class DashboardKnowledgeSummaryCard extends ConsumerWidget {
  const DashboardKnowledgeSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final overview = ref.watch(knowledgeBaseOverviewProvider);

    return overview.when(
      data: (data) {
        // Don't show if no knowledge base content yet
        if (data.totalCardCount == 0 && data.sourceCount == 0) {
          return const SizedBox.shrink();
        }

        final pendingChunks = data.chunkCount - data.linkedChunkCount;

        return GestureDetector(
          onTap: () => context.push('/plan/study/knowledge/sources'),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.border, width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 20,
                      color: colors.study,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '知识库',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colors.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _StatChip(
                      label: '卡片',
                      value: data.totalCardCount.toString(),
                      color: colors.study,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _StatChip(
                      label: '待复习',
                      value: data.dueCardCount.toString(),
                      color: data.dueCardCount > 0
                          ? colors.warning
                          : colors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _StatChip(
                      label: '资料',
                      value: data.sourceCount.toString(),
                      color: colors.textSecondary,
                    ),
                    if (pendingChunks > 0) ...[
                      const SizedBox(width: AppSpacing.lg),
                      _StatChip(
                        label: '待沉淀',
                        value: pendingChunks.toString(),
                        color: colors.accent,
                      ),
                    ],
                  ],
                ),
                if (data.dueCardCount > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.push('/plan/study/knowledge/review'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.study,
                        foregroundColor: colors.textOnAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.style_rounded, size: 16),
                      label: Text(
                        '复习 ${data.dueCardCount} 张卡片',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.growthColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
