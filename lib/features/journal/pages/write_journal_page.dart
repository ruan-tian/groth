import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/journal_provider.dart';
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
      final exp = expService.calculateJournalExp(wordCount: wordCount);
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
        wordCount: Value(wordCount),
        expGained: Value(exp),
        createdAt: nowMs,
        updatedAt: nowMs,
      );

      final journalId = await journalRepo.insertJournal(companion);

      for (var i = 0; i < _pendingImagePaths.length; i++) {
        await journalRepo.insertJournalAsset(
          JournalAssetsCompanion.insert(
            journalId: journalId,
            localPath: _pendingImagePaths[i],
            sortOrder: Value(i),
            createdAt: nowMs,
          ),
        );
      }

      final expRepo = ref.read(expRepositoryProvider);
      final oldTotal = await expRepo.getTotalExp();
      final oldLevel = expService.calculateLevel(oldTotal);
      await expRepo.insertExpLog(
        GrowthExpLogsCompanion.insert(
          sourceType: 'journal',
          sourceId: journalId,
          expValue: exp,
          reason: '日记: ${_titleController.text.trim()} ($wordCount字)',
          createdAt: nowMs,
        ),
      );

      final newLevel = expService.calculateLevel(oldTotal + exp);
      if (newLevel > oldLevel) {
        PetEventBus.instance.emit(
          PetEvent.levelUp(oldLevel: oldLevel, newLevel: newLevel),
        );
      }

      ref.invalidate(recentJournalsProvider);
      ref.invalidate(todayJournalCountProvider);
      ref.invalidate(allJournalTagsProvider);
      ref.invalidate(journalStreakProvider);
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
          backgroundColor: const Color(0xFF35C976),
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
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
            setState(() {
              _titleController.text = title;
              _contentController.text = plainText.trim();
              _quillDeltaJson = deltaJson;
              _pendingImagePaths.addAll(imagePaths);
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
        _pendingImagePaths.add(path);
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
    final streak =
        ref.watch(journalStreakProvider).whenOrNull(data: (v) => v) ?? 0;

    return Scaffold(
      backgroundColor: JournalColors.bg,
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
}
