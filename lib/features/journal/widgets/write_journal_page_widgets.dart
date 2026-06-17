part of '../pages/write_journal_page.dart';

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onSave});

  final VoidCallback onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return SizedBox(
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _SquareIconButton(
              icon: Icons.chevron_left_rounded,
              onTap: onBack,
              color: colors.textPrimary,
            ),
          ),
          const Text(
            '写日记',
            style: TextStyle(
              color: JournalColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _SquareIconButton(
              icon: Icons.save_rounded,
              onTap: onSave,
              color: colors.journal,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.selectedMood,
    required this.onSelected,
    this.compact = false,
  });

  final String? selectedMood;
  final ValueChanged<String> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return _SoftCard(
      padding: EdgeInsets.fromLTRB(20, compact ? 18 : 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今天的心情是？',
            style: TextStyle(color: JournalColors.textDark, fontSize: 15),
          ),
          const SizedBox(height: 18),
          Row(
            children: moodOptions.map((mood) {
              final selected = selectedMood == mood.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onSelected(mood.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: compact ? 82 : 92,
                      decoration: BoxDecoration(
                        color: selected ? colors.softPink : colors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? JournalColors.pinkSoft
                              : JournalColors.pinkBorder,
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mood.emoji,
                            style: const TextStyle(fontSize: 30),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mood.label,
                            style: TextStyle(
                              color: selected
                                  ? colors.journal
                                  : colors.textSecondary,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _JournalPaperCard extends StatelessWidget {
  const _JournalPaperCard({
    required this.titleController,
    required this.contentController,
    required this.wordCount,
    required this.onOpenEditor,
  });

  final TextEditingController titleController;
  final TextEditingController contentController;
  final int wordCount;
  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                journal_images.JournalAssets.pencil,
                width: 28,
                height: 28,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.edit_rounded,
                  color: JournalColors.pinkMain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  maxLength: 100,
                  style: const TextStyle(
                    color: JournalColors.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    hintText: '今天的小确幸',
                    hintStyle: TextStyle(color: JournalColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _DateChip(date: DateTime.now()),
            ],
          ),
          const Divider(color: JournalColors.pinkBorder, height: 28),
          Stack(
            children: [
              CustomPaint(
                painter: _PaperLinesPainter(),
                child: TextField(
                  controller: contentController,
                  textInputAction: TextInputAction.newline,
                  maxLength: 10000,
                  minLines: 12,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    color: JournalColors.textDark,
                    fontSize: 18,
                    height: 2.05,
                  ),
                  decoration: const InputDecoration(
                    hintText: '今天阳光特别好，记录一点平凡的小美好吧...',
                    hintStyle: TextStyle(
                      color: JournalColors.textMuted,
                      fontSize: 17,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(2, 4, 2, 112),
                  ),
                ),
              ),
              Positioned(
                right: -8,
                bottom: -4,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.9,
                    child: Image.asset(
                      journal_images.JournalAssets.catWriting,
                      width: 148,
                      height: 148,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: _TinyActionButton(
                  icon: Icons.open_in_full_rounded,
                  onTap: onOpenEditor,
                  tooltip: '全屏书写',
                ),
              ),
              Positioned(
                left: 0,
                bottom: 8,
                child: Text(
                  '$wordCount 字',
                  style: const TextStyle(
                    color: JournalColors.pinkMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid({
    required this.pickingImage,
    required this.onPrompt,
    required this.onStats,
    required this.onImage,
    required this.onMood,
  });

  final bool pickingImage;
  final VoidCallback onPrompt;
  final VoidCallback onStats;
  final VoidCallback onImage;
  final VoidCallback onMood;

  @override
  Widget build(BuildContext context) {
    final tools = [
      _ToolAction(Icons.lightbulb_rounded, '灵感提示', onPrompt),
      _ToolAction(Icons.pin_rounded, '字数统计', onStats),
      _ToolAction(
        Icons.image_rounded,
        pickingImage ? '选择中...' : '插入图片',
        onImage,
      ),
      _ToolAction(Icons.favorite_rounded, '记录心情', onMood),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 30) / 4;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tools.map((tool) {
            return SizedBox(
              width: itemWidth < 118
                  ? (constraints.maxWidth - 10) / 2
                  : itemWidth,
              child: _ToolButton(action: tool),
            );
          }).toList(),
        );
      },
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({
    required this.selectedTags,
    required this.onToggle,
    required this.onCustom,
  });

  final Set<String> selectedTags;
  final ValueChanged<String> onToggle;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final commonTags = presetTags.take(6).toList();
    final extraTags = selectedTags.where((tag) => !commonTags.contains(tag));
    final chips = [...commonTags, ...extraTags];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == chips.length) {
            return ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 18),
              label: const Text('自定义'),
              onPressed: onCustom,
              backgroundColor: colors.card,
              side: BorderSide(color: colors.border),
              labelStyle: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            );
          }
          final tag = chips[index];
          final selected = selectedTags.contains(tag);
          return FilterChip(
            label: Text(tag),
            selected: selected,
            onSelected: (_) => onToggle(tag),
            backgroundColor: colors.card,
            selectedColor: colors.softPink,
            checkmarkColor: colors.journal,
            side: BorderSide(color: selected ? colors.journal : colors.border),
            labelStyle: TextStyle(
              color: selected ? colors.journal : colors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          );
        },
      ),
    );
  }
}

class _FolderSaveSection extends StatelessWidget {
  const _FolderSaveSection({
    required this.folderName,
    required this.selectedFolderId,
    required this.onTap,
  });

  final String? folderName;
  final int? selectedFolderId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: JournalColors.pinkBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: JournalColors.pinkMain,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '保存到',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      folderName ?? '未分类',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderPickerSheet extends StatelessWidget {
  const _FolderPickerSheet({
    required this.folders,
    required this.selectedFolderId,
    required this.onCreate,
  });

  final List<JournalFolder> folders;
  final int? selectedFolderId;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _SoftSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择保存文件夹',
            style: TextStyle(
              color: JournalColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _FolderOptionTile(
            icon: Icons.inbox_rounded,
            title: '未分类',
            selected: selectedFolderId == null,
            onTap: () => Navigator.pop(context, 0),
          ),
          ...folders.map(
            (folder) => _FolderOptionTile(
              icon: Icons.folder_rounded,
              title: folder.name,
              selected: selectedFolderId == folder.id,
              onTap: () => Navigator.pop(context, folder.id),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.create_new_folder_rounded),
              label: const Text('新建文件夹'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderOptionTile extends StatelessWidget {
  const _FolderOptionTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: JournalColors.pinkMain),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: JournalColors.pinkMain,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _WritingSummary extends StatelessWidget {
  const _WritingSummary({
    required this.wordCount,
    required this.exp,
    required this.streak,
  });

  final int wordCount;
  final int exp;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日写作小结',
            style: TextStyle(
              color: JournalColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final tiles = [
                _SummaryTile(
                  icon: Icons.text_fields_rounded,
                  value: '$wordCount 字',
                  label: '本次字数',
                ),
                _SummaryTile(
                  icon: Icons.star_rounded,
                  value: '+$exp EXP',
                  label: '获得经验',
                ),
                _SummaryTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '连续 $streak 天',
                  label: '写作打卡',
                ),
              ];
              if (constraints.maxWidth < 420) {
                return Column(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      tiles[i],
                      if (i != tiles.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    Expanded(child: tiles[i]),
                    if (i != tiles.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.saving,
    required this.onSave,
    required this.onDone,
  });

  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: saving ? null : onSave,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                gradient: saving ? null : JournalColors.heroGradient,
                color: saving ? JournalColors.pinkSoft : null,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: JournalColors.pinkMain.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: saving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textOnAccent,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: colors.textOnAccent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '保存日记',
                            style: TextStyle(
                              color: colors.textOnAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: saving ? null : onDone,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              foregroundColor: JournalColors.pinkMain,
              side: const BorderSide(color: JournalColors.pinkBorder),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('完成'),
          ),
        ),
      ],
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SoftSheet extends StatelessWidget {
  const _SoftSheet({required this.child});

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
        ),
        child: child,
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: JournalColors.pinkBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: JournalColors.pinkMain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: JournalColors.pinkMain,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final text = '${date.month}月${date.day}日 ${weekdays[date.weekday - 1]}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 16,
            color: JournalColors.pinkMain,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Material(
      color: colors.surfaceVariant,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: onTap == null ? colors.textHint : color),
        ),
      ),
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  const _TinyActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: JournalColors.pinkMain),
          ),
        ),
      ),
    );
  }
}

class _ToolAction {
  const _ToolAction(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.action});

  final _ToolAction action;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Material(
      color: colors.surfaceVariant,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 20, color: JournalColors.pinkMain),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = JournalColors.pinkBorder.withValues(alpha: 0.64)
      ..strokeWidth = 1;
    for (var y = 42.0; y < size.height - 34; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
