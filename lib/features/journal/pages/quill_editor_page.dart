import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/services/image_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Constants
// ──────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFFFFFFFF);
const _kInk = Color(0xFF111827);
const _kSecondary = Color(0xFF8B92A3);
const _kHint = Color(0xFFB8BECC);
const _kBorder = Color(0xFFE5E7EB);
const _kIcon = Color(0xFF6B7280);
const _kAccent = Color(0xFF6C63FF);
const _kAccentBg = Color(0xFFF0EFFF);

// ──────────────────────────────────────────────────────────────────────────────
// Panel enum
// ──────────────────────────────────────────────────────────────────────────────

enum _ToolbarPanel { none, font, list, more, paragraph }

// ──────────────────────────────────────────────────────────────────────────────
// Page
// ──────────────────────────────────────────────────────────────────────────────

class QuillEditorPage extends StatefulWidget {
  const QuillEditorPage({
    super.key,
    required this.initialTitle,
    required this.initialDeltaJson,
    required this.onSave,
  });

  final String initialTitle;
  final String? initialDeltaJson;
  final void Function(
    String title,
    String deltaJson,
    String plainText,
    int wordCount,
    List<String> imagePaths,
  ) onSave;

  @override
  State<QuillEditorPage> createState() => _QuillEditorPageState();
}

class _QuillEditorPageState extends State<QuillEditorPage> {
  // ── Controllers ──
  late final TextEditingController _titleController;
  late QuillController _quillController;
  final FocusNode _editorFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImageService _imageService = ImageService();

  // ── State ──
  final List<String> _pickedImagePaths = [];
  _ToolbarPanel _activePanel = _ToolbarPanel.none;
  bool _pickingImage = false;
  bool _hasUndo = false;
  bool _hasRedo = false;
  int _wordCount = 0;

  // ── Lifecycle ──

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _quillController = _createQuillController();
    _quillController.addListener(_onQuillChanged);
    _wordCount = _countWords(_quillController.document.toPlainText());
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

  // ── Quill helpers ──

