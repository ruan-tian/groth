import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/journal_provider.dart';
import '../providers/journal_stats_provider.dart';
import '../utils/journal_assets.dart' as journal_images;
import '../utils/journal_constants.dart';
import '../widgets/journal_colors.dart';
import 'quill_editor_page.dart';

class EditJournalPage extends ConsumerStatefulWidget {
  const EditJournalPage({super.key, required this.journalId});

  final int journalId;

  @override
  ConsumerState<EditJournalPage> createState() => _EditJournalPageState();
}

class _EditJournalPageState extends ConsumerState<EditJournalPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String? _selectedMood;
  final Set<String> _selectedTags = {};
  bool _saving = false;
  bool _loading = true;
  int? _createdAt;
  int? _originalExpGained;
  String? _originalContent;
  String _contentType = 'markdown';
  String? _quillDeltaJson;
  bool _openedQuillEditor = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_rebuild);
    _contentController.addListener(_rebuild);
    _loadJournal();
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

  Future<void> _loadJournal() async {
    try {
      final repo = ref.read(journalRepositoryProvider);
      final journal = await repo.getJournalById(widget.journalId);
      if (journal == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      if (!mounted) return;
      setState(() {
        _titleController.text = journal.title;
        _contentController.text = journal.content;
        _selectedMood = journal.mood;
        _createdAt = journal.createdAt;
        _originalExpGained = journal.expGained;
        _originalContent = journal.content;
        _contentType = journal.contentType;
        _quillDeltaJson = journal.quillDeltaJson;
        _selectedTags
          ..clear()
          ..addAll(_parseTags(journal.tags));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载日记失败: $e')));
    }
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

      if (content != (_originalContent ?? '').trim() && !_openedQuillEditor) {
        _contentType = 'markdown';
        _quillDeltaJson = null;
      }

      final expService = ref.read(expServiceProvider);
      final exp = expService.calculateJournalExp(wordCount: wordCount);
      final companion = DailyJournalsCompanion(
        id: Value(widget.journalId),
        journalDate: Value(_formatDate(now)),
        title: Value(_titleController.text.trim()),
        content: Value(content),
        contentType: Value(_contentType),
        quillDeltaJson: Value(_quillDeltaJson),
        markdownContent: Value(_contentType == 'markdown' ? content : null),
        plainText: Value(content),
        mood: Value(_selectedMood),
        tags: Value(
          _selectedTags.isEmpty ? null : jsonEncode(_selectedTags.toList()),
        ),
        wordCount: Value(wordCount),
        expGained: Value(exp),
        createdAt: Value(_createdAt ?? nowMs),
        updatedAt: Value(nowMs),
      );

      final journalRepo = ref.read(journalRepositoryProvider);
      await journalRepo.updateJournal(companion);

      if (_originalExpGained != null && _originalExpGained != exp) {
        final expRepo = ref.read(expRepositoryProvider);
        await expRepo.insertExpLog(
          GrowthExpLogsCompanion.insert(
            sourceType: 'journal',
            sourceId: widget.journalId,
            expValue: exp - _originalExpGained!,
            reason: '日记编辑: ${_titleController.text.trim()} ($wordCount字)',
            createdAt: nowMs,
          ),
        );
      }

      ref.invalidate(recentJournalsProvider);
      ref.invalidate(todayJournalCountProvider);
      ref.invalidate(allJournalTagsProvider);
      ref.invalidate(journalStreakProvider);
      ref.invalidate(dashboardProvider);

      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已更新，当前经验 $exp EXP')));
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

  void _openQuillEditor() {
    _openedQuillEditor = true;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => QuillEditorPage(
          initialTitle: _titleController.text,
          initialPlainText: _contentController.text,
          initialDeltaJson: _quillDeltaJson,
          onSave: (title, deltaJson, plainText, wordCount, imagePaths) {
            setState(() {
              _titleController.text = title;
              _contentController.text = plainText.trim();
              _quillDeltaJson = deltaJson;
              _contentType = 'quill';
            });
          },
        ),
      ),
    );
  }

  List<String> _parseTags(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      }
    } catch (_) {}
    return raw
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int get wordCount => _contentController.text.trim().length;

  int get estimatedExp =>
      ref.read(expServiceProvider).calculateJournalExp(wordCount: wordCount);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: JournalColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: JournalColors.pinkMain),
        ),
      );
    }

    return Scaffold(
      backgroundColor: JournalColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EditTopBar(
                    onBack: () => context.pop(),
                    onSave: _saving ? null : _save,
                  ),
                  const SizedBox(height: 22),
                  _MoodSelector(
                    selectedMood: _selectedMood,
                    onSelected: (mood) {
                      setState(
                        () =>
                            _selectedMood = _selectedMood == mood ? null : mood,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _PaperEditor(
                    titleController: _titleController,
                    contentController: _contentController,
                    wordCount: wordCount,
                    onOpenEditor: _openQuillEditor,
                  ),
                  const SizedBox(height: 18),
                  _TagEditor(
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
                  _ExpPreview(wordCount: wordCount, exp: estimatedExp),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      backgroundColor: JournalColors.pinkMain,
                      shape: const StadiumBorder(),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '保存修改',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditTopBar extends StatelessWidget {
  const _EditTopBar({required this.onBack, required this.onSave});

  final VoidCallback onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _SquareButton(
              icon: Icons.chevron_left_rounded,
              onTap: onBack,
              color: JournalColors.textDark,
            ),
          ),
          const Text(
            '编辑日记',
            style: TextStyle(
              color: JournalColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _SquareButton(
              icon: Icons.save_rounded,
              onTap: onSave,
              color: JournalColors.pinkMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodSelector extends StatelessWidget {
  const _MoodSelector({required this.selectedMood, required this.onSelected});

  final String? selectedMood;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今天的心情是？',
            style: TextStyle(color: JournalColors.textDark, fontSize: 15),
          ),
          const SizedBox(height: 16),
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
                      height: 90,
                      decoration: BoxDecoration(
                        color: selected ? JournalColors.pinkBg : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? JournalColors.pinkSoft
                              : JournalColors.pinkBorder,
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
                                  ? JournalColors.pinkMain
                                  : JournalColors.textSecondary,
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

class _PaperEditor extends StatelessWidget {
  const _PaperEditor({
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
                  style: const TextStyle(
                    color: JournalColors.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    hintText: '今天的小确幸',
                    border: InputBorder.none,
                  ),
                ),
              ),
              _SquareButton(
                icon: Icons.open_in_full_rounded,
                onTap: onOpenEditor,
                color: JournalColors.pinkMain,
                small: true,
              ),
            ],
          ),
          const Divider(color: JournalColors.pinkBorder, height: 28),
          Stack(
            children: [
              CustomPaint(
                painter: _PaperLinesPainter(),
                child: TextField(
                  controller: contentController,
                  minLines: 12,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    color: JournalColors.textDark,
                    fontSize: 18,
                    height: 2.05,
                  ),
                  decoration: const InputDecoration(
                    hintText: '继续记录今天的小美好...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(2, 4, 2, 112),
                  ),
                ),
              ),
              Positioned(
                right: -8,
                bottom: -4,
                child: IgnorePointer(
                  child: Image.asset(
                    journal_images.JournalAssets.catWriting,
                    width: 148,
                    height: 148,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
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

class _TagEditor extends StatelessWidget {
  const _TagEditor({required this.selectedTags, required this.onToggle});

  final Set<String> selectedTags;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presetTags.map((tag) {
        final selected = selectedTags.contains(tag);
        return FilterChip(
          label: Text(tag),
          selected: selected,
          onSelected: (_) => onToggle(tag),
          backgroundColor: Colors.white,
          selectedColor: JournalColors.pinkBg,
          checkmarkColor: JournalColors.pinkMain,
          side: BorderSide(
            color: selected ? JournalColors.pinkSoft : JournalColors.pinkBorder,
          ),
        );
      }).toList(),
    );
  }
}

class _ExpPreview extends StatelessWidget {
  const _ExpPreview({required this.wordCount, required this.exp});

  final int wordCount;
  final int exp;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        children: [
          Expanded(
            child: _MiniMetric(
              icon: Icons.text_fields_rounded,
              value: '$wordCount 字',
              label: '本次字数',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MiniMetric(
              icon: Icons.star_rounded,
              value: '+$exp EXP',
              label: '当前经验',
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: JournalColors.pinkBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: JournalColors.pinkMain),
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
                style: const TextStyle(
                  color: JournalColors.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: JournalColors.textSecondary),
              ),
            ],
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: JournalColors.pinkBorder),
        boxShadow: [
          BoxShadow(
            color: JournalColors.pinkMain.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.small = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 40.0 : 52.0;
    return Material(
      color: Colors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(small ? 12 : 18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(small ? 12 : 18),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: onTap == null ? JournalColors.textMuted : color,
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
