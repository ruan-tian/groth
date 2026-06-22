part of '../journal_page.dart';

class _TiantianCompanionCard extends ConsumerStatefulWidget {
  const _TiantianCompanionCard();

  @override
  ConsumerState<_TiantianCompanionCard> createState() =>
      _TiantianCompanionCardState();
}

class _TiantianCompanionCardState extends ConsumerState<_TiantianCompanionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(petSceneProvider(PetModuleType.journal).notifier)
          .initScene(hasRecords: false);
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final sceneState = ref.watch(petSceneProvider(PetModuleType.journal));
    final bannerPath = sceneState.config.state.bannerPath;

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: Stack(
              key: ValueKey(bannerPath),
              fit: StackFit.expand,
              children: [
                // 第1层：底图（cover 填满容器）
                Image.asset(
                  bannerPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: JournalColors.pinkBg),
                ),
                // 第2层：渐变遮罩（左→右，左侧透明显示人物，右侧半透明白覆盖文字区）
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        colors.card.withValues(alpha: 0.86),
                      ],
                      stops: [0.3, 0.6],
                    ),
                  ),
                ),
                // 第3层：文字（右侧2/3区域）
                Positioned(
                  right: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '甜甜',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: JournalColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '记录一下今天的成长吧！',
                          style: TextStyle(
                            fontSize: 12,
                            color: JournalColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _YearSelector
// =============================================================================

class _YearSelector extends StatelessWidget {
  const _YearSelector({
    required this.year,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  final int year;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          enabled: canGoBack,
          onTap: onBack,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$year年',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: JournalColors.textDark,
            ),
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          enabled: canGoForward,
          onTap: onForward,
        ),
      ],
    );
  }
}

class _JournalHeatmapSection extends ConsumerStatefulWidget {
  const _JournalHeatmapSection();

  @override
  ConsumerState<_JournalHeatmapSection> createState() =>
      _JournalHeatmapSectionState();
}

