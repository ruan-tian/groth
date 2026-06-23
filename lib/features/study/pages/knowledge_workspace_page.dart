library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../knowledge/repositories/knowledge_v3_repository.dart';
import '../../knowledge/providers/knowledge_card_ai_provider.dart';
import '../../knowledge/providers/knowledge_v3_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../knowledge/services/knowledge_v3_ai_service.dart';
import '../../knowledge/providers/knowledge_generation_provider.dart';
import '../utils/knowledge_document_importer.dart';
import '../../../app/design/design.dart';
import '../widgets/tiantian_chat_sheet.dart';
part 'knowledge_common_widgets.part.dart';
part 'knowledge_home_widgets.part.dart';
part 'knowledge_flash_review.part.dart';
part 'knowledge_import_sheet.part.dart';
part 'knowledge_library_sheet.part.dart';
part 'knowledge_qa_sheets.part.dart';
part 'knowledge_space_editor.part.dart';
part 'knowledge_generation_sheet.part.dart';
part 'knowledge_qa_session.part.dart';

class KnowledgeWorkspacePage extends ConsumerWidget {
  const KnowledgeWorkspacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentKnowledgeSpaceV3Provider);
    return current.when(
      data: (space) => KnowledgeSpaceHomePage(space: space),
      loading: () => const _LoadingScaffold(),
      error: (error, _) => _ErrorScaffold(
        message: '知识空间加载失败',
        onRetry: () => ref.invalidate(currentKnowledgeSpaceV3Provider),
      ),
    );
  }
}

class KnowledgeSpaceSelectPage extends ConsumerWidget {
  const KnowledgeSpaceSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(knowledgeSpacesV3Provider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _GradientSurface(
        child: SafeArea(
          child: spaces.when(
            data: (items) => ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BackTitle(title: '知识空间'),
                          SizedBox(height: 6),
                          Text('选择一个空间，开始你的学习之旅', style: _T.subtitle),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () => _createAndEnterSpace(context, ref),
                      style: _primaryButtonStyle(height: 46),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('新建空间'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                for (final space in items) ...[
                  _SpaceSelectCard(space: space),
                  const SizedBox(height: 12),
                ],
                _DashedCreateCard(
                  onTap: () => _createAndEnterSpace(context, ref),
                ),
                const SizedBox(height: 16),
                const _TipCard(),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _ErrorBlock(
              message: '知识空间加载失败',
              onRetry: () => ref.invalidate(knowledgeSpacesV3Provider),
            ),
          ),
        ),
      ),
    );
  }
}

class KnowledgeSpaceHomePage extends ConsumerStatefulWidget {
  const KnowledgeSpaceHomePage({super.key, required this.space});

  final KnowledgeSpaceV3 space;

  @override
  ConsumerState<KnowledgeSpaceHomePage> createState() =>
      _KnowledgeSpaceHomePageState();
}

