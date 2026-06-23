part of 'knowledge_workspace_page.dart';

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
                  space:
                      space ??
                      KnowledgeSpaceV3(
                        id: widget.spaceId,
                        name: '知识空间',
                        type: 'custom',
                        sortOrder: 0,
                        isArchived: false,
                        createdAt: DateTime.now().millisecondsSinceEpoch,
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                      ),
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
            backgroundColor: AppColors.softBlue,
            color: AppColors.study,
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
    required this.space,
  });

  final KnowledgeCardV3 card;
  final int index;
  final int total;
  final bool answerVisible;
  final VoidCallback onFlip;
  final ValueChanged<int> onRate;
  final KnowledgeSpaceV3 space;

  @override
  Widget build(BuildContext context) {
    final progress = (index + 1) / total;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.study.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.style_rounded,
                    color: AppColors.study,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('今日复习', style: _T.cardTitleSmall),
                          const Spacer(),
                          Text('${index + 1}/$total', style: _T.metaStrong),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: AppColors.softBlue,
                        color: AppColors.study,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: _PaperCard(
              padding: const EdgeInsets.all(20),
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
                                  color: AppColors.study,
                                ),
                              _StatusPill(
                                text: _cardStatus(card).$1,
                                color: _cardStatus(card).$2,
                              ),
                              _StatusPill(
                                text: _difficultyLabel(card.difficulty),
                                color: _difficultyColor(card.difficulty),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Text(
                                card.question,
                                style: _T.question,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!answerVisible)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.softBlue,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  '先回忆 5 秒，再查看答案与解析',
                                  style: _T.body,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else ...[
                            _ReviewAnswerSection(
                              icon: Icons.check_circle_outline_rounded,
                              title: '\u7b54\u6848',
                              child: Text(card.answer, style: _T.answer),
                            ),
                            if (card.explanation?.trim().isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 12),
                              _ReviewAnswerSection(
                                icon: Icons.psychology_alt_outlined,
                                title: '\u89e3\u6790',
                                child: Text(
                                  card.explanation!,
                                  style: _T.bodyLarge,
                                ),
                              ),
                            ],
                            if (card.memoryHint?.trim().isNotEmpty == true) ...[
                              const SizedBox(height: 12),
                              _ReviewAnswerSection(
                                icon: Icons.lightbulb_outline_rounded,
                                title: '记忆口诀',
                                accent: AppColors.warning,
                                child: Text(
                                  card.memoryHint!,
                                  style: _T.bodyLarge,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _openTiantianChat(context),
                                icon: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.study,
                                  size: 18,
                                ),
                                label: Text(
                                  '问甜甜关于这个知识点',
                                  style: TextStyle(color: AppColors.study),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: AppColors.study.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
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
                            color: AppColors.danger,
                            onTap: () => onRate(0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RateButton(
                            label: '有点印象',
                            color: AppColors.warning,
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
                            color: AppColors.study,
                            onTap: () => onRate(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RateButton(
                            label: '很熟练',
                            color: AppColors.success,
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
                    style: _primaryButtonStyle(height: 52),
                    child: const Text('翻开答案'),
                  ),
                ),
        ),
      ],
    );
  }

  void _openTiantianChat(BuildContext context) {
    final question = '请详细解释：${card.question}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TiantianChatSheet(
        space: space,
        initialQuestion: question,
        materials: const [],
      ),
    );
  }
}

class _ReviewAnswerSection extends StatelessWidget {
  const _ReviewAnswerSection({
    required this.icon,
    required this.title,
    required this.child,
    this.accent = AppColors.study,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(title, style: _T.sectionTitle),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
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
