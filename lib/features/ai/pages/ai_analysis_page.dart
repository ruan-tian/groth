import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repositories/knowledge_source_repository.dart';
import '../../../core/services/ai_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../study/providers/study_provider.dart';
import '../../fitness/providers/fitness_provider.dart';
import '../../health/providers/diet_provider.dart';
import '../../health/providers/sleep_provider.dart';
import '../../../shared/providers/knowledge_card_ai_provider.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../knowledge/services/knowledge_context_service.dart';
import '../../study/services/knowledge_card_ai_service.dart';

part '../widgets/ai_analysis_tabs.dart';
part '../widgets/ai_analysis_more_tabs.dart';

// =============================================================================
// Providers
// =============================================================================

/// 当前启用的 AI 配置
final enabledAiConfigProvider = FutureProvider<AiConfig?>((ref) {
  final repo = ref.watch(aiConfigRepositoryProvider);
  return repo.getEnabledAiConfig();
});

/// AI 分析结果状态
final aiAnalysisStateProvider =
    StateNotifierProvider<AiAnalysisNotifier, AiAnalysisState>((ref) {
      return AiAnalysisNotifier();
    });

// =============================================================================
// 状态模型
// =============================================================================

/// AI 分析状态
class AiAnalysisState {
  const AiAnalysisState({
    this.isLoading = false,
    this.isStreaming = false,
    this.partialResult,
    this.result,
    this.error,
    this.referenceContext,
  });

  final bool isLoading;
  final bool isStreaming;
  final String? partialResult;
  final String? result;
  final String? error;
  final KnowledgeContextBundle? referenceContext;

  AiAnalysisState copyWith({
    bool? isLoading,
    bool? isStreaming,
    String? partialResult,
    String? result,
    String? error,
    KnowledgeContextBundle? referenceContext,
  }) {
    return AiAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      partialResult: partialResult ?? this.partialResult,
      result: result ?? this.result,
      error: error ?? this.error,
      referenceContext: referenceContext ?? this.referenceContext,
    );
  }
}

/// AI 分析状态管理
class AiAnalysisNotifier extends StateNotifier<AiAnalysisState> {
  AiAnalysisNotifier() : super(const AiAnalysisState());

  Future<void> runAnalysis(
    Future<String> Function() task, {
    KnowledgeContextBundle? referenceContext,
  }) async {
    state = const AiAnalysisState(isLoading: true);
    try {
      final result = await task();
      state = AiAnalysisState(
        result: result,
        referenceContext: referenceContext?.isEmpty ?? true
            ? null
            : referenceContext,
      );
    } on AiServiceException catch (e) {
      state = AiAnalysisState(error: e.message);
    } catch (e) {
      state = AiAnalysisState(error: '分析失败，请重试');
    }
  }

  Future<void> runStreamAnalysis(
    Stream<String> Function() task, {
    KnowledgeContextBundle? referenceContext,
  }) async {
    state = const AiAnalysisState(isLoading: true);
    try {
      final buffer = StringBuffer();
      await for (final delta in task()) {
        buffer.write(delta);
        state = state.copyWith(
          isLoading: false,
          isStreaming: true,
          partialResult: buffer.toString(),
        );
      }
      state = AiAnalysisState(
        result: buffer.toString(),
        referenceContext:
            referenceContext?.isEmpty ?? true ? null : referenceContext,
      );
    } on AiServiceException catch (e) {
      state = AiAnalysisState(error: e.message);
    } catch (e) {
      state = AiAnalysisState(error: '分析失败，请重试');
    }
  }

  void updateState(AiAnalysisState newState) {
    state = newState;
  }

  void reset() {
    state = const AiAnalysisState();
  }
}

// =============================================================================
// 页面
// =============================================================================

/// AI 分析页面
///
/// 提供学习分析、健身分析、饮食分析、睡眠分析、成长报告五个 Tab，
/// 每个 Tab 可预览待发送数据并触发 AI 分析。
class AiAnalysisPage extends ConsumerStatefulWidget {
  const AiAnalysisPage({super.key});