class _KnowledgeSpaceHomePageState
    extends ConsumerState<KnowledgeSpaceHomePage> {
  final _askController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _askController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(knowledgeMaterialsV3Provider(widget.space.id));
    final cards = ref.watch(knowledgeCardsV3Provider(widget.space.id));
    final stats = ref.watch(knowledgeSpaceStatsV3Provider(widget.space.id));
    final spaces = ref.watch(knowledgeSpacesV3Provider);
    final materialItems = materials.valueOrNull ?? const <KnowledgeMaterial>[];
    final cardItems = cards.valueOrNull ?? const <KnowledgeCardV3>[];
    final hasQuickActions =
        materialItems.isNotEmpty || cardItems.any(_isWeakCard);
    final canSupplementCards = materialItems.isNotEmpty && cardItems.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _GradientSurface(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              cacheExtent: 3200,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                _HomeTopBar(
                  space: widget.space,
                  spaces: spaces.valueOrNull ?? const [],
                  onBack: () => Navigator.of(context).maybePop(),
                  onSelectSpace: (space) async {
                    await ref
                        .read(knowledgeV3RepositoryProvider)
                        .rememberSpace(space.id);
                    ref.read(selectedKnowledgeSpaceIdProvider.notifier).state =
                        space.id;
                    invalidateKnowledgeV3(ref, spaceId: space.id);
                  },
                  onManageSpaces: () =>
                      context.push('/plan/study/knowledge/spaces'),
                  onLibrary: () =>
                      _showLibrarySheet(context, ref, widget.space),
                ),
                const SizedBox(height: 16),
                _WelcomeCard(onAsk: _askTiantian),
                const SizedBox(height: 14),
                _AskBox(
                  controller: _askController,
                  onChanged: (value) => setState(() => _query = value),
                  onAsk: _askTiantian,
                  onSubmitted: _handleAskBoxSubmitted,
                ),
                if (_query.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SearchResults(spaceId: widget.space.id, query: _query),
                ],
                const SizedBox(height: 14),
                stats.when(
                  data: (item) => _PrimaryTaskCard(
                    stats: item,
                    onImport: () =>
                        _showImportSheet(context, ref, widget.space),
                    onGenerate: () =>
                        _confirmAndGenerate(materials.valueOrNull ?? const []),
                    onReview: () => _openReview(context, widget.space),
                  ),
                  loading: () => const _Skeleton(height: 118),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 14),
                if (hasQuickActions) ...[
                  _QuickActions(
                    showGenerate: canSupplementCards,
                    showWeak: cardItems.any(_isWeakCard),
                    onSummary: () => _summarizeMaterials(materialItems),
                    onGenerate: () => _confirmAndGenerate(materialItems),
                    onWeak: () => _explainWeakCards(cardItems, materialItems),
                  ),
                  const SizedBox(height: 14),
                ],
                materials.when(
                  data: (items) => _RecentMaterials(
                    materials: items,
                    onMaterialTap: (material) =>
                        _showMaterialDetail(context, ref, material),
                    onViewAll: () =>
                        _showLibrarySheet(context, ref, widget.space),
                    onImport: () =>
                        _showImportSheet(context, ref, widget.space),
                  ),
                  loading: () => const _Skeleton(height: 178),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 14),
                stats.when(
                  data: (item) => _StatsCard(stats: item),
                  loading: () => const _Skeleton(height: 96),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 18),
                cards.when(
                  data: (items) => _RecentCards(
                    cards: items,
                    onCardTap: (card) => _showCardDetail(context, ref, card),
                    onViewAll: () =>
                        _showLibrarySheet(context, ref, widget.space),
                  ),
                  loading: () => const _Skeleton(height: 178),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _refresh() {
    invalidateKnowledgeV3(ref, spaceId: widget.space.id);
  }

  Future<void> _askTiantian() async {
    final initialQuestion = _askController.text.trim();
    FocusScope.of(context).unfocus();
    if (initialQuestion.isNotEmpty) {
      _askController.clear();
      setState(() => _query = '');
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TiantianChatSheet(
        space: widget.space,
        initialQuestion: initialQuestion,
      ),
    );
    if (!mounted) return;
    _refresh();
  }

  Future<void> _handleAskBoxSubmitted(String value) async {
    final text = value.trim();
    if (text.isEmpty) return;
    if (_looksLikeQuestion(text)) {
      await _askTiantian();
    } else {
      setState(() => _query = text);
    }
  }

  Future<void> _summarizeMaterials(List<KnowledgeMaterial> materials) async {
    if (materials.isEmpty) {
      _toast(context, '先导入资料，再让甜甜总结。');
      _showImportSheet(context, ref, widget.space);
      return;
    }
    final selected = await _confirmMaterialAction(
      context,
      materials: materials,
      title: '选择要总结的资料',
      description: '甜甜将只参考你勾选的资料，整理重点和复习顺序，不会自动生成知识卡。',
      actionLabel: '确认总结',
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiResultSheet(
        title: '总结资料',
        workingText: '甜甜正在整理这组资料...',
        future: ref
            .read(knowledgeV3AiServiceProvider)
            .summarizeMaterials(space: widget.space, materials: selected),
        successActionLabel: '根据这些资料生成知识卡',
        onSuccessAction: () async {
          Navigator.of(context).pop();
          await _showGenerationSheet(context, ref, widget.space, selected);
          _refresh();
        },
      ),
    );
  }

  Future<void> _explainWeakCards(
    List<KnowledgeCardV3> cards,
    List<KnowledgeMaterial> materials,
  ) async {
    final weakCards = cards.where(_isWeakCard).take(8).toList(growable: false);
    if (weakCards.isEmpty) {
      _toast(context, '现在还没有薄弱卡，先完成几轮抽卡吧。');
      return;
    }
    if (materials.isEmpty) {
      _toast(context, '需要先导入资料，甜甜才能结合来源解释薄弱点。');
      return;
    }
    final selected = await _confirmMaterialAction(
      context,
      materials: materials,
      title: '选择解释薄弱点的参考资料',
      description: '甜甜会结合薄弱卡和你勾选的资料，解释容易混淆的地方。',
      actionLabel: '确认解释',
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiResultSheet(
        title: '解释薄弱卡',
        workingText: '甜甜正在分析薄弱点...',
        future: ref
            .read(knowledgeV3AiServiceProvider)
            .explainWeakCards(
              space: widget.space,
              weakCards: weakCards,
              materials: selected,
            ),
        successActionLabel: '开始薄弱复习',
        onSuccessAction: () {
          Navigator.of(context).pop();
          _openReview(context, widget.space);
        },
      ),
    );
  }

  Future<void> _confirmAndGenerate(List<KnowledgeMaterial> materials) async {
    if (materials.isEmpty) {
      _toast(context, '先导入一份资料。');
      _showImportSheet(context, ref, widget.space);
      return;
    }
    final selected = await _confirmMaterialAction(
      context,
      materials: materials,
      title: '选择要生成知识卡的资料',
      description: '甜甜将只参考你勾选的资料，自动整理核心知识点并生成抽卡复习内容。',
      actionLabel: '确认生成',
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    await _showGenerationSheet(context, ref, widget.space, selected);
    _refresh();
  }
}

void _showReviewRuleSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SheetScaffold(
      title: '复习规则',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('甜甜会按你的反馈调整下次出现时间，复习页只负责抽卡，不混入资料管理。', style: _T.bodyLarge),
            SizedBox(height: 12),
            _RuleLine(title: '默认排序', body: '薄弱卡 > 今日到期卡 > 最近答错卡 > 普通卡。'),
            SizedBox(height: 12),
            _RuleLine(title: '完全忘了', body: '熟练度下降，约 10 分钟后再次出现。'),
            SizedBox(height: 12),
            _RuleLine(title: '有点印象', body: '熟练度小幅下降，明天继续复习。'),
            SizedBox(height: 12),
            _RuleLine(title: '基本记得', body: '熟练度上升，间隔约 2-4 天。'),
            SizedBox(height: 12),
            _RuleLine(title: '很熟练', body: '熟练度明显上升，间隔约 5-14 天并随连续答对延长。'),
          ],
        ),
      ),
    ),
  );
}

