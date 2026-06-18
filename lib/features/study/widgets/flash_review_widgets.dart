import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/knowledge_source_provider.dart';
import '../services/knowledge_card_ai_service.dart';
import '../utils/knowledge_card_assets.dart';

// =============================================================================
// Review Flash Card
// =============================================================================

class ReviewFlashCard extends StatelessWidget {
  const ReviewFlashCard({
    super.key,
    required this.card,
    required this.showAnswer,
    required this.onFlip,
  });

  final KnowledgeCard card;
  final bool showAnswer;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final visual = KnowledgeCardAssets.visualForKey(card.deckKey);
    final goalName = goalNameForCard(card);
    final moduleName = moduleNameForCard(card);
    final chapterName = chapterNameForCard(card);
    final tags = decodeTags(card.tags);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onFlip,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        child: AnimatedContainer(
          duration: AppMotion.normal,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.16),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      visual.asset,
                      fit: BoxFit.cover,
                      cacheWidth: 620,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DeckPill(text: goalName),
                    _DeckPill(text: moduleName),
                    if (chapterName != null) _DeckPill(text: chapterName),
                    _DeckPill(text: visual.name),
                    _DeckPill(text: '掌握 ${card.masteryLevel}/5'),
                    for (final tag in tags.take(2)) _DeckPill(text: '#$tag'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  card.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        showAnswer
                            ? AnswerContent(card: card, tags: tags)
                            : QuestionContent(question: card.question),
                        if (showAnswer) ...[
                          const SizedBox(height: AppSpacing.md),
                          SourceReferenceSection(cardId: card.id),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    showAnswer ? '点击卡片可回到问题' : '点击卡片或按钮翻开答案',
                    style: TextStyle(color: colors.textTertiary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckPill extends StatelessWidget {
  const _DeckPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: TextStyle(color: colors.study, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class QuestionContent extends StatelessWidget {
  const QuestionContent({super.key, required this.question});
  final String question;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return MarkdownBody(
      data: question,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: colors.textPrimary, fontSize: 18, height: 1.55, fontWeight: FontWeight.w600),
        h1: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.textPrimary, height: 1.4),
        h2: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary, height: 1.4),
        h3: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary, height: 1.4),
        strong: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary),
        em: TextStyle(fontStyle: FontStyle.italic, color: colors.textPrimary),
        code: TextStyle(fontSize: 15, color: colors.study, backgroundColor: colors.surface, fontFamily: 'monospace'),
        codeblockDecoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.mlg),
          border: Border.all(color: colors.border),
        ),
        listBullet: TextStyle(color: colors.textPrimary, fontSize: 18),
      ),
    );
  }
}

class AnswerContent extends StatelessWidget {
  const AnswerContent({super.key, required this.card, required this.tags});
  final KnowledgeCard card;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: card.answer,
          selectable: true,
          extensionSet: md.ExtensionSet.gitHubFlavored,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(color: colors.textPrimary, fontSize: 17, height: 1.55, fontWeight: FontWeight.w600),
            h1: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.textPrimary, height: 1.4),
            h2: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary, height: 1.4),
            h3: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary, height: 1.4),
            strong: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary),
            em: TextStyle(fontStyle: FontStyle.italic, color: colors.textPrimary),
            code: TextStyle(fontSize: 14, color: colors.study, backgroundColor: colors.surface, fontFamily: 'monospace'),
            codeblockDecoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.mlg),
              border: Border.all(color: colors.border),
            ),
            listBullet: TextStyle(color: colors.textPrimary, fontSize: 17),
          ),
        ),
        if (card.explanation != null && card.explanation!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.softBlue.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(AppRadius.mlg),
            ),
            child: MarkdownBody(
              data: card.explanation!,
              selectable: true,
              extensionSet: md.ExtensionSet.gitHubFlavored,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: colors.textSecondary, height: 1.45),
                strong: TextStyle(fontWeight: FontWeight.w700, color: colors.textSecondary),
                em: TextStyle(fontStyle: FontStyle.italic, color: colors.textSecondary),
                code: TextStyle(fontSize: 13, color: colors.study, backgroundColor: colors.surface, fontFamily: 'monospace'),
                listBullet: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ),
          ),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) => Chip(
              label: Text(tag),
              visualDensity: VisualDensity.compact,
              backgroundColor: colors.study.withValues(alpha: 0.10),
              side: BorderSide.none,
              labelStyle: TextStyle(color: colors.study),
            )).toList(growable: false),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Feedback Buttons
// =============================================================================

