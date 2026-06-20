import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/knowledge_v3_repository.dart';
import '../../../shared/providers/knowledge_card_ai_provider.dart';
import '../../../shared/providers/knowledge_v3_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../services/knowledge_v3_ai_service.dart';
import '../utils/knowledge_document_importer.dart';

const _blue = Color(0xFF315BEF);
const _paper = Color(0xFFFFFFFF);
const _paperBorder = Color(0xFFE8ECF5);
const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _softBlue = Color(0xFFEFF3FF);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFE85347);
const _success = Color(0xFF168458);

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
                _WelcomeCard(
                  onAsk: () => _askTiantian(materials.valueOrNull ?? const []),
                ),
                const SizedBox(height: 14),
                _AskBox(
                  controller: _askController,
                  onChanged: (value) => setState(() => _query = value),
                  onAsk: () => _askTiantian(materials.valueOrNull ?? const []),
                  onSubmitted: (value) => _handleAskBoxSubmitted(
                    value,
                    materials.valueOrNull ?? const [],
                  ),
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

  Future<void> _askTiantian(List<KnowledgeMaterial> materials) async {
    if (materials.isEmpty) {
      _toast(context, '先导入资料，甜甜才有依据回答。');
      _showImportSheet(context, ref, widget.space);
      return;
    }
    final request = await showModalBottomSheet<_TiantianAskRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TiantianAskComposerSheet(
        initialQuestion: _askController.text,
        materials: materials,
      ),
    );
    if (!mounted || request == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnswerSheet(
        space: widget.space,
        question: request.question,
        materials: request.materials,
      ),
    );
    _refresh();
  }

  Future<void> _handleAskBoxSubmitted(
    String value,
    List<KnowledgeMaterial> materials,
  ) async {
    final text = value.trim();
    if (text.isEmpty) return;
    if (_looksLikeQuestion(text)) {
      await _askTiantian(materials);
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

class KnowledgeFlashReviewPage extends ConsumerStatefulWidget {
  const KnowledgeFlashReviewPage({super.key, required this.spaceId});

  final int spaceId;

  @override
  ConsumerState<KnowledgeFlashReviewPage> createState() =>
      _KnowledgeFlashReviewPageState();
}

class _KnowledgeFlashReviewPageState
    extends ConsumerState<KnowledgeFlashReviewPage> {
  List<KnowledgeCardV3> _queue = const [];
  int _index = 0;
  bool _answerVisible = false;
  DateTime? _startedAt;
  int _completedCount = 0;

  @override
  Widget build(BuildContext context) {
    final spaces = ref.watch(knowledgeSpacesV3Provider);
    final cards = ref.watch(knowledgeCardsV3Provider(widget.spaceId));
    final stats = ref.watch(knowledgeSpaceStatsV3Provider(widget.spaceId));
    final space = _findSpace(spaces.valueOrNull ?? const [], widget.spaceId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _GradientSurface(
        child: SafeArea(
          child: _queue.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _ReviewTopBar(
                      title: '${space?.name ?? '知识空间'}闪卡',
                      onBack: () =>
                          _returnToSpace(context, ref, widget.spaceId),
                    ),
                    const SizedBox(height: 14),
                    stats.when(
                      data: (item) => _ReviewOverview(
                        stats: item,
                        onStart: () => _start(cards.valueOrNull ?? const []),
                      ),
                      loading: () => const _Skeleton(height: 180),
                      error: (_, _) => _ErrorBlock(
                        message: '复习数据加载失败',
                        onRetry: () =>
                            invalidateKnowledgeV3(ref, spaceId: widget.spaceId),
                      ),
                    ),
                    const SizedBox(height: 18),
                    cards.when(
                      data: (items) => _completedCount > 0
                          ? _ReviewCompleteCard(
                              count: _completedCount,
                              onAgain: () {
                                setState(() => _completedCount = 0);
                                _start(items);
                              },
                              onBack: () =>
                                  _returnToSpace(context, ref, widget.spaceId),
                            )
                          : _ReviewEmptyHint(
                              cards: items,
                              onImport: space == null
                                  ? null
                                  : () => _showImportSheet(context, ref, space),
                              onGenerate: space == null
                                  ? null
                                  : () async {
                                      final materials = await ref.read(
                                        knowledgeMaterialsV3Provider(
                                          space.id,
                                        ).future,
                                      );
                                      if (!context.mounted) return;
                                      if (materials.isEmpty) {
                                        _toast(context, '先导入资料，再生成知识卡。');
                                        return;
                                      }
                                      await _showGenerationSheet(
                                        context,
                                        ref,
                                        space,
                                        materials,
                                      );
                                    },
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                )
              : _ReviewSession(
                  card: _queue[_index],
                  index: _index,
                  total: _queue.length,
                  answerVisible: _answerVisible,
                  onFlip: () => setState(() => _answerVisible = true),
                  onRate: _rate,
                ),
        ),
      ),
    );
  }

  Future<void> _start(List<KnowledgeCardV3> cards) async {
    if (cards.isEmpty) {
      _toast(context, '还没有知识卡，先从资料生成一组。');
      return;
    }
    final mode = cards.length == 1
        ? KnowledgeReviewModeV3.all
        : await _pickReviewMode(context, cards);
    if (!mounted || mode == null) return;
    final queue = await ref.read(
      knowledgeReviewQueueV3Provider(
        KnowledgeReviewQueueRequestV3(spaceId: widget.spaceId, mode: mode),
      ).future,
    );
    if (!mounted) return;
    if (queue.isEmpty) {
      _toast(context, '当前模式没有可复习卡片，可以试试全部随机。');
      return;
    }
    setState(() {
      _queue = queue;
      _index = 0;
      _answerVisible = false;
      _startedAt = DateTime.now();
      _completedCount = 0;
    });
  }

  Future<void> _rate(int rating) async {
    final card = _queue[_index];
    final durationMs = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inMilliseconds;
    await ref
        .read(knowledgeV3RepositoryProvider)
        .reviewCard(card: card, rating: rating, durationMs: durationMs);
    if (!mounted) return;
    if (_index >= _queue.length - 1) {
      final completed = _queue.length;
      setState(() {
        _queue = const [];
        _index = 0;
        _answerVisible = false;
        _startedAt = null;
        _completedCount = completed;
      });
      invalidateKnowledgeV3(ref, spaceId: widget.spaceId);
      return;
    }
    setState(() {
      _index++;
      _answerVisible = false;
      _startedAt = DateTime.now();
    });
  }
}

class _GradientSurface extends StatelessWidget {
  const _GradientSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6F8FF), Color(0xFFFFFFFF)],
        ),
      ),
      child: child,
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _paperBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F315BEF),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.space,
    required this.spaces,
    required this.onBack,
    required this.onSelectSpace,
    required this.onManageSpaces,
    required this.onLibrary,
  });

  final KnowledgeSpaceV3 space;
  final List<KnowledgeSpaceV3> spaces;
  final VoidCallback onBack;
  final ValueChanged<KnowledgeSpaceV3> onSelectSpace;
  final VoidCallback onManageSpaces;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '返回',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: _ink),
              ),
              Expanded(
                child: PopupMenuButton<int>(
                  onSelected: (id) {
                    if (id == -1) {
                      onManageSpaces();
                      return;
                    }
                    final target = _findSpace(spaces, id);
                    if (target != null) onSelectSpace(target);
                  },
                  itemBuilder: (_) => [
                    for (final item in spaces)
                      PopupMenuItem(value: item.id, child: Text(item.name)),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: -1, child: Text('管理知识空间')),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          space.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _T.navTitle,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '知识库',
                onPressed: onLibrary,
                icon: const Icon(Icons.menu_rounded, color: _ink),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '管理空间',
                onPressed: onManageSpaces,
                icon: const Icon(Icons.more_horiz_rounded, color: _ink),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PrimaryTaskCard extends StatelessWidget {
  const _PrimaryTaskCard({
    required this.stats,
    required this.onImport,
    required this.onGenerate,
    required this.onReview,
  });

  final KnowledgeSpaceStatsV3 stats;
  final VoidCallback onImport;
  final VoidCallback onGenerate;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final task = _task;
    return _PaperCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: _T.cardTitle),
              const SizedBox(height: 4),
              Text(task.subtitle, style: _T.body),
            ],
          );
          final button = FilledButton(
            onPressed: task.onTap,
            style: _primaryButtonStyle(height: 44),
            child: Text(task.label),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IconBubble(icon: task.icon),
                    const SizedBox(width: 12),
                    Expanded(child: text),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }
          return Row(
            children: [
              _IconBubble(icon: task.icon),
              const SizedBox(width: 14),
              Expanded(child: text),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }

  _PrimaryTask get _task {
    if (stats.materialCount == 0) {
      return _PrimaryTask(
        icon: Icons.note_add_outlined,
        title: '先放进一份学习资料',
        subtitle: '甜甜会根据资料问答、总结和生成知识卡。',
        label: '导入资料',
        onTap: onImport,
      );
    }
    if (stats.cardCount == 0) {
      return _PrimaryTask(
        icon: Icons.add_box_outlined,
        title: '资料已就绪，可以生成知识卡',
        subtitle: '${stats.materialCount} 份资料等待甜甜整理成抽卡内容。',
        label: '生成知识卡',
        onTap: onGenerate,
      );
    }
    if (stats.dueCount > 0) {
      return _PrimaryTask(
        icon: Icons.style_rounded,
        title: '今天有 ${stats.dueCount} 张待复习',
        subtitle: stats.weakCount > 0
            ? '其中 ${stats.weakCount} 张薄弱卡会优先出现。'
            : '先完成今日到期卡，保持记忆节奏。',
        label: '开始抽卡',
        onTap: onReview,
      );
    }
    return _PrimaryTask(
      icon: Icons.shuffle_rounded,
      title: '今天没有到期卡',
      subtitle: '可以随机抽几张巩固，也可以继续导入新资料。',
      label: '随机抽卡',
      onTap: onReview,
    );
  }
}