ButtonStyle _primaryButtonStyle({double height = 52}) {
  return FilledButton.styleFrom(
    minimumSize: Size(0, height),
    backgroundColor: AppColors.study,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  );
}

ButtonStyle _secondaryButtonStyle({double height = 52}) {
  return OutlinedButton.styleFrom(
    minimumSize: Size(0, height),
    foregroundColor: AppColors.study,
    side: const BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  );
}

InputDecoration _inputDecoration({String? label, String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF7F9FF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.study),
    ),
  );
}

Future<int?> _showSpaceEditor(
  BuildContext context,
  WidgetRef ref, {
  KnowledgeSpaceV3? space,
  bool returnCreated = false,
}) async {
  return showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _SpaceEditorSheet(space: space, returnCreated: returnCreated),
  );
}

Future<void> _createAndEnterSpace(BuildContext context, WidgetRef ref) async {
  final createdId = await _showSpaceEditor(context, ref, returnCreated: true);
  if (!context.mounted || createdId == null) return;
  ref.read(selectedKnowledgeSpaceIdProvider.notifier).state = createdId;
  invalidateKnowledgeV3(ref, spaceId: createdId);
  context.go('/plan/study/knowledge/space');
}

Future<List<KnowledgeMaterial>?> _confirmMaterialAction(
  BuildContext context, {
  required List<KnowledgeMaterial> materials,
  required String title,
  required String description,
  required String actionLabel,
}) {
  final selected = materials.map((item) => item.id).toSet();
  return showModalBottomSheet<List<KnowledgeMaterial>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        final selectedCount = selected.length;
        return _SheetScaffold(
          title: title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description, style: _T.bodyLarge),
              const SizedBox(height: 8),
              Text('发送前确认参考资料，甜甜只会使用勾选内容。', style: _T.metaStrong),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    for (final material in materials)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selected.contains(material.id),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selected.add(material.id);
                            } else {
                              selected.remove(material.id);
                            }
                          });
                        },
                        title: Text(
                          material.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_sizeLabel(material.content.length)),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(
                          materials
                              .where((item) => selected.contains(item.id))
                              .toList(growable: false),
                        ),
                  style: _primaryButtonStyle(),
                  child: Text('$actionLabel · $selectedCount 份资料'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> _showGenerationSheet(
  BuildContext context,
  WidgetRef ref,
  KnowledgeSpaceV3 space,
  List<KnowledgeMaterial> materials,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GenerationSheet(space: space, materials: materials),
  );
}

