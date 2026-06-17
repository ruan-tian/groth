import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../app/design/design.dart';
import '../../../core/services/image_service.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/journal_assets.dart' as journal_images;
import '../widgets/journal_colors.dart';
import '../widgets/journal_safe_image.dart';

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
    _titleController.addListener(_rebuildForTitle);
    _quillController = _createQuillController();
    _quillController.addListener(_onQuillChanged);
    _editorFocus.addListener(_onFocusChanged);
    _wordCount = _countWords(_plainText);
  }

  @override
  void dispose() {
    _titleController.removeListener(_rebuildForTitle);
    _quillController.removeListener(_onQuillChanged);
    _editorFocus.removeListener(_onFocusChanged);
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

  void _rebuildForTitle() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

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
    final imagePaths = <String>{
      ..._pickedImagePaths,
      ..._extractImagePaths(),
    }.toList(growable: false);
    widget.onSave(
      _titleController.text.trim(),
      deltaJson,
      plainText,
      _countWords(plainText),
      imagePaths,
    );
    Navigator.pop(context);
  }

  List<String> _extractImagePaths() {
    final paths = <String>[];
    for (final op in _quillController.document.toDelta().toJson()) {
      final insert = op['insert'];
      if (insert is Map && insert['image'] is String) {
        paths.add(insert['image'] as String);
      }
    }
    return paths;
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
    setState(() => _pickingImage = true);
    try {
      final path = await _imageService.pickAndSaveImage();
      if (path == null || !mounted) return;
      if (!_pickedImagePaths.contains(path)) {
        _pickedImagePaths.add(path);
      }
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
        ).showSnackBar(SnackBar(content: Text('选择图片失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _togglePanel(_ToolbarPanel panel) {
    setState(() {
      _activePanel = _activePanel == panel ? _ToolbarPanel.none : panel;
    });
  }

  void _closePanel() {
    if (_activePanel == _ToolbarPanel.none) return;
    setState(() => _activePanel = _ToolbarPanel.none);
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
      Attribute.blockQuote,
      Attribute.codeBlock,
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
        _quillController.formatText(index, text.length, LinkAttribute(url));
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
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardVisible = keyboardBottom > 0;
    final compactMode = keyboardVisible || _editorFocus.hasFocus;
    final bottomOffset = keyboardVisible ? keyboardBottom + 8.0 : 12.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: JournalColors.bg,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: AppMotion.duration(context, AppMotion.normal),
                        curve: AppMotion.standard,
                        height: compactMode ? 74 : 88,
                      ),
                      AnimatedSwitcher(
                        duration: AppMotion.duration(context, AppMotion.normal),
                        switchInCurve: AppMotion.standard,
                        switchOutCurve: AppMotion.pageExit,
                        child: compactMode
                            ? const SizedBox.shrink()
                            : _TitleSection(
                                titleController: _titleController,
                                dateStr: dateStr,
                                wordCount: _wordCount,
                              ),
                      ),
                      Expanded(
                        child: _PaperEditorSurface(
                          controller: _quillController,
                          scrollController: _scrollController,
                          focusNode: _editorFocus,
                          compactMode: compactMode,
                          keyboardBottom: keyboardBottom,
                          onTap: _closePanel,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  top: 8,
                  child: _EditorTopBar(
                    titleController: _titleController,
                    compactMode: compactMode,
                    dateStr: dateStr,
                    wordCount: _wordCount,
                    hasUndo: _hasUndo,
                    hasRedo: _hasRedo,
                    onBack: _handleBack,
                    onSave: _handleSave,
                    onUndo: _hasUndo ? _quillController.undo : null,
                    onRedo: _hasRedo ? _quillController.redo : null,
                  ),
                ),
                _ToolRail(
                  activePanel: _activePanel,
                  bottomOffset: bottomOffset + 78,
                  onFont: () => _togglePanel(_ToolbarPanel.font),
                  onList: () => _togglePanel(_ToolbarPanel.list),
                  onParagraph: () => _togglePanel(_ToolbarPanel.paragraph),
                  onInsert: () => _togglePanel(_ToolbarPanel.insert),
                  onMore: () => _togglePanel(_ToolbarPanel.more),
                ),
                _ToolPopover(
                  activePanel: _activePanel,
                  bottomOffset: bottomOffset + 78,
                  child: _buildActivePanel(),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: bottomOffset,
                  child: _KeyboardToolbar(
                    pickingImage: _pickingImage,
                    toolsActive: _activePanel != _ToolbarPanel.none,
                    onPickImage: _pickImage,
                    onTask: () => _toggleAttribute(Attribute.unchecked),
                    onQuote: () => _toggleAttribute(Attribute.blockQuote),
                    onTools: () => _togglePanel(_ToolbarPanel.font),
                  ),
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
      case _ToolbarPanel.paragraph:
        return _ParagraphPanel(controller: _quillController);
      case _ToolbarPanel.insert:
        return _InsertPanel(
          pickingImage: _pickingImage,
          onPickImage: _pickImage,
          onInsertLink: _insertLink,
          onCodeBlock: () => _toggleAttribute(Attribute.codeBlock),
        );
      case _ToolbarPanel.more:
        return _MorePanel(
          onDismissKeyboard: _editorFocus.unfocus,
          onClearFormat: _clearFormat,
        );
    }
  }
}

class _EditorTopBar extends StatelessWidget {
  const _EditorTopBar({
    required this.titleController,
    required this.compactMode,
    required this.dateStr,
    required this.wordCount,
    required this.hasUndo,
    required this.hasRedo,
    required this.onBack,
    required this.onSave,
    required this.onUndo,
    required this.onRedo,
  });

  final TextEditingController titleController;
  final bool compactMode;
  final String dateStr;
  final int wordCount;
  final bool hasUndo;
  final bool hasRedo;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.growthColors.card.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: JournalColors.pinkBorder),
        boxShadow: [
          BoxShadow(
            color: JournalColors.pinkMain.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _TopIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: '返回',
            onTap: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.normal),
              child: compactMode
                  ? Column(
                      key: const ValueKey('compact-title'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleController.text.trim().isEmpty
                              ? '标题'
                              : titleController.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: JournalColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dateStr · $wordCount字',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: JournalColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(key: ValueKey('top-spacer')),
            ),
          ),
          _TopIconButton(
            icon: Icons.undo_rounded,
            tooltip: '撤销',
            onTap: onUndo,
            enabled: hasUndo,
          ),
          const SizedBox(width: 6),
          _TopIconButton(
            icon: Icons.redo_rounded,
            tooltip: '重做',
            onTap: onRedo,
            enabled: hasRedo,
          ),
          const SizedBox(width: 6),
          GrowthPressable(
            onTap: onSave,
            semanticLabel: '完成',
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: JournalColors.pinkMain,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '完成',
                style: TextStyle(
                  color: context.growthColors.textOnAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: GrowthPressable(
          onTap: enabled ? onTap : null,
          semanticLabel: tooltip,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.growthColors.card.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: JournalColors.pinkBorder),
            ),
            child: Icon(icon, color: JournalColors.textDark, size: 22),
          ),
        ),
      ),
    );
  }
}
