import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/services/image_service.dart';
import '../utils/journal_assets.dart' as journal_images;
import '../widgets/journal_colors.dart';

part '../widgets/quill_editor_toolbar.dart';
part '../widgets/quill_editor_surface.dart';
part '../widgets/quill_link_dialog.dart';
part '../widgets/quill_title_input.dart';

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
    _QuillLinkDialog.show(
      context,
      onConfirm: (text, url) {
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
      },
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

// ---------------------------------------------------------------------------
// Top navigation bar
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Top bar icon button
// ---------------------------------------------------------------------------

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