class FeedbackButtons extends StatelessWidget {
  const FeedbackButtons({super.key, required this.onSelected});
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final options = [
      _FeedbackOption('不会', 0, Icons.close_rounded, colors.danger),
      _FeedbackOption('模糊', 1, Icons.help_outline_rounded, colors.warning),
      _FeedbackOption('记得', 2, Icons.check_rounded, colors.study),
      _FeedbackOption('很熟', 3, Icons.bolt_rounded, colors.success),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: options.map((option) => _FeedbackButton(
        option: option,
        onTap: () => onSelected(option.quality),
      )).toList(growable: false),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({required this.option, required this.onTap});
  final _FeedbackOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return SizedBox(
      width: 150,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: option.color,
          side: BorderSide(color: option.color.withValues(alpha: 0.28)),
          backgroundColor: colors.card.withValues(alpha: 0.88),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mlg)),
        ),
        icon: Icon(option.icon, size: 18),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.label),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${option.quality + 1}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: option.color.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackOption {
  const _FeedbackOption(this.label, this.quality, this.icon, this.color);
  final String label;
  final int quality;
  final IconData icon;
  final Color color;
}

// =============================================================================
// Flip Button
// =============================================================================

class FlipButton extends StatelessWidget {
  const FlipButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.study,
          foregroundColor: colors.textOnAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mlg)),
        ),
        icon: const Icon(Icons.flip_rounded),
        label: const Text('翻开答案'),
      ),
    );
  }
}

// =============================================================================
// Review Complete Panel
// =============================================================================

class ReviewCompletePanel extends StatelessWidget {
  const ReviewCompletePanel({
    super.key,
    required this.results,
    required this.weakOnly,
    required this.onRestart,
    this.bestStreak = 0,
  });

  final List<ReviewSessionResult> results;
  final bool weakOnly;
  final VoidCallback onRestart;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final total = results.length;
    final wrong = _countQuality(0);
    final fuzzy = _countQuality(1);
    final remembered = _countQuality(2);
    final fluent = _countQuality(3);
    final due = _dueBuckets();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xxxl),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(KnowledgeCardAssets.goalReviewComplete, fit: BoxFit.cover, cacheWidth: 900),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          weakOnly ? '薄弱知识点复习完成' : '这组卡片复习完成',
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('本轮复习 $total 张，掌握度和下次复习时间已经更新。', textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
        if (bestStreak >= 3)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Center(
              child: Text('🔥 最佳连续答对 $bestStreak 题', style: TextStyle(fontWeight: FontWeight.w600, color: colors.warning)),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.35,
          children: [
            _ReviewStatTile(label: '不会', value: wrong, icon: Icons.close_rounded, color: colors.danger),
            _ReviewStatTile(label: '模糊', value: fuzzy, icon: Icons.help_outline_rounded, color: colors.warning),
            _ReviewStatTile(label: '记得', value: remembered, icon: Icons.check_rounded, color: colors.study),
            _ReviewStatTile(label: '很熟', value: fluent, icon: Icons.bolt_rounded, color: colors.success),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('下次复习分布', style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary)),
              const SizedBox(height: AppSpacing.md),
              _DueBucketRow(label: '24 小时内', count: due.today),
              _DueBucketRow(label: '1-7 天', count: due.thisWeek),
              _DueBucketRow(label: '7 天以后', count: due.later),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          onPressed: onRestart,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.study,
            foregroundColor: colors.textOnAccent,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mlg)),
          ),
          icon: const Icon(Icons.style_rounded),
          label: Text(weakOnly ? '再练薄弱点' : '再随机抽一组'),
        ),
      ],
    );
  }

  int _countQuality(int quality) => results.where((item) => item.quality == quality).length;

  _DueBuckets _dueBuckets() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneDay = const Duration(days: 1).inMilliseconds;
    final sevenDays = const Duration(days: 7).inMilliseconds;
    var today = 0, thisWeek = 0, later = 0;
    for (final result in results) {
      final diff = result.nextDueAt - now;
      if (diff <= oneDay) today++;
      else if (diff <= sevenDays) thisWeek++;
      else later++;
    }
    return _DueBuckets(today: today, thisWeek: thisWeek, later: later);
  }
}

class _DueBuckets {
  const _DueBuckets({required this.today, required this.thisWeek, required this.later});
  final int today, thisWeek, later;
}