Future<KnowledgeReviewModeV3?> _pickReviewMode(
  BuildContext context,
  List<KnowledgeCardV3> cards,
) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final dueCount = cards.where((item) => item.dueAt <= now).length;
  final weakCount = cards.where(_isWeakCard).length;
  return showModalBottomSheet<KnowledgeReviewModeV3>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetScaffold(
      title: '选择复习方式',
      child: Column(
        children: [
          if (dueCount > 0)
            _ModeTile(
              title: '今日到期',
              subtitle: '$dueCount 张卡片',
              icon: Icons.event_available_rounded,
              onTap: () => Navigator.of(context).pop(KnowledgeReviewModeV3.due),
            ),
          if (weakCount > 0)
            _ModeTile(
              title: '薄弱优先',
              subtitle: '$weakCount 张薄弱卡',
              icon: Icons.track_changes_rounded,
              onTap: () =>
                  Navigator.of(context).pop(KnowledgeReviewModeV3.weak),
            ),
          _ModeTile(
            title: '全部随机',
            subtitle: '${cards.length} 张卡片',
            icon: Icons.shuffle_rounded,
            onTap: () => Navigator.of(context).pop(KnowledgeReviewModeV3.all),
          ),
        ],
      ),
    ),
  );
}

void _showLibrarySheet(
  BuildContext context,
  WidgetRef ref,
  KnowledgeSpaceV3 space,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LibrarySheet(space: space),
  );
}

void _showImportSheet(
  BuildContext context,
  WidgetRef ref,
  KnowledgeSpaceV3 space,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ImportSheet(initialSpace: space),
  );
}

void _openReview(BuildContext context, KnowledgeSpaceV3 space) {
  context.push('/plan/study/knowledge/review?spaceId=${space.id}');
}

void _returnToSpace(BuildContext context, WidgetRef ref, int? spaceId) {
  if (spaceId != null) {
    ref.read(selectedKnowledgeSpaceIdProvider.notifier).state = spaceId;
  }
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  context.go('/plan/study/knowledge/space');
}

