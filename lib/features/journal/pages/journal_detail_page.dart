import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/journal_provider.dart';
import '../widgets/markdown_preview.dart';

/// 心情 emoji 映射
const _moodEmojiMap = {
  'happy': '😊',
  'neutral': '😐',
  'sad': '😢',
  'angry': '😡',
  'thinking': '🤔',
};

/// 心情文字映射
const _moodLabelMap = {
  'happy': '开心',
  'neutral': '平静',
  'sad': '难过',
  'angry': '生气',
  'thinking': '思考',
};

/// 日记详情页
///
/// 沉浸式阅读体验，参考苹果备忘录风格。
class JournalDetailPage extends ConsumerWidget {
  const JournalDetailPage({super.key, required this.journalId});

  final int journalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(journalByIdProvider(journalId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: journalAsync.when(
        data: (journal) {
          if (journal == null) {
            return _buildErrorState(context, '日记不存在');
          }
          return _DetailContent(journal: journal);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildErrorState(context, '加载失败: $e'),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.journal});

  final DailyJournal journal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = _parseTags(journal.tags);
    final createdDt = DateTime.fromMillisecondsSinceEpoch(journal.createdAt);
    final moodEmoji = _moodEmojiMap[journal.mood];
    final moodLabel = _moodLabelMap[journal.mood];

    return Column(
      children: [
        // ── 顶部栏 ──
        _buildTopBar(context, ref),

        // ── 内容区域 ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── 标题 ──
                Text(
                  journal.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2329),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // ── 元信息行 ──
                _buildMetaRow(createdDt, journal.wordCount, moodEmoji, moodLabel),
                const SizedBox(height: 16),

                // ── 分割线 ──
                Container(
                  height: 1,
                  color: const Color(0xFFE5E7EB),
                ),
                const SizedBox(height: 20),

                // ── 正文 ──
                _buildContent(journal),
                const SizedBox(height: 24),

                // ── 图片附件 ──
                FutureBuilder<List<JournalAsset>>(
                  future: ref.read(journalRepositoryProvider).getJournalAssets(journal.id),
                  builder: (context, snapshot) {
                    final assets = snapshot.data ?? [];
                    if (assets.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: assets.map((asset) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              asset.localPath,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.image_not_supported_rounded, size: 24),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),

                // ── 标签 ──
                if (tags.isNotEmpty) ...[
                  _buildTags(tags),
                  const SizedBox(height: 16),
                ],

                // ── 经验值 ──
                _buildExpBadge(journal.expGained),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: const Color(0xFF1F2329),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => context.push('/plan/journal/edit/${journal.id}'),
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.primary,
            ),
            IconButton(
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(DateTime date, int wordCount, String? moodEmoji, String? moodLabel) {
    final dateStr = '${date.month}月${date.day}日 ${_getWeekday(date.weekday)}';
    
    return Row(
      children: [
        Text(
          dateStr,
          style: const TextStyle(fontSize: 13, color: Color(0xFF86909C)),
        ),
        const SizedBox(width: 12),
        Text(
          '$wordCount字',
          style: const TextStyle(fontSize: 13, color: Color(0xFF86909C)),
        ),
        if (moodEmoji != null) ...[
          const SizedBox(width: 12),
          Tooltip(
            message: moodLabel ?? '',
            child: Text(moodEmoji, style: const TextStyle(fontSize: 18)),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(DailyJournal journal) {
    if (journal.contentType == 'quill' && journal.quillDeltaJson != null) {
      return _QuillReadOnlyContent(deltaJson: journal.quillDeltaJson!);
    }

    // Use MarkdownPreview for markdown content
    return JournalMarkdownPreview(
      markdown: journal.content,
    );
  }

  Widget _buildTags(List<String> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.journal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.journal,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpBadge(int exp) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              '+$exp EXP',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekday(int weekday) {
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[weekday - 1];
  }

  List<String> _parseTags(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) return const [];
    try {
      final list = jsonDecode(tagsJson) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除「${journal.title}」吗？\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(journalRepositoryProvider);
        await repo.deleteJournal(journal.id);

        ref.invalidate(recentJournalsProvider);
        ref.invalidate(todayJournalCountProvider);
        ref.invalidate(dashboardProvider);
        ref.invalidate(allJournalTagsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已删除')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }
}

// =============================================================================
// Quill 只读渲染
// =============================================================================

class _QuillReadOnlyContent extends StatefulWidget {
  const _QuillReadOnlyContent({required this.deltaJson});

  final String deltaJson;

  @override
  State<_QuillReadOnlyContent> createState() => _QuillReadOnlyContentState();
}

class _QuillReadOnlyContentState extends State<_QuillReadOnlyContent> {
  late final QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _parseDelta(widget.deltaJson);
    _controller.readOnly = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  QuillController _parseDelta(String json) {
    try {
      final List<dynamic> delta = jsonDecode(json) as List<dynamic>;
      return QuillController(
        document: Document.fromJson(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      final doc = Document()..insert(0, widget.deltaJson);
      return QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: QuillEditor(
        controller: _controller,
        scrollController: ScrollController(),
        focusNode: FocusNode(),
      ),
    );
  }
}