class _PrimaryTask {
  const _PrimaryTask({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String label;
  final VoidCallback onTap;
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onAsk});

  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      child: Row(
        children: [
          _TiantianImage(asset: 'tiantian_thinking.webp', size: 58),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('你好，我是甜甜', style: _T.cardTitle),
                SizedBox(height: 5),
                Text('你可以问我这个空间里的资料，也可以让我帮你生成知识卡。', style: _T.body),
              ],
            ),
          ),
          IconButton(
            tooltip: '问甜甜',
            onPressed: onAsk,
            icon: const Icon(Icons.arrow_forward_rounded, color: _blue),
          ),
        ],
      ),
    );
  }
}

class _AskBox extends StatelessWidget {
  const _AskBox({
    required this.controller,
    required this.onChanged,
    required this.onAsk,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onAsk;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        minLines: 1,
        maxLines: 3,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded, color: _blue),
          hintText: '搜索或问甜甜这个空间里的资料...',
          suffixIcon: TextButton.icon(
            onPressed: onAsk,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('问甜甜'),
          ),
        ),
      ),
    );
  }
}

class _BackTitle extends StatelessWidget {
  const _BackTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
        const SizedBox(width: 4),
        Expanded(child: Text(title, style: _T.pageTitle)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.showGenerate,
    required this.showWeak,
    required this.onSummary,
    required this.onGenerate,
    required this.onWeak,
  });

  final bool showGenerate;
  final bool showWeak;
  final VoidCallback onSummary;
  final VoidCallback onGenerate;
  final VoidCallback onWeak;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(Icons.description_outlined, '总结资料', onSummary),
      if (showGenerate)
        _QuickAction(Icons.add_box_outlined, '生成知识卡', onGenerate),
      if (showWeak) _QuickAction(Icons.track_changes_rounded, '解释薄弱卡', onWeak),
    ];
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(
            child: _PaperCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              onTap: actions[i].onTap,
              child: Column(
                children: [
                  Icon(actions[i].icon, color: _blue),
                  const SizedBox(height: 8),
                  Text(actions[i].label, style: _T.actionLabel),
                ],
              ),
            ),
          ),
          if (i != actions.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final KnowledgeSpaceStatsV3 stats;

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      child: Row(
        children: [
          _StatItem(value: '${stats.cardCount}', label: '知识卡片'),
          const _VLine(),
          _StatItem(value: '${stats.dueCount}', label: '待复习'),
          const _VLine(),
          _StatItem(value: '${stats.masteryPercent}%', label: '掌握度'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: _T.metric),
          const SizedBox(height: 4),
          Text(label, style: _T.body),
        ],
      ),
    );
  }
}

class _VLine extends StatelessWidget {
  const _VLine();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: _paperBorder);
  }
}

class _RecentMaterials extends StatelessWidget {
  const _RecentMaterials({
    required this.materials,
    required this.onMaterialTap,
    required this.onViewAll,
    required this.onImport,
  });

  final List<KnowledgeMaterial> materials;
  final ValueChanged<KnowledgeMaterial> onMaterialTap;
  final VoidCallback onViewAll;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: '最近资料', action: '查看全部', onAction: onViewAll),
          const SizedBox(height: 8),
          if (materials.isEmpty)
            _InlineEmpty(
              icon: Icons.note_add_outlined,
              title: '还没有资料',
              subtitle: '导入资料后，甜甜才能问答和生成知识卡。',
              action: '导入资料',
              onAction: onImport,
            )
          else
            for (final material in materials.take(3))
              _MaterialRow(
                material: material,
                onTap: () => onMaterialTap(material),
              ),
        ],
      ),
    );
  }
}

class _RecentCards extends StatelessWidget {
  const _RecentCards({
    required this.cards,
    required this.onCardTap,
    required this.onViewAll,
  });

