import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repositories/knowledge_source_repository.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/knowledge_source_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../widgets/knowledge_ai_qa_sheet.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/knowledge_card_assets.dart';

class KnowledgeReviewPage extends ConsumerStatefulWidget {
  const KnowledgeReviewPage({
    super.key,
    this.deckKey,
    this.goalKey,
    this.goalName,
    this.moduleKey,
    this.moduleName,
    this.includeAll = false,
    this.weakOnly = false,
  });

  final String? deckKey;
  final String? goalKey;
  final String? goalName;
  final String? moduleKey;
  final String? moduleName;
  final bool includeAll;
  final bool weakOnly;

  @override
  ConsumerState<KnowledgeReviewPage> createState() =>
      _KnowledgeReviewPageState();
}

class _KnowledgeReviewPageState extends ConsumerState<KnowledgeReviewPage> {
  var _loading = true;
  var _showAnswer = false;
  var _complete = false;
  var _usedAllCardsFallback = false;
  var _index = 0;
  var _currentStreak = 0;
  var _bestStreak = 0;
  List<KnowledgeCard> _queue = [];
  final List<_ReviewSessionResult> _sessionResults = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadQueue);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: Text(
          _pageTitle(),
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
      ),
      body: ModulePageSurface(
        color: colors.study,
        child: AnimatedSwitcher(
          duration: AppMotion.normal,
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: context.growthColors.study),
      );
    }
    if (_complete) {
      return _ReviewCompletePanel(
        results: _sessionResults,
        weakOnly: widget.weakOnly,
        onRestart: _restartWithAllCards,
        bestStreak: _bestStreak,
      );
    }
    if (_queue.isEmpty) {
      return _NoCardsPanel(
        deckKey: widget.deckKey,
        goalKey: widget.goalKey,
        goalName: widget.goalName,
        moduleKey: widget.moduleKey,
        moduleName: widget.moduleName,
        weakOnly: widget.weakOnly,
      );
    }

    final colors = context.growthColors;
    final card = _queue[_index];
    final progress = (_index + 1) / _queue.length;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;

        // Space: flip card
        if (key == LogicalKeyboardKey.space) {
          if (!_complete && !_loading) {
            setState(() => _showAnswer = !_showAnswer);
          }
          return KeyEventResult.handled;
        }

        // 1-4: rate card (only when answer is shown)
        if (_showAnswer && !_complete) {
          if (key == LogicalKeyboardKey.digit1 ||
              key == LogicalKeyboardKey.numpad1) {
            _submitFeedback(0);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.digit2 ||
              key == LogicalKeyboardKey.numpad2) {
            _submitFeedback(1);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.digit3 ||
              key == LogicalKeyboardKey.numpad3) {
            _submitFeedback(2);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.digit4 ||
              key == LogicalKeyboardKey.numpad4) {
            _submitFeedback(3);
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      child: SafeArea(
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
                Text(
                  '${_index + 1}/${_queue.length}',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (_usedAllCardsFallback) ...[
              const SizedBox(height: AppSpacing.md),
              _SoftNotice(text: '当前范围没有到期卡，已为你随机抽取全部卡片。'),
            ],
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _ReviewFlashCard(
                  card: card,
                  showAnswer: _showAnswer,
                  onFlip: () => setState(() => _showAnswer = !_showAnswer),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_showAnswer) ...[
              _FeedbackButtons(onSelected: _submitFeedback),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton.icon(
                  onPressed: () => _showAiQa(context, card),
                  icon: Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: colors.study,
                  ),
                  label: Text(
                    '问 AI',
                    style: TextStyle(
                      color: colors.study,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(
                        color: colors.study.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              _FlipButton(onTap: () => setState(() => _showAnswer = true)),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                _showAnswer ? '按 1-4 评价 · 空格翻回' : '按空格翻开答案',
                style: TextStyle(fontSize: 11, color: colors.textTertiary),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _loadQueue({bool includeAll = false}) async {
    final repo = ref.read(knowledgeCardRepositoryProvider);
    final allMode = includeAll || widget.includeAll;
    var cards = widget.weakOnly
        ? await repo.getWeakCards(
            deckKey: widget.deckKey,
            goalKey: widget.goalKey,
            goalName: widget.goalName,
            moduleKey: widget.moduleKey,
            moduleName: widget.moduleName,
            limit: 30,
          )
        : await repo.getReviewQueue(
            deckKey: widget.deckKey,
            goalKey: widget.goalKey,
            goalName: widget.goalName,
            moduleKey: widget.moduleKey,
            moduleName: widget.moduleName,
            dueOnly: !allMode,
            limit: 30,
          );

    var fallback = false;
    if (cards.isEmpty && !allMode && !widget.weakOnly) {
      cards = await repo.getReviewQueue(
        deckKey: widget.deckKey,
        goalKey: widget.goalKey,
        goalName: widget.goalName,
        moduleKey: widget.moduleKey,
        moduleName: widget.moduleName,
        dueOnly: false,
        limit: 30,
      );
      fallback = cards.isNotEmpty;
    }

    cards.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
    if (!mounted) return;
    setState(() {
      _queue = cards;
      _index = 0;
      _showAnswer = false;
      _complete = false;
      _sessionResults.clear();
      _currentStreak = 0;
      _bestStreak = 0;
      _usedAllCardsFallback = fallback;
      _loading = false;
    });
  }

  void _showAiQa(BuildContext context, KnowledgeCard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KnowledgeAiQaSheet(card: card),
    );
  }

  Future<void> _submitFeedback(int quality) async {
    final card = _queue[_index];
    await ref
        .read(knowledgeCardRepositoryProvider)
        .reviewCard(card: card, quality: quality);
    final updated = await ref
        .read(knowledgeCardRepositoryProvider)
        .getCardById(card.id);
    final result = _ReviewSessionResult(
      quality: quality,
      nextDueAt: updated?.dueAt ?? card.dueAt,
    );

    ref.invalidate(knowledgeCardsProvider);
    ref.invalidate(knowledgeGoalSummariesProvider);
    ref.invalidate(knowledgeDeckSummariesProvider);

    if (!mounted) return;
    if (_index >= _queue.length - 1) {
      setState(() {
        _sessionResults.add(result);
        _complete = true;
      });
    } else {
      setState(() {
        _sessionResults.add(result);
        if (result.quality >= 2) {
          _currentStreak++;
          if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;
        } else {
          _currentStreak = 0;
        }
        _index += 1;
        _showAnswer = false;
      });
    }
  }

  void _restartWithAllCards() {
    setState(() => _loading = true);
    _loadQueue(includeAll: true);
  }

  String _pageTitle() {
    final suffix = widget.weakOnly ? '薄弱复习' : '抽卡';
    if (widget.goalKey != null && widget.goalKey!.isNotEmpty) {
      final goal = KnowledgeCardAssets.goalForKey(widget.goalKey);
      if (goal.key == 'custom') {
        final customName = widget.goalName?.trim();
        return '${customName == null || customName.isEmpty ? goal.name : customName}$suffix';
      }
      return '${goal.name}$suffix';
    }
    if (widget.deckKey != null && widget.deckKey!.isNotEmpty) {
      final visual = KnowledgeCardAssets.visualForKey(widget.deckKey);
      return '${visual.name}$suffix';
    }
    return widget.weakOnly ? '薄弱知识点' : '知识抽卡';
  }
}

class _ReviewFlashCard extends StatelessWidget {
  const _ReviewFlashCard({
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
    final goalName = _goalNameForCard(card);
    final moduleName = _moduleNameForCard(card);
    final chapterName = _chapterNameForCard(card);
    final tags = _decodeTags(card.tags);

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
                    child: showAnswer
                        ? _AnswerContent(card: card, tags: tags)
                        : _QuestionContent(question: card.question),
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

  List<String> _decodeTags(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList(growable: false);
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }
}

class _QuestionContent extends StatelessWidget {
  const _QuestionContent({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return MarkdownBody(
      data: question,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          height: 1.55,
          fontWeight: FontWeight.w600,
        ),
        h1: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          height: 1.4,
        ),
        h2: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          height: 1.4,
        ),
        h3: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
          height: 1.4,
        ),
        strong: TextStyle(
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        em: TextStyle(
          fontStyle: FontStyle.italic,
          color: colors.textPrimary,
        ),
        code: TextStyle(
          fontSize: 15,
          color: colors.study,
          backgroundColor: colors.surface,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.mlg),
          border: Border.all(color: colors.border),
        ),
        listBullet: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
        ),
      ),
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

String? _chapterNameForCard(KnowledgeCard card) {
  final chapter = card.subject?.trim();
  if (chapter == null || chapter.isEmpty) return null;
  return '单元：$chapter';
}

String _excerpt(String content) {
  final trimmed = content.trim();
  if (trimmed.length <= 180) return trimmed;
  return '${trimmed.substring(0, 180)}...';
}

class _AnswerContent extends StatelessWidget {
  const _AnswerContent({required this.card, required this.tags});

  final KnowledgeCard card;
  final List<String> tags;

  static MarkdownStyleSheet _answerSheet(BuildContext context) {
    final colors = context.growthColors;
    return MarkdownStyleSheet(
      p: TextStyle(
        color: colors.textPrimary,
        fontSize: 17,
        height: 1.55,
        fontWeight: FontWeight.w600,
      ),
      h1: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.4,
      ),
      h2: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.4,
      ),
      h3: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.4,
      ),
      strong: TextStyle(
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      em: TextStyle(
        fontStyle: FontStyle.italic,
        color: colors.textPrimary,
      ),
      code: TextStyle(
        fontSize: 14,
        color: colors.study,
        backgroundColor: colors.surface,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.border),
      ),
      listBullet: TextStyle(
        color: colors.textPrimary,
        fontSize: 17,
      ),
    );
  }

  static MarkdownStyleSheet _explanationSheet(BuildContext context) {
    final colors = context.growthColors;
    return MarkdownStyleSheet(
      p: TextStyle(color: colors.textSecondary, height: 1.45),
      strong: TextStyle(
        fontWeight: FontWeight.w700,
        color: colors.textSecondary,
      ),
      em: TextStyle(
        fontStyle: FontStyle.italic,
        color: colors.textSecondary,
      ),
      code: TextStyle(
        fontSize: 13,
        color: colors.study,
        backgroundColor: colors.surface,
        fontFamily: 'monospace',
      ),
      listBullet: TextStyle(
        color: colors.textSecondary,
        fontSize: 14,
      ),
    );
  }

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
          styleSheet: _answerSheet(context),
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
              styleSheet: _explanationSheet(context),
            ),
          ),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colors.study.withValues(alpha: 0.10),
                    side: BorderSide.none,
                    labelStyle: TextStyle(color: colors.study),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        _ReviewSourceReferences(cardId: card.id),
      ],
    );
  }
}