  @override
  ConsumerState<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

String _joinContextTerms(Iterable<String?> values, {int limit = 10}) {
  final terms = <String>{};
  for (final value in values) {
    final text = value?.trim();
    if (text == null || text.isEmpty) continue;
    for (final term in text.split(RegExp(r'[\s,，、/|:：;；()（）\[\]【】]+'))) {
      final normalized = term.trim();
      if (normalized.length < 2) continue;
      terms.add(normalized);
      if (terms.length >= limit) return terms.join(' ');
    }
  }
  return terms.join(' ');
}

List<Widget> _buildKnowledgeContextRows(
  KnowledgeContextBundle? bundle, {
  required bool isLoading,
}) {
  if (isLoading) {
    return [_buildInfoRow('本地知识库', '检索中...')];
  }
  if (bundle != null && bundle.results.isNotEmpty) {
    return [
      _buildInfoRow('本地知识库', '${bundle.results.length} 个片段'),
      _buildInfoRow('知识库 tokens', '~${bundle.tokenEstimate}'),
      _KnowledgeContextPreview(bundle: bundle),
    ];
  }
  return [_buildInfoRow('本地知识库', '暂无匹配片段')];
}

Future<KnowledgeContextBundle?> showKnowledgeContextConfirmSheet({
  required BuildContext context,
  required KnowledgeContextBundle bundle,
}) async {
  if (bundle.results.isEmpty) return bundle;
  return _KnowledgeContextConfirmSheet.show(context: context, bundle: bundle);
}

class _KnowledgeContextPreview extends StatelessWidget {
  const _KnowledgeContextPreview({required this.bundle});