  final List<KnowledgeCardV3> cards;
  final ValueChanged<KnowledgeCardV3> onCardTap;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: '最近知识卡', action: '查看全部', onAction: onViewAll),
          const SizedBox(height: 8),
          if (cards.isEmpty)
            const _InlineEmpty(
              icon: Icons.style_outlined,
              title: '还没有知识卡',
              subtitle: '导入资料后，让甜甜帮你生成第一组知识卡。',
            )
          else
            for (final card in cards.take(3))
              _CardRow(card: card, onTap: () => onCardTap(card)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: _T.sectionTitle),
        const Spacer(),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.material, required this.onTap});

  final KnowledgeMaterial material;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(material.updatedAt);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const _IconBubble(icon: Icons.description_outlined),
      title: Text(material.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${date.year}/${date.month}/${date.day} · ${_sizeLabel(material.content.length)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card, this.onTap});

  final KnowledgeCardV3 card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = _cardStatus(card);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const _IconBubble(icon: Icons.style_outlined),
      title: Text(card.question, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(card.answer, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: _StatusPill(text: status.$1, color: status.$2),
      onTap: onTap,
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: _blue, size: 20),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _paperBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: _blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _T.cardTitleSmall),
                const SizedBox(height: 3),
                Text(subtitle, style: _T.body),
              ],
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.spaceId, required this.query});

  final int spaceId;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(
      knowledgeSearchV3Provider(
        KnowledgeSearchRequestV3(spaceId: spaceId, query: query),
      ),
    );
    return _PaperCard(
      child: result.when(
        data: (items) {
          if (items.isEmpty) {
            return const Text('没有找到相关内容', style: _T.body);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('搜索结果', style: _T.sectionTitle),
              const SizedBox(height: 8),
              if (items.materials.isNotEmpty) ...[
                const Text('资料', style: _T.metaStrong),
                for (final material in items.materials.take(3))
                  _MaterialRow(
                    material: material,
                    onTap: () => _showMaterialDetail(context, ref, material),
                  ),
              ],
              if (items.cards.isNotEmpty) ...[
                const SizedBox(height: 6),
                const Text('知识卡', style: _T.metaStrong),
                for (final card in items.cards.take(3))
                  _CardRow(
                    card: card,
                    onTap: () => _showCardDetail(context, ref, card),
                  ),
              ],
              if (items.qaHits.isNotEmpty) ...[
                const SizedBox(height: 6),
                const Text('问答记录', style: _T.metaStrong),
                for (final hit in items.qaHits.take(3))
                  _QaSearchRow(
                    hit: hit,
                    onTap: () => _showQaSessionDetail(context, ref, hit),
                  ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Text('搜索失败', style: _T.body),
      ),
    );
  }
}

class _QaSearchRow extends StatelessWidget {
  const _QaSearchRow({required this.hit, required this.onTap});

  final TiantianQaSearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(hit.updatedAt);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const _IconBubble(icon: Icons.auto_awesome_rounded),
      title: Text(hit.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${date.year}/${date.month}/${date.day} · ${hit.excerpt}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _SpaceSelectCard extends ConsumerWidget {
  const _SpaceSelectCard({required this.space});

  final KnowledgeSpaceV3 space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(knowledgeSpaceStatsV3Provider(space.id));
    return _PaperCard(
      onTap: () {
        ref.read(selectedKnowledgeSpaceIdProvider.notifier).state = space.id;
        ref.read(knowledgeV3RepositoryProvider).rememberSpace(space.id);
        context.go('/plan/study/knowledge/space');
      },
      child: Row(
        children: [
          _SpaceIcon(type: space.type),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        space.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _T.cardTitle,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'rename') {
                          _showSpaceEditor(context, ref, space: space);
                        } else if (value == 'archive') {
                          await ref
                              .read(knowledgeV3RepositoryProvider)
                              .archiveSpace(space.id);
                          invalidateKnowledgeV3(ref, spaceId: space.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('重命名')),
                        PopupMenuItem(value: 'archive', child: Text('归档')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  space.note?.trim().isNotEmpty == true
                      ? space.note!
                      : _spaceTypeLabel(space.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.body,
                ),
                const SizedBox(height: 12),
                stats.when(
                  data: (item) => Text(
                    '${item.cardCount} 张卡片   ${item.dueCount} 待复习',
                    style: _T.meta,
                  ),
                  loading: () => const Text('加载中...', style: _T.meta),
                  error: (_, _) => const Text('暂无统计', style: _T.meta),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _SpaceIcon extends StatelessWidget {
  const _SpaceIcon({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      'exam' => Icons.assignment_turned_in_rounded,
      'language' => Icons.translate_rounded,
      'skill' => Icons.psychology_alt_rounded,
      'interest' => Icons.lightbulb_outline_rounded,
      _ => Icons.auto_stories_rounded,
    };
    final color = switch (type) {
      'exam' => _blue,
      'language' => const Color(0xFF7C3AED),
      'skill' => const Color(0xFF168458),
      'interest' => const Color(0xFFF59E0B),
      _ => _blue,
    };
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _DashedCreateCard extends StatelessWidget {
  const _DashedCreateCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _blue.withValues(alpha: 0.35)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: _blue),
              SizedBox(width: 8),
              Text('新建空间', style: _T.actionBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return const _PaperCard(
      child: Text('小贴士：空间用于管理你的资料和知识卡，不同主题建议创建独立空间。', style: _T.body),
    );
  }
}

class _LibrarySheet extends ConsumerStatefulWidget {
  const _LibrarySheet({required this.space});

  final KnowledgeSpaceV3 space;

  @override
  ConsumerState<_LibrarySheet> createState() => _LibrarySheetState();
}

class _LibrarySheetState extends ConsumerState<_LibrarySheet> {
  int _tab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(knowledgeMaterialsV3Provider(widget.space.id));
    final cards = ref.watch(knowledgeCardsV3Provider(widget.space.id));
    return _SheetScaffold(
      title: '知识库',
      child: Column(
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('资料')),
              ButtonSegment(value: 1, label: Text('知识卡')),
            ],
            selected: {_tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: _tab == 0 ? '搜索资料标题或内容' : '搜索知识卡',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: const Icon(Icons.tune_rounded),
              filled: true,
              fillColor: const Color(0xFFF7F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _paperBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _paperBorder),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _tab == 0
                ? materials.when(
                    data: (items) => _MaterialManageList(
                      items: _filterMaterials(items, _query),
                      onChanged: () =>
                          invalidateKnowledgeV3(ref, spaceId: widget.space.id),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Center(child: Text('资料加载失败')),
                  )
                : cards.when(
                    data: (items) => _CardManageList(
                      items: _filterCards(items, _query),
                      fullItems: items,
                      onChanged: () =>
                          invalidateKnowledgeV3(ref, spaceId: widget.space.id),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Center(child: Text('知识卡加载失败')),
                  ),
          ),
          const SizedBox(height: 12),
          materials.when(
            data: (items) => _LibraryPrimaryAction(
              tab: _tab,
              hasMaterials: items.isNotEmpty,
              onImport: () => _showImportSheet(context, ref, widget.space),
              onGenerate: () async {
                if (items.isEmpty) {
                  _showImportSheet(context, ref, widget.space);
                  return;
                }
                final selected = await _confirmMaterialAction(
                  context,
                  materials: items,
                  title: '选择要生成知识卡的资料',
                  description: '甜甜将只参考你勾选的资料，自动整理核心知识点并生成抽卡复习内容。',
                  actionLabel: '确认生成',
                );
                if (!context.mounted || selected == null || selected.isEmpty) {
                  return;
                }
                await _showGenerationSheet(
                  context,
                  ref,
                  widget.space,
                  selected,
                );
                if (context.mounted) {
                  invalidateKnowledgeV3(ref, spaceId: widget.space.id);
                }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => _LibraryPrimaryAction(
              tab: _tab,
              hasMaterials: false,
              onImport: () => _showImportSheet(context, ref, widget.space),
              onGenerate: () => _showImportSheet(context, ref, widget.space),
            ),
          ),
        ],
      ),
    );
  }

  List<KnowledgeMaterial> _filterMaterials(
    List<KnowledgeMaterial> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.title.toLowerCase().contains(q) ||
              item.content.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  List<KnowledgeCardV3> _filterCards(
    List<KnowledgeCardV3> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.question.toLowerCase().contains(q) ||
              item.answer.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }
}

class _LibraryPrimaryAction extends StatelessWidget {
  const _LibraryPrimaryAction({
    required this.tab,
    required this.hasMaterials,
    required this.onImport,
    required this.onGenerate,
  });

  final int tab;
  final bool hasMaterials;
  final VoidCallback onImport;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final isMaterialsTab = tab == 0;
    final label = isMaterialsTab
        ? '添加资料'
        : hasMaterials
        ? '生成知识卡'
        : '导入资料';
    final icon = isMaterialsTab
        ? Icons.add_rounded
        : hasMaterials
        ? Icons.auto_awesome_rounded
        : Icons.upload_file_rounded;
    final onPressed = isMaterialsTab ? onImport : onGenerate;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: _primaryButtonStyle(),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _MaterialManageList extends ConsumerWidget {
  const _MaterialManageList({required this.items, required this.onChanged});

  final List<KnowledgeMaterial> items;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _CenteredEmpty(title: '还没有资料', subtitle: '点击底部按钮添加资料。');
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: const _IconBubble(icon: Icons.description_outlined),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(_sizeLabel(item.content.length)),
          onTap: () => _showMaterialDetail(context, ref, item),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              final repo = ref.read(knowledgeV3RepositoryProvider);
              if (value == 'view') {
                _showMaterialDetail(context, ref, item);
              } else if (value == 'append') {
                await _appendMaterial(context, ref, item);
                onChanged();
              } else if (value == 'edit') {
                await _editMaterial(context, ref, item);
                onChanged();
              } else if (value == 'up') {
                await repo.reorderMaterial(id: item.id, direction: -1);
                onChanged();
              } else if (value == 'down') {
                await repo.reorderMaterial(id: item.id, direction: 1);
                onChanged();
              } else if (value == 'delete') {
                final confirmed = await _confirmDelete(
                  context,
                  title: '删除资料',
                  message: '这份资料会从当前知识库移除，已生成的知识卡不会一起删除。',
                );
                if (confirmed) {
                  await repo.archiveMaterial(item.id);
                  onChanged();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'view', child: Text('查看')),
              PopupMenuItem(value: 'append', child: Text('续编')),
              PopupMenuItem(value: 'edit', child: Text('编辑')),
              PopupMenuItem(value: 'up', child: Text('上移')),
              PopupMenuItem(value: 'down', child: Text('下移')),
              PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        );
      },
    );
  }
}

class _CardManageList extends ConsumerWidget {
  const _CardManageList({
    required this.items,
    required this.fullItems,
    required this.onChanged,
  });

  final List<KnowledgeCardV3> items;
  final List<KnowledgeCardV3> fullItems;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _CenteredEmpty(title: '还没有知识卡', subtitle: '先从资料生成知识卡。');
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const _IconBubble(icon: Icons.style_outlined),
          title: Text(
            item.question,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.answer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _showCardDetail(context, ref, item),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              final repo = ref.read(knowledgeV3RepositoryProvider);
              if (value == 'view') {
                _showCardDetail(context, ref, item);
              } else if (value == 'edit') {
                await _editCard(context, ref, item);
                onChanged();
              } else if (value == 'up') {
                await repo.reorderCard(id: item.id, direction: -1);
                onChanged();
              } else if (value == 'down') {
                await repo.reorderCard(id: item.id, direction: 1);
                onChanged();
              } else if (value == 'delete') {
                final confirmed = await _confirmDelete(
                  context,
                  title: '删除知识卡',
                  message: '这张知识卡会从当前空间移除，复习记录保留在本地日志中。',
                );
                if (confirmed) {
                  await repo.archiveCard(item.id);
                  onChanged();
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Text('查看')),
              const PopupMenuItem(value: 'edit', child: Text('编辑')),
              PopupMenuItem(
                value: 'up',
                enabled: fullItems.indexWhere((card) => card.id == item.id) > 0,
                child: const Text('上移'),
              ),
              PopupMenuItem(
                value: 'down',
                enabled:
                    fullItems.indexWhere((card) => card.id == item.id) <
                    fullItems.length - 1,
                child: const Text('下移'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        );
      },
    );
  }
}

class _ImportSheet extends ConsumerStatefulWidget {
  const _ImportSheet({required this.initialSpace});

  final KnowledgeSpaceV3 initialSpace;

  @override
  ConsumerState<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<_ImportSheet> {
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();
  late KnowledgeSpaceV3 _space = widget.initialSpace;
  List<KnowledgeSpaceV3>? _spacesOverride;
  KnowledgeMaterial? _imported;
  bool _busy = false;

  @override
  void dispose() {
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watchedSpaces = ref.watch(knowledgeSpacesV3Provider).valueOrNull;
    final spaces = _mergeSpaces(
      _spacesOverride ?? watchedSpaces ?? const [],
      _space,
    );
    return _SheetScaffold(
      title: _imported == null ? '导入资料' : '资料已导入',
      child: _imported == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('导入到空间', style: _T.cardTitleSmall),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: _space.id,
                          items: [
                            for (final item in spaces)
                              DropdownMenuItem(
                                value: item.id,
                                child: Text(item.name),
                              ),
                          ],
                          onChanged: (id) {
                            final target = _findSpace(spaces, id ?? _space.id);
                            if (target != null) setState(() => _space = target);
                          },
                          decoration: _inputDecoration(),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _createSpaceInsideImport,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('新建空间'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _contentController,
                          minLines: 5,
                          maxLines: 10,
                          onChanged: (_) => setState(() {}),
                          decoration:
                              _inputDecoration(
                                label: '粘贴文本或内容',
                                hint: '在此粘贴学习资料、笔记、文章、题目解析等内容，甜甜会自动解析并生成知识卡。',
                              ).copyWith(
                                alignLabelWithHint: true,
                                suffix: Text(
                                  '${_contentController.text.length} 字',
                                ),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ImportMethodButton(
                              icon: Icons.upload_file_rounded,
                              title: '文件',
                              subtitle: 'PDF/Word/TXT',
                              onTap: _pickFile,
                            ),
                            _ImportMethodButton(
                              icon: Icons.link_rounded,
                              title: '网页',
                              subtitle: '粘贴链接',
                              onTap: _importUrl,
                            ),
                            _ImportMethodButton(
                              icon: Icons.image_outlined,
                              title: '图片',
                              subtitle: 'OCR 识别',
                              onTap: _pickImage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy || _contentController.text.trim().isEmpty
                        ? null
                        : _importText,
                    style: _primaryButtonStyle(),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('开始导入'),
                  ),
                ),
              ],
            )
          : _ImportDone(
              material: _imported!,
              onGenerate: () async {
                Navigator.of(context).pop();
                await _showGenerationSheet(context, ref, _space, [_imported!]);
              },
              onLater: () => Navigator.of(context).pop(),
            ),
    );
  }

  Future<void> _importText() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      _toast(context, '请先粘贴资料内容。');
      return;
    }
    await _saveMaterial(
      title: _autoMaterialTitle(content),
      content: content,
      sourceType: 'text',
    );
  }

  Future<void> _createSpaceInsideImport() async {
    final created = await _showSpaceEditor(context, ref, returnCreated: true);
    if (!mounted || created == null) return;
    final space = await ref
        .read(knowledgeV3RepositoryProvider)
        .getSpace(created);
    if (space == null) return;
    final current = ref.read(knowledgeSpacesV3Provider).valueOrNull ?? const [];
    setState(() {
      _space = space;
      _spacesOverride = _mergeSpaces(current, space);
    });
    ref.invalidate(knowledgeSpacesV3Provider);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final imported = await KnowledgeDocumentImporter().extractFromFile(
        File(path),
        ocrCallback: (imageBytes, mimeType) => ref
            .read(knowledgeV3AiServiceProvider)
            .ocrImageBytes(imageBytes: imageBytes, mimeType: mimeType),
      );
      if (!mounted) return;
      if (!imported.isSuccess) {
        _showImportError(imported, fallback: '这个文件暂时无法读取，可以试试复制文字粘贴。');
        return;
      }
      await _saveMaterial(
        title: imported.title,
        content: imported.content,
        sourceType: imported.type,
        sourcePath: imported.sourcePath,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final imported = await KnowledgeDocumentImporter().extractFromFile(
        File(path),
        ocrCallback: (imageBytes, mimeType) => ref
            .read(knowledgeV3AiServiceProvider)
            .ocrImageBytes(imageBytes: imageBytes, mimeType: mimeType),
      );
      if (!mounted) return;
      if (!imported.isSuccess) {
        _showImportError(imported, fallback: '图片文字识别失败，可以直接粘贴文字。');
        return;
      }
      await _saveMaterial(
        title: imported.title,
        content: imported.content,
        sourceType: imported.type,
        sourcePath: imported.sourcePath,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importUrl() async {
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetScaffold(
        title: '导入网页',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('粘贴网页链接，甜甜会尝试读取正文内容。', style: _T.bodyLarge),
            const SizedBox(height: 14),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: _inputDecoration(hint: 'https://example.com/article'),
            ),
            const Spacer(),
            LayoutBuilder(
              builder: (context, constraints) {
                final cancelButton = OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _secondaryButtonStyle(),
                  child: const Text('取消'),
                );
                final importButton = FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_urlController.text.trim()),
                  style: _primaryButtonStyle(),
                  child: const Text('抓取网页'),
                );
                if (constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      importButton,
                      const SizedBox(height: 8),
                      cancelButton,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cancelButton),
                    const SizedBox(width: 10),
                    Expanded(child: importButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    if (url == null || url.isEmpty) return;
    setState(() => _busy = true);
    try {
      final imported = await KnowledgeDocumentImporter().extractFromUrl(url);
      if (!mounted) return;
      if (!imported.isSuccess) {
        _showImportError(imported, fallback: '网页暂时无法读取，可以复制正文粘贴导入。');
        return;
      }
      await _saveMaterial(
        title: imported.title,
        content: imported.content,
        sourceType: imported.type,
        sourcePath: imported.sourcePath,
        url: url,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showImportError(
    DocumentImportResult imported, {
    required String fallback,
  }) {
    _toast(context, _compactImportError(imported.displayError ?? fallback));
  }

  Future<void> _saveMaterial({
    required String title,
    required String content,
    String sourceType = 'text',
    String? sourcePath,
    String? url,
  }) async {
    setState(() => _busy = true);
    try {
      final id = await ref
          .read(knowledgeV3RepositoryProvider)
          .importMaterial(
            spaceId: _space.id,
            title: title,
            content: content,
            sourceType: sourceType,
            sourcePath: sourcePath,
            url: url,
          );
      final material = await ref
          .read(knowledgeV3RepositoryProvider)
          .getMaterial(id);
      if (!mounted || material == null) return;
      ref.read(selectedKnowledgeSpaceIdProvider.notifier).state = _space.id;
      await ref.read(knowledgeV3RepositoryProvider).rememberSpace(_space.id);
      invalidateKnowledgeV3(ref, spaceId: _space.id);
      setState(() => _imported = material);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ImportMethodButton extends StatelessWidget {
  const _ImportMethodButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _paperBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _blue, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _T.cardTitleSmall,
            ),
            const SizedBox(width: 5),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _T.meta,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportDone extends StatelessWidget {
  const _ImportDone({
    required this.material,
    required this.onGenerate,
    required this.onLater,
  });

  final KnowledgeMaterial material;
  final VoidCallback onGenerate;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: _success),
              SizedBox(width: 10),
              Expanded(child: Text('资料已导入，可生成知识卡', style: _T.cardTitleSmall)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(material.title, style: _T.cardTitle),
              const SizedBox(height: 8),
              Text(
                '${_sizeLabel(material.content.length)} · 已保存到当前空间',
                style: _T.body,
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onGenerate,
            style: _primaryButtonStyle(),
            child: const Text('生成知识卡'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onLater,
            style: _secondaryButtonStyle(),
            child: const Text('回到空间'),
          ),
        ),
      ],
    );
  }
}

class _AnswerSheet extends ConsumerStatefulWidget {
  const _AnswerSheet({
    required this.space,
    required this.question,
    required this.materials,
  });

  final KnowledgeSpaceV3 space;
  final String question;
  final List<KnowledgeMaterial> materials;

  @override
  ConsumerState<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends ConsumerState<_AnswerSheet> {
  late final Future<TiantianAnswer> _future = ref
      .read(knowledgeV3AiServiceProvider)
      .answerQuestion(
        space: widget.space,
        question: widget.question,
        materials: widget.materials,
      );
  final _followUpController = TextEditingController();

  @override
  void dispose() {
    _followUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '甜甜问答',
      child: FutureBuilder<TiantianAnswer>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _WorkingState(text: '甜甜正在阅读你选择的资料...');
          }
          if (snapshot.hasError) {
            final needsAiConfig = _needsAiConfig(snapshot.error);
            return _ErrorBlock(
              message: _friendlyAiError(snapshot.error),
              retryLabel: '返回',
              onRetry: () => Navigator.of(context).pop(),
              secondaryLabel: needsAiConfig ? '去配置 AI' : null,
              onSecondary: needsAiConfig
                  ? () => context.push('/ai-config')
                  : null,
            );
          }
          final answer = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.question, style: _T.cardTitle),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Text(answer.answer, style: _T.answer),
                    const SizedBox(height: 18),
                    const Text('参考资料', style: _T.sectionTitle),
                    const SizedBox(height: 8),
                    for (final material in widget.materials)
                      _ReferenceTile(material: material),
                  ],
                ),
              ),
              _SaveAnswerAsCardButton(space: widget.space, answer: answer),
              const SizedBox(height: 10),
              _FollowUpBox(
                controller: _followUpController,
                hintText: '继续问甜甜...',
                onSend: () => _sendFollowUp(answer),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendFollowUp(TiantianAnswer answer) async {
    final question = _followUpController.text.trim();
    if (question.isEmpty) {
      _toast(context, '先输入要继续问的问题。');
      return;
    }
    final history = await ref.read(
      tiantianQaMessagesProvider(answer.sessionId).future,
    );
    if (!mounted) return;
    _followUpController.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowUpAnswerSheet(
        space: widget.space,
        sessionId: answer.sessionId,
        question: question,
        materials: widget.materials,
        history: history,
      ),
    );
    if (mounted) {
      ref.invalidate(tiantianQaMessagesProvider(answer.sessionId));
    }
  }
}

class _FollowUpBox extends StatelessWidget {
  const _FollowUpBox({
    required this.controller,
    required this.hintText,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _paperBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('发送'),
          ),
        ],
      ),
    );
  }
}

class _FollowUpAnswerSheet extends ConsumerStatefulWidget {
  const _FollowUpAnswerSheet({
    required this.space,
    required this.sessionId,
    required this.question,
    required this.materials,
    required this.history,
  });

  final KnowledgeSpaceV3 space;
  final int sessionId;
  final String question;
  final List<KnowledgeMaterial> materials;
  final List<TiantianQaMessage> history;

  @override
  ConsumerState<_FollowUpAnswerSheet> createState() =>
      _FollowUpAnswerSheetState();
}

class _FollowUpAnswerSheetState extends ConsumerState<_FollowUpAnswerSheet> {
  late final Future<TiantianAnswer> _future = ref
      .read(knowledgeV3AiServiceProvider)
      .continueQuestion(
        space: widget.space,
        sessionId: widget.sessionId,
        question: widget.question,
        materials: widget.materials,
        history: widget.history,
      );

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '甜甜继续回答',
      child: FutureBuilder<TiantianAnswer>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _WorkingState(text: '甜甜正在接着想...');
          }
          if (snapshot.hasError) {
            final needsAiConfig = _needsAiConfig(snapshot.error);
            return _ErrorBlock(
              message: _friendlyAiError(snapshot.error),
              retryLabel: '返回',
              onRetry: () => Navigator.of(context).pop(),
              secondaryLabel: needsAiConfig ? '去配置 AI' : null,
              onSecondary: needsAiConfig
                  ? () => context.push('/ai-config')
                  : null,
            );
          }
          final answer = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.question, style: _T.cardTitle),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Text(answer.answer, style: _T.answer),
                    const SizedBox(height: 18),
                    const Text('参考资料', style: _T.sectionTitle),
                    const SizedBox(height: 8),
                    for (final material in widget.materials)
                      _ReferenceTile(material: material),
                  ],
                ),
              ),
              _SaveAnswerAsCardButton(space: widget.space, answer: answer),
            ],
          );
        },
      ),
    );
  }
}