class _ReviewSourceReferences extends ConsumerWidget {
  const _ReviewSourceReferences({required this.cardId});

  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final references = ref.watch(knowledgeCardSourceReferencesProvider(cardId));
    return references.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: _ReviewSourcePanel(reference: items.first),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ReviewSourcePanel extends StatelessWidget {
  const _ReviewSourcePanel({required this.reference});

  final KnowledgeCardSourceReference reference;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final heading = reference.chunk.heading?.trim();
    final quote = reference.link.quote?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.study.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '来源：${heading == null || heading.isEmpty ? reference.source.title : '${reference.source.title} · $heading'}',
            style: TextStyle(color: colors.study, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            quote == null || quote.isEmpty
                ? _excerpt(reference.chunk.content)
                : quote,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary, height: 1.45),
          ),
        ],
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
      child: Text(
        text,
        style: TextStyle(
          color: colors.study,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FlipButton extends StatelessWidget {
  const _FlipButton({required this.onTap});

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.mlg),
          ),
        ),
        icon: const Icon(Icons.flip_rounded),
        label: const Text('翻开答案'),
      ),
    );
  }
}

class _FeedbackButtons extends StatelessWidget {
  const _FeedbackButtons({required this.onSelected});

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
      children: options
          .map(
            (option) => _FeedbackButton(
              option: option,
              onTap: () => onSelected(option.quality),
            ),
          )
          .toList(growable: false),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.mlg),
          ),
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
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: option.color.withValues(alpha: 0.7),
                ),
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

