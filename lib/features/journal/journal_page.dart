import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
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
import 'utils/journal_constants.dart';
import 'widgets/journal_colors.dart';
import '../statistics/widgets/heatmap_calendar.dart';

part 'widgets/journal_page_widgets.dart';

// =============================================================================
// New Providers
// =============================================================================

/// 连续写作天数
final journalStreakProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  final now = DateTime.now();
  final journals = await repo.getJournalsByRange(
    now.subtract(const Duration(days: 90)),
    now,
  );

  final dates = journals.map((j) => j.journalDate).toSet();
  int streak = 0;
  for (int i = 0; i < 90; i++) {
    final date = now.subtract(Duration(days: i));
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (dates.contains(dateStr)) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
});

/// 去年今天的日记
final onThisDayProvider = FutureProvider<List<DailyJournal>>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  final now = DateTime.now();
  final lastYear = DateTime(now.year - 1, now.month, now.day);
  return repo.getJournalsByDate(lastYear);
});

/// 日记总数
final totalJournalCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final count = db.dailyJournals.id.count();
  final query = db.selectOnly(db.dailyJournals)..addColumns([count]);
  final result = await query.getSingle();
  return result.read(count) ?? 0;
});

/// 本月日记篇数
final monthlyJournalCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final journals = await repo.getJournalsByRange(start, now);
  return journals.length;
});

/// 选中的热力图年份
final selectedHeatmapYearProvider = StateProvider<int>(
  (ref) => DateTime.now().year,
);

/// 日记热力图数据（按年份）
final journalHeatmapProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  final year = ref.watch(selectedHeatmapYearProvider);
  final repo = ref.watch(journalRepositoryProvider);
  final start = DateTime(year, 1, 1);
  final end = DateTime(year, 12, 31);
  final journals = await repo.getJournalsByRange(start, end);
  final data = <DateTime, int>{};
  for (final j in journals) {
    try {
      final date = DateTime.parse(j.journalDate);
      final key = DateTime(date.year, date.month, date.day);
      data[key] = (data[key] ?? 0) + 1;
    } catch (_) {}
  }
  return data;
});

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
    final recentJournals = ref.watch(recentJournalsProvider);
    final allTags = ref.watch(allJournalTagsProvider);
    final todayCount = ref.watch(todayJournalCountProvider);
    final streak = ref.watch(journalStreakProvider);
    final totalCount = ref.watch(totalJournalCountProvider);
    final monthlyCount = ref.watch(monthlyJournalCountProvider);
    final heatmapData = ref.watch(journalHeatmapProvider);

    final source = _selectedTag == null
        ? recentJournals
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

              // ── 3. 标签筛选 ──
              _buildTagFilter(allTags),
              const SizedBox(height: 20),

              // ── 4. 统计卡片 ──
              _StatsRow(
                monthlyCount: monthlyCount,
                totalCount: totalCount,
                streak: streak,
              ),
              const SizedBox(height: 20),

              // ── 5. 写作热力图 ──
              _buildHeatmapSection(heatmapData),
              const SizedBox(height: 20),

              // ── 6. 最近日记列表 ──
              _buildSectionTitle('最近日记 ✨'),
              const SizedBox(height: 12),
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

  // ---------------------------------------------------------------------------
  // Heatmap Section
  // ---------------------------------------------------------------------------

  Widget _buildHeatmapSection(AsyncValue<Map<DateTime, int>> heatmapData) {
    return heatmapData.when(
      data: (data) {
        final selectedYear = ref.watch(selectedHeatmapYearProvider);
        final currentYear = DateTime.now().year;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: JournalColors.shadow,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with year selector
              Row(
                children: [
                  Text(
                    '📅 写作热力图',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                  ),
                  const Spacer(),
                  _YearSelector(
                    year: selectedYear,
                    canGoBack: selectedYear > 2020,
                    canGoForward: selectedYear < currentYear,
                    onBack: () {
                      ref.read(selectedHeatmapYearProvider.notifier).state--;
                    },
                    onForward: () {
                      ref.read(selectedHeatmapYearProvider.notifier).state++;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Heatmap
              if (data.isNotEmpty)
                HeatmapCalendar(
                  data: data,
                  monthsToShow: 12,
                  baseColor: JournalColors.heat0,
                  maxColor: JournalColors.heat4,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '$selectedYear 年暂无写作记录',
                      style: const TextStyle(
                        fontSize: 13,
                        color: JournalColors.textMuted,
                      ),
                    ),
                  ),
                ),
              // Legend
              if (data.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      '少',
                      style: TextStyle(
                        fontSize: 10,
                        color: JournalColors.textMuted,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '→',
                        style: TextStyle(
                          fontSize: 10,
                          color: JournalColors.textMuted,
                        ),
                      ),
                    ),
                    ...JournalColors.heatColors.map(
                      (c) => Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '→',
                        style: TextStyle(
                          fontSize: 10,
                          color: JournalColors.textMuted,
                        ),
                      ),
                    ),
                    const Text(
                      '多',
                      style: TextStyle(
                        fontSize: 10,
                        color: JournalColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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