class _JournalHeatmapSectionState
    extends ConsumerState<_JournalHeatmapSection> {
  Map<DateTime, int>? _lastData;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final selectedYear = ref.watch(selectedHeatmapYearProvider);
    final heatmap = ref.watch(journalHeatmapProvider(selectedYear));
    final currentYear = DateTime.now().year;
    final value = heatmap.valueOrNull;
    if (value != null) {
      _lastData = value;
    }
    final data = value ?? _lastData ?? const <DateTime, int>{};

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📅 写作热力图',
                style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
              ),
              const SizedBox(width: 8),
              if (heatmap.isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: JournalColors.pinkMain,
                  ),
                ),
              const Spacer(),
              _YearSelector(
                year: selectedYear,
                canGoBack: selectedYear > 2020,
                canGoForward: selectedYear < currentYear,
                onBack: () =>
                    ref.read(selectedHeatmapYearProvider.notifier).state--,
                onForward: () =>
                    ref.read(selectedHeatmapYearProvider.notifier).state++,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: data.isNotEmpty
                ? Column(
                    key: ValueKey('heatmap_${selectedYear}_${data.length}'),
                    children: [
                      HeatmapCalendar(
                        data: data,
                        monthsToShow: 12,
                        startDate: DateTime(selectedYear),
                        endDate: DateTime(selectedYear, 12, 31),
                        baseColor: JournalColors.heat0,
                        maxColor: JournalColors.heat4,
                        showLegend: false,
                      ),
                      const SizedBox(height: 12),
                      const _HeatmapLegend(),
                    ],
                  )
                : Padding(
                    key: ValueKey('empty_$selectedYear'),
                    padding: const EdgeInsets.symmetric(vertical: 34),
                    child: Center(
                      child: Text(
                        '$selectedYear 年暂无写作记录',
                        style: const TextStyle(
                          fontSize: 13,
                          color: JournalColors.textMuted,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          '少',
          style: TextStyle(fontSize: 10, color: JournalColors.textMuted),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '→',
            style: TextStyle(fontSize: 10, color: JournalColors.textMuted),
          ),
        ),
        ...JournalColors.heatColors.map(
          (c) => Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '→',
            style: TextStyle(fontSize: 10, color: JournalColors.textMuted),
          ),
        ),
        const Text(
          '多',
          style: TextStyle(fontSize: 10, color: JournalColors.textMuted),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: enabled,
      label: icon == Icons.chevron_left_rounded ? '上一年' : '下一年',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: enabled
                ? JournalColors.pinkBg
                : JournalColors.pinkBg.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? JournalColors.textDark : JournalColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _StatsRow
// =============================================================================

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.monthlyCount,
    required this.totalCount,
    required this.streak,
  });

  final AsyncValue<int> monthlyCount;
  final AsyncValue<int> totalCount;
  final AsyncValue<int> streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatsCard(
            icon: Icons.bar_chart_rounded,
            label: '本月',
            value: monthlyCount.whenOrNull(data: (c) => c) ?? 0,
            unit: '篇',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatsCard(
            icon: Icons.calendar_month_rounded,
            label: '总计',
            value: totalCount.whenOrNull(data: (c) => c) ?? 0,
            unit: '篇',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatsCard(
            icon: Icons.local_fire_department_rounded,
            label: '连续',
            value: streak.whenOrNull(data: (s) => s) ?? 0,
            unit: '天',
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.icon,
    required this.label,
    required this.value,
    this.unit = '',
  });

  final IconData icon;
  final String label;
  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: JournalColors.pinkBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: JournalColors.pinkMain),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$value',
                style: AppTextStyles.numberMedium.copyWith(
                  color: colors.textPrimary,
                  height: 1.1,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// =============================================================================
// _TagChip
// =============================================================================

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Semantics(
      button: true,
      label: selected ? '取消筛选：$label' : '筛选：$label',
      selected: selected,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.journal : colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.journal : colors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? colors.textOnAccent : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderEditSheet extends StatelessWidget {
  const _FolderEditSheet({required this.controller, required this.title});

  final TextEditingController controller;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return _JournalSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: '例如：灵感、复盘、旅行',
              filled: true,
              fillColor: colors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: JournalColors.pinkMain,
              shape: const StadiumBorder(),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _FolderActionSheet extends StatelessWidget {
  const _FolderActionSheet({
    required this.folderName,
    required this.onRename,
    required this.onDelete,
  });

  final String folderName;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _JournalSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            folderName,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.edit_rounded,
              color: JournalColors.pinkMain,
            ),
            title: const Text('重命名'),
            onTap: onRename,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline_rounded,
              color: context.growthColors.danger,
            ),
            title: const Text('删除文件夹'),
            subtitle: const Text('日记会回到未分类'),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _MoveJournalSheet extends StatefulWidget {
  const _MoveJournalSheet({
    required this.journal,
    required this.folders,
    required this.onMove,
  });

  final DailyJournal journal;
  final List<JournalFolder> folders;
  final Future<void> Function(int? folderId) onMove;

  @override
  State<_MoveJournalSheet> createState() => _MoveJournalSheetState();
}

class _MoveJournalSheetState extends State<_MoveJournalSheet> {
  bool _moving = false;

  @override
  Widget build(BuildContext context) {
    return _JournalSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('移动日记', style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            widget.journal.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: JournalColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _MoveTargetTile(
            title: '未分类',
            selected: widget.journal.folderId == null,
            enabled: !_moving,
            onTap: () => _move(context, null),
          ),
          ...widget.folders.map(
            (folder) => _MoveTargetTile(
              title: folder.name,
              selected: widget.journal.folderId == folder.id,
              enabled: !_moving,
              onTap: () => _move(context, folder.id),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _move(BuildContext context, int? folderId) async {
    if (_moving) return;
    setState(() => _moving = true);
    try {
      await widget.onMove(folderId);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context);
      messenger?.showSnackBar(const SnackBar(content: Text('已移动日记')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('移动失败，请重试')));
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }
}

class _MoveTargetTile extends StatelessWidget {
  const _MoveTargetTile({
    required this.title,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      leading: Icon(
        selected ? Icons.folder_rounded : Icons.folder_outlined,
        color: selected ? JournalColors.pinkMain : JournalColors.textMuted,
      ),
      title: Text(title),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: JournalColors.pinkMain,
            )
          : null,
      onTap: enabled ? onTap : null,
    );
  }
}

class _JournalSheetShell extends StatelessWidget {
  const _JournalSheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// =============================================================================
// _JournalListItem
// =============================================================================

class _JournalListItem extends StatelessWidget {
  const _JournalListItem({
    required this.journal,
    required this.onTap,
    required this.onMove,
  });

  final DailyJournal journal;
  final VoidCallback onTap;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final moodEmoji = getMoodEmoji(journal.mood);

    return Semantics(
      button: true,
      label: '查看日记：${journal.title}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: JournalColors.pinkBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    PetAssets.journalBook,
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.pets_rounded,
                      size: 20,
                      color: JournalColors.pinkMain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journal.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: JournalColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      journal.content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: JournalColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(moodEmoji, style: const TextStyle(fontSize: 14)),
                        if (journal.tags != null)
                          _buildTagsPreview(journal.tags!),
                        Text(
                          '${journal.wordCount}字',
                          style: const TextStyle(
                            fontSize: 11,
                            color: JournalColors.textMuted,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: JournalColors.pinkBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${journal.expGained} EXP',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: JournalColors.pinkMain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                children: [
                  IconButton(
                    tooltip: '移动到文件夹',
                    onPressed: onMove,
                    icon: const Icon(Icons.folder_copy_outlined, size: 19),
                    color: JournalColors.textMuted,
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: JournalColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _parseTagsSafe(String? tagsString) {
    if (tagsString == null || tagsString.isEmpty) return const [];
    try {
      final decoded = jsonDecode(tagsString);
      if (decoded is List) return decoded.cast<String>();
    } catch (e) {
      debugPrint('parseTags failed: $e');
    }
    return tagsString.split(',').where((t) => t.trim().isNotEmpty).toList();
  }

  Widget _buildTagsPreview(String tagsJson) {
    final tags = _parseTagsSafe(tagsJson);
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.take(2).map((tag) {
        final label = tag.length > 10 ? '${tag.substring(0, 10)}…' : tag;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: JournalColors.pinkBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '#$label',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: JournalColors.pinkMain,
            ),
          ),
        );
      }).toList(),
    );
  }
}