class _ReviewStatTile extends StatelessWidget {
  const _ReviewStatTile({required this.label, required this.value, required this.icon, required this.color});
  final String label; final int value; final IconData icon; final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w700))),
          Text('$value', style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _DueBucketRow extends StatelessWidget {
  const _DueBucketRow({required this.label, required this.count});
  final String label; final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary))),
          Text('$count 张', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// =============================================================================
// Review Session Result
// =============================================================================

class ReviewSessionResult {
  const ReviewSessionResult({required this.quality, required this.nextDueAt});
  final int quality;
  final int nextDueAt;
}

// =============================================================================
// Mastery Progress Bar
// =============================================================================

class MasteryProgressBar extends StatelessWidget {
  const MasteryProgressBar({super.key, required this.stats});
  final KnowledgeCardReviewStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final unreviewed = stats.unreviewedCards;
    final weak = stats.weakCards > unreviewed ? stats.weakCards - unreviewed : 0;
    final learning = stats.totalCards - stats.masteredCards - weak - unreviewed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 10,
            child: stats.totalCards == 0
                ? ColoredBox(color: colors.border)
                : Row(
                    children: [
                      _BarPart(value: stats.masteredCards, color: colors.success),
                      _BarPart(value: weak, color: colors.warning),
                      _BarPart(value: unreviewed, color: colors.textTertiary),
                      _BarPart(value: learning > 0 ? learning : 0, color: colors.study.withValues(alpha: 0.45)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            _BarLegend(label: '已掌握 ${stats.masteredCards}', color: colors.success),
            _BarLegend(label: '薄弱 ${stats.weakCards}', color: colors.warning),
            _BarLegend(label: '未复习 ${stats.unreviewedCards}', color: colors.textTertiary),
          ],
        ),
      ],
    );
  }
}

class _BarPart extends StatelessWidget {
  const _BarPart({required this.value, required this.color});
  final int value; final Color color;

  @override
  Widget build(BuildContext context) {
    if (value <= 0) return const SizedBox.shrink();
    return Expanded(flex: value, child: ColoredBox(color: color));
  }
}

class _BarLegend extends StatelessWidget {
  const _BarLegend({required this.label, required this.color});
  final String label; final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption.copyWith(color: context.growthColors.textSecondary)),
      ],
    );
  }
}
class TodayHeroCard extends StatelessWidget {
  const TodayHeroCard({
    super.key,
    required this.dueCount,
    required this.weakCount,
    required this.reviewedToday,
    required this.totalDue,
    required this.averageMastery,
    required this.stats,
    required this.onStartReview,
    required this.onStartWeak,
  });