void _showMaterialDetail(
  BuildContext context,
  WidgetRef ref,
  KnowledgeMaterial material,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetScaffold(
      title: '资料详情',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PaperCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const _IconBubble(icon: Icons.description_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(material.title, style: _T.cardTitle),
                      const SizedBox(height: 4),
                      Text(_sizeLabel(material.content.length), style: _T.meta),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _PaperCard(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: SelectableText(material.content, style: _T.bodyLarge),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: _primaryButtonStyle(height: 48),
              child: const Text('关闭'),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showCardDetail(
  BuildContext context,
  WidgetRef ref,
  KnowledgeCardV3 card,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetScaffold(
      title: '知识卡详情',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PaperCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(
                      text: _cardStatus(card).$1,
                      color: _cardStatus(card).$2,
                    ),
                    if (card.sourceTitle?.trim().isNotEmpty == true)
                      _StatusPill(
                        text: card.sourceTitle!,
                        color: AppColors.study,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(card.question, style: _T.question),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _PaperCard(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const Text('答案', style: _T.sectionTitle),
                  const SizedBox(height: 8),
                  SelectableText(card.answer, style: _T.answer),
                  if (card.explanation?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 18),
                    const Text('解析', style: _T.sectionTitle),
                    const SizedBox(height: 8),
                    SelectableText(card.explanation!, style: _T.bodyLarge),
                  ],
                  if (card.sourceExcerpt?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 18),
                    const Text('来源摘录', style: _T.sectionTitle),
                    const SizedBox(height: 8),
                    Text(card.sourceExcerpt!, style: _T.body),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final editButton = OutlinedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _editCard(context, ref, card);
                },
                style: _secondaryButtonStyle(height: 48),
                child: const Text('编辑'),
              );
              final deleteButton = OutlinedButton(
                onPressed: () async {
                  final confirmed = await _confirmDelete(
                    context,
                    title: '删除知识卡',
                    message: '这张知识卡会从当前空间移除，复习记录保留在本地日志中。',
                  );
                  if (!confirmed) return;
                  try {
                    await ref
                        .read(knowledgeV3RepositoryProvider)
                        .archiveCard(card.id);
                    if (context.mounted) {
                      invalidateKnowledgeV3(ref, spaceId: card.spaceId);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('已删除')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.danger,
                  side: BorderSide(
                    color: AppColors.danger.withValues(alpha: 0.28),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('删除'),
              );
              final closeButton = FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: _primaryButtonStyle(height: 48),
                child: const Text('关闭'),
              );
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    closeButton,
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: editButton),
                        const SizedBox(width: 8),
                        Expanded(child: deleteButton),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: editButton),
                  const SizedBox(width: 10),
                  Expanded(child: deleteButton),
                  const SizedBox(width: 10),
                  Expanded(child: closeButton),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

void _showQaSessionDetail(
  BuildContext context,
  WidgetRef ref,
  TiantianQaSearchHit hit,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QaChatLoaderSheet(hit: hit),
  );
}

class _QaChatLoaderSheet extends ConsumerWidget {
  const _QaChatLoaderSheet({required this.hit});

  final TiantianQaSearchHit hit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<KnowledgeSpaceV3?>(
      future: ref.read(knowledgeV3RepositoryProvider).getSpace(hit.spaceId),
      builder: (context, snapshot) {
        final space = snapshot.data;
        if (space != null) {
          return TiantianChatSheet(space: space, sessionId: hit.sessionId);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SheetScaffold(
            title: '问答记录',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _QaSessionDetailSheet(hit: hit);
      },
    );
  }
}

Object? _safeJsonDecode(String raw) {
  try {
    return raw.trim().isEmpty ? null : jsonDecode(raw);
  } catch (_) {
    return null;
  }
}

Future<void> _appendMaterial(
  BuildContext context,
  WidgetRef ref,
  KnowledgeMaterial material,
) async {
  final extra = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AppendMaterialSheet(material: material),
  );
  if (extra == null || extra.trim().isEmpty) return;
  await ref
      .read(knowledgeV3RepositoryProvider)
      .updateMaterial(
        id: material.id,
        title: material.title,
        content: '${material.content.trim()}\n\n${extra.trim()}',
      );
  invalidateKnowledgeV3(ref, spaceId: material.spaceId);
}

Future<void> _editMaterial(
  BuildContext context,
  WidgetRef ref,
  KnowledgeMaterial material,
) async {
  final result = await showModalBottomSheet<_MaterialEditResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditMaterialSheet(material: material),
  );
  if (result != null) {
    await ref
        .read(knowledgeV3RepositoryProvider)
        .updateMaterial(
          id: material.id,
          title: result.title,
          content: result.content,
        );
    invalidateKnowledgeV3(ref, spaceId: material.spaceId);
  }
}

Future<void> _editCard(
  BuildContext context,
  WidgetRef ref,
  KnowledgeCardV3 card,
) async {
  final result = await showModalBottomSheet<_CardEditResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditCardSheet(card: card),
  );
  if (result != null) {
    await ref
        .read(knowledgeV3RepositoryProvider)
        .updateCard(
          id: card.id,
          question: result.question,
          answer: result.answer,
          explanation: result.explanation,
        );
    invalidateKnowledgeV3(ref, spaceId: card.spaceId);
  }
}

Future<void> _addCard(
  BuildContext context,
  WidgetRef ref,
  KnowledgeSpaceV3 space,
) async {
  final result = await showModalBottomSheet<_CardEditResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddCardSheet(),
  );
  if (result == null) return;
  final question = result.question.trim();
  final answer = result.answer.trim();
  if (question.isEmpty || answer.isEmpty) return;
  await ref
      .read(knowledgeV3RepositoryProvider)
      .createCard(
        spaceId: space.id,
        question: question,
        answer: answer,
        explanation: result.explanation,
        grounded: false,
        status: 'approved',
        tags: const ['手动添加'],
      );
  invalidateKnowledgeV3(ref, spaceId: space.id);
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SheetScaffold(
          title: title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PaperCard(
                padding: const EdgeInsets.all(16),
                child: Text(message, style: _T.bodyLarge),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: _secondaryButtonStyle(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('删除'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ) ??
      false;
}

class _AppendMaterialSheet extends StatefulWidget {
  const _AppendMaterialSheet({required this.material});

  final KnowledgeMaterial material;

  @override
  State<_AppendMaterialSheet> createState() => _AppendMaterialSheetState();
}

class _AppendMaterialSheetState extends State<_AppendMaterialSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '续编资料',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.material.title, style: _T.cardTitle),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: _inputDecoration(hint: '继续补充这份资料的内容'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _secondaryButtonStyle(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_controller.text),
                  style: _primaryButtonStyle(),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaterialEditResult {
  const _MaterialEditResult({required this.title, required this.content});

  final String title;
  final String content;
}

class _EditMaterialSheet extends StatefulWidget {
  const _EditMaterialSheet({required this.material});

  final KnowledgeMaterial material;

  @override
  State<_EditMaterialSheet> createState() => _EditMaterialSheetState();
}

class _EditMaterialSheetState extends State<_EditMaterialSheet> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.material.title,
  );
  late final TextEditingController _contentController = TextEditingController(
    text: widget.material.content,
  );

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '编辑资料',
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: _inputDecoration(label: '标题'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _contentController,
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: _inputDecoration(label: '内容'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _secondaryButtonStyle(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    _MaterialEditResult(
                      title: _titleController.text,
                      content: _contentController.text,
                    ),
                  ),
                  style: _primaryButtonStyle(),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardEditResult {
  const _CardEditResult({
    required this.question,
    required this.answer,
    required this.explanation,
  });

  final String question;
  final String answer;
  final String explanation;
}

class _EditCardSheet extends StatefulWidget {
  const _EditCardSheet({required this.card});

  final KnowledgeCardV3 card;

  @override
  State<_EditCardSheet> createState() => _EditCardSheetState();
}

class _EditCardSheetState extends State<_EditCardSheet> {
  late final TextEditingController _questionController = TextEditingController(
    text: widget.card.question,
  );
  late final TextEditingController _answerController = TextEditingController(
    text: widget.card.answer,
  );
  late final TextEditingController _explanationController =
      TextEditingController(text: widget.card.explanation);

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '编辑知识卡',
      child: Column(
        children: [
          TextField(
            controller: _questionController,
            decoration: _inputDecoration(label: '问题'),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _answerController,
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: _inputDecoration(label: '答案'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _explanationController,
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: _inputDecoration(label: '解析'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _secondaryButtonStyle(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    _CardEditResult(
                      question: _questionController.text,
                      answer: _answerController.text,
                      explanation: _explanationController.text,
                    ),
                  ),
                  style: _primaryButtonStyle(),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet();

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _explanationController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '新增知识卡',
      child: Column(
        children: [
          TextField(
            controller: _questionController,
            decoration: _inputDecoration(label: '问题'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _answerController,
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: _inputDecoration(label: '答案'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _explanationController,
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: _inputDecoration(label: '解析，可选'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _secondaryButtonStyle(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final question = _questionController.text.trim();
                    final answer = _answerController.text.trim();
                    if (question.isEmpty || answer.isEmpty) return;
                    Navigator.of(context).pop(
                      _CardEditResult(
                        question: question,
                        answer: answer,
                        explanation: _explanationController.text.trim(),
                      ),
                    );
                  },
                  style: _primaryButtonStyle(),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

KnowledgeSpaceV3? _findSpace(List<KnowledgeSpaceV3> spaces, int id) {
  for (final space in spaces) {
    if (space.id == id) return space;
  }
  return null;
}

List<KnowledgeSpaceV3> _mergeSpaces(
  List<KnowledgeSpaceV3> spaces,
  KnowledgeSpaceV3 selected,
) {
  final byId = <int, KnowledgeSpaceV3>{};
  byId[selected.id] = selected;
  for (final space in spaces) {
    byId[space.id] = space;
  }
  return byId.values.toList(growable: false);
}

(String, Color) _cardStatus(KnowledgeCardV3 card) {
  final now = DateTime.now().millisecondsSinceEpoch;
  if (card.dueAt <= now) return ('待复习', AppColors.danger);
  if (_isWeakCard(card)) return ('薄弱', AppColors.warning);
  if (card.masteryLevel >= 4 && card.correctStreak > 0) {
    return ('已掌握', AppColors.success);
  }
  return ('学习中', AppColors.study);
}

bool _isWeakCard(KnowledgeCardV3 card) {
  return card.masteryLevel <= 2 ||
      (card.reviewCount > 0 && card.correctStreak == 0);
}

IconData _cardTypeIcon(String cardType) {
  switch (cardType) {
    case 'comparison':
      return Icons.compare_arrows_rounded;
    case 'process':
      return Icons.route_rounded;
    case 'scenario':
      return Icons.extension_rounded;
    case 'trap':
      return Icons.warning_amber_rounded;
    case 'cloze':
      return Icons.edit_note_rounded;
    case 'choice':
      return Icons.quiz_rounded;
    case 'diagram':
      return Icons.insights_rounded;
    case 'application':
      return Icons.science_rounded;
    default:
      return Icons.style_outlined;
  }
}

Color _difficultyColor(int difficulty) {
  switch (difficulty) {
    case 1:
      return AppColors.success;
    case 2:
      return AppColors.study;
    case 3:
      return AppColors.warning;
    case 4:
      return AppColors.danger;
    case 5:
      return const Color(0xFF9333EA);
    default:
      return AppColors.textSecondary;
  }
}

String _difficultyLabel(int difficulty) {
  switch (difficulty) {
    case 1:
      return '基础';
    case 2:
      return '理解';
    case 3:
      return '分析';
    case 4:
      return '错';
    case 5:
      return '综合';
    default:
      return '';
  }
}

bool _looksLikeQuestion(String value) {
  final text = value.trim();
  if (text.contains('？') || text.contains('?')) return true;
  const questionStarters = [
    '为什么',
    '怎么',
    '如何',
    '什么是',
    '请解释',
    '帮我',
    '总结',
    '分析',
    '区别',
    '联系',
    '原因',
  ];
  return questionStarters.any(text.startsWith);
}

bool _needsAiConfig(Object? error) {
  return (error?.toString() ?? '').contains('还没有配置 AI');
}

String _spaceTypeLabel(String type) {
  return switch (type) {
    'exam' => '备考空间',
    'language' => '语言学习',
    'skill' => '职业技能',
    'interest' => '兴趣知识',
    _ => '自定义空间',
  };
}

String _sizeLabel(int chars) {
  if (chars < 1000) return '$chars 字';
  return '${(chars / 1000).toStringAsFixed(1)}k 字';
}

String _autoMaterialTitle(String content) {
  final lines = content
      .split(RegExp(r'[\r\n]+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  final seed = lines.isEmpty ? content.trim() : lines.first;
  final cleaned = seed
      .replaceFirst(RegExp(r'^[#>\-\s、.．0-9一二三四五六七八九十]+'), '')
      .trim();
  if (cleaned.isEmpty) return '学习资料';
  return cleaned.length <= 24 ? cleaned : '${cleaned.substring(0, 24)}...';
}

String _preview(String text, {int max = 120}) {
  final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.length <= max) return cleaned;
  return '${cleaned.substring(0, max)}...';
}

String _friendlyAiError(Object? error) {
  final text = error?.toString() ?? '';
  if (text.contains('Unexpected end of input')) {
    return 'AI 输出不完整，请重试一次。';
  }
  if (text.contains('FormatException')) {
    return 'AI 返回格式不符合要求，请重试。';
  }
  return text.replaceFirst('Exception: ', '').trim().isEmpty
      ? '操作失败，请稍后重试。'
      : text.replaceFirst('Exception: ', '').trim();
}

String _compactImportError(String message) {
  final text = message.trim();
  if (text.isEmpty) return '导入失败，可以试试复制文字粘贴。';
  final lower = text.toLowerCase();
  if (lower.contains('exception') ||
      lower.contains('unexpected end of input') ||
      lower.contains('stack trace') ||
      lower.contains('errno')) {
    return '导入失败，可以试试复制文字粘贴。';
  }
  return text.length > 48 ? '${text.substring(0, 48)}...' : text;
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
