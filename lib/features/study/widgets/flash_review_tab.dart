import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/knowledge_card_assets.dart';
import '../widgets/flash_review_widgets.dart';
import '../widgets/knowledge_ai_qa_sheet.dart';

/// 复习 Tab —— 用户 90% 时间在这里
class FlashReviewTab extends ConsumerStatefulWidget {
  const FlashReviewTab({super.key});

  @override
  ConsumerState<FlashReviewTab> createState() => _FlashReviewTabState();
}

class _FlashReviewTabState extends ConsumerState<FlashReviewTab> {
  bool _inReviewMode = false;
  var _showAnswer = false;
  var _loading = false;
  var _complete = false;
  var _index = 0;
  var _currentStreak = 0;
  var _bestStreak = 0;
  List<KnowledgeCard> _queue = [];
  final List<ReviewSessionResult> _sessionResults = [];
  String? _selectedGoalFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return ModulePageSurface(
      color: colors.study,
      child: Focus(
        autofocus: _inReviewMode,
        onKeyEvent: _inReviewMode ? _handleKeyEvent : null,
        child: AnimatedSwitcher(
          duration: AppMotion.normal,
          child: _inReviewMode ? _buildReviewMode() : _buildListMode(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // List Mode
  // ---------------------------------------------------------------------------

  Widget _buildListMode() {
    final stats = ref.watch(knowledgeReviewStatsProvider);
    final todayProgress = ref.watch(todayReviewProgressProvider);
    final recommended = ref.watch(aiRecommendedCardsProvider);
    final cards = ref.watch(knowledgeCardsProvider);
    final summaries = ref.watch(filteredKnowledgeGoalSummariesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(knowledgeCardsProvider);
        ref.invalidate(knowledgeReviewStatsProvider);
        ref.invalidate(todayReviewProgressProvider);
        ref.invalidate(aiRecommendedCardsProvider);
        ref.invalidate(knowledgeGoalSummariesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── 今日状态 ──
          todayProgress.when(
            data: (progress) => stats.when(
              data: (s) => TodayReviewCard(
                dueCount: progress.total,
                reviewedToday: progress.reviewed,
                averageMastery: s.averageMastery,
              ),
              loading: () => const CardSkeleton(height: 120),
              error: (_, _) => const SizedBox.shrink(),
            ),
            loading: () => const CardSkeleton(height: 120),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── AI 推荐 ──
          recommended.when(
            data: (items) => AiRecommendSection(
              cards: items,
              onCardTap: (card) => _startSingleCardReview(card),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 目标过滤 Chips ──
          summaries.when(
            data: (items) => _GoalFilterChips(
              selectedGoal: _selectedGoalFilter,
              onSelected: (key) => setState(() => _selectedGoalFilter = key),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 快捷操作按钮 ──
          cards.when(
            data: (allCards) {
              final filtered = _filterCards(allCards);
              final due = filtered.where((c) => c.dueAt <= DateTime.now().millisecondsSinceEpoch).toList();
              return _QuickReviewActions(
                dueCount: due.length,
                totalCount: filtered.length,
                onReviewDue: due.isEmpty ? null : () => _startReview(filtered, dueOnly: true),
                onReviewAll: filtered.isEmpty ? null : () => _startReview(filtered, dueOnly: false),
                onWeakReview: () => context.push('/plan/study/knowledge/review?weak=1'),
              );
            },
            loading: () => const CardSkeleton(height: 100),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 学习状态卡 ──
          stats.when(
            data: (s) => Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.growthColors.card.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(color: context.growthColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('掌握分布', style: AppTextStyles.sectionTitle.copyWith(color: context.growthColors.textPrimary)),
                  const SizedBox(height: AppSpacing.md),
                  MasteryProgressBar(stats: s),
                ],
              ),
            ),
            loading: () => const CardSkeleton(height: 120),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Review Mode
  // ---------------------------------------------------------------------------

  Widget _buildReviewMode() {
    if (_loading) return Center(child: CircularProgressIndicator(color: context.growthColors.study));
    if (_complete) {
      return ReviewCompletePanel(
        results: _sessionResults,
        weakOnly: false,
        onRestart: () => setState(() { _inReviewMode = false; _complete = false; }),
        bestStreak: _bestStreak,
      );
    }
    if (_queue.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.style_outlined,
        title: '没有卡片',
        subtitle: '先添加知识卡再开始复习。',
        accentColor: context.growthColors.study,
      );
    }

    final colors = context.growthColors;
    final card = _queue[_index];
    final progress = (_index + 1) / _queue.length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation(colors.study),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('${_index + 1}/${_queue.length}', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ReviewFlashCard(card: card, showAnswer: _showAnswer, onFlip: () => setState(() => _showAnswer = !_showAnswer)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_showAnswer) ...[
            FeedbackButtons(onSelected: _submitFeedback),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton.icon(
                onPressed: () => _showAiQa(card),
                icon: Icon(Icons.auto_awesome_rounded, size: 16, color: colors.study),
                label: Text('问 AI', style: TextStyle(color: colors.study, fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: colors.study.withValues(alpha: 0.3))),
                ),
              ),
            ),
          ] else
            Center(child: FlipButton(onTap: () => setState(() => _showAnswer = true))),
          const SizedBox(height: AppSpacing.sm),
          Center(child: Text(_showAnswer ? '按 1-4 评价 · 空格翻回' : '按空格翻开答案', style: TextStyle(fontSize: 11, color: colors.textTertiary))),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _inReviewMode = false),
              icon: Icon(Icons.arrow_back_rounded, size: 16, color: colors.textTertiary),
              label: Text('返回列表', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  List<KnowledgeCard> _filterCards(List<KnowledgeCard> cards) {
    if (_selectedGoalFilter == null) return cards;
    return cards.where((c) => c.goalKey == _selectedGoalFilter).toList();
  }

  void _startSingleCardReview(KnowledgeCard card) {
    setState(() {
      _inReviewMode = true;
      _queue = [card];
      _index = 0;
      _showAnswer = false;
      _complete = false;
      _loading = false;
      _sessionResults.clear();
      _currentStreak = 0;
      _bestStreak = 0;
    });
  }

  Future<void> _startReview(List<KnowledgeCard> allCards, {required bool dueOnly}) async {
    setState(() => _loading = true);

    var cards = dueOnly
        ? allCards.where((c) => c.dueAt <= DateTime.now().millisecondsSinceEpoch).toList()
        : List<KnowledgeCard>.from(allCards);

    if (cards.isEmpty && dueOnly) cards = List<KnowledgeCard>.from(allCards);
    cards.shuffle(Random(DateTime.now().millisecondsSinceEpoch));

    if (!mounted) return;
    setState(() {
      _queue = cards.take(30).toList();
      _index = 0;
      _showAnswer = false;
      _complete = false;
      _loading = false;
      _inReviewMode = true;
      _sessionResults.clear();
      _currentStreak = 0;
      _bestStreak = 0;
    });
  }

  Future<void> _submitFeedback(int quality) async {
    final card = _queue[_index];
    await ref.read(knowledgeCardRepositoryProvider).reviewCard(card: card, quality: quality);
    final updated = await ref.read(knowledgeCardRepositoryProvider).getCardById(card.id);
    final result = ReviewSessionResult(quality: quality, nextDueAt: updated?.dueAt ?? card.dueAt);

    ref.invalidate(knowledgeCardsProvider);
    ref.invalidate(knowledgeGoalSummariesProvider);
    ref.invalidate(dueKnowledgeCardsCountProvider);
    ref.invalidate(todayReviewProgressProvider);
    ref.invalidate(aiRecommendedCardsProvider);
    ref.invalidate(knowledgeReviewStatsProvider);

    if (!mounted) return;
    if (_index >= _queue.length - 1) {
      setState(() { _sessionResults.add(result); _complete = true; });
    } else {
      setState(() {
        _sessionResults.add(result);
        if (result.quality >= 2) { _currentStreak++; if (_currentStreak > _bestStreak) _bestStreak = _currentStreak; }
        else { _currentStreak = 0; }
        _index += 1;
        _showAnswer = false;
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.space) {
      if (!_complete && !_loading) setState(() => _showAnswer = !_showAnswer);
      return KeyEventResult.handled;
    }

    if (_showAnswer && !_complete) {
      if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) { _submitFeedback(0); return KeyEventResult.handled; }
      if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) { _submitFeedback(1); return KeyEventResult.handled; }
      if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) { _submitFeedback(2); return KeyEventResult.handled; }
      if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) { _submitFeedback(3); return KeyEventResult.handled; }
    }

    return KeyEventResult.ignored;
  }

  void _showAiQa(KnowledgeCard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KnowledgeAiQaSheet(card: card),
    );
  }
}

// =============================================================================
// Goal Filter Chips
// =============================================================================

class _GoalFilterChips extends StatelessWidget {
  const _GoalFilterChips({required this.selectedGoal, required this.onSelected});
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
          _FilterChip(label: '全部', selected: selectedGoal == null, onTap: () => onSelected(null), color: colors.study),
          const SizedBox(width: AppSpacing.sm),
          for (final goal in KnowledgeCardAssets.goalTemplates)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _FilterChip(label: goal.name, selected: selectedGoal == goal.key, onTap: () => onSelected(goal.key), color: colors.study),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, required this.color});
  final String label; final bool selected; final VoidCallback onTap; final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? color : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: selected ? color : colors.border),
        ),
        child: Text(label, style: AppTextStyles.caption.copyWith(color: selected ? Colors.white : colors.textPrimary)),
      ),
    );
  }
}

// =============================================================================
// Quick Review Actions
// =============================================================================

class _QuickReviewActions extends StatelessWidget {
  const _QuickReviewActions({required this.dueCount, required this.totalCount, required this.onReviewDue, required this.onReviewAll, required this.onWeakReview});
  final int dueCount; final int totalCount; final VoidCallback? onReviewDue; final VoidCallback? onReviewAll; final VoidCallback onWeakReview;

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
          Text('快速复习', style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onReviewDue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.study, foregroundColor: colors.textOnAccent, elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mlg)),
                  ),
                  icon: const Icon(Icons.style_rounded, size: 18),
                  label: Text('到期复习 $dueCount'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReviewAll,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mlg)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text('全部复习 $totalCount'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onWeakReview,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mlg)),
              ),
              icon: Icon(Icons.local_fire_department_rounded, size: 18, color: colors.warning),
              label: Text('薄弱复习', style: TextStyle(color: colors.warning)),
            ),
          ),
        ],
      ),
    );
  }
}
