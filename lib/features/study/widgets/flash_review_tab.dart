import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/knowledge_card_assets.dart';
import '../widgets/flash_review_widgets.dart';
import '../widgets/knowledge_ai_qa_sheet.dart';

/// ��ϰ Tab ���� �û� 90% ʱ��������
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
  bool _showGoalFilter = false;

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
    final colors = context.growthColors;
    final stats = ref.watch(knowledgeReviewStatsProvider);
    final todayProgress = ref.watch(todayReviewProgressProvider);
    final recommended = ref.watch(aiRecommendedCardsProvider);
    final duePreview = ref.watch(dueCardsPreviewProvider);
    final summaries = ref.watch(filteredKnowledgeGoalSummariesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(knowledgeCardsProvider);
        ref.invalidate(knowledgeReviewStatsProvider);
        ref.invalidate(todayReviewProgressProvider);
        ref.invalidate(aiRecommendedCardsProvider);
        ref.invalidate(knowledgeGoalSummariesProvider);
        ref.invalidate(dueCardsPreviewProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ���� ���ո�ϰ���� ����
          todayProgress.when(
            data: (progress) => stats.when(
              data: (s) => recommended.when(
                data: (recItems) => TodayHeroCard(
                  dueCount: progress.total,
                  weakCount: recItems.where(isWeakKnowledgeCard).length,
                  reviewedToday: progress.reviewed,
                  totalDue: progress.total + progress.reviewed,
                  averageMastery: s.averageMastery,
                  stats: s,
                  onStartReview: () {
                    final allCards = ref.read(knowledgeCardsProvider).valueOrNull ?? [];
                    final due = allCards.where((c) => c.dueAt <= DateTime.now().millisecondsSinceEpoch).toList();
                    _startReview(due, dueOnly: true);
                  },
                  onStartWeak: () {
                    final allCards = ref.read(knowledgeCardsProvider).valueOrNull ?? [];
                    final weak = allCards.where(isWeakKnowledgeCard).toList();
                    _startReview(weak, dueOnly: false);
                  },
                ),
                loading: () => const CardSkeleton(height: 200),
                error: (_, _) => const SizedBox.shrink(),
              ),
              loading: () => const CardSkeleton(height: 200),
              error: (_, _) => const SizedBox.shrink(),
            ),
            loading: () => const CardSkeleton(height: 200),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),

          // ���� Ŀ��ɸѡ����ѡչ��������
          summaries.when(
            data: (items) => GestureDetector(
              onTap: () => setState(() => _showGoalFilter = !_showGoalFilter),
              child: Row(
                children: [
                  Text('��Ŀ��ɸѡ', style: AppTextStyles.caption.copyWith(color: colors.textTertiary)),
                  Icon(_showGoalFilter ? Icons.expand_less : Icons.expand_more, size: 16, color: colors.textTertiary),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          if (_showGoalFilter) ...[
            const SizedBox(height: AppSpacing.sm),
            summaries.when(
              data: (items) => _GoalFilterChips(
                selectedGoal: _selectedGoalFilter,
                onSelected: (key) => setState(() => _selectedGoalFilter = key),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // ���� ���ն���Ԥ�� ����
          duePreview.when(
            data: (items) => TodayQueuePreview(cards: items),
            loading: () => const CardSkeleton(height: 100),
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
        title: 'û�п�Ƭ',
        subtitle: '�����֪ʶ���ٿ�ʼ��ϰ��',
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
                label: Text('�� AI', style: TextStyle(color: colors.study, fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: colors.study.withValues(alpha: 0.3))),
                ),
              ),
            ),
          ] else
            Center(child: FlipButton(onTap: () => setState(() => _showAnswer = true))),
          const SizedBox(height: AppSpacing.sm),
          Center(child: Text(_showAnswer ? '�� 1-4 ���� �� �ո񷭻�' : '���ո񷭿���', style: TextStyle(fontSize: 11, color: colors.textTertiary))),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _inReviewMode = false),
              icon: Icon(Icons.arrow_back_rounded, size: 16, color: colors.textTertiary),
              label: Text('�����б�', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
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
    ref.invalidate(dueCardsPreviewProvider);

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
          _FilterChip(label: 'ȫ��', selected: selectedGoal == null, onTap: () => onSelected(null), color: colors.study),
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
