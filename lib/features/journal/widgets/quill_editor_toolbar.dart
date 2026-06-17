part of '../pages/quill_editor_page.dart';

enum _ToolbarPanel { none, font, list, paragraph, insert, more }

class _KeyboardToolbar extends StatelessWidget {
  const _KeyboardToolbar({
    required this.pickingImage,
    required this.toolsActive,
    required this.onPickImage,
    required this.onTask,
    required this.onQuote,
    required this.onTools,
  });

  final bool pickingImage;
  final bool toolsActive;
  final VoidCallback onPickImage;
  final VoidCallback onTask;
  final VoidCallback onQuote;
  final VoidCallback onTools;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: context.growthColors.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: JournalColors.pinkBorder),
        boxShadow: [
          BoxShadow(
            color: JournalColors.pinkMain.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          _BottomToolButton(
            icon: pickingImage
                ? Icons.hourglass_top_rounded
                : Icons.image_outlined,
            label: pickingImage ? '选择中' : '图片',
            onTap: pickingImage ? null : onPickImage,
          ),
          _BottomToolButton(
            icon: Icons.check_box_outlined,
            label: '待办',
            onTap: onTask,
          ),
          _BottomToolButton(
            icon: Icons.format_quote_rounded,
            label: '引用',
            onTap: onQuote,
          ),
          _BottomToolButton(
            icon: Icons.auto_fix_high_rounded,
            label: '工具',
            active: toolsActive,
            onTap: onTools,
          ),
        ],
      ),
    );
  }
}