class _SaveAnswerAsCardButton extends ConsumerStatefulWidget {
  const _SaveAnswerAsCardButton({required this.space, required this.answer});

  final KnowledgeSpaceV3 space;
  final TiantianAnswer answer;

  @override
  ConsumerState<_SaveAnswerAsCardButton> createState() =>
      _SaveAnswerAsCardButtonState();
}

class _SaveAnswerAsCardButtonState
    extends ConsumerState<_SaveAnswerAsCardButton> {
  bool _saving = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _saving || _saved ? null : _save,
        style: _primaryButtonStyle(),
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_saved ? Icons.check_circle_rounded : Icons.style_rounded),
        label: Text(_saved ? '已转成知识卡' : '把这段回答做成知识卡'),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(knowledgeV3AiServiceProvider)
          .saveAnswerAsCard(space: widget.space, answer: widget.answer);
      invalidateKnowledgeV3(ref, spaceId: widget.space.id);
      if (!mounted) return;
      setState(() => _saved = true);
      _toast(context, '已保存为知识卡。');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _TiantianAskRequest {
  const _TiantianAskRequest({required this.question, required this.materials});

  final String question;
  final List<KnowledgeMaterial> materials;
}

class _TiantianAskComposerSheet extends StatefulWidget {
  const _TiantianAskComposerSheet({
    required this.initialQuestion,
    required this.materials,
  });

