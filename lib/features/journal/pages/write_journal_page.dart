import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/journal_provider.dart';
import '../../pet/models/pet_event.dart';
import '../../pet/services/pet_event_bus.dart';
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

/// 引导问题
const _guidedQuestions = [
  '今天完成了什么？',
  '今天哪里做得不好？',
  '明天最重要的一件事是什么？',
];

/// 写日记页面（淡粉色风格）
class WriteJournalPage extends ConsumerStatefulWidget {
  const WriteJournalPage({super.key});

  @override
  ConsumerState<WriteJournalPage> createState() => _WriteJournalPageState();
}

class _WriteJournalPageState extends ConsumerState<WriteJournalPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String? _selectedMood;
  final Set<String> _selectedTags = {};
  bool _showGuidedQuestions = true;
  bool _saving = false;
  bool _pickingImage = false;

  /// Image paths picked from the full-screen editor or inline picker,
  /// to be persisted to journal_assets on save.
  final List<String> _pendingImagePaths = [];

  /// Quill delta JSON from the rich text editor
  String? _quillDeltaJson;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正文')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;
      final content = _contentController.text.trim();
      final wordCount = content.length;

      // 生成纯文本（去除 Markdown 标记）
      final plainText = _stripMarkdown(content);

      // Determine content type
      final contentType = _quillDeltaJson != null ? 'quill' : 'markdown';

      final expService = ref.read(expServiceProvider);
      final exp = expService.calculateJournalExp(wordCount: wordCount);

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
          _selectedTags.isEmpty ? null : _selectedTags.join(','),
        ),
        wordCount: Value(wordCount),
        expGained: Value(exp),
        createdAt: nowMs,
        updatedAt: nowMs,
      );

      final journalRepo = ref.read(journalRepositoryProvider);
      final journalId = await journalRepo.insertJournal(companion);

      // Persist picked images to journal_assets
      if (_pendingImagePaths.isNotEmpty) {
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
      }

      final expRepo = ref.read(expRepositoryProvider);
      await expRepo.insertExpLog(
        GrowthExpLogsCompanion.insert(
          sourceType: 'journal',
          sourceId: journalId,
          expValue: exp,
          reason: '日记: ${_titleController.text.trim()} ($wordCount字)',
          createdAt: nowMs,
        ),
      );

      ref.invalidate(recentJournalsProvider);
      ref.invalidate(todayJournalCountProvider);
      ref.invalidate(dashboardProvider);

      if (mounted) {
        // 发送宠物事件
        PetEventBus.instance.emit(PetEvent(
          type: PetEventType.journalCompleted,
          module: 'journal',
          createdAt: DateTime.now(),
        ));

        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已保存，获得 $exp EXP'),
            backgroundColor: const Color(0xFF35C976),
          ),
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
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 移除 Markdown 标记，返回纯文本。
  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '') // 标题
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1') // 粗体
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1') // 斜体
        .replaceAll(RegExp(r'__(.+?)__'), r'$1') // 粗体
        .replaceAll(RegExp(r'_(.+?)_'), r'$1') // 斜体
        .replaceAll(RegExp(r'~~(.+?)~~'), r'$1') // 删除线
        .replaceAll(RegExp(r'^>\s+', multiLine: true), '') // 引用
        .replaceAll(RegExp(r'^[-*+]\s+', multiLine: true), '') // 无序列表
        .replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '') // 有序列表
        .replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1') // 链接
        .replaceAll(RegExp(r'!\[.*?\]\(.+?\)'), '') // 图片
        .replaceAll(RegExp(r'`(.+?)`'), r'$1') // 行内代码
        .replaceAll(RegExp(r'```[\s\S]*?```'), '') // 代码块
        .replaceAll(RegExp(r'---+'), '') // 分割线
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // 多余空行
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text(
          '写日记',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5C3D2E),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF5C3D2E),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 标题 ──
            _buildSectionTitle('标题'),
            const SizedBox(height: 8),
            _buildTitleField(),
            const SizedBox(height: 24),

            // ── 心情选择 ──
            _buildSectionTitle('今天心情'),
            const SizedBox(height: 12),
            _buildMoodSelector(),
            const SizedBox(height: 24),

            // ── 标签选择 ──
            _buildSectionTitle('标签'),
            const SizedBox(height: 12),
            _buildTagSelector(),
            const SizedBox(height: 24),

            // ── 引导问题 ──
            _buildGuidedQuestions(),
            const SizedBox(height: 24),

            // ── 正文 ──
            _buildSectionTitle('正文'),
            const SizedBox(height: 8),
            _buildContentField(),
            const SizedBox(height: 32),

            // ── 保存按钮 ──
            _buildSaveButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8B6F5E),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 标题输入框
  // ---------------------------------------------------------------------------

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8A0BF).withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          hintText: '例如：充实的一天',
          hintStyle: const TextStyle(color: Color(0xFFC9CDD4)),
          prefixIcon: const Icon(
            Icons.title_rounded,
            size: 20,
            color: Color(0xFFE8A0BF),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 心情选择器
  // ---------------------------------------------------------------------------

  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _moods.map((mood) {
        final isSelected = _selectedMood == mood.key;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedMood = (_selectedMood == mood.key) ? null : mood.key;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF0F5) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE8A0BF)
                    : const Color(0xFFE8A0BF).withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? const Color(0xFFE8A0BF) : const Color(0xFF8B6F5E),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // 标签选择器
  // ---------------------------------------------------------------------------

  Widget _buildTagSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presetTags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              if (_selectedTags.contains(tag)) {
                _selectedTags.remove(tag);
              } else {
                _selectedTags.add(tag);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8A0BF) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE8A0BF)
                    : const Color(0xFFE8A0BF).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '#$tag',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? Colors.white : const Color(0xFF8B6F5E),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // 引导问题
  // ---------------------------------------------------------------------------

  Widget _buildGuidedQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _showGuidedQuestions = !_showGuidedQuestions);
          },
          child: Row(
            children: [
              const Text(
                '引导问题',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8B6F5E),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showGuidedQuestions
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: const Color(0xFFB0A09A),
              ),
            ],
          ),
        ),
        if (_showGuidedQuestions) ...[
          const SizedBox(height: 12),
          ..._guidedQuestions.map((question) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  final current = _contentController.text;
                  final prefix = current.isEmpty ? '' : '\n\n';
                  _contentController.text = '$current【$question】\n';
                  _contentController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _contentController.text.length),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE8A0BF).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: Color(0xFFE8A0BF),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          question,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8B6F5E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 正文输入框
  // ---------------------------------------------------------------------------

  Widget _buildContentField() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE8A0BF).withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            controller: _contentController,
            maxLines: 12,
            minLines: 6,
            decoration: InputDecoration(
              hintText: '写下今天的复盘...',
              hintStyle: const TextStyle(color: Color(0xFFC9CDD4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── 图片导入 + 全屏书写 ──
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickingImage ? null : _pickImageInline,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE8A0BF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 18, color: Color(0xFFE8A0BF)),
                      SizedBox(width: 6),
                      Text(
                        '图片导入',
                        style: TextStyle(fontSize: 13, color: Color(0xFF8B6F5E)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _openFullScreenEditor,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8A0BF), Color(0xFFF0C4D4)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8A0BF).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fullscreen_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        '全屏书写',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 全屏编辑器
  // ---------------------------------------------------------------------------

  void _openFullScreenEditor() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => QuillEditorPage(
          initialTitle: _titleController.text,
          initialDeltaJson: _quillDeltaJson,
          onSave: (title, deltaJson, plainText, wordCount, imagePaths) {
            setState(() {
              _titleController.text = title;
              _contentController.text = plainText;
              _quillDeltaJson = deltaJson;
              _pendingImagePaths.addAll(imagePaths);
            });
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 图片选取（正文页内）
  // ---------------------------------------------------------------------------

  Future<void> _pickImageInline() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);

    try {
      final imageService = ref.read(imageServiceProvider);
      final path = await imageService.pickAndSaveImage();
      if (path == null) return; // user cancelled

      setState(() {
        _pendingImagePaths.add(path);
      });

      // Insert markdown image syntax at end of content
      final current = _contentController.text;
      final prefix = current.isEmpty ? '' : '\n';
      _contentController.text = '$current$prefix![image]($path)\n';
      _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _contentController.text.length),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('图片已添加'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  // ---------------------------------------------------------------------------
  // 保存按钮
  // ---------------------------------------------------------------------------

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _saving
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFE8A0BF), Color(0xFFF0C4D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _saving ? const Color(0xFFF0C4D4) : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _saving
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFE8A0BF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '保存日记',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

// =============================================================================
// 心情选项模型
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
