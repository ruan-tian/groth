import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../journal/providers/journal_provider.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../../../core/services/pet_event_bus.dart';
import '../providers/journal_stats_provider.dart';
import '../utils/journal_assets.dart' as journal_images;
import '../utils/journal_constants.dart';
import '../widgets/journal_colors.dart';
import 'quill_editor_page.dart';

part '../widgets/write_journal_page_widgets.dart';

class WriteJournalPage extends ConsumerStatefulWidget {
  const WriteJournalPage({super.key});

  @override
  ConsumerState<WriteJournalPage> createState() => _WriteJournalPageState();
}

class _WriteJournalPageState extends ConsumerState<WriteJournalPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String? _selectedMood = 'happy';
  final Set<String> _selectedTags = {};
  int? _folderId;
  String? _folderName;
  bool _saving = false;
  bool _pickingImage = false;
  final List<String> _pendingImagePaths = [];
  String? _quillDeltaJson;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_rebuild);
    _contentController.addListener(_rebuild);
  }

  @override
  void dispose() {
    _titleController.removeListener(_rebuild);
    _contentController.removeListener(_rebuild);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入标题')));
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入正文')));
      return;
    }

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;
      final content = _contentController.text.trim();
      final wordCount = content.length;
      final plainText = _stripMarkdown(content);
      final contentType = _quillDeltaJson != null ? 'quill' : 'markdown';

      final expService = ref.read(expServiceProvider);
      final rawExp = expService.calculateJournalExp(wordCount: wordCount);
      // 每日上限 20 EXP：查询当日已获得的日记 EXP，计算剩余可用额度
      final expRepoForCap = ref.read(expRepositoryProvider);
      final todayJournalExp = await expRepoForCap.getTotalExpBySourceAndDate(
        'journal',
        now,
      );
      final remainingCap = (20 - todayJournalExp).clamp(0, 20);
      final exp = rawExp.clamp(0, remainingCap);
      final journalRepo = ref.read(journalRepositoryProvider);

      final companion = DailyJournalsCompanion.insert(
        journalDate: _formatDate(now),
        title: _titleController.text.trim(),
        content: content,
        contentType: Value(contentType),
        quillDeltaJson: Value(_quillDeltaJson),
        markdownContent: Value(contentType == 'markdown' ? content : null),
        plainText: Value(plainText),
        mood: Value(_selectedMood),
        tags: Value(
          _selectedTags.isEmpty ? null : jsonEncode(_selectedTags.toList()),
        ),
        folderId: Value(_folderId),
        wordCount: Value(wordCount),
        expGained: Value(exp),
        createdAt: nowMs,
        updatedAt: nowMs,
      );

      final expRepo = ref.read(expRepositoryProvider);
      final oldTotal = await expRepo.getTotalExp();
      final oldLevel = expService.calculateLevel(oldTotal);
      await journalRepo.createJournalWithAssetsAndExp(
        journal: companion,
        assetPaths: _pendingImagePaths,
        exp: exp,
        reason: 'journal: ${_titleController.text.trim()} ($wordCount words)',
        createdAt: nowMs,
      );

      final newLevel = expService.calculateLevel(oldTotal + exp);
      if (newLevel > oldLevel) {
        PetEventBus.instance.emit(
          PetEvent.levelUp(oldLevel: oldLevel, newLevel: newLevel),
        );
      }

      ref.invalidate(recentJournalsProvider);
      ref.invalidate(journalsByFolderProvider);
      ref.invalidate(todayJournalCountProvider);
      ref.invalidate(allJournalTagsProvider);
      ref.invalidate(journalStreakProvider);
      ref.invalidate(totalJournalCountProvider);
      ref.invalidate(monthlyJournalCountProvider);
      ref.invalidate(journalHeatmapProvider);
      ref.invalidate(dashboardProvider);

      if (!mounted) return;
      PetEventBus.instance.emit(
        PetEvent.moduleCompleted(
          eventId: 'journal_${DateTime.now().millisecondsSinceEpoch}',
          type: PetEventType.journalCompleted,
          module: 'journal',
        ),
      );
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已保存，获得 $exp EXP'),
          backgroundColor: context.growthColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll(RegExp(r'__(.+?)__'), r'$1')
        .replaceAll(RegExp(r'_(.+?)_'), r'$1')
        .replaceAll(RegExp(r'~~(.+?)~~'), r'$1')
        .replaceAll(RegExp(r'^>\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^[-*+]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1')
        .replaceAll(RegExp(r'!\[.*?\]\(.+?\)'), '')
        .replaceAll(RegExp(r'`(.+?)`'), r'$1')
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll(RegExp(r'---+'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  void _openFullScreenEditor() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => QuillEditorPage(
          initialTitle: _titleController.text,
          initialPlainText: _contentController.text,
          initialDeltaJson: _quillDeltaJson,
          onSave: (title, deltaJson, plainText, wordCount, imagePaths) {
            final mergedImagePaths = {..._pendingImagePaths, ...imagePaths};
            setState(() {
              _titleController.text = title;
              _contentController.text = plainText.trim();
              _quillDeltaJson = deltaJson;
              _pendingImagePaths
                ..clear()
                ..addAll(mergedImagePaths);
            });
          },
        ),
      ),
    );
  }

  Future<void> _pickImageInline() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);

    try {
      final imageService = ref.read(imageServiceProvider);
      final path = await imageService.pickAndSaveImage();
      if (path == null) return;

      setState(() {
        if (!_pendingImagePaths.contains(path)) {
          _pendingImagePaths.add(path);
        }
        final current = _contentController.text;
        final prefix = current.isEmpty ? '' : '\n';
        _contentController.text = '$current$prefix![image]($path)\n';
        _contentController.selection = TextSelection.fromPosition(
          TextPosition(offset: _contentController.text.length),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('图片已添加')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('图片导入失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _insertPrompt() {
    final prompt = getRandomPrompt().text;
    final current = _contentController.text;
    final prefix = current.trim().isEmpty ? '' : '\n\n';
    _contentController.text = '$current$prefix$prompt\n';
    _contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _contentController.text.length),
    );
  }

  void _showWordStats() {
    final content = _contentController.text.trim();
    final lineCount = content.isEmpty ? 0 : content.split('\n').length;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SoftSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '字数统计',
              style: TextStyle(
                color: JournalColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(value: '$wordCount', label: '本次字数'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(value: '$lineCount', label: '段落行数'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int get wordCount => _contentController.text.trim().length;

  int get estimatedExp {
    return ref
        .read(expServiceProvider)
        .calculateJournalExp(wordCount: wordCount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final streak =
        ref.watch(journalStreakProvider).whenOrNull(data: (v) => v) ?? 0;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 760;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 720 : 520),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 28 : 20,
                    12,
                    wide ? 28 : 20,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(
                        onBack: () => context.pop(),
                        onSave: _saving ? null : _save,
                      ),
                      const SizedBox(height: 22),
                      _MoodCard(
                        selectedMood: _selectedMood,
                        onSelected: (mood) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedMood = _selectedMood == mood ? null : mood;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _JournalPaperCard(
                        titleController: _titleController,
                        contentController: _contentController,
                        wordCount: wordCount,
                        onOpenEditor: _openFullScreenEditor,
                      ),
                      const SizedBox(height: 18),
                      _ToolGrid(
                        pickingImage: _pickingImage,
                        onPrompt: _insertPrompt,
                        onStats: _showWordStats,
                        onImage: _pickImageInline,
                        onMood: () => _showMoodSheet(),
                      ),
                      const SizedBox(height: 18),
                      _TagSection(
                        selectedTags: _selectedTags,
                        onToggle: (tag) {
                          setState(() {
                            _selectedTags.contains(tag)
                                ? _selectedTags.remove(tag)
                                : _selectedTags.add(tag);
                          });
                        },
                        onCustom: _showCustomTagDialog,
                      ),
                      const SizedBox(height: 18),
                      _FolderSaveSection(
                        folderName: _folderName,
                        selectedFolderId: _folderId,
                        onTap: _showFolderPicker,
                      ),
                      const SizedBox(height: 18),
                      _WritingSummary(
                        wordCount: wordCount,
                        exp: estimatedExp,
                        streak: streak,
                      ),
                      const SizedBox(height: 24),
                      _BottomActions(
                        saving: _saving,
                        onSave: _save,
                        onDone: _save,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMoodSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SoftSheet(
        child: _MoodCard(
          selectedMood: _selectedMood,
          compact: true,
          onSelected: (mood) {
            setState(() => _selectedMood = mood);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _showCustomTagDialog() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('添加自定义标签'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 12,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: '例如：旅行、灵感、复盘',
            counterText: '',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    controller.dispose();
    final value = tag?.trim();
    if (value == null || value.isEmpty) return;
    setState(() => _selectedTags.add(value));
  }

  Future<void> _showFolderPicker() async {
    final folders = await ref.read(journalFoldersProvider.future);
    if (!mounted) return;
    final selected = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FolderPickerSheet(
        folders: folders,
        selectedFolderId: _folderId,
        onCreate: () async {
          Navigator.pop(context, -1);
        },
      ),
    );
    if (selected == -1) {
      await _createFolderFromWriter();
      return;
    }
    if (!mounted || selected == null) return;
    final folderId = selected == 0 ? null : selected;
    if (folderId == _folderId) return;
    final folderName = folderId == null
        ? null
        : folders
              .where((folder) => folder.id == folderId)
              .map((folder) => folder.name)
              .first;
    setState(() {
      _folderId = folderId;
      _folderName = folderName;
    });
  }

  Future<void> _createFolderFromWriter() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 16,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: '给这组日记起个名字',
            counterText: '',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    controller.dispose();
    final value = name?.trim();
    if (value == null || value.isEmpty) return;
    final id = await ref
        .read(journalRepositoryProvider)
        .createFolder(name: value);
    ref.invalidate(journalFoldersProvider);
    if (!mounted) return;
    setState(() {
      _folderId = id;
      _folderName = value;
    });
  }
}