  final String initialQuestion;
  final List<KnowledgeMaterial> materials;

  @override
  State<_TiantianAskComposerSheet> createState() =>
      _TiantianAskComposerSheetState();
}

class _TiantianAskComposerSheetState extends State<_TiantianAskComposerSheet> {
  late final TextEditingController _questionController = TextEditingController(
    text: widget.initialQuestion.trim(),
  );
  late final Set<int> _selected = widget.materials
      .map((item) => item.id)
      .toSet();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '问甜甜',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _questionController,
            minLines: 3,
            maxLines: 5,
            autofocus: _questionController.text.isEmpty,
            decoration: _inputDecoration(
              label: '你想问什么？',
              hint: '例如：这份资料里最容易混淆的点是什么？',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: Text('参考资料', style: _T.cardTitleSmall)),
              TextButton(
                onPressed: () => setState(() {
                  _selected
                    ..clear()
                    ..addAll(widget.materials.map((item) => item.id));
                }),
                child: const Text('全选'),
              ),
              TextButton(
                onPressed: () => setState(_selected.clear),
                child: const Text('清空'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '发送前请确认。已选择 ${_selected.length} 份资料，甜甜只会使用这些资料回答。',
            style: _T.body,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                for (final material in widget.materials)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selected.contains(material.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selected.add(material.id);
                        } else {
                          _selected.remove(material.id);
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
            child: FilledButton.icon(
              onPressed: _selected.isEmpty ? null : _submit,
              style: _primaryButtonStyle(),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('确认并提问'),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      _toast(context, '先问甜甜一个问题吧。');
      return;
    }
    Navigator.of(context).pop(
      _TiantianAskRequest(
        question: question,
        materials: widget.materials
            .where((item) => _selected.contains(item.id))
            .toList(growable: false),
      ),
    );
  }
}

class _AiResultSheet extends StatefulWidget {
  const _AiResultSheet({
    required this.title,
    required this.workingText,
    required this.future,
    this.successActionLabel,
    this.onSuccessAction,
  });

  final String title;
  final String workingText;
  final Future<String> future;
  final String? successActionLabel;
  final VoidCallback? onSuccessAction;

  @override
  State<_AiResultSheet> createState() => _AiResultSheetState();
}

class _AiResultSheetState extends State<_AiResultSheet> {
  late final Future<String> _future = widget.future;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: widget.title,
      child: FutureBuilder<String>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _WorkingState(text: widget.workingText);
          }
          if (snapshot.hasError) {
            final needsAiConfig = _needsAiConfig(snapshot.error);
            return _ErrorBlock(
              message: _friendlyAiError(snapshot.error),
              retryLabel: '返回',
              onRetry: () => Navigator.of(context).pop(),
              secondaryLabel: needsAiConfig ? '去配置 AI' : null,
              onSecondary: needsAiConfig
                  ? () => context.push('/ai-config')
                  : null,
            );
          }
          final content = snapshot.data?.trim() ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    content.isEmpty ? '甜甜没有整理出有效内容，请稍后重试。' : content,
                    style: _T.answer,
                  ),
                ),
              ),
              if (widget.successActionLabel != null &&
                  widget.onSuccessAction != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.onSuccessAction,
                    style: _primaryButtonStyle(),
                    child: Text(widget.successActionLabel!),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({required this.material});

  final KnowledgeMaterial material;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(material.title, style: _T.cardTitleSmall),
      subtitle: Text(_sizeLabel(material.content.length), style: _T.meta),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(_preview(material.content, max: 600), style: _T.body),
        ),
      ],
    );
  }
}

