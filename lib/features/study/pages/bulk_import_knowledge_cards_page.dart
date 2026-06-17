import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/knowledge_card_assets.dart';
import '../utils/knowledge_card_import_parser.dart';

const _largeImportWarningThreshold = 300;

class BulkImportKnowledgeCardsPage extends ConsumerStatefulWidget {
  const BulkImportKnowledgeCardsPage({
    super.key,
    this.initialGoalKey,
    this.initialGoalName,
    this.initialModuleKey,
    this.initialModuleName,
    this.initialDeckKey,
    this.initialSubject,
  });

  final String? initialGoalKey;
  final String? initialGoalName;
  final String? initialModuleKey;
  final String? initialModuleName;
  final String? initialDeckKey;
  final String? initialSubject;

  @override
  ConsumerState<BulkImportKnowledgeCardsPage> createState() =>
      _BulkImportKnowledgeCardsPageState();
}

class _BulkImportKnowledgeCardsPageState
    extends ConsumerState<BulkImportKnowledgeCardsPage> {
  final _inputController = TextEditingController();
  _ImportPreview? _preview;
  bool _parsing = false;
  bool _importing = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final scope = _resolveImportScope();
    final visual = KnowledgeCardAssets.visualForKey(scope.deckKey);
    final preview = _preview;

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: Text(
          '批量导入知识卡',
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
      ),
      body: ModulePageSurface(
        color: colors.study,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ImportContextCover(
              goal: scope.goal,
              deck: visual,
              goalName: scope.displayGoalName,
              moduleName: scope.displayModuleName,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ImportFormatCard(),
            const SizedBox(height: AppSpacing.md),
            _ImportEditorCard(
              controller: _inputController,
              onParse: _parsePreview,
              parsing: _parsing,
            ),
            if (preview != null) ...[
              const SizedBox(height: AppSpacing.md),
              _PreviewResultPanel(
                preview: preview,
                importing: _importing,
                onItemSelectionChanged: _setDraftSelected,
                onImport: preview.selectedCount > 0 && !_importing
                    ? () => _importDrafts(preview.selectedDrafts)
                    : null,
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _parsePreview() async {
    setState(() => _parsing = true);
    final result = KnowledgeCardImportParser.parse(_inputController.text);
    final scope = _resolveImportScope();

    var items = result.drafts
        .map((draft) => _ImportDraftPreview(draft: draft))
        .toList(growable: false);

    try {
      if (result.drafts.isNotEmpty) {
        final existing = await ref
            .read(knowledgeCardRepositoryProvider)
            .getCardsForImportScope(
              deckKey: scope.deckKey,
              goalKey: scope.goal.key,
              goalName: scope.goalName,
              moduleKey: scope.module.key,
              moduleName: scope.moduleName,
            );
        items = _markDuplicates(result.drafts, existing);
      }

      if (!mounted) return;
      setState(() {
        _preview = _ImportPreview(result: result, items: items);
        _parsing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _preview = _ImportPreview(result: result, items: items);
        _parsing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('解析完成，但重复检测暂时不可用')));
    }
  }

  void _setDraftSelected(int index, bool selected) {
    final preview = _preview;
    if (preview == null || index < 0 || index >= preview.items.length) return;

    final nextItems = [...preview.items];
    nextItems[index] = nextItems[index].copyWith(selected: selected);
    setState(() => _preview = preview.copyWith(items: nextItems));
  }

  Future<void> _importDrafts(List<ParsedKnowledgeCardDraft> drafts) async {
    if (drafts.isEmpty) return;
    if (drafts.length > _largeImportWarningThreshold) {
      final confirmed = await _confirmLargeImport(drafts.length);
      if (confirmed != true) return;
    }

    setState(() => _importing = true);
    final repo = ref.read(knowledgeCardRepositoryProvider);
    final scope = _resolveImportScope();
    final now = DateTime.now().millisecondsSinceEpoch;
    final cards = drafts
        .map(
          (draft) => KnowledgeCardsCompanion(
            deckKey: Value(scope.deckKey),
            goalKey: Value(scope.goal.key),
            goalName: Value(scope.goalName),
            moduleKey: Value(scope.module.key),
            moduleName: Value(scope.moduleName),
            subject: Value(draft.subject ?? scope.defaultSubject),
            title: Value(draft.title),
            question: Value(draft.question),
            answer: Value(draft.answer),
            explanation: Value(draft.explanation),
            tags: Value(draft.tags.isEmpty ? null : jsonEncode(draft.tags)),
            dueAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        )
        .toList(growable: false);

    try {
      await repo.insertCards(cards);

      ref.invalidate(knowledgeCardsProvider);
      ref.invalidate(knowledgeGoalSummariesProvider);
      ref.invalidate(knowledgeDeckSummariesProvider);
      ref.invalidate(dueKnowledgeCardsCountProvider);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.go(_goalDetailPath(scope));
      messenger.showSnackBar(
        SnackBar(content: Text('已导入 ${drafts.length} 张知识卡')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('导入失败，请检查文本后再试')));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  List<_ImportDraftPreview> _markDuplicates(
    List<ParsedKnowledgeCardDraft> drafts,
    List<KnowledgeCard> existing,
  ) {
    final existingQuestions = existing
        .map((card) => _normalizeDuplicateText(card.question))
        .where((item) => item.isNotEmpty)
        .toSet();
    final existingPairs = existing
        .map((card) => _titleAnswerKey(card.title, card.answer))
        .where((item) => item.isNotEmpty)
        .toSet();
    final seenQuestions = <String>{};
    final seenPairs = <String>{};

    return drafts
        .map((draft) {
          final questionKey = _normalizeDuplicateText(draft.question);
          final pairKey = _titleAnswerKey(draft.title, draft.answer);
          String? duplicateReason;

          if (existingQuestions.contains(questionKey)) {
            duplicateReason = '已存在相同问题';
          } else if (existingPairs.contains(pairKey)) {
            duplicateReason = '已存在相同标题和答案';
          } else if (seenQuestions.contains(questionKey)) {
            duplicateReason = '本次导入内问题重复';
          } else if (seenPairs.contains(pairKey)) {
            duplicateReason = '本次导入内标题和答案重复';
          }

          seenQuestions.add(questionKey);
          seenPairs.add(pairKey);
          return _ImportDraftPreview(
            draft: draft,
            duplicateReason: duplicateReason,
            selected: duplicateReason == null,
          );
        })
        .toList(growable: false);
  }

  Future<bool?> _confirmLargeImport(int count) {
    final colors = context.growthColors;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        surfaceTintColor: colors.card,
        title: const Text('确认大批量导入'),
        content: Text('这次将导入 $count 张知识卡，移动端可能会短暂等待。建议资料很多时分批导入。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('继续导入'),
          ),
        ],
      ),
    );
  }

  _ResolvedImportScope _resolveImportScope() {
    final goal = KnowledgeCardAssets.goalForKey(widget.initialGoalKey);
    final module = KnowledgeCardAssets.moduleForKeys(
      goal.key,
      widget.initialModuleKey,
    );
    final deckKey = _effectiveDeckKey(module);
    final goalName = goal.key == 'custom'
        ? _nullable(widget.initialGoalName)
        : null;
    final moduleName = module.deckKey == 'custom'
        ? _nullable(widget.initialModuleName)
        : null;
    return _ResolvedImportScope(
      goal: goal,
      module: module,
      deckKey: deckKey,
      goalName: goalName,
      moduleName: moduleName,
      defaultSubject: _nullable(widget.initialSubject),
    );
  }

  String _effectiveDeckKey(KnowledgeGoalModuleVisual module) {
    if (module.deckKey != 'custom') return module.deckKey;
    return KnowledgeCardAssets.visualForKey(widget.initialDeckKey).key;
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String _goalDetailPath(_ResolvedImportScope scope) {
    final params = <String, String>{'goalKey': scope.goal.key};
    if (scope.goalName != null) params['goalName'] = scope.goalName!;
    return '/plan/study/knowledge/goal?${Uri(queryParameters: params).query}';
  }

  String _normalizeDuplicateText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  String _titleAnswerKey(String title, String answer) {
    final titleKey = _normalizeDuplicateText(title);
    final answerKey = _normalizeDuplicateText(answer);
    if (titleKey.isEmpty || answerKey.isEmpty) return '';
    return '$titleKey\u0001$answerKey';
  }
}

class _ResolvedImportScope {
  const _ResolvedImportScope({
    required this.goal,
    required this.module,
    required this.deckKey,
    required this.goalName,
    required this.moduleName,
    required this.defaultSubject,
  });

  final KnowledgeGoalVisual goal;
  final KnowledgeGoalModuleVisual module;
  final String deckKey;
  final String? goalName;
  final String? moduleName;
  final String? defaultSubject;

  String get displayGoalName => goalName ?? goal.name;
  String get displayModuleName => moduleName ?? module.name;
}

class _ImportPreview {
  const _ImportPreview({required this.result, required this.items});

  final KnowledgeCardImportParseResult result;
  final List<_ImportDraftPreview> items;

  int get duplicateCount =>
      items.where((item) => item.duplicateReason != null).length;
  int get selectedCount => items.where((item) => item.selected).length;
  int get skippedCount => items.length - selectedCount;

  List<ParsedKnowledgeCardDraft> get selectedDrafts => items
      .where((item) => item.selected)
      .map((item) => item.draft)
      .toList(growable: false);

  _ImportPreview copyWith({List<_ImportDraftPreview>? items}) {
    return _ImportPreview(result: result, items: items ?? this.items);
  }
}

class _ImportDraftPreview {
  const _ImportDraftPreview({
    required this.draft,
    this.duplicateReason,
    this.selected = true,
  });

  final ParsedKnowledgeCardDraft draft;
  final String? duplicateReason;
  final bool selected;

  _ImportDraftPreview copyWith({bool? selected}) {
    return _ImportDraftPreview(
      draft: draft,
      duplicateReason: duplicateReason,
      selected: selected ?? this.selected,
    );
  }
}

class _ImportContextCover extends StatelessWidget {
  const _ImportContextCover({
    required this.goal,
    required this.deck,
    required this.goalName,
    required this.moduleName,
  });

  final KnowledgeGoalVisual goal;
  final KnowledgeDeckVisual deck;
  final String goalName;
  final String moduleName;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(goal.asset, fit: BoxFit.cover, cacheWidth: 900),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      colors.card.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _ImportPill(text: goalName, strong: true),
                    _ImportPill(text: moduleName),
                    _ImportPill(text: deck.name),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportFormatCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file_rounded, color: colors.study),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '支持的粘贴格式',
                style: AppTextStyles.sectionTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _FormatExample(title: '一行一张卡', text: '问题|答案\n问题|答案|章节\n问题|答案|章节|标签'),
          const SizedBox(height: AppSpacing.md),
          _FormatExample(
            title: '多段文本',
            text:
                '标题：进程与线程\n问题：进程和线程有什么区别？\n答案：进程是资源分配单位...\n章节：操作系统\n标签：408，易错\n---\nQ: What is an index?\nA: A structure that speeds up lookup.',
          ),
        ],
      ),
    );
  }
}

