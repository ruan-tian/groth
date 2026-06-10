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
          border: Border.all(color: JournalColors.pinkBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: JournalColors.shadow,
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
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0x00FFFFFF), // 左侧透明
                        Color(0xD9FFFFFF), // 右侧半透明白 (85%)
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: JournalColors.shadow,
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
                  color: JournalColors.textDark,
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: selected ? '取消筛选：$label' : '筛选：$label',
      selected: selected,
      child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? JournalColors.pinkMain : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? JournalColors.pinkMain : JournalColors.pinkBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : JournalColors.textSecondary,
          ),
        ),
      ),
    ),
    );
  }
}

// =============================================================================
// _JournalListItem
// =============================================================================

class _JournalListItem extends StatelessWidget {
  const _JournalListItem({required this.journal, required this.onTap});

  final DailyJournal journal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: JournalColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left icon ──
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

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
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

                  // Preview
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

                  // Bottom row: mood + tags + word count + EXP
                  Row(
                    children: [
                      // Mood emoji
                      Text(moodEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),

                      // Tags
                      if (journal.tags != null) ...[
                        _buildTagsPreview(journal.tags!),
                      ],

                      const Spacer(),

                      // Word count
                      Text(
                        '${journal.wordCount}字',
                        style: const TextStyle(
                          fontSize: 11,
                          color: JournalColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // EXP badge
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

            // ── Chevron ──
            const Padding(
              padding: EdgeInsets.only(left: 8, top: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: JournalColors.textMuted,
              ),
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
    } catch (_) {}
    return tagsString.split(',').where((t) => t.trim().isNotEmpty).toList();
  }

  Widget _buildTagsPreview(String tagsJson) {
    final tags = _parseTagsSafe(tagsJson);
    if (tags.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: tags.take(2).map((tag) {
        return Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: JournalColors.pinkBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '#$tag',
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