  QuillController _createQuillController() {
    if (widget.initialDeltaJson != null && widget.initialDeltaJson!.isNotEmpty) {
      try {
        final delta = jsonDecode(widget.initialDeltaJson!);
        return QuillController(
          document: Document.fromJson(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {}
    }
    return QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void _onQuillChanged() {
    final newCount = _countWords(_quillController.document.toPlainText());
    final hasUndo = _quillController.hasUndo;
    final hasRedo = _quillController.hasRedo;
    if (newCount != _wordCount || hasUndo != _hasUndo || hasRedo != _hasRedo) {
      setState(() {
        _wordCount = newCount;
        _hasUndo = hasUndo;
        _hasRedo = hasRedo;
      });
    } else {
      // Selection-only change — rebuild for format indicators.
      setState(() {});
    }
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    final chinese = RegExp(r'[\u4e00-\u9fa5]').allMatches(text).length;
    final english = text
        .replaceAll(RegExp(r'[\u4e00-\u9fa5]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    return chinese + english;
  }

  // ── Actions ──

  void _handleSave() {
    final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText();
    widget.onSave(
      _titleController.text.trim(),
      deltaJson,
      plainText,
      _countWords(plainText),
      _pickedImagePaths,
    );
    Navigator.pop(context);
  }

  void _handleBack() {
    final hasContent = _quillController.document.toPlainText().trim().isNotEmpty ||
        _titleController.text.isNotEmpty;
    if (!hasContent) {
      Navigator.pop(context);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存本次书写？'),
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
      if (path != null && mounted) {
        _pickedImagePaths.add(path);
        final index = _quillController.selection.baseOffset;
        _quillController.replaceText(
          index,
          0,
          BlockEmbed.image(path),
          TextSelection.collapsed(offset: index + 1),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
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

  // ── Format helpers ──

  void _toggleAttribute(Attribute attr) {
    final attrs = _quillController.getSelectionStyle();
    if (attrs.containsKey(attr.key)) {
      _quillController.formatSelection(Attribute.clone(attr, null) as Attribute<dynamic>);
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
      _quillController.formatSelection(
        Attribute.clone(attr, null) as Attribute<dynamic>,
      );
    }
  }

  void _insertLink() {
    final urlCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('插入链接'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(labelText: '链接文字', hintText: '显示的文字'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'URL', hintText: 'https://example.com'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final text = textCtrl.text;
              final url = urlCtrl.text;
              if (text.isNotEmpty && url.isNotEmpty) {
                final index = _quillController.selection.baseOffset;
                _quillController.document.insert(index, text);
                _quillController.formatText(index, text.length, LinkAttribute(url));
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

  // ────────────────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            _TopBar(onBack: _handleBack, onSave: _handleSave),

            // ── Title + meta ──
            _TitleSection(
              titleController: _titleController,
              dateStr: dateStr,
              wordCount: _wordCount,
            ),

            // ── Editor ──
            Expanded(
              child: QuillEditor(
                controller: _quillController,
                scrollController: _scrollController,
                focusNode: _editorFocus,
                config: const QuillEditorConfig(
                  placeholder: '开始书写吧...',
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),

            // ── Panel (animated) ──
            AnimatedSize(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _buildActivePanel(),
            ),

            // ── Keyboard toolbar ──
            _KeyboardToolbar(
              activePanel: _activePanel,
              onPickImage: _pickImage,
              onTask: () => _quillController.formatSelection(Attribute.unchecked),
              onList: () => _togglePanel(_ToolbarPanel.list),
              onQuote: () => _toggleAttribute(Attribute.blockQuote),
              onFont: () => _togglePanel(_ToolbarPanel.font),
              onMore: () => _togglePanel(_ToolbarPanel.more),
            ),
          ],
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
          controller: _quillController,
          onInsertLink: _insertLink,
          onCodeBlock: () => _toggleAttribute(Attribute.codeBlock),
          onDivider: () {
            final idx = _quillController.selection.baseOffset;
            _quillController.document.insert(idx, '\n────────────────────\n');
            _quillController.updateSelection(
              TextSelection.collapsed(offset: idx + 23),
              ChangeSource.local,
            );
          },
          onUndo: _hasUndo ? () => _quillController.undo() : null,
          onRedo: _hasRedo ? () => _quillController.redo() : null,
          onDismissKeyboard: () => _editorFocus.unfocus(),
          onParagraph: () => _togglePanel(_ToolbarPanel.paragraph),
        );
      case _ToolbarPanel.paragraph:
        return _ParagraphPanel(controller: _quillController);
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Top Bar
// ──────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onSave});

  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 24, color: _kInk),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSave,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  '完成',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kAccent,
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

// ──────────────────────────────────────────────────────────────────────────────
// Title + Meta
// ──────────────────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: titleController,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: _kInk,
              height: 1.2,
            ),
            decoration: const InputDecoration(
              hintText: '标题',
              hintStyle: TextStyle(color: _kHint),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              filled: false,
            ),
            maxLines: null,
          ),
          const SizedBox(height: 4),
          Text(
            '$dateStr · $wordCount 字',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Keyboard Toolbar
// ──────────────────────────────────────────────────────────────────────────────

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
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder, width: 0.6)),
      ),
      child: Row(
        children: [
          _ToolbarBtn(icon: Icons.image_outlined, label: '图片', active: false, onTap: onPickImage),
          _ToolbarBtn(icon: Icons.check_box_outlined, label: '任务', active: false, onTap: onTask),
          _ToolbarBtn(icon: Icons.format_list_bulleted, label: '列表', active: activePanel == _ToolbarPanel.list, onTap: onList),
          _ToolbarBtn(icon: Icons.format_quote, label: '引用', active: false, onTap: onQuote),
          _ToolbarBtn(icon: Icons.font_download_outlined, label: '字体', active: activePanel == _ToolbarPanel.font, onTap: onFont),
          _ToolbarBtn(icon: Icons.more_horiz, label: '更多', active: activePanel == _ToolbarPanel.more, onTap: onMore),
        ],
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 30,
              decoration: active
                  ? BoxDecoration(
                      color: _kAccentBg,
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Icon(icon, size: 22, color: active ? _kAccent : _kIcon),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? _kAccent : _kSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Font Panel
// ──────────────────────────────────────────────────────────────────────────────

class _FontPanel extends StatelessWidget {
  const _FontPanel({required this.controller, required this.onClear});

  final QuillController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final style = controller.getSelectionStyle();
    final isBold = style.containsKey(Attribute.bold.key);
    final isItalic = style.containsKey(Attribute.italic.key);
    final isUnderline = style.containsKey(Attribute.underline.key);
    final isStrike = style.containsKey(Attribute.strikeThrough.key);
    final isHighlight = style.containsKey(Attribute.background.key);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder, width: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Font sizes
          Row(
            children: [
              const Text('字号', style: TextStyle(fontSize: 13, color: _kSecondary)),
              const SizedBox(width: 16),
              ..._fontSizes.map((size) {
                final currentSize = controller.getSelectionStyle().attributes[Attribute.size.key];
                final selected = currentSize?.value == size.toString();
                final displaySize = size > 18 ? 18.0 : size.toDouble();
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => controller.formatSelection(SizeAttribute(size.toString())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? _kAccentBg : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selected ? _kAccent : _kBorder),
                      ),
                      child: Text(
                        '$size',
                        style: TextStyle(
                          fontSize: displaySize,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? _kAccent : _kInk,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),
          // Style buttons
          Row(
            children: [
              _StyleBtn(label: 'B', active: isBold, onTap: () => _toggle(controller, Attribute.bold)),
              const SizedBox(width: 10),
              _StyleBtn(label: 'I', italic: true, active: isItalic, onTap: () => _toggle(controller, Attribute.italic)),
              const SizedBox(width: 10),
              _StyleBtn(label: 'U', active: isUnderline, onTap: () => _toggle(controller, Attribute.underline)),
              const SizedBox(width: 10),
              _StyleBtn(label: 'S', active: isStrike, onTap: () => _toggle(controller, Attribute.strikeThrough)),
              const SizedBox(width: 10),
              _StyleBtn(label: '高亮', active: isHighlight, onTap: () {
                if (isHighlight) {
                  controller.formatSelection(Attribute.clone(Attribute.background, null) as Attribute<dynamic>);
                } else {
                  controller.formatSelection(BackgroundAttribute('#FFF8DC'));
                }
              }),
              const Spacer(),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Text('清除', style: TextStyle(fontSize: 12, color: _kSecondary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _fontSizes = [14, 16, 18, 20, 24];

  static void _toggle(QuillController c, Attribute attr) {
    final attrs = c.getSelectionStyle();
    if (attrs.containsKey(attr.key)) {
      c.formatSelection(Attribute.clone(attr, null) as Attribute<dynamic>);
    } else {
      c.formatSelection(attr);
    }
  }
}

class _StyleBtn extends StatelessWidget {
  const _StyleBtn({
    required this.label,
    required this.active,
    required this.onTap,
    this.italic = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active ? _kAccent : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? _kAccent : _kBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              color: active ? Colors.white : _kInk,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// List Panel
// ──────────────────────────────────────────────────────────────────────────────

class _ListPanel extends StatelessWidget {
  const _ListPanel({required this.controller, required this.onToggle});

  final QuillController controller;
  final void Function(String type) onToggle;

  @override
  Widget build(BuildContext context) {
    final style = controller.getSelectionStyle();
    final isUl = style.containsKey(Attribute.ul.key);
    final isOl = style.containsKey(Attribute.ol.key);
    final isCheck = style.containsKey(Attribute.unchecked.key) ||
        style.containsKey(Attribute.checked.key);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder, width: 0.6)),
      ),
      child: Row(
        children: [
          _ListTypeBtn(icon: Icons.format_list_bulleted, label: '无序', active: isUl, onTap: () => onToggle('ul')),
          const SizedBox(width: 16),
          _ListTypeBtn(icon: Icons.format_list_numbered, label: '有序', active: isOl, onTap: () => onToggle('ol')),
          const SizedBox(width: 16),
          _ListTypeBtn(icon: Icons.check_box_outlined, label: '任务', active: isCheck, onTap: () => onToggle('check')),
        ],
      ),
    );
  }
}

class _ListTypeBtn extends StatelessWidget {
  const _ListTypeBtn({
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: active ? _kAccentBg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? _kAccent : _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? _kAccent : _kIcon),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? _kAccent : _kInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// More Panel
// ──────────────────────────────────────────────────────────────────────────────

class _MorePanel extends StatelessWidget {
  const _MorePanel({
    required this.controller,
    required this.onInsertLink,
    required this.onCodeBlock,
    required this.onDivider,
    required this.onUndo,
    required this.onRedo,
    required this.onDismissKeyboard,
    required this.onParagraph,
  });

  final QuillController controller;
  final VoidCallback onInsertLink;
  final VoidCallback onCodeBlock;
  final VoidCallback onDivider;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onDismissKeyboard;
  final VoidCallback onParagraph;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder, width: 0.6)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _MoreBtn(icon: Icons.horizontal_rule, label: '分割线', onTap: onDivider),
          _MoreBtn(icon: Icons.notes, label: '段落', onTap: onParagraph),
          _MoreBtn(icon: Icons.code, label: '代码块', onTap: onCodeBlock),
          _MoreBtn(icon: Icons.link, label: '链接', onTap: onInsertLink),
          _MoreBtn(
            icon: Icons.undo,
            label: '撤销',
            onTap: onUndo,
            disabled: onUndo == null,
          ),
          _MoreBtn(
            icon: Icons.redo,
            label: '重做',
            onTap: onRedo,
            disabled: onRedo == null,
          ),
          _MoreBtn(icon: Icons.keyboard_hide_outlined, label: '收起键盘', onTap: onDismissKeyboard),
        ],
      ),
    );
  }
}

class _MoreBtn extends StatelessWidget {
  const _MoreBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: disabled ? _kBorder.withAlpha(128) : _kBorder),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: disabled ? _kBorder : _kIcon),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: disabled ? _kBorder : _kSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Paragraph Panel
// ──────────────────────────────────────────────────────────────────────────────

class _ParagraphPanel extends StatelessWidget {
  const _ParagraphPanel({required this.controller});

  final QuillController controller;

  @override
  Widget build(BuildContext context) {
    final style = controller.getSelectionStyle();
    final isH1 = style.containsKey(Attribute.h1.key);
    final isH2 = style.containsKey(Attribute.h2.key);
    final isH3 = style.containsKey(Attribute.h3.key);
    final isBody = !isH1 && !isH2 && !isH3;
    final isLeft = !style.containsKey(Attribute.centerAlignment.key) &&
        !style.containsKey(Attribute.rightAlignment.key);
    final isCenter = style.containsKey(Attribute.centerAlignment.key);
    final isRight = style.containsKey(Attribute.rightAlignment.key);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder, width: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading levels
          Row(
            children: [
              _HeadingChip(label: '正文', active: isBody, onTap: () {
                controller.formatSelection(Attribute.clone(Attribute.h1, null) as Attribute<dynamic>);
                controller.formatSelection(Attribute.clone(Attribute.h2, null) as Attribute<dynamic>);
                controller.formatSelection(Attribute.clone(Attribute.h3, null) as Attribute<dynamic>);
              }),
              const SizedBox(width: 10),
              _HeadingChip(label: 'H1', active: isH1, onTap: () => controller.formatSelection(Attribute.h1)),
              const SizedBox(width: 10),
              _HeadingChip(label: 'H2', active: isH2, onTap: () => controller.formatSelection(Attribute.h2)),
              const SizedBox(width: 10),
              _HeadingChip(label: 'H3', active: isH3, onTap: () => controller.formatSelection(Attribute.h3)),
            ],
          ),
          const SizedBox(height: 14),
          // Alignment
          Row(
            children: [
              _AlignBtn(icon: Icons.format_align_left, active: isLeft, onTap: () => controller.formatSelection(Attribute.leftAlignment)),
              const SizedBox(width: 10),
              _AlignBtn(icon: Icons.format_align_center, active: isCenter, onTap: () => controller.formatSelection(Attribute.centerAlignment)),
              const SizedBox(width: 10),
              _AlignBtn(icon: Icons.format_align_right, active: isRight, onTap: () => controller.formatSelection(Attribute.rightAlignment)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeadingChip extends StatelessWidget {
  const _HeadingChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _kAccentBg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? _kAccent : _kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? _kAccent : _kInk,
          ),
        ),
      ),
    );
  }
}

class _AlignBtn extends StatelessWidget {
  const _AlignBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? _kAccentBg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? _kAccent : _kBorder),
        ),
        child: Icon(icon, size: 20, color: active ? _kAccent : _kIcon),
      ),
    );
  }
}
