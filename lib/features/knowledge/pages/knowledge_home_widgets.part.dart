part of 'knowledge_workspace_page.dart';

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
    final colors = Theme.of(context).extension<AppThemeColors>()!;
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
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: colors.textPrimary,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showSpaceSelector(
                    context,
                    space,
                    spaces,
                    onSelectSpace,
                    onManageSpaces,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                icon: Icon(
                  Icons.menu_rounded,
                  color: colors.textPrimary,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '管理空间',
                onPressed: onManageSpaces,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: colors.textPrimary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSpaceSelector(
    BuildContext context,
    KnowledgeSpaceV3 current,
    List<KnowledgeSpaceV3> spaces,
    ValueChanged<KnowledgeSpaceV3> onSelect,
    VoidCallback onManage,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SpaceSelectorSheet(
        current: current,
        spaces: spaces,
        onSelect: onSelect,
        onManage: onManage,
      ),
    );
  }
}

class _SpaceSelectorSheet extends StatelessWidget {
  const _SpaceSelectorSheet({
    required this.current,
    required this.spaces,
    required this.onSelect,
    required this.onManage,
  });
  final KnowledgeSpaceV3 current;
  final List<KnowledgeSpaceV3> spaces;
  final ValueChanged<KnowledgeSpaceV3> onSelect;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Text('选择知识空间', style: _T.sectionTitle),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onManage();
                  },
                  child: Text('管理', style: TextStyle(color: colors.study)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: spaces.length,
              itemBuilder: (context, index) {
                final item = spaces[index];
                return _SpaceOptionTile(
                  space: item,
                  isCurrent: item.id == current.id,
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelect(item);
                  },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
        ],
      ),
    );
  }
}

