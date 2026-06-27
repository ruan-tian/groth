import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../knowledge/providers/knowledge_source_provider.dart';

const _knowledgeHomeIllustration =
    'assets/images/knowledge_cards/knowledge_home_tiantian.webp';

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
        final hasDue = data.dueCardCount > 0;
        final hasPendingChunks = pendingChunks > 0;
        final cardHeight = hasDue ? 164.0 : (hasPendingChunks ? 138.0 : 124.0);

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/plan/study/knowledge/sources'),
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              height: cardHeight,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.study.withValues(alpha: 0.12),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.study.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 72,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              colors.study.withValues(alpha: 0.13),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -10,
                      bottom: -14,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.9,
                          child: Image.asset(
                            _knowledgeHomeIllustration,
                            width: hasDue || hasPendingChunks ? 140 : 132,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        hasDue ? 12 : 14,
                        hasDue || hasPendingChunks ? 108 : 100,
                        hasDue ? 10 : 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: colors.study.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: colors.study.withValues(alpha: 0.16),
                                  ),
                                ),
                                child: Icon(
                                  Icons.auto_stories_rounded,
                                  size: 17,
                                  color: colors.study,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '知识库',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: hasDue ? 7 : 8),
                          Text(
                            data.statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: colors.textSecondary,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: hasDue ? 9 : 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _StatChip(
                                  label: '卡片',
                                  value: data.totalCardCount.toString(),
                                  color: colors.study,
                                ),
                                const SizedBox(width: 7),
                                _StatChip(
                                  label: '待复习',
                                  value: data.dueCardCount.toString(),
                                  color: hasDue
                                      ? colors.warning
                                      : colors.textSecondary,
                                ),
                                const SizedBox(width: 7),
                                _StatChip(
                                  label: '资料',
                                  value: data.sourceCount.toString(),
                                  color: colors.textSecondary,
                                ),
                                if (hasPendingChunks) ...[
                                  const SizedBox(width: 7),
                                  _StatChip(
                                    label: '待沉淀',
                                    value: pendingChunks.toString(),
                                    color: colors.accent,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (hasDue) ...[
                            const SizedBox(height: 8),
                            _ReviewPillButton(
                              label: '复习 ${data.dueCardCount} 张卡片',
                              onTap: () =>
                                  context.push('/plan/study/knowledge/review'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: colors.study.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ReviewPillButton extends StatelessWidget {
  const _ReviewPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: colors.study,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: colors.study.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.style_rounded, size: 15, color: colors.textOnAccent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: colors.textOnAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
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
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.border.withValues(alpha: 0.72)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              height: 1,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              height: 1.1,
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