  final KnowledgeContextBundle bundle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(
            Icons.manage_search_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          title: const Text(
            '查看将发送的知识库片段',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '检索词：${bundle.query}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          children: [
            for (var i = 0; i < bundle.results.length; i++) ...[
              _KnowledgeContextChunkTile(index: i, result: bundle.results[i]),
              if (i != bundle.results.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _KnowledgeContextReferences extends StatelessWidget {
  const _KnowledgeContextReferences({required this.bundle});

  final KnowledgeContextBundle bundle;

  @override
  Widget build(BuildContext context) {
    if (bundle.results.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.22)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(
            Icons.source_rounded,
            color: AppColors.success,
            size: 20,
          ),
          title: const Text(
            '本次参考来源',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '${bundle.results.length} 个片段 · ~${bundle.tokenEstimate} tokens',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          children: [
            for (var i = 0; i < bundle.results.length; i++) ...[
              _KnowledgeContextChunkTile(index: i, result: bundle.results[i]),
              if (i != bundle.results.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _KnowledgeContextChunkTile extends StatelessWidget {
  const _KnowledgeContextChunkTile({required this.index, required this.result});

  final int index;
  final KnowledgeChunkSearchResult result;

  @override
  Widget build(BuildContext context) {
    final source = result.source;
    final chunk = result.chunk;
    final heading = chunk.heading?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${source.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MiniContextPill(
                text: heading == null || heading.isEmpty ? '无标题片段' : heading,
              ),
              _MiniContextPill(text: '${chunk.tokenEstimate} tokens'),
              _MiniContextPill(text: '相关度 ${result.score}'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _compactContextPreview(chunk.content),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeContextConfirmSheet extends StatefulWidget {
  const _KnowledgeContextConfirmSheet({required this.bundle});

  final KnowledgeContextBundle bundle;

  static Future<KnowledgeContextBundle?> show({
    required BuildContext context,
    required KnowledgeContextBundle bundle,
  }) {
    return showModalBottomSheet<KnowledgeContextBundle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _KnowledgeContextConfirmSheet(bundle: bundle),
    );
  }

  @override
  State<_KnowledgeContextConfirmSheet> createState() =>
      _KnowledgeContextConfirmSheetState();
}

class _KnowledgeContextConfirmSheetState
    extends State<_KnowledgeContextConfirmSheet> {
  late final List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.filled(widget.bundle.results.length, true);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.where((value) => value).length;
    final selectedResults = <KnowledgeChunkSearchResult>[
      for (var i = 0; i < widget.bundle.results.length; i++)
        if (_selected[i]) widget.bundle.results[i],
    ];
    final selectedBundle = KnowledgeContextBundle(
      query: widget.bundle.query,
      results: selectedResults,
    );
    final selectedTokens = selectedBundle.tokenEstimate;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.52,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '确认发送知识库片段',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '你可以取消不想发送的片段，最终只会把保留内容发给 AI。',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('ai-context-keep-top1'),
                  onPressed: () => _keepTopResults(1),
                  child: const Text('保留前 1 个'),
                ),
                OutlinedButton(
                  key: const Key('ai-context-keep-top3'),
                  onPressed: () => _keepTopResults(3),
                  child: const Text('保留前 3 个'),
                ),
                OutlinedButton(
                  key: const Key('ai-context-keep-all'),
                  onPressed: () => _setAllSelected(true),
                  child: const Text('全选'),
                ),
                OutlinedButton(
                  key: const Key('ai-context-clear-all'),
                  onPressed: () => _setAllSelected(false),
                  child: const Text('全不选'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SelectionSummary(
              selectedCount: selectedCount,
              selectedTokens: selectedTokens,
              totalCount: widget.bundle.results.length,
              totalTokens: widget.bundle.tokenEstimate,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < widget.bundle.results.length; i++) ...[
              CheckboxListTile(
                value: _selected[i],
                onChanged: (value) {
                  setState(() => _selected[i] = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  widget.bundle.results[i].source.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  _contextTileSubtitle(widget.bundle.results[i]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 8),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: selectedCount == 0
                  ? null
                  : () => Navigator.pop(context, selectedBundle),
              icon: const Icon(Icons.send_rounded),
              label: Text('确认发送 $selectedCount 个片段'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                KnowledgeContextBundle(
                  query: widget.bundle.query,
                  results: const [],
                ),
              ),
              child: const Text('不发送知识库片段，继续分析'),
            ),
          ],
        ),
      ),
    );
  }

  String _contextTileSubtitle(KnowledgeChunkSearchResult result) {
    final heading = result.chunk.heading?.trim();
    final title = heading == null || heading.isEmpty ? '无标题片段' : heading;
    final compact = _compactContextPreview(result.chunk.content);
    return '$title · ${result.chunk.tokenEstimate} tokens · $compact';
  }

  void _setAllSelected(bool value) {
    setState(() {
      for (var i = 0; i < _selected.length; i++) {
        _selected[i] = value;
      }
    });
  }

  void _keepTopResults(int count) {
    setState(() {
      for (var i = 0; i < _selected.length; i++) {
        _selected[i] = i < count;
      }
    });
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({
    required this.selectedCount,
    required this.selectedTokens,
    required this.totalCount,
    required this.totalTokens,
  });

  final int selectedCount;
  final int selectedTokens;
  final int totalCount;
  final int totalTokens;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        '已选 $selectedCount/$totalCount 个片段，约 $selectedTokens/$totalTokens tokens',
        style: TextStyle(
          fontSize: 12,
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AiAnalysisDraftPreviewSheet extends StatefulWidget {
  const _AiAnalysisDraftPreviewSheet({
    required this.drafts,
    required this.duplicateReasons,
  });

  final List<KnowledgeCardAiDraft> drafts;
  final List<String?> duplicateReasons;

  static Future<List<KnowledgeCardAiDraft>?> show({
    required BuildContext context,
    required List<KnowledgeCardAiDraft> drafts,
    required List<String?> duplicateReasons,
  }) {
    return showModalBottomSheet<List<KnowledgeCardAiDraft>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AiAnalysisDraftPreviewSheet(
        drafts: drafts,
        duplicateReasons: duplicateReasons,
      ),
    );
  }

  @override
  State<_AiAnalysisDraftPreviewSheet> createState() =>
      _AiAnalysisDraftPreviewSheetState();
}

class _AiAnalysisDraftPreviewSheetState
    extends State<_AiAnalysisDraftPreviewSheet> {
  late final List<_EditableAnalysisDraft> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = [
      for (var i = 0; i < widget.drafts.length; i++)
        _EditableAnalysisDraft(
          widget.drafts[i],
          duplicateReason: i < widget.duplicateReasons.length
              ? widget.duplicateReasons[i]
              : null,
        ),
    ];
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _drafts.where((draft) => draft.selected).length;
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.52,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '确认分析知识卡',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '这些草稿来自本次 AI 分析结果，保存后会关联本次参考的本地知识库片段。',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _drafts.length; i++) ...[
              _EditableAnalysisDraftCard(
                index: i,
                draft: _drafts[i],
                onSelectionChanged: (value) {
                  setState(() => _drafts[i].selected = value);
                },
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              key: const Key('ai-analysis-confirm-save-card-button'),
              onPressed: selectedCount == 0 ? null : _submit,
              icon: const Icon(Icons.save_alt_rounded),
              label: Text('保存 $selectedCount 张知识卡'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final selected = _drafts
        .where((draft) => draft.selected)
        .map((draft) => draft.toDraft())
        .where((draft) => draft.question.isNotEmpty && draft.answer.isNotEmpty)
        .toList(growable: false);
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('至少保留一张有问答内容的草稿')));
      return;
    }
    Navigator.pop(context, selected);
  }
}

class _EditableAnalysisDraftCard extends StatelessWidget {
  const _EditableAnalysisDraftCard({
    required this.index,
    required this.draft,
    required this.onSelectionChanged,
  });

  final int index;
  final _EditableAnalysisDraft draft;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: draft.selected,
            onChanged: (value) => onSelectionChanged(value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('草稿 ${index + 1}'),
            subtitle: Text(draft.duplicateReason ?? '确认后写入本地知识卡片库'),
          ),
          if (draft.duplicateReason != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: _MiniContextPill(text: '可能重复：${draft.duplicateReason}'),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: draft.titleController,
            decoration: const InputDecoration(labelText: '标题'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.questionController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: '问题'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.answerController,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: '答案'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.explanationController,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(labelText: '解释（可选）'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.tagsController,
            decoration: const InputDecoration(labelText: '标签（逗号分隔，可选）'),
          ),
        ],
      ),
    );
  }
}

class _EditableAnalysisDraft {
  _EditableAnalysisDraft(KnowledgeCardAiDraft draft, {this.duplicateReason})
    : titleController = TextEditingController(text: draft.title),
      questionController = TextEditingController(text: draft.question),
      answerController = TextEditingController(text: draft.answer),
      explanationController = TextEditingController(
        text: draft.explanation ?? '',
      ),
      tagsController = TextEditingController(text: draft.tags.join(', '));

  final TextEditingController titleController;
  final TextEditingController questionController;
  final TextEditingController answerController;
  final TextEditingController explanationController;
  final TextEditingController tagsController;
  final String? duplicateReason;
  late bool selected = duplicateReason == null;

  KnowledgeCardAiDraft toDraft() {
    return KnowledgeCardAiDraft(
      title: _text(titleController) ?? _text(questionController) ?? '知识卡',
      question: _text(questionController) ?? '',
      answer: _text(answerController) ?? '',
      explanation: _text(explanationController),
      tags: tagsController.text
          .split(RegExp(r'[,，、\s]+'))
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .take(6)
          .toList(growable: false),
    );
  }

  void dispose() {
    titleController.dispose();
    questionController.dispose();
    answerController.dispose();
    explanationController.dispose();
    tagsController.dispose();
  }

  String? _text(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }
}

class _MiniContextPill extends StatelessWidget {
  const _MiniContextPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}

String _compactContextPreview(String value) {
  final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.length <= 220) return text;
  return '${text.substring(0, 220)}...';
}

class _AiAnalysisPageState extends ConsumerState<AiAnalysisPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // 切换 Tab 时重置分析状态
    ref.read(aiAnalysisStateProvider.notifier).reset();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.growthColors.background,
      appBar: AppBar(
        title: const Text('AI 分析', style: AppTextStyles.sectionTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: context.growthColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: context.growthColors.primary,
          unselectedLabelColor: context.growthColors.textTertiary,
          indicatorColor: context.growthColors.primary,
          tabs: const [
            Tab(text: '学习', icon: Icon(Icons.school, size: 18)),
            Tab(text: '健身', icon: Icon(Icons.fitness_center, size: 18)),
            Tab(text: '饮食', icon: Icon(Icons.restaurant, size: 18)),
            Tab(text: '睡眠', icon: Icon(Icons.bedtime, size: 18)),
            Tab(text: '成长报告', icon: Icon(Icons.auto_graph, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StudyAnalysisTab(),
          _FitnessAnalysisTab(),
          _DietAnalysisTab(),
          _SleepAnalysisTab(),
          _GrowthReportTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// 学习分析 Tab
// =============================================================================
