import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/services/image_service.dart';
import '../utils/journal_assets.dart' as journal_images;
import '../widgets/journal_colors.dart';

enum _ToolbarPanel { none, font, list, more, paragraph }

class QuillEditorPage extends StatefulWidget {
  const QuillEditorPage({
    super.key,
    required this.initialTitle,
    required this.initialDeltaJson,
    required this.onSave,
    this.initialPlainText = '',
  });

  final String initialTitle;
  final String initialPlainText;
  final String? initialDeltaJson;
  final void Function(
    String title,
    String deltaJson,
    String plainText,
    int wordCount,
    List<String> imagePaths,
  )
  onSave;

  @override
  State<QuillEditorPage> createState() => _QuillEditorPageState();
}

class _QuillEditorPageState extends State<QuillEditorPage> {
  late final TextEditingController _titleController;
  late final QuillController _quillController;
  final FocusNode _editorFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImageService _imageService = ImageService();

  final List<String> _pickedImagePaths = [];
  _ToolbarPanel _activePanel = _ToolbarPanel.none;
  bool _pickingImage = false;
  bool _hasUndo = false;
  bool _hasRedo = false;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _quillController = _createQuillController();
    _quillController.addListener(_onQuillChanged);
    _wordCount = _countWords(_plainText);
  }

  @override
  void dispose() {
    _quillController.removeListener(_onQuillChanged);
    _titleController.dispose();
    _quillController.dispose();
    _editorFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  QuillController _createQuillController() {
    if (widget.initialDeltaJson != null &&
        widget.initialDeltaJson!.isNotEmpty) {
      try {
        final delta = jsonDecode(widget.initialDeltaJson!);
        return QuillController(
          document: Document.fromJson(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        // Fall back to plain text below.
      }
    }

    final document = Document();
    final plainText = widget.initialPlainText.trim();
    if (plainText.isNotEmpty) {
      document.insert(0, plainText);
    }
    return QuillController(
      document: document,
      selection: TextSelection.collapsed(offset: document.length - 1),
    );
  }

  String get _plainText => _quillController.document.toPlainText().trim();

  void _onQuillChanged() {
    final newCount = _countWords(_plainText);
    final hasUndo = _quillController.hasUndo;
    final hasRedo = _quillController.hasRedo;
    if (newCount != _wordCount || hasUndo != _hasUndo || hasRedo != _hasRedo) {
      setState(() {
        _wordCount = newCount;
        _hasUndo = hasUndo;
        _hasRedo = hasRedo;
      });
      return;
    }
    setState(() {});
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    final chinese = RegExp(r'[\u4e00-\u9fa5]').allMatches(text).length;
    final english = text
        .replaceAll(RegExp(r'[\u4e00-\u9fa5]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    return chinese + english;
  }

  int _selectionOffset() {
    final offset = _quillController.selection.baseOffset;
    if (offset < 0) return math.max(0, _quillController.document.length - 1);
    return offset;
  }

  void _handleSave() {
    final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _plainText;
    widget.onSave(
      _titleController.text.trim(),
      deltaJson,
      plainText,
      _countWords(plainText),
      List<String>.from(_pickedImagePaths),
    );
    Navigator.pop(context);
  }

  void _handleBack() {
    final hasContent =
        _plainText.isNotEmpty || _titleController.text.trim().isNotEmpty;
    if (!hasContent) {
      Navigator.pop(context);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存本次书写吗？'),
        content: const Text('离开前可以先保存到日记草稿页。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('放弃'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSave();
            },
            child: const Text('保存并返回'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_pickingImage) return;
    _pickingImage = true;
    try {
      final path = await _imageService.pickAndSaveImage();
      if (path == null || !mounted) return;
      _pickedImagePaths.add(path);
      final index = _selectionOffset();
      _quillController.replaceText(
        index,
        0,
        BlockEmbed.image(path),
        TextSelection.collapsed(offset: index + 1),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    } finally {
      _pickingImage = false;
    }
  }

  void _togglePanel(_ToolbarPanel panel) {
    setState(() {
      _activePanel = _activePanel == panel ? _ToolbarPanel.none : panel;
    });
  }

  void _toggleAttribute(Attribute<dynamic> attr) {
    final attrs = _quillController.getSelectionStyle();
    if (attrs.containsKey(attr.key)) {
      _quillController.formatSelection(Attribute.clone(attr, null));
    } else {
      _quillController.formatSelection(attr);
    }
  }

  void _toggleList(String type) {
    switch (type) {
      case 'ul':
        _toggleAttribute(Attribute.ul);
        break;
      case 'ol':
        _toggleAttribute(Attribute.ol);
        break;
      case 'check':
        _toggleAttribute(Attribute.unchecked);
        break;
    }
  }

  void _clearFormat() {
    const attrs = <Attribute>[
      Attribute.bold,
      Attribute.italic,
      Attribute.underline,
      Attribute.strikeThrough,
      Attribute.background,
      Attribute.h1,
      Attribute.h2,
      Attribute.h3,
    ];
    for (final attr in attrs) {
      _quillController.formatSelection(Attribute.clone(attr, null));
    }
  }

  void _insertLink() {
    final textCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('插入链接'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(labelText: '链接文字'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final text = textCtrl.text.trim();
              final url = urlCtrl.text.trim();
              if (text.isNotEmpty && url.isNotEmpty) {
                final index = _selectionOffset();
                _quillController.document.insert(index, text);
                _quillController.formatText(
                  index,
                  text.length,
                  LinkAttribute(url),
                );
                _quillController.updateSelection(
                  TextSelection.collapsed(offset: index + text.length),
                  ChangeSource.local,
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: JournalColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                _TopBar(onBack: _handleBack, onSave: _handleSave),
                _TitleSection(
                  titleController: _titleController,
                  dateStr: dateStr,
                  wordCount: _wordCount,
                ),
                Expanded(
                  child: _PaperEditorSurface(
                    controller: _quillController,
                    scrollController: _scrollController,
                    focusNode: _editorFocus,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _buildActivePanel(),
                ),
                _KeyboardToolbar(
                  activePanel: _activePanel,
                  onPickImage: _pickImage,
                  onTask: () => _toggleAttribute(Attribute.unchecked),
                  onList: () => _togglePanel(_ToolbarPanel.list),
                  onQuote: () => _toggleAttribute(Attribute.blockQuote),
                  onFont: () => _togglePanel(_ToolbarPanel.font),
                  onMore: () => _togglePanel(_ToolbarPanel.more),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivePanel() {
    switch (_activePanel) {
      case _ToolbarPanel.none:
        return const SizedBox.shrink();
      case _ToolbarPanel.font:
        return _FontPanel(controller: _quillController, onClear: _clearFormat);
      case _ToolbarPanel.list:
        return _ListPanel(controller: _quillController, onToggle: _toggleList);
      case _ToolbarPanel.more:
        return _MorePanel(
          onInsertLink: _insertLink,
          onCodeBlock: () => _toggleAttribute(Attribute.codeBlock),
          onUndo: _hasUndo ? _quillController.undo : null,
          onRedo: _hasRedo ? _quillController.redo : null,
          onDismissKeyboard: _editorFocus.unfocus,
          onParagraph: () => _togglePanel(_ToolbarPanel.paragraph),
        );
      case _ToolbarPanel.paragraph:
        return _ParagraphPanel(controller: _quillController);
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onSave});

  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
      child: Row(
        children: [
          _TopIconButton(icon: Icons.chevron_left_rounded, onTap: onBack),
          const Spacer(),
          TextButton(
            onPressed: onSave,
            style: TextButton.styleFrom(
              foregroundColor: JournalColors.pinkMain,
            ),
            child: const Text(
              '完成',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({
    required this.titleController,
    required this.dateStr,
    required this.wordCount,
  });

  final TextEditingController titleController;
  final String dateStr;
  final int wordCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 16, 30, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(width: 4, color: JournalColors.pinkMain),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: titleController,
                    style: const TextStyle(
                      color: JournalColors.pinkMain,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                    decoration: const InputDecoration(
                      hintText: '标题',
                      hintStyle: TextStyle(color: JournalColors.pinkSoft),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$dateStr  ·  $wordCount字',
            style: const TextStyle(
              color: JournalColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperEditorSurface extends StatelessWidget {
  const _PaperEditorSurface({
    required this.controller,
    required this.scrollController,
    required this.focusNode,
  });

  final QuillController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(26, 0, 26, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: JournalColors.pinkBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _EditorLinesPainter())),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
              child: QuillEditor(
                controller: controller,
                scrollController: scrollController,
                focusNode: focusNode,
                config: const QuillEditorConfig(
                  placeholder: '开始书写吧...',
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: IgnorePointer(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: JournalColors.pinkBorder),
                      ),
                      child: const Text(
                        '甜甜陪你\n记录每一天~',
                        style: TextStyle(
                          color: JournalColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Image.asset(
                      journal_images.JournalAssets.catWriting,
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: JournalColors.textDark),
        ),
      ),
    );
  }
}

class _EditorLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = JournalColors.pinkBorder.withValues(alpha: 0.52)
      ..strokeWidth = 1;
    for (var y = 52.0; y < size.height - 20; y += 48) {
      canvas.drawLine(Offset(22, y), Offset(size.width - 22, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