class _ReviewTopBar extends StatelessWidget {
  const _ReviewTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(title, style: _T.navTitle, textAlign: TextAlign.center),
          ),
          IconButton(
            tooltip: '复习规则',
            onPressed: () => _showReviewRuleSheet(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}

class _ReviewOverview extends StatelessWidget {
  const _ReviewOverview({required this.stats, required this.onStart});

  final KnowledgeSpaceStatsV3 stats;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${stats.dueCount} 今日待复习', style: _T.reviewNumber),
                    const SizedBox(height: 8),
                    Text('${stats.weakCount} 薄弱卡片', style: _T.body),
                  ],
                ),
              ),
              _MasteryRing(percent: stats.masteryPercent),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onStart,
              style: _primaryButtonStyle(),
              child: const Text('开始抽卡'),
            ),
          ),
        ],
      ),
    );
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

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _T.cardTitleSmall),
          const SizedBox(height: 4),
          Text(body, style: _T.bodyLarge),
        ],
      ),
    );
  }
}

class _MasteryRing extends StatelessWidget {
  const _MasteryRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent / 100,
            strokeWidth: 8,
            backgroundColor: _softBlue,
            color: _blue,
          ),
          Text('$percent%', style: _T.cardTitle),
        ],
      ),
    );
  }
}

class _ReviewEmptyHint extends StatelessWidget {
  const _ReviewEmptyHint({
    required this.cards,
    required this.onImport,
    required this.onGenerate,
  });

