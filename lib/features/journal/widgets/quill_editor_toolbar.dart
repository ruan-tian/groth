part of '../pages/quill_editor_page.dart';

// ---------------------------------------------------------------------------
// Toolbar panel enum
// ---------------------------------------------------------------------------

enum _ToolbarPanel { none, font, list, more, paragraph }

// ---------------------------------------------------------------------------
// Keyboard toolbar (bottom bar)
// ---------------------------------------------------------------------------

class _KeyboardToolbar extends StatelessWidget {
  const _KeyboardToolbar({
    required this.activePanel,
    required this.onPickImage,
    required this.onTask,
    required this.onList,
    required this.onQuote,
    required this.onFont,
    required this.onMore,
  });

  final _ToolbarPanel activePanel;
  final VoidCallback onPickImage;
  final VoidCallback onTask;
  final VoidCallback onList;
  final VoidCallback onQuote;
  final VoidCallback onFont;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: JournalColors.pinkMain.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            _ToolbarItem(
              icon: Icons.image_outlined,
              label: '图片',
              onTap: onPickImage,
            ),
            _ToolbarItem(
              icon: Icons.check_box_outlined,
              label: '任务',
              onTap: onTask,
            ),
            _ToolbarItem(
              icon: Icons.format_list_bulleted_rounded,
              label: '列表',
              active: activePanel == _ToolbarPanel.list,
              onTap: onList,
            ),
            _ToolbarItem(
              icon: Icons.format_quote_rounded,
              label: '引用',
              onTap: onQuote,
            ),
            _ToolbarItem(
              icon: Icons.text_fields_rounded,
              label: '字体',
              active: activePanel == _ToolbarPanel.font,
              onTap: onFont,
            ),
            _ToolbarItem(
              icon: Icons.more_horiz_rounded,
              label: '更多',
              active: activePanel == _ToolbarPanel.more,
              onTap: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single toolbar button
// ---------------------------------------------------------------------------

class _ToolbarItem extends StatelessWidget {
  const _ToolbarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 25,
                color: active
                    ? JournalColors.pinkMain
                    : JournalColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active
                      ? JournalColors.pinkMain
                      : JournalColors.textSecondary,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Font formatting panel
// ---------------------------------------------------------------------------

class _FontPanel extends StatelessWidget {
  const _FontPanel({required this.controller, required this.onClear});

  final QuillController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final style = controller.getSelectionStyle();
    return _PanelShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [14, 16, 18, 20, 24].map((size) {
                final current = style.attributes[Attribute.size.key];
                final selected = current?.value == size.toString();
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
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
          const SizedBox(height: 12),
          Row(
            children: [
              _ChipButton(
                label: 'B',
                active: style.containsKey(Attribute.bold.key),
                onTap: () => _toggle(controller, Attribute.bold),
              ),
              const SizedBox(width: 8),
              _ChipButton(
                label: 'I',
                active: style.containsKey(Attribute.italic.key),
                onTap: () => _toggle(controller, Attribute.italic),
              ),
              const SizedBox(width: 8),
              _ChipButton(
                label: 'U',
                active: style.containsKey(Attribute.underline.key),
                onTap: () => _toggle(controller, Attribute.underline),
              ),
              const SizedBox(width: 8),
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
              const Spacer(),
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

// ---------------------------------------------------------------------------
// List formatting panel
// ---------------------------------------------------------------------------

class _ListPanel extends StatelessWidget {
  const _ListPanel({required this.controller, required this.onToggle});

  final QuillController controller;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final style = controller.getSelectionStyle();
    return _PanelShell(
      child: Row(
        children: [
          _PanelIconButton(
            icon: Icons.format_list_bulleted,
            label: '无序',
            active: style.containsKey(Attribute.ul.key),
            onTap: () => onToggle('ul'),
          ),
          const SizedBox(width: 12),
          _PanelIconButton(
            icon: Icons.format_list_numbered,
            label: '有序',
            active: style.containsKey(Attribute.ol.key),
            onTap: () => onToggle('ol'),
          ),
          const SizedBox(width: 12),
          _PanelIconButton(
            icon: Icons.check_box_outlined,
            label: '任务',
            active:
                style.containsKey(Attribute.checked.key) ||
                style.containsKey(Attribute.unchecked.key),
            onTap: () => onToggle('check'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// More options panel
// ---------------------------------------------------------------------------

class _MorePanel extends StatelessWidget {
  const _MorePanel({
    required this.onInsertLink,
    required this.onCodeBlock,
    required this.onUndo,
    required this.onRedo,
    required this.onDismissKeyboard,
    required this.onParagraph,
  });

  final VoidCallback onInsertLink;
  final VoidCallback onCodeBlock;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onDismissKeyboard;
  final VoidCallback onParagraph;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PanelIconButton(icon: Icons.notes, label: '段落', onTap: onParagraph),
          _PanelIconButton(icon: Icons.code, label: '代码', onTap: onCodeBlock),
          _PanelIconButton(icon: Icons.link, label: '链接', onTap: onInsertLink),
          _PanelIconButton(icon: Icons.undo, label: '撤销', onTap: onUndo),
          _PanelIconButton(icon: Icons.redo, label: '重做', onTap: onRedo),
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

// ---------------------------------------------------------------------------
// Paragraph / heading panel
// ---------------------------------------------------------------------------

class _ParagraphPanel extends StatelessWidget {
  const _ParagraphPanel({required this.controller});

  final QuillController controller;

  @override
  Widget build(BuildContext context) {
    final style = controller.getSelectionStyle();
    return _PanelShell(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ChipButton(
            label: '正文',
            active:
                !style.containsKey(Attribute.h1.key) &&
                !style.containsKey(Attribute.h2.key) &&
                !style.containsKey(Attribute.h3.key),
            onTap: () {
              controller.formatSelection(Attribute.clone(Attribute.h1, null));
              controller.formatSelection(Attribute.clone(Attribute.h2, null));
              controller.formatSelection(Attribute.clone(Attribute.h3, null));
            },
          ),
          _ChipButton(
            label: 'H1',
            active: style.containsKey(Attribute.h1.key),
            onTap: () => controller.formatSelection(Attribute.h1),
          ),
          _ChipButton(
            label: 'H2',
            active: style.containsKey(Attribute.h2.key),
            onTap: () => controller.formatSelection(Attribute.h2),
          ),
          _ChipButton(
            label: 'H3',
            active: style.containsKey(Attribute.h3.key),
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

// ---------------------------------------------------------------------------
// Reusable panel shell
// ---------------------------------------------------------------------------

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JournalColors.pinkBorder),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable icon + label button for panels
// ---------------------------------------------------------------------------

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: active ? JournalColors.pinkBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable chip button
// ---------------------------------------------------------------------------

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? JournalColors.pinkMain : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? JournalColors.pinkMain : JournalColors.pinkBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : JournalColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