  final int dueCount;
  final int weakCount;
  final int reviewedToday;
  final int totalDue;
  final double averageMastery;
  final KnowledgeCardReviewStats stats;
  final VoidCallback onStartReview;
  final VoidCallback onStartWeak;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final percent = (averageMastery / 5 * 100).round();
    final learning = stats.totalCards - stats.masteredCards - stats.weakCards - stats.unreviewedCards;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          Row(
            children: [
              Icon(Icons.today_rounded, color: colors.study, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('今日复习', style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.study.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '掌握 $percent%',
                  style: TextStyle(color: colors.study, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '待复习 $dueCount 张  其中薄弱 $weakCount 张',
            style: AppTextStyles.bodySmall.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '已完成 $reviewedToday / $totalDue',
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          MasteryProgressBar(stats: stats),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                '已掌握 ${stats.masteredCards}',
                style: TextStyle(color: colors.success, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(' · ', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
              Text(
                '学习中 $learning',
                style: TextStyle(color: colors.study, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(' · ', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
              Text(
                '薄弱 ${stats.weakCards}',
                style: TextStyle(color: colors.warning, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: dueCount > 0 ? onStartReview : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.study,
                    foregroundColor: colors.textOnAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.mlg),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('开始今日复习'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: weakCount > 0 ? onStartWeak : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.warning,
                    side: BorderSide(color: colors.warning.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.mlg),
                    ),
                  ),
                  icon: const Icon(Icons.local_fire_department_rounded, size: 18),
                  label: const Text('薄弱强化'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Today Queue Preview
// =============================================================================

class TodayQueuePreview extends StatelessWidget {
  const TodayQueuePreview({
    super.key,
    required this.cards,
  });

  final List<KnowledgeCard> cards;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.queue_rounded, color: colors.study, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('今日队列', style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (cards.isEmpty)
            Text(
              '暂无待复习卡片',
              style: AppTextStyles.bodySmall.copyWith(color: colors.textTertiary),
            )
          else ...[
            for (final card in cards.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const Text('📌 ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        card.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (cards.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '查看全部 →',
                  style: TextStyle(color: colors.study, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
// =============================================================================
// Source Reference Section
// =============================================================================

class SourceReferenceSection extends ConsumerWidget {
  const SourceReferenceSection({super.key, required this.cardId});

  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final referencesAsync = ref.watch(knowledgeCardSourceReferencesProvider(cardId));

    return referencesAsync.when(
      data: (references) {
        if (references.isEmpty) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: colors.softBlue.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.mlg),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              title: Text(
                '来源引用',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              iconColor: colors.textTertiary,
              collapsedIconColor: colors.textTertiary,
              children: [
                for (final ref in references)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref.source.title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (ref.link.quote != null && ref.link.quote!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              ref.link.quote!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// =============================================================================
// Knowledge Card Slim Tile
// =============================================================================

class KnowledgeCardSlimTile extends StatelessWidget {
  const KnowledgeCardSlimTile({
    super.key,
    required this.card,
    required this.onTap,
    required this.onLongPress,
  });

  final KnowledgeCard card;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final goalName = goalNameForCard(card);
    final moduleName = moduleNameForCard(card);

    Color tagColor;
    String statusLabel;
    if (isMasteredKnowledgeCard(card)) {
      tagColor = colors.success;
      statusLabel = '已掌握';
    } else if (isWeakKnowledgeCard(card)) {
      tagColor = colors.warning;
      statusLabel = '待复习';
    } else {
      tagColor = colors.study;
      statusLabel = '学习中';
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(AppRadius.mlg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.question,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  '$goalName · $moduleName',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12),
                ),
                Text(
                  ' · 掌握 ${card.masteryLevel}/5',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: tagColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// =============================================================================
// Draft Summary Card (AI Import)
// =============================================================================

class DraftSummaryCard extends StatelessWidget {
  const DraftSummaryCard({
    super.key,
    required this.totalCount,
    required this.availableCount,
    required this.duplicateCount,
    required this.onImportAll,
    required this.onCheckOneByOne,
  });

  final int totalCount;
  final int availableCount;
  final int duplicateCount;
  final VoidCallback onImportAll;
  final VoidCallback onCheckOneByOne;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI 已生成 $totalCount 张',
            style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '可导入 $availableCount 张',
                style: TextStyle(color: colors.success, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                '  疑似重复 $duplicateCount 张',
                style: TextStyle(color: colors.warning, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: availableCount > 0 ? onImportAll : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.study,
                    foregroundColor: colors.textOnAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.mlg),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('全部导入'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCheckOneByOne,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.study,
                    side: BorderSide(color: colors.study.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.mlg),
                    ),
                  ),
                  icon: const Icon(Icons.checklist_rounded, size: 18),
                  label: const Text('逐张检查'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Draft Compact Tile (AI Import)
// =============================================================================

class DraftCompactTile extends StatelessWidget {
  const DraftCompactTile({
    super.key,
    required this.index,
    required this.draft,
    required this.selected,
    required this.duplicateReason,
    required this.onSelectionChanged,
  });

  final int index;
  final KnowledgeCardAiDraft draft;
  final bool selected;
  final String? duplicateReason;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final isDuplicate = duplicateReason != null && duplicateReason!.isNotEmpty;

    Color tagColor;
    String tagLabel;
    if (isDuplicate) {
      tagColor = colors.warning;
      tagLabel = '疑似重复';
    } else {
      tagColor = colors.success;
      tagLabel = '可用';
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Checkbox(
          value: selected,
          onChanged: (value) {
            if (value != null) onSelectionChanged(value);
          },
          activeColor: colors.study,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                draft.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                tagLabel,
                style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        subtitle: Text(
          draft.question,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
        ),
        iconColor: colors.textTertiary,
        collapsedIconColor: colors.textTertiary,
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        children: [
          if (isDuplicate)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                '⚠️ $duplicateReason',
                style: TextStyle(color: colors.warning, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          Text(
            draft.answer,
            style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.5),
          ),
          if (draft.explanation != null && draft.explanation!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.softBlue.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                draft.explanation!,
                style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

String goalNameForCard(KnowledgeCard card) {
  if (card.goalKey != 'custom') return KnowledgeCardAssets.goalForKey(card.goalKey).name;
  final customName = card.goalName?.trim();
  return customName == null || customName.isEmpty ? '自定义目标' : customName;
}

String moduleNameForCard(KnowledgeCard card) {
  final module = KnowledgeCardAssets.moduleForKeys(card.goalKey, card.moduleKey);
  if (module.deckKey != 'custom') return module.name;
  final customName = card.moduleName?.trim();
  return customName == null || customName.isEmpty ? module.name : customName;
}

String? chapterNameForCard(KnowledgeCard card) {
  final chapter = card.subject?.trim();
  if (chapter == null || chapter.isEmpty) return null;
  return '单元：$chapter';
}

List<String> decodeTags(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.map((item) => item.toString()).toList(growable: false);
  } catch (_) {}
  return const [];
}