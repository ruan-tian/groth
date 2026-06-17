import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repositories/knowledge_source_repository.dart';
import '../../../shared/providers/knowledge_card_ai_provider.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/knowledge_source_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../services/knowledge_card_ai_service.dart';
import '../utils/knowledge_card_assets.dart';
import '../utils/knowledge_document_importer.dart';

/// AI 导入 Tab —— AI 工厂入口
class FlashImportTab extends ConsumerStatefulWidget {
  const FlashImportTab({super.key});

  @override
  ConsumerState<FlashImportTab> createState() => _FlashImportTabState();
}

class _FlashImportTabState extends ConsumerState<FlashImportTab> {
  final _docImporter = KnowledgeDocumentImporter();
  final _textController = TextEditingController();
  final _urlController = TextEditingController();

  String _selectedGoalKey = 'custom';
  String _selectedModuleKey = 'custom';
  bool _isImporting = false;
  bool _isGenerating = false;

  String? _parsedTitle;
  String? _parsedContent;
  String? _parsedSourcePath;
  String _parsedType = 'paste';

  List<KnowledgeCardAiDraft>? _drafts;
  List<bool>? _draftSelected;
  List<String?>? _duplicateReasons;

  KnowledgeSource? _importedSource;
  List<KnowledgeChunk>? _importedChunks;

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildEntryCards(colors),
        const SizedBox(height: AppSpacing.lg),
        _buildGoalSelection(colors),
        const SizedBox(height: AppSpacing.lg),
        if (_parsedContent != null || _isImporting) ...[
          _buildParsedPreview(colors),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_parsedContent != null && !_isImporting && _drafts == null) ...[
          _buildAiGenerateButton(colors),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_isGenerating) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(color: colors.border),
            ),
            child: Column(children: [
              CircularProgressIndicator(color: colors.study),
              const SizedBox(height: AppSpacing.md),
              Text('AI 正在基于片段生成草稿...', style: TextStyle(color: colors.textSecondary)),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_drafts != null && _drafts!.isNotEmpty && !_isGenerating) ...[
          _buildDraftPreview(colors),
          const SizedBox(height: AppSpacing.lg),
        ],
        _buildQuickEntries(colors),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildEntryCards(AppThemeColors colors) {
    return Row(children: [
      Expanded(child: _EntryCard(icon: Icons.picture_as_pdf_rounded, label: '文件导入', subtitle: 'PDF/Word/TXT/MD/图片', color: colors.study, onTap: _pickAndImportFile)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: _EntryCard(icon: Icons.language_rounded, label: '网页导入', subtitle: 'URL 抓取', color: colors.focus, onTap: _showUrlImportDialog)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: _EntryCard(icon: Icons.edit_note_rounded, label: '文本输入', subtitle: '手动粘贴', color: colors.journal, onTap: _showTextInput)),
    ]);
  }

  Widget _buildGoalSelection(AppThemeColors colors) {
    final goal = KnowledgeCardAssets.goalForKey(_selectedGoalKey);
    final modules = goal.modules;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: colors.card.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(AppRadius.xxl), border: Border.all(color: colors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('目标设置', style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        Text('选择导入到哪个目标和模块。', style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _selectedGoalKey,
          decoration: const InputDecoration(labelText: '复习目标'),
          items: [for (final item in KnowledgeCardAssets.goalTemplates) DropdownMenuItem(value: item.key, child: Text(item.name))],
          onChanged: (value) {
            if (value == null) return;
            final nextGoal = KnowledgeCardAssets.goalForKey(value);
            setState(() { _selectedGoalKey = value; _selectedModuleKey = nextGoal.modules.first.key; });
          },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          key: ValueKey('module-$_selectedGoalKey'),
          initialValue: modules.any((m) => m.key == _selectedModuleKey) ? _selectedModuleKey : modules.first.key,
          decoration: const InputDecoration(labelText: '目标内模块'),
          items: [for (final item in modules) DropdownMenuItem(value: item.key, child: Text(item.name))],
          onChanged: (value) { if (value != null) setState(() => _selectedModuleKey = value); },
        ),
      ]),
    );
  }

  Widget _buildParsedPreview(AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: colors.card.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(AppRadius.xxl), border: Border.all(color: colors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.check_circle_outline_rounded, color: colors.success, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text('已解析', style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        if (_parsedTitle != null) Text('标题: $_parsedTitle', style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        Text('内容长度: ${_parsedContent!.length} 字', style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
        if (_importedChunks != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('已切片: ${_importedChunks!.length} 个片段', style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
        ],
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: colors.border)),
          child: Text(
            _parsedContent!.length > 300 ? '${_parsedContent!.substring(0, 300)}...' : _parsedContent!,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
            maxLines: 6, overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Widget _buildAiGenerateButton(AppThemeColors colors) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _importAndGenerate,
        style: ElevatedButton.styleFrom(backgroundColor: colors.study, foregroundColor: colors.textOnAccent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mlg))),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('AI 生成卡片'),
      ),
    );
  }

  Widget _buildDraftPreview(AppThemeColors colors) {
    final selectedCount = _draftSelected?.where((s) => s).length ?? 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: colors.card.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(AppRadius.xxl), border: Border.all(color: colors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('确认知识卡草稿', style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary)),
        const SizedBox(height: AppSpacing.xs),
        Text('可以取消勾选。保存后才会进入知识卡片库，并保留资料来源。', style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < _drafts!.length; i++) ...[
          _DraftCard(
            index: i, draft: _drafts![i], selected: _draftSelected![i],
            duplicateReason: _duplicateReasons != null && i < _duplicateReasons!.length ? _duplicateReasons![i] : null,
            onSelectionChanged: (value) => setState(() => _draftSelected![i] = value),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton.icon(
            onPressed: selectedCount == 0 ? null : _saveDrafts,
            style: ElevatedButton.styleFrom(backgroundColor: colors.study, foregroundColor: colors.textOnAccent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mlg))),
            icon: const Icon(Icons.save_alt_rounded),
            label: Text('保存 $selectedCount 张知识卡'),
          ),
        ),
      ]),
    );
  }

  Widget _buildQuickEntries(AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: colors.card.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(AppRadius.xxl), border: Border.all(color: colors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('更多入口', style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        _QuickEntryTile(icon: Icons.add_card_rounded, label: '手动添加卡片', subtitle: '逐张创建知识卡', onTap: () => context.push('/plan/study/knowledge/add'), color: colors.study),
        const SizedBox(height: AppSpacing.sm),
        _QuickEntryTile(icon: Icons.upload_file_rounded, label: '批量导入', subtitle: '文本粘贴批量建卡', onTap: () => context.push('/plan/study/knowledge/import'), color: colors.study),
        const SizedBox(height: AppSpacing.sm),
        _QuickEntryTile(icon: Icons.dashboard_customize_rounded, label: '管理自定义模板', subtitle: '创建/管理复习模板和模块', onTap: () => context.push('/plan/study/knowledge/templates'), color: colors.study),
      ]),
    );
  }

  // ---------------------------------------------------------------------------
  // Import Actions
  // ---------------------------------------------------------------------------

  Future<void> _pickAndImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'txt', 'md', 'png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;

      setState(() => _isImporting = true);
      try {
        final file = File(filePath);
        final extractResult = await _docImporter.extractFromFile(file);
        if (!mounted) return;
        if (!extractResult.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractResult.displayError ?? '文件解析失败')));
          return;
        }
        setState(() { _parsedTitle = extractResult.title; _parsedContent = extractResult.content; _parsedSourcePath = filePath; _parsedType = extractResult.type; _isImporting = false; _resetDrafts(); });
      } finally {
        if (mounted) setState(() => _isImporting = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('文件导入失败: ${e.toString().split("\n").first}')));
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
          backgroundColor: colors.card, surfaceTintColor: colors.card,
          title: const Text('从网页导入'),
          content: TextField(controller: _urlController, decoration: const InputDecoration(labelText: '网页地址', hintText: 'https://example.com/article'), autofocus: true, keyboardType: TextInputType.url),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('抓取')),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractResult.displayError ?? '网页抓取失败')));
        return;
      }
      setState(() { _parsedTitle = extractResult.title; _parsedContent = extractResult.content; _parsedSourcePath = url; _parsedType = 'markdown'; _isImporting = false; _resetDrafts(); });
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _showTextInput() async {
    _textController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.growthColors;
        return AlertDialog(
          backgroundColor: colors.card, surfaceTintColor: colors.card,
          title: const Text('粘贴文本'),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(controller: _textController, minLines: 8, maxLines: 15, decoration: const InputDecoration(labelText: '学习资料文本', hintText: '粘贴课堂笔记、错题解析或学习资料...', alignLabelWithHint: true)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认')),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() { _parsedTitle = '手动输入'; _parsedContent = text; _parsedSourcePath = null; _parsedType = 'paste'; _resetDrafts(); });
  }

  void _resetDrafts() {
    _drafts = null; _draftSelected = null; _duplicateReasons = null; _importedSource = null; _importedChunks = null;
  }

  // ---------------------------------------------------------------------------
  // Import + AI Generate
  // ---------------------------------------------------------------------------

  Future<void> _importAndGenerate() async {
    if (_parsedContent == null) return;

    setState(() => _isGenerating = true);
    try {
      final sourceRepo = ref.read(knowledgeSourceRepositoryProvider);
      final goal = KnowledgeCardAssets.goalForKey(_selectedGoalKey);
      final module = KnowledgeCardAssets.moduleForKeys(_selectedGoalKey, _selectedModuleKey);

      final sourceId = await sourceRepo.importTextSource(
        title: _parsedTitle ?? '导入资料',
        content: _parsedContent!,
        type: _parsedType,
        sourcePath: _parsedSourcePath,
        goalKey: _selectedGoalKey,
        goalName: goal.key == 'custom' ? goal.name : null,
        moduleKey: _selectedModuleKey,
        moduleName: module.deckKey == 'custom' ? module.name : null,
      );

      final source = await sourceRepo.getSourceById(sourceId);
      final chunks = await sourceRepo.getChunksForSource(sourceId);

      if (!mounted) return;
      if (source == null || chunks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('资料切片失败，请检查内容后重试')));
        setState(() => _isGenerating = false);
        return;
      }

      setState(() { _importedSource = source; _importedChunks = chunks; });

      final aiService = ref.read(knowledgeCardAiServiceProvider);
      final searchResults = chunks.map((chunk) => KnowledgeChunkSearchResult(source: source, chunk: chunk, score: 1)).toList();

      final drafts = await aiService.generateDraftsFromResults(searchResults, topic: _parsedTitle);

      if (!mounted) return;
      if (drafts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI 没有生成可用卡片，请检查内容后重试')));
        setState(() => _isGenerating = false);
        return;
      }

      final duplicateReasons = await aiService.findDuplicateReasonsFromResults(results: searchResults, drafts: drafts);

      if (!mounted) return;
      setState(() { _drafts = drafts; _draftSelected = List.filled(drafts.length, true); _duplicateReasons = duplicateReasons; _isGenerating = false; });

      ref.invalidate(knowledgeSourcesProvider);
      ref.invalidate(knowledgeSourcesWithProgressProvider);
      ref.invalidate(knowledgeBaseOverviewProvider);

    } on KnowledgeCardAiException catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成失败: ${e.toString().split("\n").first}')));
    }
  }

  // ---------------------------------------------------------------------------
  // Save Drafts
  // ---------------------------------------------------------------------------

  Future<void> _saveDrafts() async {
    if (_drafts == null || _draftSelected == null || _importedSource == null || _importedChunks == null) return;

    final selectedDrafts = <KnowledgeCardAiDraft>[];
    for (var i = 0; i < _drafts!.length; i++) {
      if (_draftSelected![i]) selectedDrafts.add(_drafts![i]);
    }

    if (selectedDrafts.isEmpty) return;

    try {
      final aiService = ref.read(knowledgeCardAiServiceProvider);
      final searchResults = _importedChunks!.map((chunk) => KnowledgeChunkSearchResult(source: _importedSource!, chunk: chunk, score: 1)).toList();

      await aiService.saveDraftsFromResults(results: searchResults, drafts: selectedDrafts);

      ref.invalidate(knowledgeCardsProvider);
      ref.invalidate(knowledgeReviewStatsProvider);
      ref.invalidate(knowledgeGoalSummariesProvider);
      ref.invalidate(dueKnowledgeCardsCountProvider);
      ref.invalidate(todayReviewProgressProvider);
      ref.invalidate(aiRecommendedCardsProvider);
      ref.invalidate(knowledgeSourcesWithProgressProvider);
      ref.invalidate(knowledgeBaseOverviewProvider);

      if (!mounted) return;
      final savedCount = selectedDrafts.length;
      setState(() { _drafts = null; _draftSelected = null; _duplicateReasons = null; _parsedTitle = null; _parsedContent = null; _parsedSourcePath = null; _importedSource = null; _importedChunks = null; });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已保存 $savedCount 张知识卡')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: ${e.toString().split("\n").first}')));
    }
  }
}

