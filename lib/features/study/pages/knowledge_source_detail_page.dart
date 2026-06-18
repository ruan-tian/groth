import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repositories/knowledge_source_repository.dart';
import '../../../core/services/ai_service.dart';
import '../../../shared/providers/knowledge_card_ai_provider.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/knowledge_source_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../services/knowledge_card_ai_service.dart';
import '../utils/knowledge_card_assets.dart';
import '../utils/knowledge_source_batch_utils.dart';
import '../widgets/knowledge_source_management_sheet.dart';
import '../widgets/knowledge_source_rechunk_sheet.dart';

class KnowledgeSourceDetailPage extends ConsumerStatefulWidget {
  const KnowledgeSourceDetailPage({super.key, required this.sourceId});

  final int sourceId;

  @override
  ConsumerState<KnowledgeSourceDetailPage> createState() =>
      _KnowledgeSourceDetailPageState();
}

class _KnowledgeSourceDetailPageState
    extends ConsumerState<KnowledgeSourceDetailPage> {
  bool _showOnlyUnconverted = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final sourceId = widget.sourceId;
    final sourceAsync = ref.watch(knowledgeSourceProvider(sourceId));
    final duplicatesAsync = ref.watch(
      knowledgeSourceDuplicateCandidatesProvider(sourceId),
    );
    final chunksAsync = ref.watch(knowledgeSourceChunksProvider(sourceId));
    final referencesAsync = ref.watch(
      knowledgeSourceCardReferencesProvider(sourceId),
    );

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: Text(
          '资料详情',
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        actions: sourceAsync.valueOrNull == null
            ? null
            : [
                IconButton(
                  key: const Key('knowledge-source-detail-edit-button'),
                  tooltip: '编辑资料',
                  onPressed: () => _editSource(sourceAsync.valueOrNull!),
                  icon: Icon(Icons.edit_outlined, color: colors.textSecondary),
                ),
                _DetailSourceMenu(
                  linkedCardCount:
                      referencesAsync.valueOrNull
                          ?.map((reference) => reference.card.id)
                          .toSet()
                          .length ??
                      0,
                  onArchive: () => _archiveSource(sourceAsync.valueOrNull!),
                  onDelete: () => _deleteSource(
                    sourceAsync.valueOrNull!,
                    referencesAsync.valueOrNull
                            ?.map((reference) => reference.card.id)
                            .toSet()
                            .length ??
                        0,
                  ),
                ),
              ],
      ),
      body: ModulePageSurface(
        color: colors.study,
        child: sourceAsync.when(
          data: (source) {
            if (source == null) {
              return const Center(child: Text('资料不存在或已被移除'));
            }

            final linkedCardCount =
                referencesAsync.valueOrNull
                    ?.map((reference) => reference.card.id)
                    .toSet()
                    .length ??
                0;
            final duplicateCandidates =
                duplicatesAsync.valueOrNull ??
                const <KnowledgeSourceImportDuplicateCandidate>[];
            final showDuplicateSection =
                duplicatesAsync.isLoading || duplicateCandidates.isNotEmpty;

            return RefreshIndicator(
              onRefresh: () => _refreshSource(source.id),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _SourceSummaryCard(
                    source: source,
                    chunks: chunksAsync.valueOrNull,
                    references: referencesAsync.valueOrNull,
                    loading: chunksAsync.isLoading || referencesAsync.isLoading,
                    onGenerate: () => _generateSourceDrafts(source),
                    onRechunk: () => _editSourceContent(
                      source: source,
                      chunks:
                          chunksAsync.valueOrNull ?? const <KnowledgeChunk>[],
                      linkedCardCount: linkedCardCount,
                    ),
                  ),
                  if (showDuplicateSection) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionTitle('可能重复的资料'),
                    const SizedBox(height: AppSpacing.md),
                    duplicatesAsync.when(
                      data: (candidates) => _DuplicateCandidatesPanel(
                        candidates: candidates,
                        onKeepCandidate: _keepDuplicateSource,
                        onArchiveCandidate: (source) => _archiveSource(
                          source,
                          refreshSourceId: widget.sourceId,
                        ),
                      ),
                      loading: () => const CardSkeleton(height: 160),
                      error: (_, _) => const ErrorRetryWidget(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionTitle('资料切片'),
                  const SizedBox(height: AppSpacing.md),
                  chunksAsync.when(
                    data: (chunks) => referencesAsync.when(
                      data: (references) => _ChunkPanel(
                        source: source,
                        chunks: chunks,
                        references: references,
                        showOnlyUnconverted: _showOnlyUnconverted,
                        onShowOnlyUnconvertedChanged: (value) {
                          setState(() => _showOnlyUnconverted = value);
                        },
                        onGenerateChunk: (chunk) =>
                            _generateChunkDrafts(source: source, chunk: chunk),
                      ),
                      loading: () => const CardSkeleton(height: 220),
                      error: (_, _) => const ErrorRetryWidget(),
                    ),
                    loading: () => const CardSkeleton(height: 220),
                    error: (_, _) => const ErrorRetryWidget(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle('已生成知识卡'),
                  const SizedBox(height: AppSpacing.md),
                  referencesAsync.when(
                    data: (references) =>
                        _GeneratedCardsPanel(references: references),
                    loading: () => const CardSkeleton(height: 180),
                    error: (_, _) => const ErrorRetryWidget(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            );
          },
          loading: () =>
              Center(child: CircularProgressIndicator(color: colors.study)),
          error: (_, _) => const ErrorRetryWidget(),
        ),
      ),
    );
  }

  Future<void> _refreshSource(int sourceId) async {
    ref.invalidate(knowledgeSourcesProvider);
    ref.invalidate(knowledgeSourcesWithProgressProvider);
    ref.invalidate(knowledgeSourceDuplicateSummariesProvider);
    ref.invalidate(knowledgeBaseOverviewProvider);
    ref.invalidate(knowledgeChunkSearchProvider);
    ref.invalidate(knowledgeSourceProvider(sourceId));
    ref.invalidate(knowledgeSourceDuplicateCandidatesProvider(sourceId));
    ref.invalidate(knowledgeSourceChunksProvider(sourceId));
    ref.invalidate(knowledgeSourceCardReferencesProvider(sourceId));
    ref.invalidate(knowledgeSourceConversionProgressProvider(sourceId));
  }

  void _invalidateAfterSaving(int sourceId) {
    ref.invalidate(knowledgeCardsProvider);
    ref.invalidate(knowledgeGoalSummariesProvider);
    ref.invalidate(knowledgeDeckSummariesProvider);
    _refreshSource(sourceId);
  }

  Future<void> _editSource(KnowledgeSource source) async {
    final draft = await KnowledgeSourceMetadataSheet.show(
      context: context,
      source: source,
    );
    if (draft == null || !mounted) return;

    await ref
        .read(knowledgeSourceRepositoryProvider)
        .updateSourceMetadata(
          id: source.id,
          title: draft.title,
          type: draft.type,
          goalKey: draft.goalKey,
          goalName: draft.goalName,
          moduleKey: draft.moduleKey,
          moduleName: draft.moduleName,
          sourcePath: draft.sourcePath,
          tags: draft.tags,
        );
    await _refreshSource(source.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('资料设置已更新')));
  }

  Future<void> _archiveSource(
    KnowledgeSource source, {
    int? refreshSourceId,
  }) async {
    final colors = context.growthColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        surfaceTintColor: colors.card,
        title: const Text('归档资料'),
        content: const Text('归档后不会再参与本地搜索，但会保留现有数据和来源追溯。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: colors.danger),
            child: const Text('归档'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(knowledgeSourceRepositoryProvider).archiveSource(source.id);
    await _refreshSource(refreshSourceId ?? source.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('资料已归档')));
  }

  Future<void> _deleteSource(
    KnowledgeSource source,
    int linkedCardCount,
  ) async {
    if (linkedCardCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('这份资料已有 $linkedCardCount 张知识卡引用，请先归档以保留来源追溯。')),
      );
      return;
    }

    final colors = context.growthColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        surfaceTintColor: colors.card,
        title: const Text('删除资料'),
        content: Text('删除后会同时移除本地切片，而且无法恢复。\n\n资料标题：\n类型：'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: colors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(knowledgeSourceRepositoryProvider).deleteSource(source.id);
    await _refreshSource(source.id);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
    messenger.showSnackBar(const SnackBar(content: Text('资料已删除')));
  }

  Future<void> _keepDuplicateSource(KnowledgeSource source) async {
    await ref
        .read(knowledgeSourceRepositoryProvider)
        .markDuplicatePairKept(
          sourceId: widget.sourceId,
          candidateSourceId: source.id,
        );
    await _refreshSource(widget.sourceId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已标记为保留多个版本')));
  }

  Future<void> _editSourceContent({
    required KnowledgeSource source,
    required List<KnowledgeChunk> chunks,
    required int linkedCardCount,
  }) async {
    if (linkedCardCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '这份资料已有 $linkedCardCount 张知识卡引用，暂不支持直接重切片。请归档后导入新资料，以保留来源追溯。',
          ),
        ),
      );
      return;
    }

    final draft = await KnowledgeSourceRechunkSheet.show(
      context: context,
      sourceTitle: source.title,
      initialContent: _editableContentFromChunks(chunks),
    );
    if (draft == null || !mounted) return;

    try {
      await ref
          .read(knowledgeSourceRepositoryProvider)
          .replaceSourceContent(id: source.id, content: draft.content);
    } on ArgumentError {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('资料原文不能为空。')));
      return;
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    await _refreshSource(source.id);
    if (!mounted) return;
    final refreshedChunks = await ref.read(
      knowledgeSourceChunksProvider(source.id).future,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('资料已重切片，当前共有 ${refreshedChunks.length} 个片段。')),
    );
  }

  Future<void> _generateSourceDrafts(KnowledgeSource source) async {
    final repo = ref.read(knowledgeSourceRepositoryProvider);
    final latestSource = await ref.read(
      knowledgeSourceProvider(source.id).future,
    );
    if (latestSource == null || !mounted) return;

    final chunks = await repo.getChunksForSource(source.id);
    final references = await repo.getCardReferencesForSource(source.id);
    if (!mounted) return;

    final selected = buildKnowledgeSourceBatchResults(
      source: latestSource,
      chunks: chunks,
      references: references,
    );
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('这份资料暂时没有可处理的片段。')));
      return;
    }

    final service = ref.read(knowledgeCardAiServiceProvider);
    final payload = service.buildPayloadForResults(
      selected,
      topic: latestSource.title,
    );
    final confirmed = await _DetailAiMultiSendPreviewSheet.show(
      context: context,
      results: selected,
      payload: payload,
    );
    if (confirmed != true || !mounted) return;

    final ids = await _runAiGenerationForResults(
      selected: selected,
      topic: latestSource.title,
      emptyMessage: selected.length == 1
          ? '这份资料信息不足，AI 没有生成可用卡片。'
          : '这些片段信息不足，AI 没有生成可用卡片。',
    );
    if (ids == null || ids.isEmpty || !mounted) return;

    final feedback = buildKnowledgeSourceBatchSavedFeedback(
      savedCardCount: ids.length,
      allChunks: chunks,
      existingReferences: references,
      selectedResults: selected,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feedback.message),
        action: feedback.hasNextBatch
            ? SnackBarAction(
                label: '继续下一批',
                onPressed: () => _generateSourceDrafts(latestSource),
              )
            : null,
      ),
    );
  }

  Future<void> _generateChunkDrafts({
    required KnowledgeSource source,
    required KnowledgeChunk chunk,
  }) async {
    final service = ref.read(knowledgeCardAiServiceProvider);
    final result = KnowledgeChunkSearchResult(
      source: source,
      chunk: chunk,
      score: 0,
    );
    final payload = service.buildPayload(result);
    final confirmed = await _DetailAiSendPreviewSheet.show(
      context: context,
      result: result,
      payload: payload,
    );
    if (confirmed != true || !mounted) return;

    final ids = await _runAiGenerationForResults(
      selected: [result],
      topic: (chunk.heading ?? '').trim().isNotEmpty
          ? chunk.heading!.trim()
          : source.title,
      emptyMessage: '这个片段信息不足，AI 没有生成可用卡片。',
    );
    if (ids == null || ids.isEmpty || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已保存 ${ids.length} 张知识卡')));
  }

  Future<List<int>?> _runAiGenerationForResults({
    required List<KnowledgeChunkSearchResult> selected,
    required String topic,
    required String emptyMessage,
  }) async {
    final service = ref.read(knowledgeCardAiServiceProvider);

    if (!mounted) return null;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DetailAiGeneratingDialog(),
    );

    var generatingDialogOpen = true;
    try {
      final drafts = await service.generateDraftsFromResults(
        selected,
        topic: topic,
      );
      if (!mounted) return null;
      Navigator.of(context, rootNavigator: true).pop();
      generatingDialogOpen = false;

      if (drafts.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(emptyMessage)));
        return const <int>[];
      }

      final duplicateReasons = await service.findDuplicateReasonsFromResults(
        results: selected,
        drafts: drafts,
      );
      if (!mounted) return null;

      final chosen = await _DetailAiDraftPreviewSheet.show(
        context: context,
        drafts: drafts,
        duplicateReasons: duplicateReasons,
      );
      if (chosen == null || chosen.isEmpty) return null;

      final ids = await service.saveDraftsFromResults(
        results: selected,
        drafts: chosen,
      );
      if (selected.isNotEmpty) {
        _invalidateAfterSaving(selected.first.source.id);
      }
      return ids;
    } on KnowledgeCardAiException catch (error) {
      if (!mounted) return null;
      if (generatingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showAiError(error.message, canOpenConfig: true);
    } on AiServiceException catch (error) {
      if (!mounted) return null;
      if (generatingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showAiError(error.message);
    } on FormatException {
      if (!mounted) return null;
      if (generatingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showAiError('AI 返回格式不是可识别的卡片 JSON，请重试一次。');
    } catch (_) {
      if (!mounted) return null;
      if (generatingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showAiError('生成失败，请检查 AI 配置或网络后重试。');
    }
    return null;
  }

  void _showAiError(String message, {bool canOpenConfig = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: canOpenConfig
            ? SnackBarAction(
                label: '去配置',
                onPressed: () => context.push('/ai-config'),
              )
            : null,
      ),
    );
  }
}

class _DetailSourceMenu extends StatelessWidget {
  const _DetailSourceMenu({
    required this.linkedCardCount,
    required this.onArchive,
    required this.onDelete,
  });

  final int linkedCardCount;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return PopupMenuButton<_DetailSourceAction>(
      key: const Key('knowledge-source-detail-menu-button'),
      tooltip: '资料操作',
      icon: Icon(Icons.more_horiz_rounded, color: colors.textSecondary),
      onSelected: (action) {
        switch (action) {
          case _DetailSourceAction.archive:
            onArchive();
            break;
          case _DetailSourceAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem<_DetailSourceAction>(
          value: _DetailSourceAction.archive,
          child: Row(
            children: [
              Icon(Icons.archive_outlined, size: 18),
              SizedBox(width: 10),
              Text('归档资料'),
            ],
          ),
        ),
        if (linkedCardCount == 0)
          const PopupMenuItem<_DetailSourceAction>(
            value: _DetailSourceAction.delete,
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, size: 18),
                SizedBox(width: 10),
                Text('删除资料'),
              ],
            ),
          )
        else
          PopupMenuItem<_DetailSourceAction>(
            enabled: false,
            child: SizedBox(
              width: 220,
              child: Text(
                '已有 $linkedCardCount 张知识卡引用，先归档以保留来源追溯。',
                style: TextStyle(color: colors.textTertiary),
              ),
            ),
          ),
      ],
    );
  }
}