class _ReviewSessionResult {
  const _ReviewSessionResult({required this.quality, required this.nextDueAt});

  final int quality;
  final int nextDueAt;
}

class _SoftNotice extends StatelessWidget {
  const _SoftNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.mlg),
      ),
      child: Text(text, style: TextStyle(color: colors.textSecondary)),
    );
  }
}

class _ReviewCompletePanel extends StatelessWidget {
  const _ReviewCompletePanel({
    required this.results,
    required this.weakOnly,
    required this.onRestart,
    this.bestStreak = 0,
  });

  final List<_ReviewSessionResult> results;
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
            child: Image.asset(
              KnowledgeCardAssets.goalReviewComplete,
              fit: BoxFit.cover,
              cacheWidth: 900,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          weakOnly ? '薄弱知识点复习完成' : '这组卡片复习完成',
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '本轮复习 $total 张，掌握度和下次复习时间已经更新。',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textSecondary),
        ),
        if (bestStreak >= 3)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Center(
              child: Text(
                '🔥 最佳连续答对 $bestStreak 题',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.warning,
                ),
              ),
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
            _ReviewStatTile(
              label: '不会',
              value: wrong,
              icon: Icons.close_rounded,
              color: colors.danger,
            ),
            _ReviewStatTile(
              label: '模糊',
              value: fuzzy,
              icon: Icons.help_outline_rounded,
              color: colors.warning,
            ),
            _ReviewStatTile(
              label: '记得',
              value: remembered,
              icon: Icons.check_rounded,
              color: colors.study,
            ),
            _ReviewStatTile(
              label: '很熟',
              value: fluent,
              icon: Icons.bolt_rounded,
              color: colors.success,
            ),
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
              Text(
                '下次复习分布',
                style: AppTextStyles.sectionTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.mlg),
            ),
          ),
          icon: const Icon(Icons.style_rounded),
          label: Text(weakOnly ? '再练薄弱点' : '再随机抽一组'),
        ),
      ],
    );
  }

  int _countQuality(int quality) {
    return results.where((item) => item.quality == quality).length;
  }

  _DueBuckets _dueBuckets() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneDay = const Duration(days: 1).inMilliseconds;
    final sevenDays = const Duration(days: 7).inMilliseconds;
    var today = 0;
    var thisWeek = 0;
    var later = 0;
    for (final result in results) {
      final diff = result.nextDueAt - now;
      if (diff <= oneDay) {
        today += 1;
      } else if (diff <= sevenDays) {
        thisWeek += 1;
      } else {
        later += 1;
      }
    }
    return _DueBuckets(today: today, thisWeek: thisWeek, later: later);
  }
}

