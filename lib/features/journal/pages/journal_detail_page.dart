import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../models/journal_data.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../journal/providers/journal_provider.dart';
import '../providers/journal_stats_provider.dart';
import '../widgets/journal_colors.dart';
import '../widgets/journal_safe_image.dart';
import '../widgets/markdown_preview.dart';

const _moodEmojiMap = {
  'happy': '😊',
  'calm': '😌',
  'neutral': '😐',
  'sad': '😢',
  'great': '🥳',
  'angry': '😠',
  'thinking': '🤔',
};

const _moodLabelMap = {
  'happy': '开心',
  'calm': '平静',
  'neutral': '一般',
  'sad': '难过',
  'great': '很棒',
  'angry': '生气',
  'thinking': '思考中',
};

class JournalDetailPage extends ConsumerWidget {
  const JournalDetailPage({super.key, required this.journalId});

  final int journalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(journalByIdProvider(journalId));

    return Scaffold(
      backgroundColor: JournalColors.bg,
      body: journalAsync.when(
        data: (journal) {
          if (journal == null) {
            return _ErrorState(message: '日记不存在', onBack: context.pop);
          }
          return _DetailContent(journal: journal);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: '加载失败: $e', onBack: context.pop),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: context.growthColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(onPressed: onBack, child: const Text('返回')),
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

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 96, 24, 36),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: _ReadingCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            journal.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: context.growthColors.textPrimary,
                              height: 1.22,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _MetaRow(
                            date: createdDt,
                            wordCount: journal.wordCount,
                            moodEmoji: moodEmoji,
                            moodLabel: moodLabel,
                          ),
                          const SizedBox(height: 16),
                          Container(height: 1, color: JournalColors.pinkBorder),
                          const SizedBox(height: 20),
                          _JournalBody(journal: journal),
                          const SizedBox(height: 24),
                          _JournalAssetsWrap(journalId: journal.id),
                          if (tags.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _TagWrap(tags: tags),
                          ],
                          const SizedBox(height: 20),
                          _ExpBadge(exp: journal.expGained),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        _FloatingTopBar(journal: journal),
      ],
    );
  }

  List<String> _parseTags(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return raw.split(',').where((tag) => tag.trim().isNotEmpty).toList();
    }
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.growthColors.paper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: JournalColors.pinkBorder),
        boxShadow: [
          BoxShadow(
            color: JournalColors.pinkMain.withValues(alpha: 0.06),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
        child: child,
      ),
    );
  }
}

class _FloatingTopBar extends ConsumerWidget {
  const _FloatingTopBar({required this.journal});