enum _DetailSourceAction { archive, delete }

class _SourceSummaryCard extends StatelessWidget {
  const _SourceSummaryCard({
    required this.source,
    required this.chunks,
    required this.references,
    required this.loading,
    required this.onGenerate,
    required this.onRechunk,
  });

  final KnowledgeSource source;
  final List<KnowledgeChunk>? chunks;
  final List<KnowledgeSourceCardReference>? references;
  final bool loading;
  final VoidCallback onGenerate;
  final VoidCallback onRechunk;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final loadedChunks = chunks ?? const <KnowledgeChunk>[];
    final loadedReferences =
        references ?? const <KnowledgeSourceCardReference>[];
    final chunkCount = loadedChunks.length;
    final tokenTotal = loadedChunks.fold<int>(
      0,
      (sum, chunk) => sum + chunk.tokenEstimate,
    );
    final distinctCardCount = loadedReferences
        .map((reference) => reference.card.id)
        .toSet()
        .length;
    final convertedChunkCount = loadedReferences
        .map((reference) => reference.chunk.id)
        .toSet()
        .length;
    final pendingCount = chunkCount - convertedChunkCount;
    final nextBatch = chunkCount == 0
        ? const <KnowledgeChunkSearchResult>[]
        : buildKnowledgeSourceBatchResults(
            source: source,
            chunks: loadedChunks,
            references: loadedReferences,
          );
    final nextTokenEstimate = nextBatch.fold<int>(
      0,
      (sum, result) => sum + result.chunk.tokenEstimate,
    );
    final hasPending = pendingCount > 0;
    final canRechunk = distinctCardCount == 0;

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
            source.title,
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${_goalNameForSource(source)} · ${_moduleNameForSource(source)}',
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(text: source.type),
              _MiniPill(text: '$chunkCount 个切片'),
              _MiniPill(text: '$distinctCardCount 张知识卡'),
              _MiniPill(text: '待沉淀 $pendingCount'),
              _MiniPill(text: '约 $tokenTotal tokens'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            loading
                ? '正在整理这份资料的切片与沉淀进度...'
                : hasPending
                ? '优先处理还没有转成知识卡的片段，继续把这份资料沉淀进本地知识库。'
                : '这份资料已经全部沉淀完成。如果你想换一种问法，也可以重新生成一批草稿。',
            style: TextStyle(color: colors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('knowledge-source-detail-generate-source-button'),
            onPressed: loading || chunkCount == 0 ? null : onGenerate,
            style: FilledButton.styleFrom(
              backgroundColor: colors.study,
              foregroundColor: colors.textOnAccent,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(hasPending ? '继续沉淀这份资料' : '重新生成一批草稿'),
          ),
          if (!loading && nextBatch.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '本批会发送 ${nextBatch.length} 个片段，约 $nextTokenEstimate tokens，不会上传整份资料。',
              style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('knowledge-source-detail-rechunk-button'),
            onPressed: loading || !canRechunk ? null : onRechunk,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
            label: Text(chunkCount == 0 ? '补充原文并切片' : '编辑原文并重切片'),
          ),
          if (!canRechunk) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '已有 $distinctCardCount 张知识卡引用。为了保持来源稳定，这份资料暂不支持直接重切片。',
              style: AppTextStyles.caption.copyWith(
                color: colors.textTertiary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DuplicateCandidatesPanel extends StatelessWidget {
  const _DuplicateCandidatesPanel({
    required this.candidates,
    required this.onKeepCandidate,
    required this.onArchiveCandidate,
  });

  final List<KnowledgeSourceImportDuplicateCandidate> candidates;
  final ValueChanged<KnowledgeSource> onKeepCandidate;
  final ValueChanged<KnowledgeSource> onArchiveCandidate;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '检测到 ${candidates.length} 份可能重复的资料，建议先确认是否需要合并、归档或保留多个版本，再继续沉淀知识卡。',
            style: TextStyle(color: colors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < candidates.length; i++) ...[
            _DuplicateCandidateTile(
              candidate: candidates[i],
              onKeep: candidates[i].source.archived
                  ? null
                  : () => onKeepCandidate(candidates[i].source),
              onArchive: candidates[i].source.archived
                  ? null
                  : () => onArchiveCandidate(candidates[i].source),
            ),
            if (i != candidates.length - 1)
              Divider(color: colors.divider, height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _DuplicateCandidateTile extends StatelessWidget {
  const _DuplicateCandidateTile({
    required this.candidate,
    this.onKeep,
    this.onArchive,
  });

  final KnowledgeSourceImportDuplicateCandidate candidate;
  final VoidCallback? onKeep;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final source = candidate.source;
    final sourcePath = source.sourcePath?.trim();
    final metaText =
        '${_goalNameForSource(source)} · ${_moduleNameForSource(source)}';

    return InkWell(
      key: ValueKey('knowledge-source-detail-duplicate-${source.id}'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push('/plan/study/knowledge/sources/${source.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    sourcePath != null && sourcePath.isNotEmpty
                        ? '$metaText · $sourcePath'
                        : metaText,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...candidate.reasons.map(
                        (reason) => _MiniPill(text: reason),
                      ),
                      _MiniPill(text: '${candidate.chunkCount} 个切片'),
                      _MiniPill(text: '${candidate.linkedCardCount} 张知识卡'),
                      if (source.archived) const _MiniPill(text: '已归档'),
                    ],
                  ),
                  if (candidate.reasonSummary.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      candidate.reasonSummary,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (onKeep != null)
              IconButton(
                key: ValueKey(
                  'knowledge-source-detail-duplicate-keep-${source.id}',
                ),
                tooltip: '保留多个版本',
                onPressed: onKeep,
                icon: Icon(Icons.layers_outlined, color: colors.textTertiary),
              ),
            if (onArchive != null)
              IconButton(
                key: ValueKey(
                  'knowledge-source-detail-duplicate-archive-${source.id}',
                ),
                tooltip: '褰掓。杩欎唤鍊欓€夎祫鏂?',
                onPressed: onArchive,
                icon: Icon(Icons.archive_outlined, color: colors.textTertiary),
              ),
            Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _ChunkPanel extends StatelessWidget {
  const _ChunkPanel({
    required this.source,
    required this.chunks,
    required this.references,
    required this.showOnlyUnconverted,
    required this.onShowOnlyUnconvertedChanged,
    required this.onGenerateChunk,
  });

  final KnowledgeSource source;
  final List<KnowledgeChunk> chunks;
  final List<KnowledgeSourceCardReference> references;
  final bool showOnlyUnconverted;
  final ValueChanged<bool> onShowOnlyUnconvertedChanged;
  final ValueChanged<KnowledgeChunk> onGenerateChunk;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final countsByChunkId = <int, int>{};
    for (final reference in references) {
      countsByChunkId.update(
        reference.chunk.id,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final visibleChunks = chunks
        .where(
          (chunk) =>
              !showOnlyUnconverted || (countsByChunkId[chunk.id] ?? 0) == 0,
        )
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            key: const Key('knowledge-source-detail-unconverted-filter'),
            value: showOnlyUnconverted,
            onChanged: onShowOnlyUnconvertedChanged,
            contentPadding: EdgeInsets.zero,
            title: const Text('只看未转卡片段'),
            subtitle: const Text('优先处理还没有沉淀成知识卡的内容。'),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (visibleChunks.isEmpty)
            EmptyStateWidget(
              icon: Icons.check_circle_outline_rounded,
              title: '没有待处理切片',
              subtitle: '当前资料的切片都已经转成知识卡了。',
              accentColor: colors.study,
            )
          else
            for (final chunk in visibleChunks) ...[
              _ChunkTile(
                chunk: chunk,
                generatedCardCount: countsByChunkId[chunk.id] ?? 0,
                onGenerate: () => onGenerateChunk(chunk),
              ),
              if (chunk != visibleChunks.last)
                Divider(color: colors.divider, height: AppSpacing.lg),
            ],
        ],
      ),
    );
  }
}

class _ChunkTile extends StatelessWidget {
  const _ChunkTile({
    required this.chunk,
    required this.generatedCardCount,
    required this.onGenerate,
  });

  final KnowledgeChunk chunk;
  final int generatedCardCount;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final heading = chunk.heading?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading == null || heading.isEmpty ? '未命名切片' : heading,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniPill(text: '${chunk.tokenEstimate} tokens'),
                      _MiniPill(
                        text: generatedCardCount == 0
                            ? '待沉淀'
                            : '已生成 $generatedCardCount 张卡',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            OutlinedButton.icon(
              key: ValueKey(
                'knowledge-source-detail-generate-chunk-${chunk.id}',
              ),
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text('生成草稿'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _compact(chunk.content),
          style: TextStyle(color: colors.textSecondary, height: 1.45),
        ),
      ],
    );
  }
}

class _GeneratedCardsPanel extends StatelessWidget {
  const _GeneratedCardsPanel({required this.references});

  final List<KnowledgeSourceCardReference> references;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final uniqueCards = <int, KnowledgeCard>{};
    for (final reference in references) {
      uniqueCards[reference.card.id] = reference.card;
    }
    final cards = uniqueCards.values.toList(growable: false);

    if (cards.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.style_outlined,
        title: '还没有知识卡',
        subtitle: '这份资料还没有沉淀出知识卡。',
        accentColor: colors.study,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (final card in cards) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                card.title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                card.question,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (card != cards.last)
              Divider(color: colors.divider, height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _DetailAiSendPreviewSheet extends StatelessWidget {
  const _DetailAiSendPreviewSheet({
    required this.result,
    required this.payload,
  });

  final KnowledgeChunkSearchResult result;
  final KnowledgeCardAiPayload payload;

  static Future<bool?> show({
    required BuildContext context,
    required KnowledgeChunkSearchResult result,
    required KnowledgeCardAiPayload payload,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _DetailAiSendPreviewSheet(result: result, payload: payload),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.74,
      minChildSize: 0.46,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const _SheetGrabber(),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: colors.study),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '确认发送给 AI 的片段',
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '只会发送下面这个片段，不会上传整份资料。AI 生成结果会先作为草稿，你确认后才会入库。',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniPill(text: result.source.title),
                if ((result.chunk.heading ?? '').trim().isNotEmpty)
                  _MiniPill(text: result.chunk.heading!.trim()),
                _MiniPill(text: '约 ${payload.tokenEstimate} tokens'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.paper,
                borderRadius: BorderRadius.circular(AppRadius.mlg),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                result.chunk.content.trim(),
                style: TextStyle(color: colors.textPrimary, height: 1.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.study,
                      foregroundColor: colors.textOnAccent,
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('确认生成'),
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

class _DetailAiMultiSendPreviewSheet extends StatelessWidget {
  const _DetailAiMultiSendPreviewSheet({
    required this.results,
    required this.payload,
  });

  final List<KnowledgeChunkSearchResult> results;
  final KnowledgeCardAiPayload payload;

  static Future<bool?> show({
    required BuildContext context,
    required List<KnowledgeChunkSearchResult> results,
    required KnowledgeCardAiPayload payload,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _DetailAiMultiSendPreviewSheet(results: results, payload: payload),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.50,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const _SheetGrabber(),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: colors.study),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '确认发送多个片段给 AI',
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '只会发送下面列出的 ${results.length} 个片段，不会上传整份资料。AI 结果仍会先作为草稿，你确认后才会入库。',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniPill(text: '${results.length} 个片段'),
                _MiniPill(text: '约 ${payload.tokenEstimate} tokens'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < results.length; i++) ...[
              _DetailChunkPreview(index: i, result: results[i]),
              if (i != results.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.study,
                      foregroundColor: colors.textOnAccent,
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('确认生成'),
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

class _DetailChunkPreview extends StatelessWidget {
  const _DetailChunkPreview({required this.index, required this.result});

  final int index;
  final KnowledgeChunkSearchResult result;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final heading = result.chunk.heading?.trim();
    final label = heading == null || heading.isEmpty
        ? result.source.title
        : '${result.source.title} · $heading';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. $label',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _excerpt(result.chunk.content),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _DetailAiGeneratingDialog extends StatelessWidget {
  const _DetailAiGeneratingDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: colors.card,
      content: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(color: colors.study),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'AI 正在基于片段生成草稿...',
              style: TextStyle(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailAiDraftPreviewSheet extends StatefulWidget {
  const _DetailAiDraftPreviewSheet({
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
      builder: (_) => _DetailAiDraftPreviewSheet(
        drafts: drafts,
        duplicateReasons: duplicateReasons,
      ),
    );
  }

  @override
  State<_DetailAiDraftPreviewSheet> createState() =>
      _DetailAiDraftPreviewSheetState();
}

class _DetailAiDraftPreviewSheetState
    extends State<_DetailAiDraftPreviewSheet> {
  late final List<_DetailEditableDraft> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = [
      for (var i = 0; i < widget.drafts.length; i++)
        _DetailEditableDraft(
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
    final colors = context.growthColors;
    final selectedCount = _drafts.where((draft) => draft.selected).length;
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.52,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          children: [
            const _SheetGrabber(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '确认知识卡草稿',
              style: AppTextStyles.sectionTitle.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '你可以取消勾选或直接编辑。保存后才会进入知识卡片库，并保留资料来源。',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < _drafts.length; i++) ...[
              _DetailEditableDraftCard(
                index: i,
                draft: _drafts[i],
                onSelectionChanged: (value) {
                  setState(() => _drafts[i].selected = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            FilledButton.icon(
              onPressed: selectedCount == 0 ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: colors.study,
                foregroundColor: colors.textOnAccent,
                minimumSize: const Size.fromHeight(48),
              ),
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

class _DetailEditableDraftCard extends StatelessWidget {
  const _DetailEditableDraftCard({
    required this.index,
    required this.draft,
    required this.onSelectionChanged,
  });

  final int index;
  final _DetailEditableDraft draft;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: draft.selected,
            onChanged: (value) => onSelectionChanged(value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              '草稿 ${index + 1}',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              draft.duplicateReason ?? '确认后写入本地知识卡片库',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          if (draft.duplicateReason != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: _MiniPill(text: '可能重复：${draft.duplicateReason}'),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: draft.titleController,
            decoration: const InputDecoration(labelText: '标题'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: draft.questionController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: '问题'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: draft.answerController,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: '答案'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: draft.explanationController,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(labelText: '解释（可选）'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: draft.tagsController,
            decoration: const InputDecoration(labelText: '标签（逗号分隔，可选）'),
          ),
        ],
      ),
    );
  }
}

class _DetailEditableDraft {
  _DetailEditableDraft(KnowledgeCardAiDraft draft, {this.duplicateReason})
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

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: context.growthColors.border,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.sectionTitle.copyWith(
        color: context.growthColors.textPrimary,
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(color: colors.textSecondary, fontSize: 12),
      ),
    );
  }
}

String _goalNameForSource(KnowledgeSource source) {
  if ((source.goalName ?? '').trim().isNotEmpty) {
    return source.goalName!.trim();
  }
  return KnowledgeCardAssets.goalForKey(source.goalKey).name;
}

String _moduleNameForSource(KnowledgeSource source) {
  if ((source.moduleName ?? '').trim().isNotEmpty) {
    return source.moduleName!.trim();
  }
  return KnowledgeCardAssets.moduleForKeys(
    source.goalKey,
    source.moduleKey,
  ).name;
}

String _compact(String text) {
  final compacted = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (compacted.length <= 220) return compacted;
  return '${compacted.substring(0, 220)}...';
}

String _excerpt(String text) {
  final compacted = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (compacted.length <= 140) return compacted;
  return '${compacted.substring(0, 140)}...';
}

String _editableContentFromChunks(List<KnowledgeChunk> chunks) {
  return chunks
      .map((chunk) => chunk.content.trim())
      .where((content) => content.isNotEmpty)
      .join('\n\n');
}
