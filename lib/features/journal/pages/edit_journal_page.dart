import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart';
import 'quill_editor_page.dart';

/// 心情选项
const _moods = [
  _MoodOption(key: 'happy', emoji: '😊', label: '开心'),
  _MoodOption(key: 'neutral', emoji: '😐', label: '平静'),
  _MoodOption(key: 'sad', emoji: '😢', label: '难过'),
  _MoodOption(key: 'angry', emoji: '😡', label: '生气'),
  _MoodOption(key: 'thinking', emoji: '🤔', label: '思考'),
];

/// 预设标签
const _presetTags = [
  '学习',
  '健身',
  '情绪',
  '反思',
  '感恩',
  '目标',
  '阅读',
  '工作',
];

/// 编辑日记页面
///
/// 复用 WriteJournalPage 的表单结构，接收现有日记数据进行编辑。
class EditJournalPage extends ConsumerStatefulWidget {
  const EditJournalPage({super.key, required this.journalId});

  final int journalId;

  @override
  ConsumerState<EditJournalPage> createState() => _EditJournalPageState();
}

class _EditJournalPageState extends ConsumerState<EditJournalPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String? _selectedMood;
  final Set<String> _selectedTags = {};
  bool _saving = false;
  bool _loading = true;

  // 编辑模式下保留的原始数据
  int? _createdAt;
  int? _originalExpGained;

  // Quill 富文本支持
  String _contentType = 'markdown';
  String? _quillDeltaJson;

  @override
  void initState() {
    super.initState();
    _loadJournal();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 加载现有日记数据
  // ---------------------------------------------------------------------------

  Future<void> _loadJournal() async {
    try {
      final repo = ref.read(journalRepositoryProvider);
      final journal = await repo.getJournalById(widget.journalId);

      if (journal != null && mounted) {
        setState(() {
          _titleController.text = journal.title;
          _contentController.text = journal.content;
          _selectedMood = journal.mood;
          _createdAt = journal.createdAt;
          _originalExpGained = journal.expGained;
          _contentType = journal.contentType;
          _quillDeltaJson = journal.quillDeltaJson;

          // 解析标签
          if (journal.tags != null && journal.tags!.isNotEmpty) {
            try {
              final list = jsonDecode(journal.tags!) as List<dynamic>;
              _selectedTags.addAll(list.map((e) => e.toString()));
            } catch (_) {
              // skip malformed tags
            }
          }

          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载日记失败: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 保存（更新）
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;
      final content = _contentController.text.trim();
      final wordCount = content.length;

      // 重新计算经验值
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

      // 更新日记
      final journalRepo = ref.read(journalRepositoryProvider);
      await journalRepo.updateJournal(companion);

      // 如果经验值有变化，更新经验日志
      if (_originalExpGained != null && _originalExpGained != exp) {
        final expDiff = exp - _originalExpGained!;
        final expRepo = ref.read(expRepositoryProvider);
        await expRepo.insertExpLog(
          GrowthExpLogsCompanion.insert(
            sourceType: 'journal_edit',
            sourceId: widget.journalId,
            expValue: expDiff,
            reason: '日记编辑: ${_titleController.text.trim()} ($wordCount字)',
            createdAt: nowMs,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已更新，经验值 $exp EXP')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ---------------------------------------------------------------------------
  // 打开全屏 Quill 编辑器
  // ---------------------------------------------------------------------------

  void _openQuillEditor() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => QuillEditorPage(
          initialTitle: _titleController.text,
          initialDeltaJson: _quillDeltaJson,
          onSave: (title, deltaJson, plainText, wordCount, imagePaths) {
            setState(() {
              _titleController.text = title;
              _contentController.text = plainText;
              _quillDeltaJson = deltaJson;
              _contentType = 'quill';
            });
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('编辑日记'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑日记'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          children: [
            // ── 标题 ──
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题 *',
                hintText: '例如：充实的一天',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入标题' : null,
            ),
            const SizedBox(height: AppTheme.spaceLg),

            // ── 心情选择 ──
            Text('今天心情', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.spaceSm),
            _MoodSelector(
              selectedMood: _selectedMood,
              onMoodSelected: (mood) {
                setState(() {
                  _selectedMood = (_selectedMood == mood) ? null : mood;
                });
              },
            ),
            const SizedBox(height: AppTheme.spaceLg),

            // ── 标签选择 ──
            Text('标签', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.spaceSm),
            _TagSelector(
              tags: _presetTags,
              selectedTags: _selectedTags,
              onTagToggled: (tag) {
                setState(() {
                  if (_selectedTags.contains(tag)) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
            ),
            const SizedBox(height: AppTheme.spaceLg),

            // ── 正文 ──
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '正文 *',
                hintText: '写下今天的复盘...',
                alignLabelWithHint: true,
              ),
              maxLines: 12,
              minLines: 6,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入正文' : null,
            ),
            const SizedBox(height: AppTheme.spaceMd),

            // ── 全屏编辑按钮 ──
            OutlinedButton.icon(
              onPressed: _openQuillEditor,
              icon: const Icon(Icons.fullscreen, size: 20),
              label: Text(
                _contentType == 'quill' ? '继续富文本编辑' : '全屏编辑（富文本）',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: GrowthColors.journalPrimary,
                side: BorderSide(color: GrowthColors.journalPrimary),
              ),
            ),
            if (_contentType == 'quill') ...[
              const SizedBox(height: AppTheme.spaceXs),
              Text(
                '当前为富文本格式',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: GrowthColors.journalPrimary,
                    ),
              ),
            ],
            const SizedBox(height: AppTheme.spaceXl),

            // ── 保存按钮 ──
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: GrowthColors.journalPrimary,
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('保存修改'),
            ),
            const SizedBox(height: AppTheme.spaceLg),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 心情选择器
// =============================================================================

class _MoodOption {
  const _MoodOption({
    required this.key,
    required this.emoji,
    required this.label,
  });

  final String key;
  final String emoji;
  final String label;
}

class _MoodSelector extends StatelessWidget {
  const _MoodSelector({
    required this.selectedMood,
    required this.onMoodSelected,
  });

  final String? selectedMood;
  final ValueChanged<String> onMoodSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _moods.map((mood) {
        final isSelected = selectedMood == mood.key;
        return GestureDetector(
          onTap: () => onMoodSelected(mood.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceSm,
              vertical: AppTheme.spaceSm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: isSelected
                  ? Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: AppTheme.spaceXs),
                Text(
                  mood.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// 标签选择器
// =============================================================================

class _TagSelector extends StatelessWidget {
  const _TagSelector({
    required this.tags,
    required this.selectedTags,
    required this.onTagToggled,
  });

  final List<String> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spaceSm,
      runSpacing: AppTheme.spaceXs,
      children: tags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (_) => onTagToggled(tag),
          selectedColor: GrowthColors.journalLight,
          checkmarkColor: GrowthColors.journalPrimary,
        );
      }).toList(),
    );
  }
}