class _SpaceOptionTile extends StatelessWidget {
  const _SpaceOptionTile({
    required this.space,
    required this.isCurrent,
    required this.onTap,
  });
  final KnowledgeSpaceV3 space;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final icon = switch (space.type) {
      'study' => Icons.menu_book_rounded,
      'exam' => Icons.quiz_rounded,
      'work' => Icons.work_rounded,
      'hobby' => Icons.palette_rounded,
      _ => Icons.folder_rounded,
    };
    final color = switch (space.type) {
      'study' => colors.study,
      'exam' => colors.warning,
      'work' => colors.fitness,
      'hobby' => colors.journal,
      _ => colors.textSecondary,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isCurrent
            ? colors.study.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        space.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (space.note?.trim().isNotEmpty == true)
                        Text(
                          space.note!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.study,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
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
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final task = _task;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.study,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.colored(colors.study),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: _T.cardTitle.copyWith(color: colors.card),
              ),
              const SizedBox(height: 4),
              Text(
                task.subtitle,
                style: _T.body.copyWith(
                  color: colors.card.withValues(alpha: 0.86),
                ),
              ),
            ],
          );
          final button = FilledButton(
            onPressed: task.onTap,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: colors.card,
              foregroundColor: colors.study,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(task.label),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TaskIconBubble(icon: task.icon),
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
              _TaskIconBubble(icon: task.icon),
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
        subtitle: '${stats.materialCount} 份资料等待整理成抽卡内容。',
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
            : '完成今日到期卡，保持记忆节奏。',
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

class _TaskIconBubble extends StatelessWidget {
  const _TaskIconBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.mlg),
      ),
      child: Icon(icon, color: colors.card, size: 24),
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
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          _TiantianImage(asset: 'tiantian_thinking.webp', size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('你好，我是甜甜', style: _T.cardTitle),
                const SizedBox(height: 5),
                Text('有资料想问我，或让我帮你生成知识卡吧。', style: _T.body),
              ],
            ),
          ),
          IconButton(
            tooltip: '问甜甜',
            onPressed: onAsk,
            style: IconButton.styleFrom(
              backgroundColor: colors.study.withValues(alpha: 0.1),
              foregroundColor: colors.study,
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
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
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.sm,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        minLines: 1,
        maxLines: 3,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: colors.study),
          hintText: '搜索资料、知识卡，或直接问甜甜...',
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
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colors.textPrimary,
          ),
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
        _QuickAction(Icons.add_box_outlined, '生成卡片', onGenerate),
      if (showWeak) _QuickAction(Icons.track_changes_rounded, '薄弱卡', onWeak),
    ];
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: _QuickActionTile(action: actions[i])),
          if (i != actions.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return _PaperCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.study.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.smd),
            ),
            child: Icon(action.icon, color: colors.study, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _T.actionLabel,
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        children: [
          _StatItem(
            value: '${stats.cardCount}',
            label: '\u77e5\u8bc6\u5361\u7247',
          ),
          const _VLine(),
          _StatItem(value: '${stats.dueCount}', label: '\u5f85\u590d\u4e60'),
          const _VLine(),
          _StatItem(
            value: '${stats.masteryPercent}%',
            label: '\u638c\u63e1\u5ea6',
          ),
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
          Text(
            label,
            style: _T.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VLine extends StatelessWidget {
  const _VLine();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(width: 1, height: 42, color: colors.border);
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
          _SectionTitle(
            title: '\u6700\u8fd1\u8d44\u6599',
            action: '\u67e5\u770b\u5168\u90e8',
            onAction: onViewAll,
          ),
          const SizedBox(height: 8),
          if (materials.isEmpty)
            _InlineEmpty(
              icon: Icons.note_add_outlined,
              title: '\u8fd8\u6ca1\u6709\u8d44\u6599',
              subtitle:
                  '\u5bfc\u5165\u8d44\u6599\u540e\uff0c\u751c\u751c\u624d\u80fd\u57fa\u4e8e\u5185\u5bb9\u95ee\u7b54\u548c\u751f\u6210\u77e5\u8bc6\u5361\u3002',
              action: '\u5bfc\u5165\u8d44\u6599',
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
          _SectionTitle(
            title: '\u6700\u8fd1\u77e5\u8bc6\u5361',
            action: '\u67e5\u770b\u5168\u90e8',
            onAction: onViewAll,
          ),
          const SizedBox(height: 8),
          if (cards.isEmpty)
            const _InlineEmpty(
              icon: Icons.style_outlined,
              title: '\u8fd8\u6ca1\u6709\u77e5\u8bc6\u5361',
              subtitle:
                  '\u5bfc\u5165\u8d44\u6599\u540e\uff0c\u8ba9\u751c\u751c\u5e2e\u4f60\u751f\u6210\u7b2c\u4e00\u7ec4\u77e5\u8bc6\u5361\u3002',
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
        '${date.year}/${date.month}/${date.day} ? ${_sizeLabel(material.content.length)}',
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
      leading: _IconBubble(icon: _cardTypeIcon(card.cardType)),
      title: Text(card.question, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              card.answer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (card.difficulty >= 3)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _difficultyColor(card.difficulty).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _difficultyLabel(card.difficulty),
                style: TextStyle(
                  fontSize: 10,
                  color: _difficultyColor(card.difficulty),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      trailing: _StatusPill(text: status.$1, color: status.$2),
      onTap: onTap,
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
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.softBlue,
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.study),
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
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final cardCount = stats.valueOrNull?.cardCount ?? 0;
    final dueCount = stats.valueOrNull?.dueCount ?? 0;
    final masteryPercent = stats.valueOrNull?.masteryPercent ?? 0;

    return _PaperCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        ref.read(selectedKnowledgeSpaceIdProvider.notifier).state = space.id;
        ref.read(knowledgeV3RepositoryProvider).rememberSpace(space.id);
        context.go('/plan/study/knowledge/space');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部行：图标 + 名称 + 类型 + 菜单
          Row(
            children: [
              _SpaceIcon(type: space.type),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _T.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _spaceTypeLabel(space.type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _T.meta,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: '空间操作',
                icon: Icon(Icons.more_horiz_rounded, color: colors.textTertiary),
                onSelected: (action) async {
                  if (!context.mounted) return;
                  if (action == 'rename') {
                    await _showSpaceEditor(context, ref, space: space);
                  } else if (action == 'archive') {
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

          const SizedBox(height: 14),

          // 三列统计
          Row(
            children: [
              _MiniStat(label: '卡片', value: '$cardCount', color: colors.study),
              const SizedBox(width: 12),
              _MiniStat(label: '待复习', value: '$dueCount', color: colors.warning),
              const SizedBox(width: 12),
              _MiniStat(label: '掌握度', value: '$masteryPercent%', color: colors.success),
            ],
          ),

          const SizedBox(height: 12),

          // 功能标签
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _FeaturePill(label: '资料库', icon: Icons.description_outlined, color: colors.study),
              _FeaturePill(label: 'AI问答', icon: Icons.auto_awesome_rounded, color: colors.primary),
              _FeaturePill(label: '抽卡复习', icon: Icons.style_rounded, color: colors.accent),
            ],
          ),

          // 掌握进度条
          if (cardCount > 0) ...[
            const SizedBox(height: 12),
            _MasteryProgressBar(percent: masteryPercent),
          ],
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
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final icon = switch (type) {
      'exam' => Icons.assignment_turned_in_rounded,
      'language' => Icons.translate_rounded,
      'skill' => Icons.psychology_alt_rounded,
      'interest' => Icons.lightbulb_outline_rounded,
      _ => Icons.auto_stories_rounded,
    };
    final color = switch (type) {
      'exam' => colors.study,
      'language' => const Color(0xFF7C3AED),
      'skill' => const Color(0xFF168458),
      'interest' => const Color(0xFFF59E0B),
      _ => colors.study,
    };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _DashedCreateCard extends StatelessWidget {
  const _DashedCreateCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: colors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: colors.study, size: 20),
              const SizedBox(width: 8),
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

// =============================================================================
// 新增组件：今日概览卡、迷你统计、功能标签、进度条、空状态、胶囊提示
// =============================================================================

/// 今日概览卡 — 显示全局聚合数据
class _TodayOverviewCard extends StatelessWidget {
  const _TodayOverviewCard({required this.overview});

  final AsyncValue<KnowledgeWorkspaceOverviewV3> overview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return overview.when(
      data: (item) => _PaperCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: _OverviewChip(
                icon: Icons.schedule_rounded,
                label: '今日待复习',
                value: '${item.dueCount}张',
                color: colors.warning,
              ),
            ),
            Container(width: 1, height: 32, color: colors.border),
            Expanded(
              child: _OverviewChip(
                icon: Icons.folder_rounded,
                label: '空间',
                value: '${item.spaceCount}个',
                color: colors.study,
              ),
            ),
            Container(width: 1, height: 32, color: colors.border),
            Expanded(
              child: _OverviewChip(
                icon: Icons.style_rounded,
                label: '知识卡',
                value: '${item.cardCount}张',
                color: colors.accent,
              ),
            ),
          ],
        ),
      ),
      loading: () => const _PaperCard(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: _OverviewChip(icon: Icons.schedule, label: '今日待复习', value: '--', color: AppColors.warning)),
            Expanded(child: _OverviewChip(icon: Icons.folder, label: '空间', value: '--', color: AppColors.study)),
            Expanded(child: _OverviewChip(icon: Icons.style, label: '知识卡', value: '--', color: AppColors.accent)),
          ],
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  const _OverviewChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).extension<AppThemeColors>()!.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: _T.meta),
      ],
    );
  }
}

/// 区域标题
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(title, style: _T.sectionTitle),
    );
  }
}

/// 迷你统计标签（用于空间卡片内）
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.10)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: _T.meta),
          ],
        ),
      ),
    );
  }
}

/// 功能标签胶囊（用于空间卡片内）
class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 掌握进度条（用于空间卡片内）
class _MasteryProgressBar extends StatelessWidget {
  const _MasteryProgressBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            minHeight: 6,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(colors.success),
          ),
        ),
      ],
    );
  }
}

/// 空状态卡片（0 个空间时显示）
class _EmptySpaceCard extends StatelessWidget {
  const _EmptySpaceCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return _PaperCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/knowledge_cards/v3/tiantian_reading.webp',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.auto_stories_rounded,
              size: 48,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有知识空间',
            style: _T.cardTitle,
          ),
          const SizedBox(height: 8),
          Text(
            '创建一个空间，甜甜帮你整理资料和复习卡片',
            style: _T.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            style: _primaryButtonStyle(height: 46),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('创建第一个空间'),
          ),
        ],
      ),
    );
  }
}

/// 胶囊提示（有空间时显示，替代大面积 _TipCard）
class _TipPill extends StatelessWidget {
  const _TipPill();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.softBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_rounded, size: 16, color: colors.study),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '一个主题建一个空间，复习会更清晰。',
              style: _T.body.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