class _DueBuckets {
  const _DueBuckets({
    required this.today,
    required this.thisWeek,
    required this.later,
  });

  final int today;
  final int thisWeek;
  final int later;
}

class _ReviewStatTile extends StatelessWidget {
  const _ReviewStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

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
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueBucketRow extends StatelessWidget {
  const _DueBucketRow({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: colors.textSecondary)),
          ),
          Text(
            '$count 张',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoCardsPanel extends StatelessWidget {
  const _NoCardsPanel({
    this.deckKey,
    this.goalKey,
    this.goalName,
    this.moduleKey,
    this.moduleName,
    this.weakOnly = false,
  });

  final String? deckKey;
  final String? goalKey;
  final String? goalName;
  final String? moduleKey;
  final String? moduleName;
  final bool weakOnly;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final hasScope = deckKey != null || goalKey != null || moduleKey != null;
    final image = !hasScope
        ? KnowledgeCardAssets.emptyCards
        : KnowledgeCardAssets.noDueCards;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xxxl),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(image, fit: BoxFit.cover, cacheWidth: 900),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          weakOnly
              ? '暂无薄弱知识点'
              : !hasScope
              ? '还没有知识卡'
              : '当前目标还没有卡片',
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          weakOnly ? '目前没有低掌握或最近答错的卡片，可以继续按目标抽卡复习。' : '先把你学过的内容整理成问答卡，再开始抽卡复习。',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          onPressed: () => context.push(weakOnly ? _reviewPath() : _addPath()),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.study,
            foregroundColor: colors.textOnAccent,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.mlg),
            ),
          ),
          icon: Icon(weakOnly ? Icons.style_rounded : Icons.add_rounded),
          label: Text(weakOnly ? '普通抽卡复习' : '添加知识卡'),
        ),
      ],
    );
  }

  String _addPath() {
    final params = _scopeParams();
    final query = Uri(queryParameters: params).query;
    return query.isEmpty
        ? '/plan/study/knowledge/add'
        : '/plan/study/knowledge/add?$query';
  }

  String _reviewPath() {
    final params = _scopeParams()..['all'] = '1';
    final query = Uri(queryParameters: params).query;
    return query.isEmpty
        ? '/plan/study/knowledge/review'
        : '/plan/study/knowledge/review?$query';
  }

  Map<String, String> _scopeParams() {
    final params = <String, String>{};
    if (deckKey != null && deckKey!.isNotEmpty) {
      params['deckKey'] = deckKey!;
    }
    if (goalKey != null && goalKey!.isNotEmpty) {
      params['goalKey'] = goalKey!;
    }
    if (goalName != null && goalName!.isNotEmpty) {
      params['goalName'] = goalName!;
    }
    if (moduleKey != null && moduleKey!.isNotEmpty) {
      params['moduleKey'] = moduleKey!;
    }
    if (moduleName != null && moduleName!.isNotEmpty) {
      params['moduleName'] = moduleName!;
    }
    return params;
  }
}