  final List<KnowledgeCardV3> cards;
  final VoidCallback? onImport;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    if (cards.isNotEmpty) {
      return const _PaperCard(
        child: Text('如果今天没有到期卡，也可以点击开始抽卡后选择“全部随机”。', style: _T.body),
      );
    }
    return _PaperCard(
      child: Row(
        children: [
          _TiantianImage(asset: 'tiantian_empty.webp', size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('还没有可复习的知识卡', style: _T.cardTitle),
                const SizedBox(height: 5),
                const Text('先导入资料，再让甜甜生成一组知识卡。', style: _T.body),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 260;
                    final importButton = OutlinedButton(
                      onPressed: onImport,
                      style: _secondaryButtonStyle(height: 40),
                      child: const Text('导入资料'),
                    );
                    final generateButton = FilledButton(
                      onPressed: onGenerate,
                      style: _primaryButtonStyle(height: 40),
                      child: const Text('生成知识卡'),
                    );
                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          importButton,
                          const SizedBox(height: 8),
                          generateButton,
                        ],
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [importButton, generateButton],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCompleteCard extends StatelessWidget {
  const _ReviewCompleteCard({
    required this.count,
    required this.onAgain,
    required this.onBack,
  });

  final int count;
  final VoidCallback onAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      child: Row(
        children: [
          _TiantianImage(asset: 'tiantian_success.webp', size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('本组抽卡完成', style: _T.cardTitle),
                const SizedBox(height: 5),
                Text('刚刚复习了 $count 张卡。甜甜已经根据你的反馈安排下次出现时间。', style: _T.body),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: onAgain,
                      style: _primaryButtonStyle(height: 40),
                      child: const Text('再抽一组'),
                    ),
                    OutlinedButton(
                      onPressed: onBack,
                      style: _secondaryButtonStyle(height: 40),
                      child: const Text('回到空间'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSession extends StatelessWidget {
  const _ReviewSession({
    required this.card,
    required this.index,
    required this.total,
    required this.answerVisible,
    required this.onFlip,
    required this.onRate,
  });

  final KnowledgeCardV3 card;
  final int index;
  final int total;
  final bool answerVisible;
  final VoidCallback onFlip;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (index + 1) / total,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: _softBlue,
                  color: _blue,
                ),
              ),
              const SizedBox(width: 12),
              Text('${index + 1}/$total', style: _T.metaStrong),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: _PaperCard(
              padding: const EdgeInsets.all(22),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (card.sourceTitle != null)
                                _StatusPill(
                                  text: card.sourceTitle!,
                                  color: _blue,
                                ),
                              _StatusPill(
                                text: _cardStatus(card).$1,
                                color: _cardStatus(card).$2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(card.question, style: _T.question),
                          const SizedBox(height: 18),
                          if (!answerVisible)
                            const Text('点击「翻开答案」查看解析', style: _T.body)
                          else ...[
                            const Text('答案', style: _T.sectionTitle),
                            const SizedBox(height: 8),
                            Text(card.answer, style: _T.answer),
                            if (card.explanation?.trim().isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 16),
                              const Text('解析', style: _T.sectionTitle),
                              const SizedBox(height: 8),
                              Text(card.explanation!, style: _T.bodyLarge),
                            ],
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: answerVisible
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _RateButton(
                            label: '完全忘了',
                            color: _danger,
                            onTap: () => onRate(0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RateButton(
                            label: '有点印象',
                            color: _warning,
                            onTap: () => onRate(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _RateButton(
                            label: '基本记得',
                            color: _blue,
                            onTap: () => onRate(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RateButton(
                            label: '很熟练',
                            color: _success,
                            onTap: () => onRate(3),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onFlip,
                    style: _primaryButtonStyle(),
                    child: const Text('翻开答案'),
                  ),
                ),
        ),
      ],
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: color,
            backgroundColor: Colors.white.withValues(alpha: 0.74),
            side: BorderSide(color: color.withValues(alpha: 0.25)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = (size.height - bottomInset).clamp(
      320.0,
      size.height,
    );
    final height = availableHeight * 0.92;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: height,
                decoration: const BoxDecoration(
                  color: Color(0xF7FFFFFF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(title, style: _T.sheetTitle)),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: _paperBorder),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkingState extends StatelessWidget {
  const _WorkingState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TiantianImage(asset: 'tiantian_focus.webp', size: 82),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(text, style: _T.bodyLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _CenteredEmpty extends StatelessWidget {
  const _CenteredEmpty({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TiantianImage(asset: 'tiantian_empty.webp', size: 78),
          const SizedBox(height: 12),
          Text(title, style: _T.cardTitle),
          const SizedBox(height: 6),
          Text(subtitle, style: _T.body),
        ],
      ),
    );
  }
}

class _TiantianImage extends StatelessWidget {
  const _TiantianImage({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/knowledge_cards/v3/$asset',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _softBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: _blue),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: _GradientSurface(child: Center(child: CircularProgressIndicator())),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _GradientSurface(
        child: Center(
          child: _ErrorBlock(message: message, onRetry: onRetry),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({
    required this.message,
    required this.onRetry,
    this.retryLabel = '重试',
    this.secondaryLabel,
    this.onSecondary,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger),
          const SizedBox(height: 8),
          Text(message, style: _T.cardTitle, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
              if (secondaryLabel != null && onSecondary != null)
                FilledButton(
                  onPressed: onSecondary,
                  style: _primaryButtonStyle(height: 40),
                  child: Text(secondaryLabel!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _paperBorder),
      ),
    );
  }
}

class _T {
  static const pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: _ink,
    height: 1.15,
  );
  static const sheetTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: _ink,
  );
  static const navTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: _ink,
  );
  static const sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: _ink,
  );
  static const cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: _ink,
  );
  static const cardTitleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _ink,
  );
  static const subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _muted,
  );
  static const body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: _muted,
    height: 1.35,
  );
  static const bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: _muted,
    height: 1.45,
  );
  static const answer = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: _ink,
    height: 1.55,
  );
  static const question = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: _ink,
    height: 1.35,
  );
  static const metric = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: _blue,
  );
  static const reviewNumber = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: _ink,
  );
  static const actionLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: _ink,
  );
  static const actionBlue = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: _blue,
  );
  static const meta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _muted,
  );
  static const metaStrong = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: _ink,
  );
}

ButtonStyle _primaryButtonStyle({double height = 52}) {
  return FilledButton.styleFrom(
    minimumSize: Size(0, height),
    backgroundColor: _blue,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  );
}

