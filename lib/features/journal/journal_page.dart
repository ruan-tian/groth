import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../core/database/app_database.dart';
import '../../../core/constants/pet_assets.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/journal_provider.dart';
import '../../shared/widgets/sort_button.dart';
import '../../shared/widgets/swipe_delete_tile.dart';
import '../pet/models/pet_scene_model.dart';
import '../../shared/providers/pet_scene_provider.dart';
import '../plan/utils/plan_module_assets.dart';
import '../plan/widgets/plan_module_visuals.dart';
import 'providers/journal_stats_provider.dart';
import 'utils/journal_constants.dart';
import 'widgets/journal_colors.dart';
import '../statistics/widgets/heatmap_calendar.dart';

part 'widgets/journal_page_widgets.dart';

// =============================================================================
// JournalPage
// =============================================================================

class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final allTags = ref.watch(allJournalTagsProvider);
    final todayCount = ref.watch(todayJournalCountProvider);
    final streak = ref.watch(journalStreakProvider);
    final totalCount = ref.watch(totalJournalCountProvider);
    final monthlyCount = ref.watch(monthlyJournalCountProvider);
    final folders = ref.watch(journalFoldersProvider);
    final selectedFolder = ref.watch(selectedJournalFolderProvider);

    final source = _selectedTag == null
        ? ref.watch(journalsByFolderProvider(selectedFolder))
        : ref.watch(journalsByTagProvider(_selectedTag!));

    final sort = ref.watch(journalSortProvider);
    final journals = source.whenData((items) {
      final sorted = List<DailyJournal>.from(items);
      switch (sort) {
        case SortOption.newest:
          sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case SortOption.oldest:
          sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case SortOption.highestExp:
          sorted.sort((a, b) => b.expGained.compareTo(a.expGained));
          break;
      }
      return sorted;
    });

    return Scaffold(
      backgroundColor: JournalColors.bg,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('成长日记', style: AppTextStyles.sectionTitle),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: JournalColors.textDark,
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                SortButton(
                  currentSort: sort,
                  onSortChanged: (s) =>
                      ref.read(journalSortProvider.notifier).state = s,
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: RefreshIndicator(
        color: JournalColors.pinkMain,
        onRefresh: () async {
          ref.invalidate(recentJournalsProvider);
          ref.invalidate(allJournalTagsProvider);
          ref.invalidate(todayJournalCountProvider);
          ref.invalidate(journalStreakProvider);
          ref.invalidate(totalJournalCountProvider);
          ref.invalidate(monthlyJournalCountProvider);
          ref.invalidate(journalFoldersProvider);
          ref.invalidate(journalsByFolderProvider);
          ref.invalidate(journalHeatmapProvider);
          if (_selectedTag != null) {
            ref.invalidate(journalsByTagProvider(_selectedTag!));
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. 甜甜陪伴卡 ──
              PlanModuleVisualHeader(
                module: PlanModuleType.journal,
                color: JournalColors.pinkMain,
              ),
              const SizedBox(height: 16),

              // ── 2. 今日记录 Hero ──
              _buildTodayRecordCard(context, todayCount),
              const SizedBox(height: 20),

              const SizedBox.shrink(),
              const SizedBox.shrink(),

              // ── 3. 标签筛选 ──
              const SizedBox.shrink(),
              const SizedBox(height: 0),

              // ── 4. 统计卡片 ──
              _StatsRow(
                monthlyCount: monthlyCount,
                totalCount: totalCount,
                streak: streak,
              ),
              const SizedBox(height: 20),

              // ── 5. 写作热力图 ──
              const _JournalHeatmapSection(),
              const SizedBox(height: 20),

              // ── 6. 最近日记列表 ──
              _buildRecentJournalFilters(folders, selectedFolder, allTags),
              const SizedBox(height: 14),
              journals.when(
                data: (list) {
                  if (list.isEmpty) return _buildEmptyState();
                  return Column(
                    children: List.generate(list.length, (index) {
                      final journal = list[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400 + index * 60),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: SwipeDeleteTile(
                          key: ValueKey('journal_${journal.id}'),
                          onConfirmDelete: () async {
                            _deleteJournal(context, ref, journal);
                            return false;
                          },
                          onDismissed: () {},
                          child: _JournalListItem(
                            journal: journal,
                            onMove: () => _showMoveJournalSheet(journal),
                            onTap: () => context.push(
                              '/plan/journal/detail/${journal.id}',
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: JournalColors.pinkMain,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      '加载失败: $e',
                      style: const TextStyle(
                        color: JournalColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
    );
  }

  // ---------------------------------------------------------------------------
  // Today Record Card
  // ---------------------------------------------------------------------------

  Widget _buildTodayRecordCard(
    BuildContext context,
    AsyncValue<int> todayCount,
  ) {
    final count = todayCount.whenOrNull(data: (c) => c) ?? 0;

    return PlanModuleActionImageCard(
      module: PlanModuleType.journal,
      color: JournalColors.pinkMain,
      onTap: () => context.push('/plan/journal/write'),
      title: '今日记录',
      caption: count > 0 ? '已记录 $count 篇，继续把今天留在纸上' : '开始记录今天的成长',
      buttonLabel: '开始写日记',
      height: 180,
    );
  }

  // ---------------------------------------------------------------------------
  // Folder Filter
  // ---------------------------------------------------------------------------

  Widget _buildFolderFilter(
    AsyncValue<List<JournalFolder>> folders,
    JournalFolderSelection selectedFolder,
  ) {
    return folders.when(
      data: (items) {
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length + 3,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _TagChip(
                  label: '全部',
                  selected: selectedFolder.kind == JournalFolderFilterKind.all,
                  onTap: () =>
                      _selectFolder(const JournalFolderSelection.all()),
                );
              }
              if (index == 1) {
                return _TagChip(
                  label: '未分类',
                  selected:
                      selectedFolder.kind ==
                      JournalFolderFilterKind.uncategorized,
                  onTap: () => _selectFolder(
                    const JournalFolderSelection.uncategorized(),
                  ),
                );
              }
              if (index == items.length + 2) {
                return _TagChip(
                  label: '+ 文件夹',
                  selected: false,
                  onTap: () => _showFolderEditor(),
                );
              }

              final folder = items[index - 2];
              return _TagChip(
                label: folder.name,
                selected:
                    selectedFolder.kind == JournalFolderFilterKind.folder &&
                    selectedFolder.folderId == folder.id,
                onTap: () =>
                    _selectFolder(JournalFolderSelection.folder(folder.id)),
                onLongPress: () => _showFolderActions(folder),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _selectFolder(JournalFolderSelection selection) {
    ref.read(selectedJournalFolderProvider.notifier).state = selection;
    if (_selectedTag != null) {
      setState(() => _selectedTag = null);
    }
  }

  Future<void> _showFolderEditor({JournalFolder? folder}) async {
    final controller = TextEditingController(text: folder?.name ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: _FolderEditSheet(
            controller: controller,
            title: folder == null ? '新建文件夹' : '重命名文件夹',
          ),
        );
      },
    );
    controller.dispose();
    final name = result?.trim();
    if (name == null || name.isEmpty) return;

    try {
      final repo = ref.read(journalRepositoryProvider);
      if (folder == null) {
        await repo.createFolder(name: name);
      } else {
        await repo.updateFolder(id: folder.id, name: name);
      }
      _invalidateJournalLists();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('文件夹保存失败: $e')));
    }
  }

  Future<void> _showFolderActions(JournalFolder folder) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FolderActionSheet(
          folderName: folder.name,
          onRename: () {
            Navigator.pop(context);
            _showFolderEditor(folder: folder);
          },
          onDelete: () async {
            Navigator.pop(context);
            await _confirmDeleteFolder(folder);
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteFolder(JournalFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除文件夹'),
        content: Text('删除「${folder.name}」后，里面的日记会回到未分类。'),
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
    if (confirmed != true) return;

    try {
      await ref.read(journalRepositoryProvider).deleteFolder(folder.id);
      final selected = ref.read(selectedJournalFolderProvider);
      if (selected.folderId == folder.id) {
        ref.read(selectedJournalFolderProvider.notifier).state =
            const JournalFolderSelection.all();
      }
      _invalidateJournalLists();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('文件夹删除失败: $e')));
    }
  }

  Future<void> _showMoveJournalSheet(DailyJournal journal) async {
    final folders = await ref.read(journalFoldersProvider.future);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MoveJournalSheet(
          journal: journal,
          folders: folders,
          onMove: (folderId) async {
            await ref
                .read(journalRepositoryProvider)
                .moveJournalToFolder(journal.id, folderId);
            _invalidateJournalLists();
          },
        );
      },
    );
  }

  void _invalidateJournalLists() {
    ref.invalidate(journalFoldersProvider);
    ref.invalidate(journalsByFolderProvider);
    ref.invalidate(recentJournalsProvider);
    ref.invalidate(allJournalTagsProvider);
    ref.invalidate(dashboardProvider);
  }

  // ---------------------------------------------------------------------------
  // Tag Filter
  // ---------------------------------------------------------------------------

  Widget _buildTagFilter(AsyncValue<List<String>> allTags) {
    return allTags.when(
      data: (tags) {
        final visibleTags = ['全部', ...tags.take(8)];
        return SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: visibleTags.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tag = visibleTags[index];
              final isAll = tag == '全部';
              final selected = isAll
                  ? _selectedTag == null
                  : _selectedTag == tag;
              return _TagChip(
                label: tag,
                selected: selected,
                onTap: () {
                  setState(() {
                    if (isAll) {
                      _selectedTag = null;
                    } else {
                      _selectedTag = _selectedTag == tag ? null : tag;
                    }
                  });
                },
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecentJournalFilters(
    AsyncValue<List<JournalFolder>> folders,
    JournalFolderSelection selectedFolder,
    AsyncValue<List<String>> allTags,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: JournalColors.pinkBorder),
        boxShadow: [
          BoxShadow(
            color: JournalColors.pinkMain.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildSectionTitle('最近日记 ✨')),
              SortButton(
                currentSort: ref.watch(journalSortProvider),
                onSortChanged: (s) =>
                    ref.read(journalSortProvider.notifier).state = s,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '按文件夹和标签筛选你的记录',
            style: TextStyle(
              color: JournalColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildFolderFilter(folders, selectedFolder),
          const SizedBox(height: 10),
          _buildTagFilter(allTags),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty State
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Image.asset(
              PetAssets.journalBook,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有日记，写下今天的第一句话吧',
              style: TextStyle(
                fontSize: 14,
                color: JournalColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete Journal
  // ---------------------------------------------------------------------------

  Future<void> _deleteJournal(
    BuildContext context,
    WidgetRef ref,
    DailyJournal journal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除日记'),
        content: Text('确定要删除「${journal.title}」吗？'),
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
        ref.invalidate(journalsByFolderProvider);
        ref.invalidate(totalJournalCountProvider);
        ref.invalidate(monthlyJournalCountProvider);
        ref.invalidate(journalHeatmapProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已删除')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
        }
      }
    }
  }
}

// =============================================================================
// _TiantianCompanionCard
// =============================================================================