// =============================================================================
// Entry Card
// =============================================================================

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});
  final IconData icon; final String label; final String subtitle; final Color color; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: colors.border),
          boxShadow: [BoxShadow(color: colors.shadow.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ]),
      ),
    );
  }
}

// =============================================================================
// Draft Card
// =============================================================================

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.index, required this.draft, required this.selected, required this.duplicateReason, required this.onSelectionChanged});
  final int index; final KnowledgeCardAiDraft draft; final bool selected; final String? duplicateReason; final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: selected ? colors.study.withValues(alpha: 0.3) : colors.border),
      ),
      child: Column(children: [
        CheckboxListTile(
          value: selected, onChanged: (value) => onSelectionChanged(value ?? false),
          contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
          title: Text('草稿 ${index + 1}', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
          subtitle: Text(duplicateReason ?? '确认后写入本地知识卡片库', style: TextStyle(color: colors.textSecondary)),
        ),
        if (duplicateReason != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(99)),
              child: Text('可能重复: $duplicateReason', style: TextStyle(color: colors.warning, fontSize: 12)),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        _DraftField(label: '标题', value: draft.title, maxLines: 1),
        const SizedBox(height: AppSpacing.sm),
        _DraftField(label: '问题', value: draft.question, maxLines: 3),
        const SizedBox(height: AppSpacing.sm),
        _DraftField(label: '答案', value: draft.answer, maxLines: 4),
      ]),
    );
  }
}

class _DraftField extends StatelessWidget {
  const _DraftField({required this.label, required this.value, this.maxLines = 1});
  final String label; final String value; final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: colors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(fontSize: 13)),
      ]),
    );
  }
}

// =============================================================================
// Quick Entry Tile
// =============================================================================

class _QuickEntryTile extends StatelessWidget {
  const _QuickEntryTile({required this.icon, required this.label, required this.subtitle, required this.onTap, required this.color});
  final IconData icon; final String label; final String subtitle; final VoidCallback onTap; final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.sm)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ])),
          Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
        ]),
      ),
    );
  }
}