ButtonStyle _secondaryButtonStyle({double height = 52}) {
  return OutlinedButton.styleFrom(
    minimumSize: Size(0, height),
    foregroundColor: _blue,
    side: const BorderSide(color: _paperBorder),
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
      borderSide: const BorderSide(color: _paperBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _paperBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _blue),
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

class _SpaceEditorSheet extends ConsumerStatefulWidget {
  const _SpaceEditorSheet({this.space, required this.returnCreated});

  final KnowledgeSpaceV3? space;
  final bool returnCreated;

  @override
  ConsumerState<_SpaceEditorSheet> createState() => _SpaceEditorSheetState();
}

class _SpaceEditorSheetState extends ConsumerState<_SpaceEditorSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.space?.name ?? '',
  );
  late final TextEditingController _noteController = TextEditingController(
    text: widget.space?.note ?? '',
  );
  late String _type = widget.space?.type ?? 'exam';

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final space = widget.space;
    return _SheetScaffold(
      title: space == null ? '新建空间' : '编辑空间',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: _inputDecoration(label: '空间名称', hint: '例如：考公、考研英语'),
          ),
          const SizedBox(height: 14),
          const Text('空间类型', style: _T.cardTitleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const [
                ('exam', '备考'),
                ('language', '语言学习'),
                ('skill', '职业技能'),
                ('interest', '兴趣知识'),
                ('custom', '自定义'),
              ])
                ChoiceChip(
                  label: Text(item.$2),
                  selected: _type == item.$1,
                  onSelected: (_) => setState(() => _type = item.$1),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            minLines: 3,
            maxLines: 4,
            decoration: _inputDecoration(
              label: '一句话备注（可选）',
              hint: '用于快速记住这个空间的用途',
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: _primaryButtonStyle(),
              child: Text(space == null ? '创建并进入' : '保存'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast(context, '请填写空间名称。');
      return;
    }
    final repo = ref.read(knowledgeV3RepositoryProvider);
    final space = widget.space;
    if (space == null) {
      final id = await repo.createSpace(
        name: name,
        type: _type,
        note: _noteController.text,
      );
      await repo.rememberSpace(id);
      ref.read(selectedKnowledgeSpaceIdProvider.notifier).state = id;
      invalidateKnowledgeV3(ref, spaceId: id);
      if (mounted) Navigator.of(context).pop(widget.returnCreated ? id : null);
      return;
    }
    await repo.renameSpace(
      id: space.id,
      name: name,
      type: _type,
      note: _noteController.text,
    );
    await repo.rememberSpace(space.id);
    invalidateKnowledgeV3(ref, spaceId: space.id);
    if (mounted) Navigator.of(context).pop();
  }
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

class _GenerationSheet extends ConsumerStatefulWidget {
  const _GenerationSheet({required this.space, required this.materials});

  final KnowledgeSpaceV3 space;
  final List<KnowledgeMaterial> materials;

  @override
  ConsumerState<_GenerationSheet> createState() => _GenerationSheetState();
}

class _GenerationSheetState extends ConsumerState<_GenerationSheet> {
  late final Future<List<int>> _future = ref
      .read(knowledgeV3AiServiceProvider)
      .generateCards(space: widget.space, materials: widget.materials);
  bool _invalidated = false;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '生成知识卡',
      child: FutureBuilder<List<int>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _WorkingState(text: '甜甜正在整理核心知识点...');
          }
          if (snapshot.hasError) {
            final needsAiConfig = _needsAiConfig(snapshot.error);
            return _ErrorBlock(
              message: _friendlyAiError(snapshot.error),
              retryLabel: '返回',
              onRetry: () => Navigator.of(context).pop(),
              secondaryLabel: needsAiConfig ? '去配置 AI' : null,
              onSecondary: needsAiConfig
                  ? () => context.push('/ai-config')
                  : null,
            );
          }
          final count = snapshot.data?.length ?? 0;
          if (!_invalidated) {
            _invalidated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) invalidateKnowledgeV3(ref, spaceId: widget.space.id);
            });
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TiantianImage(asset: 'tiantian_success.webp', size: 92),
              const SizedBox(height: 16),
              Text('已生成 $count 张知识卡', style: _T.cardTitle),
              const SizedBox(height: 8),
              const Text('现在可以开始抽卡复习。', style: _T.body),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openReview(context, widget.space);
                  },
                  style: _primaryButtonStyle(),
                  child: const Text('开始抽卡'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _secondaryButtonStyle(),
                  child: const Text('回到空间'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
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

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      onTap: onTap,
      child: Row(
        children: [
          _IconBubble(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _T.cardTitle),
                const SizedBox(height: 3),
                Text(subtitle, style: _T.body),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
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
                      _StatusPill(text: card.sourceTitle!, color: _blue),
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
                    await ref.read(knowledgeV3RepositoryProvider).archiveCard(card.id);
                    if (context.mounted) {
                      invalidateKnowledgeV3(ref, spaceId: card.spaceId);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已删除')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('删除失败: $e')),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: _danger,
                  side: BorderSide(color: _danger.withValues(alpha: 0.28)),
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
    builder: (_) => _QaSessionDetailSheet(hit: hit),
  );
}

class _QaSessionDetailSheet extends ConsumerStatefulWidget {
  const _QaSessionDetailSheet({required this.hit});

  final TiantianQaSearchHit hit;

  @override
  ConsumerState<_QaSessionDetailSheet> createState() =>
      _QaSessionDetailSheetState();
}

class _QaSessionDetailSheetState extends ConsumerState<_QaSessionDetailSheet> {
  final _followUpController = TextEditingController();

  @override
  void dispose() {
    _followUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(
      tiantianQaMessagesProvider(widget.hit.sessionId),
    );
    return _SheetScaffold(
      title: '问答记录',
      child: messages.when(
        data: (items) => Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = items[index];
                  final isUser = message.role == 'user';
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser ? _blue : const Color(0xFFF7F9FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isUser ? _blue : _paperBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.content,
                              style: TextStyle(
                                color: isUser ? Colors.white : _ink,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                            if (!isUser && message.savedAsCard) ...[
                              const SizedBox(height: 8),
                              _StatusPill(text: '已转成知识卡', color: _success),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _FollowUpBox(
              controller: _followUpController,
              hintText: '继续问这个话题...',
              onSend: () => _sendHistoryFollowUp(items),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorBlock(
          message: '问答记录加载失败',
          onRetry: () =>
              ref.invalidate(tiantianQaMessagesProvider(widget.hit.sessionId)),
        ),
      ),
    );
  }

  Future<void> _sendHistoryFollowUp(List<TiantianQaMessage> history) async {
    final question = _followUpController.text.trim();
    if (question.isEmpty) {
      _toast(context, '先输入要继续问的问题。');
      return;
    }
    final space = await ref.read(currentKnowledgeSpaceV3Provider.future);
    final materials = await _materialsFromHistory(history, space.id);
    if (!mounted) return;
    if (materials.isEmpty) {
      _toast(context, '这条记录缺少参考资料，请从空间主页重新选择资料提问。');
      return;
    }
    _followUpController.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowUpAnswerSheet(
        space: space,
        sessionId: widget.hit.sessionId,
        question: question,
        materials: materials,
        history: history,
      ),
    );
    if (mounted) {
      ref.invalidate(tiantianQaMessagesProvider(widget.hit.sessionId));
    }
  }

  Future<List<KnowledgeMaterial>> _materialsFromHistory(
    List<TiantianQaMessage> history,
    int fallbackSpaceId,
  ) async {
    final ids = <int>{};
    for (final message in history) {
      final raw = message.sourcesJson;
      if (raw == null || raw.trim().isEmpty) continue;
      final decoded = _safeJsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded.whereType<Map>()) {
          final id = item['id'];
          if (id is int) ids.add(id);
        }
      }
    }
    final repo = ref.read(knowledgeV3RepositoryProvider);
    final materials = <KnowledgeMaterial>[];
    for (final id in ids) {
      final material = await repo.getMaterial(id);
      if (material != null && !material.isArchived) materials.add(material);
    }
    if (materials.isNotEmpty) return materials;
    return repo.getMaterials(fallbackSpaceId);
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
  final controller = TextEditingController();
  final extra = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetScaffold(
      title: '续编资料',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(material.title, style: _T.cardTitle),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: controller,
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
                  onPressed: () => Navigator.of(context).pop(controller.text),
                  style: _primaryButtonStyle(),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  if (extra == null || extra.trim().isEmpty) return;
  await ref
      .read(knowledgeV3RepositoryProvider)
      .updateMaterial(
        id: material.id,
        title: material.title,
        content: '${material.content.trim()}\n\n${extra.trim()}',
      );
}

Future<void> _editMaterial(
  BuildContext context,
  WidgetRef ref,
  KnowledgeMaterial material,
) async {
  final titleController = TextEditingController(text: material.title);
  final contentController = TextEditingController(text: material.content);
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetScaffold(
      title: '编辑资料',
      child: Column(
        children: [
          TextField(
            controller: titleController,
            decoration: _inputDecoration(label: '标题'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: contentController,
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
                  onPressed: () => Navigator.of(context).pop(false),
                  style: _secondaryButtonStyle(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: _primaryButtonStyle(),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  if (saved == true) {
    await ref
        .read(knowledgeV3RepositoryProvider)
        .updateMaterial(
          id: material.id,
          title: titleController.text,
          content: contentController.text,
        );
  }
  titleController.dispose();
  contentController.dispose();
}

Future<void> _editCard(
  BuildContext context,
  WidgetRef ref,
  KnowledgeCardV3 card,
) async {
  final questionController = TextEditingController(text: card.question);
  final answerController = TextEditingController(text: card.answer);
  final explanationController = TextEditingController(text: card.explanation);
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetScaffold(
      title: '编辑知识卡',
      child: Column(
        children: [
          TextField(
            controller: questionController,
            decoration: _inputDecoration(label: '问题'),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 2,
            child: TextField(
              controller: answerController,
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
              controller: explanationController,
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
                  onPressed: () => Navigator.of(context).pop(false),
                  style: _secondaryButtonStyle(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: _primaryButtonStyle(),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  if (saved == true) {
    await ref
        .read(knowledgeV3RepositoryProvider)
        .updateCard(
          id: card.id,
          question: questionController.text,
          answer: answerController.text,
          explanation: explanationController.text,
        );
    invalidateKnowledgeV3(ref, spaceId: card.spaceId);
  }
  questionController.dispose();
  answerController.dispose();
  explanationController.dispose();
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
                        backgroundColor: _danger,
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
  if (card.dueAt <= now) return ('待复习', _danger);
  if (_isWeakCard(card)) return ('薄弱', _warning);
  if (card.masteryLevel >= 4 && card.correctStreak > 0) {
    return ('已掌握', _success);
  }
  return ('学习中', _blue);
}

bool _isWeakCard(KnowledgeCardV3 card) {
  return card.masteryLevel <= 2 ||
      (card.reviewCount > 0 && card.correctStreak == 0);
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
