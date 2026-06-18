import 'dart:io';
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
import '../../../shared/providers/service_providers.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../services/knowledge_card_ai_service.dart';
import '../utils/knowledge_card_assets.dart';
import '../utils/knowledge_source_batch_utils.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/knowledge_document_importer.dart';
import '../widgets/knowledge_source_management_sheet.dart';

class KnowledgeSourcesPage extends ConsumerStatefulWidget {
  const KnowledgeSourcesPage({super.key});

  @override
  ConsumerState<KnowledgeSourcesPage> createState() =>
      _KnowledgeSourcesPageState();
}

class _KnowledgeSourcesPageState extends ConsumerState<KnowledgeSourcesPage> {
  String _query = '';
  String? _searchGoalKey;
  String? _searchModuleKey;
  bool _showOnlyPendingSources = false;
  bool _showOnlyDuplicateSources = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final sources = ref.watch(knowledgeSourcesWithProgressProvider);
    final duplicateSummaries = ref.watch(
      knowledgeSourceDuplicateSummariesProvider,
    );
    final overview = ref.watch(knowledgeBaseOverviewProvider);
    final searchQuery = _query.trim();
    final searchResults = searchQuery.isEmpty
        ? null
        : ref.watch(
            knowledgeChunkSearchProvider(
              KnowledgeChunkSearchQuery(
                query: searchQuery,
                goalKey: _searchGoalKey,
                moduleKey: _searchModuleKey,
                limit: 10,
              ),
            ),
          );

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: Text(
          '本地知识库',
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: '数据健康检查',
            onPressed: () => _runHealthCheck(context),
            icon: Icon(
              Icons.health_and_safety_outlined,
              color: colors.textSecondary,
            ),
          ),
          IconButton(
            tooltip: '导入资料',
            onPressed: () => _showImportSheet(context),
            icon: Icon(Icons.note_add_rounded, color: colors.study),
          ),
        ],
      ),
      body: ModulePageSurface(
        color: colors.study,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(knowledgeSourcesProvider);
            ref.invalidate(knowledgeSourcesWithProgressProvider);
            ref.invalidate(knowledgeSourceDuplicateSummariesProvider);
            ref.invalidate(knowledgeBaseOverviewProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _KnowledgeSourceHero(onImport: () => _showImportSheet(context)),
              const SizedBox(height: AppSpacing.lg),
              overview.when(
                data: (item) => _KnowledgeBaseOverviewCard(overview: item),
                loading: () => const CardSkeleton(height: 140),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SearchPanel(
                query: _query,
                goalKey: _searchGoalKey,
                moduleKey: _searchModuleKey,
                onChanged: (value) => setState(() => _query = value),
                onScopeChanged: (goalKey, moduleKey) {
                  setState(() {
                    _searchGoalKey = goalKey;
                    _searchModuleKey = moduleKey;
                  });
                },
              ),
              if (searchQuery.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                searchResults!.when(
                  data: (items) =>
                      _SearchResults(results: items, query: searchQuery),
                  loading: () => const CardSkeleton(height: 180),
                  error: (_, _) => const ErrorRetryWidget(),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              Row(
                children: [
                  Text(
                    '资料列表',
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showImportSheet(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('导入'),
                  ),
                ],
              ),
              SwitchListTile(
                key: const Key('knowledge-source-pending-filter'),
                value: _showOnlyPendingSources,
                onChanged: (value) {
                  setState(() => _showOnlyPendingSources = value);
                },
                contentPadding: EdgeInsets.zero,
                title: const Text('只看待沉淀资料'),
                subtitle: const Text('聚焦还有片段未转成知识卡的资料'),
              ),
              SwitchListTile(
                key: const Key('knowledge-source-duplicate-filter'),
                value: _showOnlyDuplicateSources,
                onChanged: (value) {
                  setState(() => _showOnlyDuplicateSources = value);
                },
                contentPadding: EdgeInsets.zero,
                title: const Text('只看疑似重复资料'),
                subtitle: const Text('优先整理库内可能重复的资料，避免后续沉淀越积越乱'),
              ),
              const SizedBox(height: AppSpacing.md),
              sources.when(
                data: (items) => items.isEmpty
                    ? _EmptySourcesPanel(
                        onImport: () => _showImportSheet(context),
                      )
                    : duplicateSummaries.when(
                        data: (summaries) => _SourcesList(
                          items: items,
                          duplicateSummaries: summaries,
                          showOnlyPending: _showOnlyPendingSources,
                          showOnlyDuplicates: _showOnlyDuplicateSources,
                          goalKey: _searchGoalKey,
                          moduleKey: _searchModuleKey,
                        ),
                        loading: () => const CardSkeleton(height: 220),
                        error: (_, _) => const ErrorRetryWidget(),
                      ),
                loading: () => const CardSkeleton(height: 220),
                error: (_, _) => const ErrorRetryWidget(),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showImportSheet(context),
        backgroundColor: colors.study,
        foregroundColor: colors.textOnAccent,
        icon: const Icon(Icons.note_add_rounded),
        label: const Text('导入资料'),
      ),
    );
  }

  Future<String> Function(List<int>, String)? _buildOcrCallback() {
    final aiConfigRepo = ref.read(aiConfigRepositoryProvider);
    return (List<int> imageBytes, String mimeType) async {
      final aiConfig = await aiConfigRepo.getEnabledAiConfig();
      if (aiConfig == null) {
        throw Exception('请先在设置中配置 AI API Key');
      }
      final aiService = ref.read(aiServiceProvider);
      return aiService.ocrImage(
        apiKey: aiConfig.apiKey,
        baseUrl: aiConfig.baseUrl,
        model: aiConfig.modelName,
        imageBytes: imageBytes,
        mimeType: mimeType,
      );
    };
  }

  Future<void> _runHealthCheck(BuildContext context) async {
    final repo = ref.read(knowledgeSourceRepositoryProvider);
    final issues = await repo.checkHealth();
    if (!context.mounted) return;

    final colors = context.growthColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            Icon(
              issues.isEmpty
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
              color: issues.isEmpty ? colors.success : colors.warning,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(issues.isEmpty ? '数据健康' : '发现 ${issues.length} 个问题'),
          ],
        ),
        content: issues.isEmpty
            ? const Text('所有资料和来源引用均正常，没有发现问题。')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: issues.length,
                  separatorBuilder: (_, _) => const Divider(height: 16),
                  itemBuilder: (_, i) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: colors.warning,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          issues[i],
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_ImportSourceDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImportSourceSheet(ocrCallback: _buildOcrCallback()),
    );
    if (result == null) return;

    final repo = ref.read(knowledgeSourceRepositoryProvider);
    final duplicates = await repo.findImportDuplicateCandidates(
      title: result.title,
      content: result.content,
      sourcePath: result.sourcePath,
    );
    if (!context.mounted) return;
    if (duplicates.isNotEmpty) {
      final shouldContinue = await _KnowledgeSourceDuplicateDialog.show(
        context: context,
        duplicates: duplicates,
      );
      if (shouldContinue != true) return;
    }

    final sourceId = await repo.importTextSource(
      title: result.title,
      content: result.content,
      type: result.type,
      sourcePath: result.sourcePath,
      goalKey: result.goalKey,
      goalName: result.goalName,
      moduleKey: result.moduleKey,
      moduleName: result.moduleName,
      tags: result.tags,
    );
    _invalidateKnowledgeSourceProviders(ref, sourceId: sourceId);

    if (!context.mounted) return;
    final chunks = await repo.getChunksForSource(sourceId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已导入「${result.title}」，生成 ${chunks.length} 个片段')),
    );
  }
}

class _KnowledgeSourceDuplicateDialog extends StatelessWidget {
  const _KnowledgeSourceDuplicateDialog({required this.duplicates});

  final List<KnowledgeSourceImportDuplicateCandidate> duplicates;

  static Future<bool?> show({
    required BuildContext context,
    required List<KnowledgeSourceImportDuplicateCandidate> duplicates,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _KnowledgeSourceDuplicateDialog(duplicates: duplicates),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return AlertDialog(
      key: const Key('knowledge-source-duplicate-dialog'),
      backgroundColor: colors.card,
      surfaceTintColor: colors.card,
      title: const Text('发现可能重复的资料'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('下面这些资料和你准备导入的内容很像，继续导入可能会造成知识库重复。'),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final candidate in duplicates) ...[
                      _DuplicateSourceTile(candidate: candidate),
                      if (candidate != duplicates.last)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消导入'),
        ),
        FilledButton(
          key: const Key('knowledge-source-duplicate-continue-button'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('仍然导入'),
        ),
      ],
    );
  }
}

class _DuplicateSourceTile extends StatelessWidget {
  const _DuplicateSourceTile({required this.candidate});

  final KnowledgeSourceImportDuplicateCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            candidate.source.title,
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
              _SmallPill(text: candidate.source.archived ? '已归档' : '资料中'),
              _SmallPill(text: '${candidate.chunkCount} 个切片'),
              if (candidate.linkedCardCount > 0)
                _SmallPill(text: '${candidate.linkedCardCount} 张知识卡'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _duplicateReasonText(candidate),
            style: TextStyle(color: colors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _duplicateReasonText(
    KnowledgeSourceImportDuplicateCandidate candidate,
  ) {
    final reasons = <String>[];
    if (candidate.exactContentMatch) reasons.add('正文内容完全一致');
    if (candidate.similarContentMatch) reasons.add('正文内容高度相似');
    if (candidate.sameTitle) reasons.add('资料标题一致');
    if (candidate.sameSourcePath) reasons.add('来源说明一致');
    if (reasons.isEmpty) return '这份资料与当前导入内容相似。';
    return reasons.join(' · ');
  }
}

void _invalidateKnowledgeSourceProviders(WidgetRef ref, {int? sourceId}) {
  ref.invalidate(knowledgeSourcesProvider);
  ref.invalidate(knowledgeSourcesWithProgressProvider);
  ref.invalidate(knowledgeSourceDuplicateSummariesProvider);
  ref.invalidate(knowledgeBaseOverviewProvider);
  ref.invalidate(knowledgeChunkSearchProvider);
  if (sourceId != null) {
    ref.invalidate(knowledgeSourceProvider(sourceId));
    ref.invalidate(knowledgeSourceDuplicateCandidatesProvider(sourceId));
    ref.invalidate(knowledgeSourceChunksProvider(sourceId));
    ref.invalidate(knowledgeSourceCardReferencesProvider(sourceId));
    ref.invalidate(knowledgeSourceConversionProgressProvider(sourceId));
  }
}

class _KnowledgeSourceHero extends StatelessWidget {
  const _KnowledgeSourceHero({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxxl),
      child: AspectRatio(
        aspectRatio: 2.33,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              KnowledgeCardAssets.customTemplateBuilderWide,
              fit: BoxFit.cover,
              cacheWidth: 900,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    colors.card.withValues(alpha: 0.97),
                    colors.card.withValues(alpha: 0.74),
                    colors.card.withValues(alpha: 0.10),
                  ],
                ),
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(AppRadius.xxxl),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '知识库原材料',
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '先把笔记和资料留在本地，之后 AI 只读取相关片段来生成知识卡。',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: onImport,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.study,
                          foregroundColor: colors.textOnAccent,
                        ),
                        icon: const Icon(Icons.note_add_rounded, size: 18),
                        label: const Text('导入文本'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeBaseOverviewCard extends StatelessWidget {
  const _KnowledgeBaseOverviewCard({required this.overview});

  final KnowledgeBaseOverview overview;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final ratioPercent = (overview.linkedChunkRatio * 100).round();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded, color: colors.study, size: 20),
              const SizedBox(width: 8),
              Text(
                '知识库总览',
                style: AppTextStyles.sectionTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            overview.statusText,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _OverviewMetric(label: '资料', value: '${overview.sourceCount}'),
              _OverviewMetric(label: '切片', value: '${overview.chunkCount}'),
              _OverviewMetric(
                label: '已关联卡',
                value: '${overview.linkedCardCount}',
              ),
              _OverviewMetric(
                label: '待沉淀',
                value: '${overview.pendingChunkCount}',
              ),
              _OverviewMetric(label: '待复习', value: '${overview.dueCardCount}'),
              _OverviewMetric(label: '薄弱卡', value: '${overview.weakCardCount}'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: overview.linkedChunkRatio,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: colors.border,
            color: colors.study,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '已关联 ${overview.linkedChunkCount}/${overview.chunkCount} 个片段 · 待沉淀 ${overview.pendingChunkCount} 个 · $ratioPercent%',
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.query,
    required this.goalKey,
    required this.moduleKey,
    required this.onChanged,
    required this.onScopeChanged,
  });

  final String query;
  final String? goalKey;
  final String? moduleKey;
  final ValueChanged<String> onChanged;
  final void Function(String? goalKey, String? moduleKey) onScopeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final selectedGoal = goalKey == null
        ? null
        : KnowledgeCardAssets.goalForKey(goalKey);
    final selectedModules = selectedGoal?.modules ?? const [];
    final normalizedModuleKey =
        selectedModules.any((module) => module.key == moduleKey)
        ? moduleKey
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          TextField(
            key: const Key('knowledge-source-search-field'),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: '搜索资料片段，例如：进程 线程 调度',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colors.textTertiary,
              ),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => onChanged(''),
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: colors.paper,
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
                borderSide: BorderSide(color: colors.study, width: 1.3),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: const Key('knowledge-source-search-goal-filter'),
                  initialValue: goalKey,
                  decoration: const InputDecoration(
                    labelText: '搜索目标',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('全部目标'),
                    ),
                    for (final goal in KnowledgeCardAssets.goalTemplates)
                      DropdownMenuItem<String?>(
                        value: goal.key,
                        child: Text(goal.name),
                      ),
                  ],
                  onChanged: (value) {
                    final nextGoal = value == null
                        ? null
                        : KnowledgeCardAssets.goalForKey(value);
                    onScopeChanged(value, nextGoal?.modules.first.key);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey(
                    'knowledge-source-search-module-filter-${goalKey ?? 'all'}',
                  ),
                  initialValue: normalizedModuleKey,
                  decoration: const InputDecoration(
                    labelText: '目标内模块',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('全部模块'),
                    ),
                    for (final module in selectedModules)
                      DropdownMenuItem<String?>(
                        value: module.key,
                        child: Text(module.name),
                      ),
                  ],
                  onChanged: goalKey == null
                      ? null
                      : (value) => onScopeChanged(goalKey, value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.query});

  final List<KnowledgeChunkSearchResult> results;
  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    if (results.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: '没有找到相关片段',
        subtitle: '换个关键词，或先导入更多学习资料。',
        accentColor: colors.study,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.90),
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
                  '相关片段',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MultiChunkGenerateButton(results: results, query: query),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final result in results) ...[
            _ChunkResultTile(result: result, query: query),
            if (result != results.last)
              Divider(height: AppSpacing.lg, color: colors.divider),
          ],
        ],
      ),
    );
  }
}

