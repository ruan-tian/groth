import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/journal_provider.dart';
import '../../../shared/providers/service_providers.dart';
import '../../pet/models/pet_event.dart';
import '../../pet/services/pet_event_bus.dart';
import '../../pet/utils/pet_assets.dart';
import '../utils/journal_constants.dart';
import '../widgets/journal_colors.dart';
import 'quill_editor_page.dart';

/// 引导问题（固定 3 条）
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

  // ===========================================================================
  // _save() — 业务逻辑，不可改动
  // ===========================================================================

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
          _selectedTags.isEmpty ? null : jsonEncode(_selectedTags.toList()),
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

      final newTotal = oldTotal + exp;
      final newLevel = expService.calculateLevel(newTotal);
      if (newLevel > oldLevel) {
        PetEventBus.instance.emit(PetEvent.levelUp(
          oldLevel: oldLevel,
          newLevel: newLevel,
        ));
      }

      ref.invalidate(recentJournalsProvider);
      ref.invalidate(todayJournalCountProvider);
      ref.invalidate(dashboardProvider);

      if (mounted) {
        // 发送宠物事件
        final eventId = 'journal_${DateTime.now().millisecondsSinceEpoch}';
        PetEventBus.instance.emit(PetEvent.moduleCompleted(
          eventId: eventId,
          type: PetEventType.journalCompleted,
          module: 'journal',
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

  // ===========================================================================
  // 全屏编辑器
  // ===========================================================================

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

  // ===========================================================================
  // 图片选取（正文页内）
  // ===========================================================================

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

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JournalColors.bg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 甜甜陪伴 ──
            const _TiantianCompanionSection(),
            const SizedBox(height: 24),

            // ── 标题 ──
            _buildLabel('标题'),
            const SizedBox(height: 8),
            _buildTitleField(),
            const SizedBox(height: 24),

            // ── 心情选择 ──
            _buildLabel('今天心情'),
            const SizedBox(height: 12),
            _buildMoodSelector(),
            const SizedBox(height: 24),

            // ── 标签选择 ──
            _buildLabel('标签'),
            const SizedBox(height: 12),
            _buildTagSelector(),
            const SizedBox(height: 24),

            // ── 引导问题 ──
            _buildGuidedQuestions(),
            const SizedBox(height: 24),

            // ── 正文 ──
            _buildLabel('正文'),
            const SizedBox(height: 8),
            _buildContentField(),
            const SizedBox(height: 20),

            // ── 工具按钮 ──
            _buildToolButtons(),
            const SizedBox(height: 24),

            // ── 底部操作按钮 ──
            _buildSaveButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: JournalColors.textDark,
        onPressed: () => context.pop(),
      ),
      title: const Text(
        '写日记',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: JournalColors.textDark,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.save_rounded, size: 24),
          color: JournalColors.pinkMain,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Label helper
  // ---------------------------------------------------------------------------

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: JournalColors.textSecondary,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 标题输入框
  // ---------------------------------------------------------------------------

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        hintText: '例如：充实的一天',
        hintStyle: const TextStyle(color: JournalColors.textMuted),
        prefixIcon: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: JournalColors.pinkBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('T', style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: JournalColors.pinkMain,
            )),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 40),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: JournalColors.pinkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: JournalColors.pinkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: JournalColors.pinkMain, width: 1.5),
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
      children: moodOptions.map((mood) {
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
            width: 62,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? JournalColors.pinkBg : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? JournalColors.pinkMain
                    : JournalColors.pinkBorder,
                width: isSelected ? 1.5 : 1,
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
                    color: isSelected
                        ? JournalColors.pinkMain
                        : JournalColors.textSecondary,
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
      children: presetTags.map((tag) {
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
              color: isSelected ? JournalColors.pinkBg : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? JournalColors.pinkMain
                    : JournalColors.pinkBorder,
              ),
            ),
            child: Text(
              '#$tag',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected
                    ? JournalColors.pinkMain
                    : JournalColors.textSecondary,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: JournalColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showGuidedQuestions
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: JournalColors.textMuted,
              ),
            ],
          ),
        ),
        if (_showGuidedQuestions) ...[
          const SizedBox(height: 12),
          ..._guidedQuestions.map((question) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: JournalColors.pinkBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.push_pin_rounded,
                        size: 18,
                        color: JournalColors.pinkSoft,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question,
                          style: const TextStyle(
                            fontSize: 13,
                            color: JournalColors.textDark,
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
    return Stack(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 220),
          child: TextField(
            controller: _contentController,
            maxLines: null,
            minLines: 8,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '写下今天的复盘...',
              hintStyle: const TextStyle(color: JournalColors.textMuted),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: JournalColors.pinkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: JournalColors.pinkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    const BorderSide(color: JournalColors.pinkMain, width: 1.5),
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Opacity(
            opacity: 0.45,
            child: Image.asset(
              PetAssets.journalWriting,
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 工具按钮
  // ---------------------------------------------------------------------------

  Widget _buildToolButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickingImage ? null : _pickImageInline,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: JournalColors.pinkBorder),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 18, color: JournalColors.textDark),
                  SizedBox(width: 6),
                  Text(
                    '📷 图片导入',
                    style: TextStyle(fontSize: 13, color: JournalColors.textDark),
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: JournalColors.pinkBorder),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note_rounded, size: 18, color: JournalColors.textDark),
                  SizedBox(width: 6),
                  Text(
                    '🔲 全屏书写',
                    style: TextStyle(fontSize: 13, color: JournalColors.textDark),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 保存按钮
  // ---------------------------------------------------------------------------

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: _saving ? null : JournalColors.heroGradient,
          color: _saving ? JournalColors.pinkSoft : null,
          borderRadius: BorderRadius.circular(999),
          boxShadow: _saving
              ? null
              : [
                  BoxShadow(
                    color: JournalColors.pinkMain.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
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
                  '✓ 保存日记',
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
// 甜甜陪伴区域
// =============================================================================

class _TiantianCompanionSection extends StatelessWidget {
  const _TiantianCompanionSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: JournalColors.companionGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: JournalColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Speech bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: JournalColors.pinkMain.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '甜甜在这里陪着你 ✨',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: JournalColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '今天也要好好记录自己的小美好哦～',
                  style: TextStyle(
                    fontSize: 12,
                    color: JournalColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Cat image + hearts
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                PetAssets.journalWriting,
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 100,
                  height: 100,
                  child: Center(
                    child: Icon(Icons.pets_rounded,
                        size: 50, color: JournalColors.pinkSoft),
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: 10,
                child: Icon(Icons.favorite, size: 14,
                    color: JournalColors.pinkMain.withValues(alpha: 0.4)),
              ),
              Positioned(
                top: 10,
                left: -8,
                child: Icon(Icons.favorite, size: 10,
                    color: JournalColors.pinkSoft.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