  final DailyJournal journal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Container(
        height: 58,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: context.growthColors.card.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(22),
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
            IconButton(
              tooltip: '返回',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: context.growthColors.textPrimary,
            ),
            const Spacer(),
            IconButton(
              tooltip: '移动到文件夹',
              onPressed: () => _showMoveSheet(context, ref),
              icon: const Icon(Icons.folder_copy_outlined, size: 20),
              color: JournalColors.pinkMain,
            ),
            IconButton(
              tooltip: '编辑',
              onPressed: () => context.push('/plan/journal/edit/${journal.id}'),
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: context.growthColors.primary,
            ),
            IconButton(
              tooltip: '删除',
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline, size: 20),
              color: context.growthColors.danger,
            ),
          ],
        ),
      ),
    );
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
            style: TextButton.styleFrom(
              foregroundColor: context.growthColors.danger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      final repo = ref.read(journalRepositoryProvider);
      await repo.deleteJournal(journal.id);
      _invalidateJournalProviders(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已删除')));
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败，请重试')));
      }
    }
  }

  Future<void> _showMoveSheet(BuildContext context, WidgetRef ref) async {
    final folders = await ref.read(journalFoldersProvider.future);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: JournalColors.bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: JournalColors.pinkBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '移动日记',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                _MoveTargetListTile(
                  title: '未分类',
                  selected: journal.folderId == null,
                  onTap: () => _moveToFolder(sheetContext, ref, null),
                ),
                ...folders.map(
                  (folder) => _MoveTargetListTile(
                    title: folder.name,
                    selected: journal.folderId == folder.id,
                    onTap: () => _moveToFolder(sheetContext, ref, folder.id),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _moveToFolder(
    BuildContext context,
    WidgetRef ref,
    int? folderId,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref
          .read(journalRepositoryProvider)
          .moveJournalToFolder(journal.id, folderId);
      ref.invalidate(journalByIdProvider(journal.id));
      ref.invalidate(journalsByFolderProvider);
      ref.invalidate(recentJournalsProvider);
      ref.invalidate(dashboardProvider);
      if (context.mounted) Navigator.pop(context);
      messenger?.showSnackBar(const SnackBar(content: Text('已移动日记')));
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text('移动失败，请重试')));
    }
  }

  void _invalidateJournalProviders(WidgetRef ref) {
    ref.invalidate(recentJournalsProvider);
    ref.invalidate(journalsByFolderProvider);
    ref.invalidate(todayJournalCountProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(allJournalTagsProvider);
    ref.invalidate(totalJournalCountProvider);
    ref.invalidate(monthlyJournalCountProvider);
    ref.invalidate(journalHeatmapProvider);
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.date,
    required this.wordCount,
    required this.moodEmoji,
    required this.moodLabel,
  });

  final DateTime date;
  final int wordCount;
  final String? moodEmoji;
  final String? moodLabel;

  @override
  Widget build(BuildContext context) {
    final dateStr = '${date.month}月${date.day}日 ${_weekday(date.weekday)}';
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          dateStr,
          style: TextStyle(
            fontSize: 13,
            color: context.growthColors.textTertiary,
          ),
        ),
        Text(
          '$wordCount字',
          style: TextStyle(
            fontSize: 13,
            color: context.growthColors.textTertiary,
          ),
        ),
        if (moodEmoji != null)
          Tooltip(
            message: moodLabel ?? '',
            child: Text(moodEmoji!, style: const TextStyle(fontSize: 18)),
          ),
      ],
    );
  }

  String _weekday(int weekday) {
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[weekday - 1];
  }
}

class _JournalBody extends StatelessWidget {
  const _JournalBody({required this.journal});

  final DailyJournal journal;

  @override
  Widget build(BuildContext context) {
    if (journal.contentType == 'quill' && journal.quillDeltaJson != null) {
      return _QuillReadOnlyContent(deltaJson: journal.quillDeltaJson!);
    }
    return JournalMarkdownPreview(markdown: journal.content);
  }
}

class _JournalAssetsWrap extends ConsumerWidget {
  const _JournalAssetsWrap({required this.journalId});

  final int journalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<JournalAsset>>(
      future: ref.read(journalRepositoryProvider).getJournalAssets(journalId),
      builder: (context, snapshot) {
        final assets = snapshot.data ?? [];
        if (assets.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: assets.map((asset) {
            return JournalSafeImage(
              path: asset.localPath,
              width: 100,
              height: 100,
              maxHeight: 100,
              fit: BoxFit.cover,
              borderRadius: 12,
              cacheWidth: 300,
            );
          }).toList(),
        );
      },
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.growthColors.journal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              fontSize: 13,
              color: context.growthColors.journal,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ExpBadge extends StatelessWidget {
  const _ExpBadge({required this.exp});

  final int exp;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.growthColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 18,
              color: context.growthColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '+$exp EXP',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.growthColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveTargetListTile extends StatelessWidget {
  const _MoveTargetListTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.folder_rounded : Icons.folder_outlined,
        color: selected
            ? JournalColors.pinkMain
            : context.growthColors.textTertiary,
      ),
      title: Text(title),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: JournalColors.pinkMain,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _QuillReadOnlyContent extends StatefulWidget {
  const _QuillReadOnlyContent({required this.deltaJson});

  final String deltaJson;

  @override
  State<_QuillReadOnlyContent> createState() => _QuillReadOnlyContentState();
}

class _QuillReadOnlyContentState extends State<_QuillReadOnlyContent> {
  late final QuillController _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = _parseDelta(widget.deltaJson);
    _controller.readOnly = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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
    return RepaintBoundary(
      child: QuillEditor(
        controller: _controller,
        scrollController: _scrollController,
        focusNode: _focusNode,
        config: const QuillEditorConfig(
          scrollPhysics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          embedBuilders: [JournalQuillImageEmbedBuilder()],
        ),
      ),
    );
  }
}