class _FormatExample extends StatelessWidget {
  const _FormatExample({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.mlg),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: colors.textSecondary,
              height: 1.45,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

class _ImportEditorCard extends StatelessWidget {
  const _ImportEditorCard({
    required this.controller,
    required this.onParse,
    required this.parsing,
  });

  final TextEditingController controller;
  final VoidCallback onParse;
  final bool parsing;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
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
            '粘贴知识点',
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            minLines: 9,
            maxLines: 16,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: '把整理好的题目、答案、章节粘贴到这里',
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mlg),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mlg),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mlg),
                borderSide: BorderSide(color: colors.study, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: parsing ? null : onParse,
            style: FilledButton.styleFrom(
              backgroundColor: colors.study,
              foregroundColor: colors.textOnAccent,
              minimumSize: const Size.fromHeight(50),
            ),
            icon: parsing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fact_check_rounded),
            label: Text(parsing ? '正在解析...' : '解析预览'),
          ),
        ],
      ),
    );
  }
}

class _PreviewResultPanel extends StatelessWidget {
  const _PreviewResultPanel({
    required this.preview,
    required this.importing,
    required this.onItemSelectionChanged,
    required this.onImport,
  });

  final _ImportPreview preview;
  final bool importing;
  final void Function(int index, bool selected) onItemSelectionChanged;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final result = preview.result;
    final items = preview.items;
    final visibleItems = items.take(50).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '预览 ${items.length} 张知识卡',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (preview.duplicateCount > 0)
                _ImportPill(text: '${preview.duplicateCount} 张可能重复'),
              if (preview.duplicateCount > 0)
                const SizedBox(width: AppSpacing.xs),
              if (result.errors.isNotEmpty)
                _ImportPill(text: '${result.errors.length} 条需检查'),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '将导入 ${preview.selectedCount} 张，已跳过 ${preview.skippedCount} 张',
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
          if (preview.selectedCount > _largeImportWarningThreshold) ...[
            const SizedBox(height: AppSpacing.sm),
            _InlineWarning(text: '本次导入数量较大，建议在手机端分批处理；继续导入前会再次确认。'),
          ],
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final error in result.errors.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        error.displayText,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (visibleItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < visibleItems.length; i += 1)
              _DraftPreviewTile(
                item: visibleItems[i],
                onSelected: (selected) => onItemSelectionChanged(i, selected),
              ),
            if (items.length > visibleItems.length)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  '还有 ${items.length - visibleItems.length} 张未显示，会按当前默认状态一起处理。',
                  style: TextStyle(color: colors.textTertiary),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onImport,
            style: FilledButton.styleFrom(
              backgroundColor: colors.study,
              foregroundColor: colors.textOnAccent,
              minimumSize: const Size.fromHeight(52),
            ),
            icon: importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.library_add_check_rounded),
            label: Text(
              importing ? '正在导入...' : '导入 ${preview.selectedCount} 张',
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftPreviewTile extends StatelessWidget {
  const _DraftPreviewTile({required this.item, required this.onSelected});

  final _ImportDraftPreview item;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final draft = item.draft;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(
          color: item.duplicateReason == null
              ? colors.border
              : colors.warning.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.selected,
            onChanged: (value) => onSelected(value ?? false),
            activeColor: colors.study,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.selected
                        ? colors.textPrimary
                        : colors.textTertiary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  draft.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.selected
                        ? colors.textPrimary
                        : colors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  draft.answer,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary),
                ),
                if (draft.subject != null ||
                    draft.tags.isNotEmpty ||
                    item.duplicateReason != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (item.duplicateReason != null)
                        _ImportPill(text: item.duplicateReason!, warning: true),
                      if (draft.subject != null)
                        _ImportPill(text: draft.subject!),
                      for (final tag in draft.tags) _ImportPill(text: tag),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: colors.warning, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: TextStyle(color: colors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _ImportPill extends StatelessWidget {
  const _ImportPill({
    required this.text,
    this.strong = false,
    this.warning = false,
  });

  final String text;
  final bool strong;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: warning
            ? colors.warning.withValues(alpha: 0.12)
            : strong
            ? colors.study.withValues(alpha: 0.14)
            : colors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: warning
              ? colors.warning
              : strong
              ? colors.study
              : colors.textSecondary,
          fontSize: 12,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
    );
  }
}
