import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../core/database/app_database.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/journal_provider.dart';
import '../../shared/widgets/common/common_widgets.dart';
import '../../shared/widgets/sort_button.dart';
import '../../shared/widgets/swipe_delete_tile.dart';
import 'package:go_router/go_router.dart';
import '../pet/models/pet_scene_model.dart';
import '../pet/widgets/pet_scene_banner.dart';

/// 日记首页（淡粉色风格）
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
    final recentJournals = ref.watch(recentJournalsProvider);
    final allTags = ref.watch(allJournalTagsProvider);
    final todayCount = ref.watch(todayJournalCountProvider);

    // 根据选中标签决定数据源
    final source = _selectedTag == null
        ? recentJournals
        : ref.watch(journalsByTagProvider(_selectedTag!));

    // 排序
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
      backgroundColor: AppColors.softPink,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text(
                '成长日记',
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
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentJournalsProvider);
          ref.invalidate(allJournalTagsProvider);
          ref.invalidate(todayJournalCountProvider);
          if (_selectedTag != null) {
            ref.invalidate(journalsByTagProvider(_selectedTag!));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 小猫提示条 ──
              _buildPetBanner(todayCount),
              const SizedBox(height: 20),

              // ── 今日记录卡片 ──
              _buildTodayRecordCard(context, todayCount),
              const SizedBox(height: 24),

              // ── 标签筛选 ──
              _buildTagFilter(allTags),
              const SizedBox(height: 24),

              // ── 最近日记 ──
              _buildSectionTitle('最近日记'),
              const SizedBox(height: 12),
              journals.when(
                data: (list) {
                  if (list.isEmpty) return _buildEmptyState();
                  return Column(
                    children: list.map((journal) {
                      return SwipeDeleteTile(
                        key: ValueKey('journal_${journal.id}'),
                        onConfirmDelete: () async {
                          _deleteJournal(context, ref, journal);
                          return false;
                        },
                        onDismissed: () {},
                        child: _JournalListItem(
                          journal: journal,
                          onTap: () => context.push(
                            '/plan/journal/detail/${journal.id}',
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(child: Text('加载失败: $e')),
                ),
              ),
              const SizedBox(height: 80), // 为FAB留空间
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plan/journal/write'),
        backgroundColor: const Color(0xFFE8A0BF),
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit_rounded, size: 24),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF5C3D2E),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 小猫提示条
  // ---------------------------------------------------------------------------

  Widget _buildPetBanner(AsyncValue<int> todayCount) {
    final count = todayCount.whenOrNull(data: (c) => c) ?? 0;
    return PetSceneBanner(
      module: PetModuleType.journal,
      hasRecords: count > 0,
      onTap: () => context.push('/pet-center'),
    );
  }

  // ---------------------------------------------------------------------------
  // 今日记录卡片
  // ---------------------------------------------------------------------------

  Widget _buildTodayRecordCard(BuildContext context, AsyncValue<int> todayCount) {
    final count = todayCount.whenOrNull(data: (c) => c) ?? 0;

    return GestureDetector(
      onTap: () => context.push('/plan/journal/write'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8A0BF), Color(0xFFF0C4D4)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8A0BF).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今日记录',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    count > 0 ? '已记录 $count 篇' : '开始记录今天的成长',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '开始写日记',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Text('🐱', style: TextStyle(fontSize: 56)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 标签筛选
  // ---------------------------------------------------------------------------

  Widget _buildTagFilter(AsyncValue<List<String>> allTags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('标签筛选'),
        const SizedBox(height: 12),
        allTags.when(
          data: (tags) {
            final visibleTags = ['全部', ...tags.take(8)];
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visibleTags.map((tag) {
                final isAll = tag == '全部';
                final selected = isAll ? _selectedTag == null : _selectedTag == tag;
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
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 空状态
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.edit_note_rounded,
      title: '还没有日记',
      subtitle: '点击右下角按钮开始记录',
      accentColor: AppColors.journal,
    );
  }

  // ---------------------------------------------------------------------------
  // 删除日记
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
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B6B)),
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
// _TagChip - 标签选择器
// =============================================================================

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8A0BF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFFE8A0BF)
                : const Color(0xFFE8A0BF).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: selected ? Colors.white : const Color(0xFF8B6F5E),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _JournalListItem - 日记列表项
// =============================================================================

class _JournalListItem extends StatelessWidget {
  const _JournalListItem({
    required this.journal,
    required this.onTap,
  });

  final DailyJournal journal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(journal.createdAt);
    final dateStr = '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE8A0BF).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Expanded(
                  child: Text(
                    journal.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5C3D2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB0A09A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 内容预览
            Text(
              journal.content,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8B6F5E),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // 底部信息
            Row(
              children: [
                // 心情
                if (journal.mood != null) ...[
                  _buildMoodChip(journal.mood!),
                  const SizedBox(width: 8),
                ],

                // 标签
                if (journal.tags != null) ...[
                  _buildTagsPreview(journal.tags!),
                  const Spacer(),
                ] else
                  const Spacer(),

                // 字数和经验
                Text(
                  '${journal.wordCount}字',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB0A09A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A0BF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${journal.expGained} EXP',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE8A0BF),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChip(String mood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        mood,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFE8A0BF),
        ),
      ),
    );
  }

  Widget _buildTagsPreview(String tagsJson) {
    try {
      final tags = List<String>.from(
        (tagsJson.isNotEmpty ? tagsJson.split(',') : []),
      );
      if (tags.isEmpty) return const SizedBox.shrink();

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: tags.take(2).map((tag) {
          return Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFB0A09A),
              ),
            ),
          );
        }).toList(),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