class _ChunkResultTile extends ConsumerWidget {
  const _ChunkResultTile({required this.result, this.query});

  final KnowledgeChunkSearchResult result;
  final String? query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final heading = result.chunk.heading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article_outlined, color: colors.study, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                heading == null || heading.isEmpty
                    ? result.source.title
                    : '${result.source.title} · $heading',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _SmallPill(text: '约 ${result.chunk.tokenEstimate} tokens'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _HighlightedText(
          text: _excerpt(result.chunk.content),
          query: query,
          maxLines: 4,
          style: TextStyle(color: colors.textSecondary, height: 1.45),
          highlightColor: colors.study.withValues(alpha: 0.18),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _generateDrafts(context, ref),
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: const Text('用这个片段生成卡片'),
        ),
      ],
    );
  }

  Future<void> _generateDrafts(BuildContext context, WidgetRef ref) async {
    final service = ref.read(knowledgeCardAiServiceProvider);
    final payload = service.buildPayload(result);
    final confirmed = await _AiSendPreviewSheet.show(
      context: context,
      result: result,
      payload: payload,
    );
    if (confirmed != true) return;

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _AiGeneratingDialog(),
    );

    var generatingDialogOpen = true;
    try {
      final drafts = await service.generateDrafts(result);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      generatingDialogOpen = false;

      if (drafts.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('这个片段信息不足，AI 没有生成可用卡片')));
        return;
      }

      final duplicateReasons = await service.findDuplicateReasonsFromResults(
        results: [result],
        drafts: drafts,
      );
      if (!context.mounted) return;
      final selected = await _AiDraftPreviewSheet.show(
        context: context,
        drafts: drafts,
        duplicateReasons: duplicateReasons,
      );
      if (selected == null || selected.isEmpty) return;

      final ids = await service.saveDrafts(result: result, drafts: selected);
      ref.invalidate(knowledgeCardsProvider);
      ref.invalidate(knowledgeGoalSummariesProvider);
      ref.invalidate(knowledgeDeckSummariesProvider);
        ref.invalidate(knowledgeBaseOverviewProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已保存 ${ids.length} 张知识卡')));
    } on KnowledgeCardAiException catch (e) {
      if (!context.mounted) return;
      if (generatingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showAiError(context, e.message, canOpenConfig: true);
    } on AiServiceException catch (e) {
      if (!context.mounted) return;
      if (generatingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      final msg = e.message.contains('timeout') || e.message.contains('超时')
          ? 'AI 请求超时，请检查网络后重试。'
          : e.message;
      _showAiError(context, msg, onRetry: () => _generateDrafts(context, ref));
    } on FormatException catch (_) {
      if (!context.mounted) return;
      if (generatingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showAiError(
        context,
        'AI 返回格式不是可识别的卡片 JSON，请重试一次。',
        onRetry: () => _generateDrafts(context, ref),
      );
    } catch (_) {
      if (!context.mounted) return;
      if (generatingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showAiError(
        context,
        '生成失败，请检查 AI 配置或网络后重试。',
        onRetry: () => _generateDrafts(context, ref),
      );
    }
  }

  void _showAiError(
    BuildContext context,
    String message, {
    bool canOpenConfig = false,
    VoidCallback? onRetry,
  }) {
    final actions = <SnackBarAction>[];
    if (onRetry != null) {
      actions.add(SnackBarAction(label: '重试', onPressed: onRetry));
    }
    if (canOpenConfig) {
      actions.add(
        SnackBarAction(
          label: '去配置',
          onPressed: () => context.push('/ai-config'),
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: actions.isNotEmpty
            ? actions.length == 1
                  ? actions.first
                  : actions.last
            : null,
      ),
    );
  }
}

class _MultiChunkGenerateButton extends ConsumerWidget {
  const _MultiChunkGenerateButton({required this.results, required this.query});

  final List<KnowledgeChunkSearchResult> results;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = _topResults(results);
    if (selected.length < 2) return const SizedBox.shrink();

    return OutlinedButton.icon(
      key: const Key('knowledge-source-generate-from-results-button'),
      onPressed: () => _generateDrafts(context, ref, selected),
      icon: const Icon(Icons.auto_awesome_motion_rounded, size: 18),
      label: Text('用 ${selected.length} 个片段生成'),
    );
  }

  Future<void> _generateDrafts(
    BuildContext context,
    WidgetRef ref,
    List<KnowledgeChunkSearchResult> selected,
  ) async {
    final service = ref.read(knowledgeCardAiServiceProvider);
    final payload = service.buildPayloadForResults(selected, topic: query);
    final confirmed = await _AiMultiSendPreviewSheet.show(
      context: context,
      results: selected,
      payload: payload,
    );
    if (confirmed != true) return;

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _AiGeneratingDialog(),
    );

    var generatingDialogOpen = true;
    try {
      final drafts = await service.generateDraftsFromResults(
        selected,
        topic: query,
      );
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      generatingDialogOpen = false;

      if (drafts.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('这些片段信息不足，AI 没有生成可用卡片')));
        return;
      }

      final duplicateReasons = await service.findDuplicateReasonsFromResults(
        results: selected,
        drafts: drafts,
      );
      if (!context.mounted) return;
      final chosen = await _AiDraftPreviewSheet.show(
        context: context,
        drafts: drafts,
        duplicateReasons: duplicateReasons,
      );
      if (chosen == null || chosen.isEmpty) return;

      final ids = await service.saveDraftsFromResults(
        results: selected,
        drafts: chosen,
      );
      ref.invalidate(knowledgeCardsProvider);
      ref.invalidate(knowledgeGoalSummariesProvider);
      ref.invalidate(knowledgeDeckSummariesProvider);
        ref.invalidate(knowledgeBaseOverviewProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已保存 ${ids.length} 张知识卡')));
    } on KnowledgeCardAiException catch (e) {
      if (!context.mounted) return;
      if (generatingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showAiError(context, e.message, canOpenConfig: true);
    } on AiServiceException catch (e) {
      if (!context.mounted) return;
      if (generatingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showAiError(context, e.message);
    } on FormatException catch (_) {
      if (!context.mounted) return;
      if (generatingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showAiError(context, 'AI 返回格式不是可识别的卡片 JSON，请重试一次。');
    } catch (_) {
      if (!context.mounted) return;
      if (generatingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showAiError(context, '生成失败，请检查 AI 配置或网络后重试。');
    }
  }

  List<KnowledgeChunkSearchResult> _topResults(
    List<KnowledgeChunkSearchResult> results,
  ) {
    final seen = <int>{};
    final selected = <KnowledgeChunkSearchResult>[];
    for (final result in results) {
      if (seen.add(result.chunk.id)) selected.add(result);
      if (selected.length >= 5) break;
    }
    return selected;
  }

  void _showAiError(
    BuildContext context,
    String message, {
    bool canOpenConfig = false,
  }) {
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

class _AiSendPreviewSheet extends StatelessWidget {
  const _AiSendPreviewSheet({required this.result, required this.payload});

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
      builder: (ctx) => _AiSendPreviewSheet(result: result, payload: payload),
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
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
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
              '只会发送下面这个检索片段，不会上传整份资料。AI 生成结果会先作为草稿，你确认后才会入库。',
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
                _SmallPill(text: result.source.title),
                if ((result.chunk.heading ?? '').trim().isNotEmpty)
                  _SmallPill(text: result.chunk.heading!.trim()),
                _SmallPill(text: '约 ${payload.tokenEstimate} tokens'),
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

class _AiMultiSendPreviewSheet extends StatelessWidget {
  const _AiMultiSendPreviewSheet({
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
      builder: (ctx) =>
          _AiMultiSendPreviewSheet(results: results, payload: payload),
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
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
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
              '只会发送下面列出的 ${results.length} 个检索片段，不会上传整份资料。AI 结果仍会先作为草稿，你确认后才会入库。',
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
                _SmallPill(text: '${results.length} 个片段'),
                _SmallPill(text: '约 ${payload.tokenEstimate} tokens'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < results.length; i++) ...[
              _MultiSendChunkPreview(index: i, result: results[i]),
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

class _MultiSendChunkPreview extends StatelessWidget {
  const _MultiSendChunkPreview({required this.index, required this.result});

  final int index;
  final KnowledgeChunkSearchResult result;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final heading = result.chunk.heading?.trim();
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
            '${index + 1}. ${heading == null || heading.isEmpty ? result.source.title : '${result.source.title} · $heading'}',
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

class _AiGeneratingDialog extends StatelessWidget {
  const _AiGeneratingDialog();

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

class _AiDraftPreviewSheet extends StatefulWidget {
  const _AiDraftPreviewSheet({
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
      builder: (ctx) => _AiDraftPreviewSheet(
        drafts: drafts,
        duplicateReasons: duplicateReasons,
      ),
    );
  }

  @override
  State<_AiDraftPreviewSheet> createState() => _AiDraftPreviewSheetState();
}

class _AiDraftPreviewSheetState extends State<_AiDraftPreviewSheet> {
  late final List<_EditableDraft> _drafts;

  @override
  void initState() {
    super.initState();
    final qualityWarnings = KnowledgeCardAiService.checkDraftQuality(
      widget.drafts,
    );
    _drafts = [
      for (var i = 0; i < widget.drafts.length; i++)
        _EditableDraft(
          widget.drafts[i],
          duplicateReason: i < widget.duplicateReasons.length
              ? widget.duplicateReasons[i]
              : null,
          qualityWarning: i < qualityWarnings.length
              ? qualityWarnings[i]
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
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '确认知识卡草稿',
              style: AppTextStyles.sectionTitle.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '可以取消勾选或直接编辑。保存后才会进入知识卡片库，并保留资料来源。',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < _drafts.length; i++) ...[
              _EditableDraftCard(
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

class _EditableDraftCard extends StatelessWidget {
  const _EditableDraftCard({
    required this.index,
    required this.draft,
    required this.onSelectionChanged,
  });

  final int index;
  final _EditableDraft draft;
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
              draft.duplicateReason ?? draft.qualityWarning ?? '确认后写入本地知识卡片库',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          if (draft.duplicateReason != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: _SmallPill(text: '可能重复：${draft.duplicateReason}'),
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

class _EditableDraft {
  _EditableDraft(
    KnowledgeCardAiDraft draft, {
    this.duplicateReason,
    this.qualityWarning,
  }) : titleController = TextEditingController(text: draft.title),
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
  final String? qualityWarning;
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

class _SourcesList extends ConsumerWidget {
  const _SourcesList({
    required this.items,
    required this.duplicateSummaries,
    required this.showOnlyPending,
    required this.showOnlyDuplicates,
    required this.goalKey,
    required this.moduleKey,
  });

  final List<KnowledgeSourceWithProgress> items;
  final Map<int, KnowledgeSourceDuplicateSummary> duplicateSummaries;
  final bool showOnlyPending;
  final bool showOnlyDuplicates;
  final String? goalKey;
  final String? moduleKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final visibleItems = items
        .where((item) => _matchesScope(item.source))
        .where((item) => !showOnlyPending || item.progress.hasPendingChunks)
        .where(
          (item) =>
              !showOnlyDuplicates ||
              (duplicateSummaries[item.source.id]?.hasDuplicates ?? false),
        )
        .toList(growable: false);
    final firstPending = _firstPendingItem(visibleItems);
    final pendingChunkTotal = visibleItems.fold<int>(
      0,
      (sum, item) => sum + item.progress.pendingChunkCount,
    );
    if (visibleItems.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.check_circle_outline_rounded,
        title: showOnlyPending ? '没有待沉淀资料' : '没有匹配的资料',
        subtitle: showOnlyPending
            ? '当前范围内的资料都已经转成知识卡，可以继续复习或导入新资料。'
            : '可以切换目标/模块筛选，或导入新的学习资料。',
        accentColor: colors.study,
      );
    }

    return Column(
      children: [
        if (firstPending != null) ...[
          _ScopePendingActionCard(
            item: firstPending,
            pendingChunkTotal: pendingChunkTotal,
            onPressed: () =>
                _continueScopeConversion(context, ref, visibleItems),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final item in visibleItems) ...[
          _SourceCard(
            source: item.source,
            progress: item.progress,
            duplicateSummary: duplicateSummaries[item.source.id],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  bool _matchesScope(KnowledgeSource source) {
    if (goalKey != null && source.goalKey != goalKey) return false;
    if (moduleKey != null && source.moduleKey != moduleKey) return false;
    return true;
  }

  KnowledgeSourceWithProgress? _firstPendingItem(
    List<KnowledgeSourceWithProgress> items,
  ) {
    for (final item in items) {
      if (item.progress.hasPendingChunks) return item;
    }
    return null;
  }
}

class _ScopePendingActionCard extends StatelessWidget {
  const _ScopePendingActionCard({
    required this.item,
    required this.pendingChunkTotal,
    required this.onPressed,
  });

  final KnowledgeSourceWithProgress item;
  final int pendingChunkTotal;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.study.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_motion_rounded, color: colors.study),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '当前范围还有 $pendingChunkTotal 个片段待沉淀，先处理「${item.source.title}」。',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            key: const Key('knowledge-source-scope-continue-button'),
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: colors.study,
              foregroundColor: colors.textOnAccent,
            ),
            child: const Text('处理当前范围'),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends ConsumerWidget {
  const _SourceCard({
    required this.source,
    required this.progress,
    this.duplicateSummary,
  });

  final KnowledgeSource source;
  final KnowledgeSourceConversionProgress progress;
  final KnowledgeSourceDuplicateSummary? duplicateSummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final duplicateCount = duplicateSummary?.duplicateCount ?? 0;
    final archivedDuplicateCount =
        duplicateSummary?.archivedDuplicateCount ?? 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('knowledge-source-card-${source.id}'),
        onTap: () => context.push('/plan/study/knowledge/sources/${source.id}'),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.study.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.mlg),
                ),
                child: Icon(Icons.library_books_rounded, color: colors.study),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _SmallPill(text: source.type),
                        _SmallPill(
                          text:
                              '${progress.convertedChunkCount}/${progress.chunkCount} 片段已转卡',
                        ),
                        progress.hasPendingChunks
                            ? _SmallPill(
                                text: '待沉淀 ${progress.pendingChunkCount}',
                              )
                            : const _SmallPill(text: '已沉淀完成'),
                        if (duplicateCount > 0)
                          _SmallPill(text: '疑似重复 $duplicateCount 份'),
                        if (duplicateCount == 0 && archivedDuplicateCount > 0)
                          _SmallPill(
                            text: '宸插綊妗ｉ噸澶? $archivedDuplicateCount 浠?',
                          ),
                        _SmallPill(text: _formatDate(source.createdAt)),
                      ],
                    ),
                    if (duplicateCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          '可能与 $duplicateCount 份资料重复，点开详情可继续整理。',
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                    if (duplicateCount == 0 && archivedDuplicateCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          '原先的重复候选已归档 $archivedDuplicateCount 份，当前活跃资料已没有未处理的重复项。',
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                    if (progress.hasPendingChunks)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: TextButton.icon(
                          key: ValueKey('knowledge-source-direct-${source.id}'),
                          onPressed: () =>
                              _continueSourceConversion(context, ref, source),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: colors.study,
                          ),
                          icon: const Icon(
                            Icons.auto_awesome_motion_rounded,
                            size: 16,
                          ),
                          label: const Text('继续沉淀这份资料'),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '归档资料',
                onPressed: () => _archive(context, ref),
                icon: Icon(Icons.archive_outlined, color: colors.textTertiary),
              ),
              PopupMenuButton<_SourceCardAction>(
                key: ValueKey('knowledge-source-card-menu-${source.id}'),
                tooltip: '资料操作',
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: colors.textTertiary,
                ),
                onSelected: (action) {
                  switch (action) {
                    case _SourceCardAction.edit:
                      _edit(context, ref);
                    case _SourceCardAction.archive:
                      _archive(context, ref);
                    case _SourceCardAction.delete:
                      _delete(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<_SourceCardAction>(
                    key: Key('knowledge-source-card-edit-action'),
                    value: _SourceCardAction.edit,
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('编辑资料'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<_SourceCardAction>(
                    key: Key('knowledge-source-card-archive-action'),
                    value: _SourceCardAction.archive,
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('归档资料'),
                      ],
                    ),
                  ),
                  if (progress.linkedCardCount == 0)
                    const PopupMenuItem<_SourceCardAction>(
                      key: Key('knowledge-source-card-delete-action'),
                      value: _SourceCardAction.delete,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('删除资料'),
                        ],
                      ),
                    )
                  else
                    PopupMenuItem<_SourceCardAction>(
                      enabled: false,
                      child: SizedBox(
                        width: 220,
                        child: Text(
                          '已有 ${progress.linkedCardCount} 张知识卡引用，先归档以保留来源追溯。',
                          style: TextStyle(color: colors.textTertiary),
                        ),
                      ),
                    ),
                ],
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final draft = await KnowledgeSourceMetadataSheet.show(
      context: context,
      source: source,
    );
    if (draft == null) return;

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
    _invalidateKnowledgeSourceProviders(ref, sourceId: source.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('资料设置已更新')));
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final colors = context.growthColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        surfaceTintColor: colors.card,
        title: const Text('归档资料'),
        content: Text('确定要归档「${source.title}」吗？归档后不会参与本地搜索。'),
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
    if (confirmed != true) return;
    await ref.read(knowledgeSourceRepositoryProvider).archiveSource(source.id);
    _invalidateKnowledgeSourceProviders(ref, sourceId: source.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('资料已归档')));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (progress.linkedCardCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '这份资料已有 ${progress.linkedCardCount} 张知识卡引用，先归档以保留来源追溯。',
          ),
        ),
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
        content: Text('确定要删除「${source.title}」吗？这会同时移除本地切片，且无法恢复。'),
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
    if (confirmed != true) return;

    await ref.read(knowledgeSourceRepositoryProvider).deleteSource(source.id);
    _invalidateKnowledgeSourceProviders(ref, sourceId: source.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('资料已删除')));
  }
}

enum _SourceCardAction { edit, archive, delete }

Future<void> _continueSourceConversion(
  BuildContext context,
  WidgetRef ref,
  KnowledgeSource source,
) async {
  final sourceId = source.id;
  final sourceRepo = ref.read(knowledgeSourceRepositoryProvider);
  final latestSource = await ref.read(knowledgeSourceProvider(sourceId).future);
  if (latestSource == null || !context.mounted) return;

  final chunks = await sourceRepo.getChunksForSource(sourceId);
  final references = await sourceRepo.getCardReferencesForSource(sourceId);
  if (!context.mounted) return;
  final selected = buildKnowledgeSourceBatchResults(
    source: latestSource,
    chunks: chunks,
    references: references,
  );
  if (selected.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('这份资料已经没有待沉淀片段')));
    return;
  }

  await _showSourceBatchGenerationFlow(
    context: context,
    ref: ref,
    selected: selected,
    source: latestSource,
    chunks: chunks,
    references: references,
  );
}

Future<void> _continueScopeConversion(
  BuildContext context,
  WidgetRef ref,
  List<KnowledgeSourceWithProgress> visibleItems,
) async {
  final pendingItems = visibleItems
      .where((item) => item.progress.hasPendingChunks)
      .toList(growable: false);
  if (pendingItems.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('当前范围已经没有待沉淀片段')));
    return;
  }

  final sourceRepo = ref.read(knowledgeSourceRepositoryProvider);
  final contexts = <KnowledgeSourceBatchContext>[];
  for (final item in pendingItems) {
    final sourceId = item.source.id;
    final latestSource = await ref.read(
      knowledgeSourceProvider(sourceId).future,
    );
    if (!context.mounted) return;
    if (latestSource == null) continue;

    final chunks = await sourceRepo.getChunksForSource(sourceId);
    final references = await sourceRepo.getCardReferencesForSource(sourceId);
    if (!context.mounted) return;
    contexts.add(
      KnowledgeSourceBatchContext(
        source: latestSource,
        chunks: chunks,
        references: references,
      ),
    );
  }

  final selected = buildKnowledgeSourceRangeBatchResults(contexts: contexts);
  if (selected.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('当前范围已经没有待沉淀片段')));
    return;
  }

  await _showSourceBatchGenerationFlow(
    context: context,
    ref: ref,
    selected: selected,
    source: contexts.first.source,
    chunks: contexts.first.chunks,
    references: contexts.first.references,
    rangeContexts: contexts,
  );
}

Future<void> _showSourceBatchGenerationFlow({
  required BuildContext context,
  required WidgetRef ref,
  required KnowledgeSource source,
  required List<KnowledgeChunk> chunks,
  required List<KnowledgeSourceCardReference> references,
  required List<KnowledgeChunkSearchResult> selected,
  List<KnowledgeSourceBatchContext>? rangeContexts,
}) async {
  final service = ref.read(knowledgeCardAiServiceProvider);
  final payload = service.buildPayloadForResults(selected, topic: source.title);
  final confirmed = await _AiMultiSendPreviewSheet.show(
    context: context,
    results: selected,
    payload: payload,
  );
  if (confirmed != true) return;

  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _AiGeneratingDialog(),
  );

  var generatingDialogOpen = true;
  try {
    final drafts = await service.generateDraftsFromResults(
      selected,
      topic: source.title,
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    generatingDialogOpen = false;

    if (drafts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('这份资料信息不足，AI 没有生成可用卡片')));
      return;
    }

    final duplicateReasons = await service.findDuplicateReasonsFromResults(
      results: selected,
      drafts: drafts,
    );
    if (!context.mounted) return;
    final chosen = await _AiDraftPreviewSheet.show(
      context: context,
      drafts: drafts,
      duplicateReasons: duplicateReasons,
    );
    if (chosen == null || chosen.isEmpty) return;

    final ids = await service.saveDraftsFromResults(
      results: selected,
      drafts: chosen,
    );
    ref.invalidate(knowledgeCardsProvider);
    ref.invalidate(knowledgeGoalSummariesProvider);
    ref.invalidate(knowledgeDeckSummariesProvider);
    ref.invalidate(knowledgeBaseOverviewProvider);
    ref.invalidate(knowledgeSourcesWithProgressProvider);
    final affectedSourceIds =
        (rangeContexts?.map((context) => context.source.id) ?? [source.id])
            .toSet();
    for (final sourceId in affectedSourceIds) {
      ref.invalidate(knowledgeSourceConversionProgressProvider(sourceId));
      ref.invalidate(knowledgeSourceCardReferencesProvider(sourceId));
    }

    if (!context.mounted) return;
    final feedback = rangeContexts == null
        ? buildKnowledgeSourceBatchSavedFeedback(
            savedCardCount: ids.length,
            allChunks: chunks,
            existingReferences: references,
            selectedResults: selected,
          )
        : buildKnowledgeSourceRangeBatchSavedFeedback(
            savedCardCount: ids.length,
            contexts: rangeContexts,
            selectedResults: selected,
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feedback.message),
        action: feedback.hasNextBatch
            ? SnackBarAction(
                label: '继续下一批',
                onPressed: () => _continueAfterBatchFeedback(
                  context: context,
                  ref: ref,
                  source: source,
                  rangeContexts: rangeContexts,
                ),
              )
            : null,
      ),
    );
  } on KnowledgeCardAiException catch (e) {
    if (!context.mounted) return;
    if (generatingDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    _showKnowledgeSourceAiError(context, e.message, canOpenConfig: true);
  } on AiServiceException catch (e) {
    if (!context.mounted) return;
    if (generatingDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    _showKnowledgeSourceAiError(context, e.message);
  } on FormatException catch (_) {
    if (!context.mounted) return;
    if (generatingDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    _showKnowledgeSourceAiError(context, 'AI 返回格式不是可识别的卡片 JSON，请重试一次。');
  } catch (_) {
    if (!context.mounted) return;
    if (generatingDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    _showKnowledgeSourceAiError(context, '生成失败，请检查 AI 配置或网络后重试。');
  }
}

void _continueAfterBatchFeedback({
  required BuildContext context,
  required WidgetRef ref,
  required KnowledgeSource source,
  required List<KnowledgeSourceBatchContext>? rangeContexts,
}) {
  if (rangeContexts == null) {
    _continueSourceConversion(context, ref, source);
    return;
  }

  _continueScopeConversion(
    context,
    ref,
    rangeContexts
        .map(
          (context) => KnowledgeSourceWithProgress(
            source: context.source,
            progress: KnowledgeSourceConversionProgress.fromChunksAndReferences(
              chunks: context.chunks,
              references: context.references,
            ),
          ),
        )
        .toList(growable: false),
  );
}

void _showKnowledgeSourceAiError(
  BuildContext context,
  String message, {
  bool canOpenConfig = false,
}) {
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

class _EmptySourcesPanel extends StatelessWidget {
  const _EmptySourcesPanel({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return EmptyStateWidget(
      icon: Icons.library_books_outlined,
      title: '还没有知识库资料',
      subtitle: '先粘贴一段笔记或 Markdown，系统会本地切片，之后 AI 只读取相关片段。',
      accentColor: colors.study,
    );
  }
}

class _ImportSourceDraft {
  const _ImportSourceDraft({
    required this.title,
    required this.content,
    required this.type,
    required this.goalKey,
    required this.moduleKey,
    this.sourcePath,
    this.goalName,
    this.moduleName,
    this.tags,
  });

  final String title;
  final String content;
  final String type;
  final String goalKey;
  final String moduleKey;
  final String? sourcePath;
  final String? goalName;
  final String? moduleName;
  final String? tags;
}

class _ImportSourceSheet extends StatefulWidget {
  const _ImportSourceSheet({this.ocrCallback});

  final Future<String> Function(List<int> imageBytes, String mimeType)?
  ocrCallback;

  @override
  State<_ImportSourceSheet> createState() => _ImportSourceSheetState();
}

class _ImportSourceSheetState extends State<_ImportSourceSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _sourceController = TextEditingController();
  final _goalNameController = TextEditingController();
  final _moduleNameController = TextEditingController();
  final _tagsController = TextEditingController();
  final _urlController = TextEditingController();
  String _type = 'markdown';
  String _goalKey = 'custom';
  String _moduleKey = 'custom';
  bool _isImporting = false;
  final _docImporter = KnowledgeDocumentImporter();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _sourceController.dispose();
    _goalNameController.dispose();
    _moduleNameController.dispose();
    _tagsController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final goal = KnowledgeCardAssets.goalForKey(_goalKey);
    final modules = goal.modules;
    final module = KnowledgeCardAssets.moduleForKeys(_goalKey, _moduleKey);
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.52,
      maxChildSize: 0.94,
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
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '导入知识库资料',
              style: AppTextStyles.sectionTitle.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_isImporting) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.paper,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.study,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Text('正在解析文件...'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              '快速导入',
              style: AppTextStyles.body.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isImporting ? null : _pickAndImportFile,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('PDF / Word'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isImporting ? null : _showUrlImportDialog,
                    icon: const Icon(Icons.language_rounded, size: 18),
                    label: const Text('从网页导入'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (widget.ocrCallback != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isImporting ? null : _pickAndOcrImage,
                  icon: const Icon(Icons.document_scanner_rounded, size: 18),
                  label: const Text('图片 OCR 文字识别'),
                ),
              ),
            const Divider(height: AppSpacing.xl),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('knowledge-source-title-field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '资料标题',
                hintText: '例如：操作系统进程管理笔记',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: '资料类型'),
              items: const [
                DropdownMenuItem(value: 'markdown', child: Text('Markdown')),
                DropdownMenuItem(value: 'text', child: Text('纯文本')),
                DropdownMenuItem(value: 'paste', child: Text('粘贴内容')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: '来源说明（可选）',
                hintText: '例如：教材第 2 章、课堂笔记、文件名',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: '标签（可选）',
                hintText: '用逗号分隔，例如：408, 高频',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              key: const Key('knowledge-source-goal-field'),
              initialValue: _goalKey,
              decoration: const InputDecoration(labelText: '复习目标'),
              items: [
                for (final item in KnowledgeCardAssets.goalTemplates)
                  DropdownMenuItem(value: item.key, child: Text(item.name)),
              ],
              onChanged: (value) {
                if (value == null) return;
                final nextGoal = KnowledgeCardAssets.goalForKey(value);
                setState(() {
                  _goalKey = nextGoal.key;
                  _moduleKey = nextGoal.modules.first.key;
                  _goalNameController.clear();
                  _moduleNameController.clear();
                });
              },
            ),
            if (goal.key == 'custom') ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _goalNameController,
                decoration: const InputDecoration(
                  labelText: '自定义目标名称（可选）',
                  hintText: '例如：蓝桥杯、期末复习、读书计划',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              key: ValueKey('knowledge-source-module-field-$_goalKey'),
              initialValue: _moduleKey,
              decoration: const InputDecoration(labelText: '目标内模块'),
              items: [
                for (final item in modules)
                  DropdownMenuItem(value: item.key, child: Text(item.name)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _moduleKey = value;
                  _moduleNameController.clear();
                });
              },
            ),
            if (module.deckKey == 'custom') ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _moduleNameController,
                decoration: const InputDecoration(
                  labelText: '自定义模块名称（可选）',
                  hintText: '例如：专业课、错题、论文笔记',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('knowledge-source-content-field'),
              controller: _contentController,
              minLines: 10,
              maxLines: 18,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                labelText: '资料正文',
                hintText: '粘贴 Markdown、课堂笔记、错题解析或学习资料文本...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: const Key('knowledge-source-import-save-button'),
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: colors.study,
                foregroundColor: colors.textOnAccent,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.library_add_rounded),
              label: const Text('导入并本地切片'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'docx',
          'doc',
          'txt',
          'md',
          'png',
          'jpg',
          'jpeg',
          'bmp',
          'gif',
          'webp',
        ],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;

      setState(() => _isImporting = true);
      try {
        final file = File(filePath);
        final extractResult = await _docImporter.extractFromFile(
          file,
          ocrCallback: widget.ocrCallback,
        );
        if (!mounted) return;
        if (!extractResult.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(extractResult.displayError ?? '文件解析失败')),
          );
          return;
        }
        setState(() {
          _titleController.text = extractResult.title;
          _contentController.text = extractResult.content;
          _sourceController.text = extractResult.sourcePath ?? '';
          _type = extractResult.type == 'pdf_text'
              ? 'markdown'
              : extractResult.type == 'docx_text'
              ? 'markdown'
              : extractResult.type == 'pdf_ocr' ||
                    extractResult.type == 'image_ocr'
              ? 'markdown'
              : extractResult.type;
        });
        final ocrLabel =
            extractResult.type == 'image_ocr' || extractResult.type == 'pdf_ocr'
            ? ' (OCR)'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已解析「${extractResult.title}」$ocrLabel，提取 ${extractResult.content.length} 字',
            ),
          ),
        );
      } finally {
        if (mounted) setState(() => _isImporting = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件导入失败：${e.toString().split("\n").first}')),
        );
      }
    }
  }

  Future<void> _pickAndOcrImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;

      setState(() => _isImporting = true);
      try {
        final file = File(filePath);
        final extractResult = await _docImporter.extractFromFile(
          file,
          ocrCallback: widget.ocrCallback,
        );
        if (!mounted) return;
        if (!extractResult.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(extractResult.displayError ?? 'OCR 识别失败')),
          );
          return;
        }
        setState(() {
          _titleController.text = extractResult.title;
          _contentController.text = extractResult.content;
          _sourceController.text = extractResult.sourcePath ?? '';
          _type = 'markdown';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OCR 已识别「${extractResult.title}」，提取 ${extractResult.content.length} 字',
            ),
          ),
        );
      } finally {
        if (mounted) setState(() => _isImporting = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片导入失败：${e.toString().split("\n").first}')),
        );
      }
    }
  }

  Future<void> _showUrlImportDialog() async {
    _urlController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.growthColors;
        return AlertDialog(
          backgroundColor: colors.card,
          surfaceTintColor: colors.card,
          title: const Text('从网页导入'),
          content: TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: '网页地址',
              hintText: 'https://example.com/article',
            ),
            autofocus: true,
            keyboardType: TextInputType.url,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('抓取'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final extractResult = await _docImporter.extractFromUrl(url);
      if (!mounted) return;
      if (!extractResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractResult.displayError ?? '网页抓取失败')),
        );
        return;
      }
      setState(() {
        _titleController.text = extractResult.title;
        _contentController.text = extractResult.content;
        _sourceController.text = url;
        _type = 'markdown';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已抓取「${extractResult.title}」，提取 ${extractResult.content.length} 字',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final module = KnowledgeCardAssets.moduleForKeys(_goalKey, _moduleKey);
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('标题和正文都要填写')));
      return;
    }
    Navigator.of(context).pop(
      _ImportSourceDraft(
        title: title,
        content: content,
        type: _type,
        goalKey: _goalKey,
        goalName: _goalKey == 'custom'
            ? _nullable(_goalNameController.text)
            : null,
        moduleKey: _moduleKey,
        moduleName: module.deckKey == 'custom'
            ? _nullable(_moduleNameController.text)
            : null,
        sourcePath: _nullable(_sourceController.text),
        tags: _nullable(_tagsController.text),
      ),
    );
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    this.query,
    this.maxLines,
    this.style,
    this.highlightColor,
  });

  final String text;
  final String? query;
  final int? maxLines;
  final TextStyle? style;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final q = query?.trim();
    if (q == null || q.isEmpty || text.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final terms = q
        .toLowerCase()
        .split(RegExp(r'[\s,，、]+'))
        .where((t) => t.isNotEmpty && t.length >= 2)
        .toList(growable: false);
    if (terms.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final pattern = terms.map(RegExp.escape).join('|');
    final regex = RegExp(pattern, caseSensitive: false);
    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final spans = <TextSpan>[];
    var lastEnd = 0;
    final hlColor = highlightColor ?? Colors.yellow.withValues(alpha: 0.3);
    final hlStyle = (style ?? const TextStyle()).copyWith(
      backgroundColor: hlColor,
      fontWeight: FontWeight.w700,
    );

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(
        TextSpan(text: text.substring(match.start, match.end), style: hlStyle),
      );
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return Text.rich(
      TextSpan(children: spans, style: style),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.study,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _excerpt(String content) {
  final trimmed = content.trim();
  if (trimmed.length <= 260) return trimmed;
  return '${trimmed.substring(0, 260)}...';
}

String _formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