class _BottomToolButton extends StatelessWidget {
  const _BottomToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.46,
        child: GrowthPressable(
          onTap: onTap,
          semanticLabel: label,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: active ? JournalColors.pinkBg : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: active
                      ? JournalColors.pinkMain
                      : JournalColors.textSecondary,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? JournalColors.pinkMain
                        : JournalColors.textSecondary,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w600,
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

class _ToolRail extends StatelessWidget {
  const _ToolRail({
    required this.activePanel,
    required this.bottomOffset,
    required this.onFont,
    required this.onList,
    required this.onParagraph,
    required this.onInsert,
    required this.onMore,
  });

  final _ToolbarPanel activePanel;
  final double bottomOffset;
  final VoidCallback onFont;
  final VoidCallback onList;
  final VoidCallback onParagraph;
  final VoidCallback onInsert;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final visible = activePanel != _ToolbarPanel.none;
    return AnimatedPositioned(
      duration: AppMotion.duration(context, AppMotion.normal),
      curve: AppMotion.standard,
      left: visible ? 14 : -76,
      bottom: bottomOffset,
      child: AnimatedOpacity(
        duration: AppMotion.duration(context, AppMotion.fast),
        opacity: visible ? 1 : 0,
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: context.growthColors.card.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: JournalColors.pinkBorder),
            boxShadow: [
              BoxShadow(
                color: JournalColors.pinkMain.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RailButton(
                icon: Icons.text_fields_rounded,
                label: '字体',
                active: activePanel == _ToolbarPanel.font,
                onTap: onFont,
              ),
              _RailButton(
                icon: Icons.format_list_bulleted_rounded,
                label: '列表',
                active: activePanel == _ToolbarPanel.list,
                onTap: onList,
              ),
              _RailButton(
                icon: Icons.notes_rounded,
                label: '段落',
                active: activePanel == _ToolbarPanel.paragraph,
                onTap: onParagraph,
              ),
              _RailButton(
                icon: Icons.add_photo_alternate_outlined,
                label: '插入',
                active: activePanel == _ToolbarPanel.insert,
                onTap: onInsert,
              ),
              _RailButton(
                icon: Icons.more_horiz_rounded,
                label: '更多',
                active: activePanel == _ToolbarPanel.more,
                onTap: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GrowthPressable(
        onTap: onTap,
        semanticLabel: label,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: active ? JournalColors.pinkMain : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            color: active
                ? context.growthColors.textOnAccent
                : JournalColors.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ToolPopover extends StatelessWidget {
  const _ToolPopover({
    required this.activePanel,
    required this.bottomOffset,
    required this.child,
  });

  final _ToolbarPanel activePanel;
  final double bottomOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visible = activePanel != _ToolbarPanel.none;
    return AnimatedPositioned(
      duration: AppMotion.duration(context, AppMotion.normal),
      curve: AppMotion.standard,
      left: visible ? 88 : 64,
      right: 18,
      bottom: bottomOffset,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          duration: AppMotion.duration(context, AppMotion.fast),
          opacity: visible ? 1 : 0,
          child: AnimatedScale(
            duration: AppMotion.duration(context, AppMotion.normal),
            curve: AppMotion.standard,
            alignment: Alignment.bottomLeft,
            scale: visible ? 1 : 0.96,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _FontPanel extends StatelessWidget {
  const _FontPanel({required this.controller, required this.onClear});

  final QuillController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final style = controller.getSelectionStyle();
    return _PanelShell(
      title: '字体',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [14, 16, 18, 20, 24].map((size) {
                final current = style.attributes[Attribute.size.key];
                final selected = current?.value == size.toString();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ChipButton(
                    label: '$size',
                    active: selected,
                    onTap: () => controller.formatSelection(
                      SizeAttribute(size.toString()),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipButton(
                label: 'B',
                active: style.containsKey(Attribute.bold.key),
                onTap: () => _toggle(controller, Attribute.bold),
              ),
              _ChipButton(
                label: 'I',
                active: style.containsKey(Attribute.italic.key),
                onTap: () => _toggle(controller, Attribute.italic),
              ),
              _ChipButton(
                label: 'U',
                active: style.containsKey(Attribute.underline.key),
                onTap: () => _toggle(controller, Attribute.underline),
              ),
              _ChipButton(
                label: '高亮',
                active: style.containsKey(Attribute.background.key),
                onTap: () {
                  if (style.containsKey(Attribute.background.key)) {
                    controller.formatSelection(
                      Attribute.clone(Attribute.background, null),
                    );
                  } else {
                    controller.formatSelection(BackgroundAttribute('#FFF1F5'));
                  }
                },
              ),
              _ChipButton(label: '清除', active: false, onTap: onClear),
            ],
          ),
        ],
      ),
    );
  }

  static void _toggle(QuillController controller, Attribute<dynamic> attr) {
    final attrs = controller.getSelectionStyle();
    controller.formatSelection(
      attrs.containsKey(attr.key) ? Attribute.clone(attr, null) : attr,
    );
  }
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({required this.controller, required this.onToggle});

  final QuillController controller;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final style = controller.getSelectionStyle();
    final listValue = style.attributes[Attribute.list.key]?.value;
    return _PanelShell(
      title: '列表',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PanelIconButton(
            icon: Icons.format_list_bulleted,
            label: '无序',
            active: listValue == Attribute.ul.value,
            onTap: () => onToggle('ul'),
          ),
          _PanelIconButton(
            icon: Icons.format_list_numbered,
            label: '有序',
            active: listValue == Attribute.ol.value,
            onTap: () => onToggle('ol'),
          ),
          _PanelIconButton(
            icon: Icons.check_box_outlined,
            label: '待办',
            active:
                listValue == Attribute.checked.value ||
                listValue == Attribute.unchecked.value,
            onTap: () => onToggle('check'),
          ),
        ],
      ),
    );
  }
}

class _ParagraphPanel extends StatelessWidget {
  const _ParagraphPanel({required this.controller});

  final QuillController controller;

  @override
  Widget build(BuildContext context) {
    final style = controller.getSelectionStyle();
    final headerValue = style.attributes[Attribute.header.key]?.value;
    return _PanelShell(
      title: '段落',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ChipButton(
            label: '正文',
            active: headerValue == null,
            onTap: () {
              controller.formatSelection(
                Attribute.clone(Attribute.header, null),
              );
            },
          ),
          _ChipButton(
            label: 'H1',
            active: headerValue == Attribute.h1.value,
            onTap: () => controller.formatSelection(Attribute.h1),
          ),
          _ChipButton(
            label: 'H2',
            active: headerValue == Attribute.h2.value,
            onTap: () => controller.formatSelection(Attribute.h2),
          ),
          _ChipButton(
            label: 'H3',
            active: headerValue == Attribute.h3.value,
            onTap: () => controller.formatSelection(Attribute.h3),
          ),
          _PanelIconButton(
            icon: Icons.format_align_left,
            label: '左对齐',
            onTap: () => controller.formatSelection(Attribute.leftAlignment),
          ),
          _PanelIconButton(
            icon: Icons.format_align_center,
            label: '居中',
            onTap: () => controller.formatSelection(Attribute.centerAlignment),
          ),
        ],
      ),
    );
  }
}

class _InsertPanel extends StatelessWidget {
  const _InsertPanel({
    required this.pickingImage,
    required this.onPickImage,
    required this.onInsertLink,
    required this.onCodeBlock,
  });

  final bool pickingImage;
  final VoidCallback onPickImage;
  final VoidCallback onInsertLink;
  final VoidCallback onCodeBlock;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      title: '插入',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PanelIconButton(
            icon: pickingImage
                ? Icons.hourglass_top_rounded
                : Icons.image_outlined,
            label: pickingImage ? '选择中' : '图片',
            onTap: pickingImage ? null : onPickImage,
          ),
          _PanelIconButton(icon: Icons.link, label: '链接', onTap: onInsertLink),
          _PanelIconButton(icon: Icons.code, label: '代码', onTap: onCodeBlock),
        ],
      ),
    );
  }
}

class _MorePanel extends StatelessWidget {
  const _MorePanel({
    required this.onDismissKeyboard,
    required this.onClearFormat,
  });

  final VoidCallback onDismissKeyboard;
  final VoidCallback onClearFormat;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      title: '更多',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PanelIconButton(
            icon: Icons.cleaning_services_outlined,
            label: '清除格式',
            onTap: onClearFormat,
          ),
          _PanelIconButton(
            icon: Icons.keyboard_hide_outlined,
            label: '收起键盘',
            onTap: onDismissKeyboard,
          ),
        ],
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.42,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.growthColors.card.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: JournalColors.pinkBorder),
          boxShadow: [
            BoxShadow(
              color: JournalColors.pinkMain.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: JournalColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelIconButton extends StatelessWidget {
  const _PanelIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GrowthPressable(
        onTap: onTap,
        semanticLabel: label,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: active ? JournalColors.pinkBg : context.growthColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? JournalColors.pinkSoft : JournalColors.pinkBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: active
                    ? JournalColors.pinkMain
                    : JournalColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? JournalColors.pinkMain
                      : JournalColors.textSecondary,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GrowthPressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? JournalColors.pinkMain : context.growthColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? JournalColors.pinkMain : JournalColors.pinkBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? context.growthColors.textOnAccent
                : JournalColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
