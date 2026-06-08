import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../core/database/app_database.dart';
import '../../core/repositories/journal_repository.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/journal_provider.dart';
import '../../shared/widgets/common/common_widgets.dart';
import '../../shared/widgets/sort_button.dart';
import '../../shared/widgets/swipe_delete_tile.dart';
import '../pet/models/pet_scene_model.dart';
import '../pet/widgets/pet_scene_banner.dart';
import '../statistics/widgets/heatmap_calendar.dart';
import 'utils/journal_constants.dart';

// =============================================================================
// Design Tokens (journal-local)
// =============================================================================

const _kJournalBg = Color(0xFFFFF8F5);
const _kJournalText = Color(0xFF5C3D2E);
const _kJournalTextSecondary = Color(0xFF8B6F5E);
const _kJournalTextMuted = Color(0xFFB0A09A);
const _kWarmOrange = Color(0xFFFF8A3D);
const _kCardRadius = 20.0;
const _kChipRadius = 12.0;

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

/// 日记热力图数据
final journalHeatmapProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month - 2, 1);
  final journals = await repo.getJournalsByRange(start, now);
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

/// 日记首页 — warm, inviting, Day One + Bear inspired
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
    final onThisDay = ref.watch(onThisDayProvider);
    final totalCount = ref.watch(totalJournalCountProvider);
    final monthlyCount = ref.watch(monthlyJournalCountProvider);
    final heatmapData = ref.watch(journalHeatmapProvider);

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
      backgroundColor: _kJournalBg,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text(
                '成长日记',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _kJournalText,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: _kJournalText,
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
        color: AppColors.journal,
        onRefresh: () async {
          ref.invalidate(recentJournalsProvider);
          ref.invalidate(allJournalTagsProvider);
          ref.invalidate(todayJournalCountProvider);
          ref.invalidate(journalStreakProvider);
          ref.invalidate(onThisDayProvider);
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
              // ── 1. Streak Banner ──
              streak.when(
                data: (s) => s > 0
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _StreakBanner(streak: s),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // ── 2. Writing Prompt Card ──
              const _WritingPromptCard(),
              const SizedBox(height: 16),

              // ── 3. Today Record Card ──
              _buildTodayRecordCard(context, todayCount),
              const SizedBox(height: 16),

              // ── 4. On This Day ──
              onThisDay.when(
                data: (journals) => journals.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _OnThisDayCard(journals: journals),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // ── 5. Tag Filter ──
              _buildTagFilter(allTags),
              const SizedBox(height: 20),

              // ── 6. Stats Overview Row ──
              _StatsOverviewRow(
                monthlyCount: monthlyCount,
                totalCount: totalCount,
                streak: streak,
              ),
              const SizedBox(height: 20),

              // ── 7. Heatmap Calendar ──
              heatmapData.when(
                data: (data) => data.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _HeatmapSection(data: data),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // ── 8. Recent Journals List ──
              _buildSectionTitle('最近日记'),
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
                      color: AppColors.journal,
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
                        color: _kJournalTextMuted,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plan/journal/write'),
        backgroundColor: AppColors.journal,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
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
        color: _kJournalText,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Today Record Card
  // ---------------------------------------------------------------------------

  Widget _buildTodayRecordCard(
      BuildContext context, AsyncValue<int> todayCount) {
    final count = todayCount.whenOrNull(data: (c) => c) ?? 0;

    return GestureDetector(
      onTap: () => context.push('/plan/journal/write'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.journal,
              AppColors.journal.withValues(alpha: 0.75),
            ],
          ),
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.journal.withValues(alpha: 0.3),
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
                    '📝 今日记录',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    count > 0 ? '已记录 $count 篇' : '开始记录今天的成长',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          count > 0
                              ? Icons.arrow_forward_rounded
                              : Icons.edit_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          count > 0 ? '继续写 →' : '开始写日记',
                          style: const TextStyle(
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
            Text(
              '🐱',
              style: TextStyle(fontSize: 52),
            ),
          ],
        ),
      ),
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
              final selected =
                  isAll ? _selectedTag == null : _selectedTag == tag;
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
  // Empty State
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.edit_note_rounded,
      title: '还没有日记',
      subtitle: '点击右下角按钮开始记录你的成长故事',
      accentColor: AppColors.journal,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kCardRadius),
        ),
        title: const Text('删除日记'),
        content: Text('确定要删除「${journal.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
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
// _StreakBanner
// =============================================================================

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kWarmOrange.withValues(alpha: 0.12),
            _kWarmOrange.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _kWarmOrange.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(
            '连续写作 $streak 天',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kWarmOrange,
            ),
          ),
          const Spacer(),
          if (streak >= 7)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kWarmOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                streak >= 30 ? '月度坚持！' : '一周达成！',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _kWarmOrange.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// _WritingPromptCard — with floating animation
// =============================================================================

class _WritingPromptCard extends ConsumerStatefulWidget {
  const _WritingPromptCard();

  @override
  ConsumerState<_WritingPromptCard> createState() => _WritingPromptCardState();
}

class _WritingPromptCardState extends ConsumerState<_WritingPromptCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;
  late WritingPrompt _prompt;

  @override
  void initState() {
    super.initState();
    _prompt = getRandomPrompt();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => context.push('/plan/journal/write'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.journal.withValues(alpha: 0.12),
                AppColors.journal.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: Border.all(
              color: AppColors.journal.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.journal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('💡', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '"${_prompt.text}"',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kJournalText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '开始写 →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.journal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _OnThisDayCard
// =============================================================================

class _OnThisDayCard extends StatelessWidget {
  const _OnThisDayCard({required this.journals});

  final List<DailyJournal> journals;

  @override
  Widget build(BuildContext context) {
    final journal = journals.first;
    final preview = journal.content.length > 60
        ? '${journal.content.substring(0, 60)}...'
        : journal.content;

    return GestureDetector(
      onTap: () => context.push('/plan/journal/detail/${journal.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0E8),
          borderRadius: BorderRadius.circular(_kCardRadius),
          border: Border.all(
            color: _kWarmOrange.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text(
                  '去年的今天',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kWarmOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '"$preview"',
              style: const TextStyle(
                fontSize: 13,
                color: _kJournalTextSecondary,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '查看回忆 →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kWarmOrange.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _StatsOverviewRow
// =============================================================================

class _StatsOverviewRow extends StatelessWidget {
  const _StatsOverviewRow({
    required this.monthlyCount,
    required this.totalCount,
    required this.streak,
  });

  final AsyncValue<int> monthlyCount;
  final AsyncValue<int> totalCount;
  final AsyncValue<int> streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            emoji: '📊',
            label: '本月',
            value: monthlyCount.whenOrNull(data: (c) => c) ?? 0,
            unit: '篇',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            emoji: '📅',
            label: '总计',
            value: totalCount.whenOrNull(data: (c) => c) ?? 0,
            unit: '篇',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            emoji: '✍️',
            label: '连续',
            value: streak.whenOrNull(data: (s) => s) ?? 0,
            unit: '天',
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.unit,
  });

  final String emoji;
  final String label;
  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.journal.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$value',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kJournalText,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kJournalTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _kJournalTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _HeatmapSection
// =============================================================================

class _HeatmapSection extends StatelessWidget {
  const _HeatmapSection({required this.data});

  final Map<DateTime, int> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(
          color: AppColors.journal.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📅', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                '写作热力图',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kJournalText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          HeatmapCalendar(
            data: data,
            monthsToShow: 3,
            baseColor: AppColors.journal.withValues(alpha: 0.06),
            maxColor: AppColors.journal,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _TagChip
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
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.journal : Colors.white,
          borderRadius: BorderRadius.circular(_kChipRadius),
          border: Border.all(
            color: selected
                ? AppColors.journal
                : AppColors.journal.withValues(alpha: 0.2),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.journal.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : _kJournalTextSecondary,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _JournalListItem — premium card with photo, mood emoji, tags
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
    final dateStr =
        '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final moodEmoji = getMoodEmoji(journal.mood);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.journal.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: mood + title + date ──
            Row(
              children: [
                // Mood emoji
                Text(moodEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                // Title
                Expanded(
                  child: Text(
                    journal.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kJournalText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kJournalTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Content preview ──
            Text(
              journal.content,
              style: const TextStyle(
                fontSize: 13,
                color: _kJournalTextSecondary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // ── Bottom row: photo + tags + stats ──
            Row(
              children: [
                // Photo thumbnail (if exists)
                _AssetThumbnail(journalId: journal.id),

                // Tags
                if (journal.tags != null) ...[
                  _buildTagsPreview(journal.tags!),
                  const Spacer(),
                ] else
                  const Spacer(),

                // Word count
                Text(
                  '${journal.wordCount}字',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kJournalTextMuted,
                  ),
                ),
                const SizedBox(width: 8),

                // EXP badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.journal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${journal.expGained} EXP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.journal,
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

  List<String> _parseTagsSafe(String? tagsString) {
    if (tagsString == null || tagsString.isEmpty) return const [];
    try {
      final decoded = jsonDecode(tagsString);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return tagsString.split(',').where((t) => t.trim().isNotEmpty).toList();
  }

  Widget _buildTagsPreview(String tagsJson) {
    final tags = _parseTagsSafe(tagsJson);
    if (tags.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: tags.take(2).map((tag) {
        return Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.journal.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.journal.withValues(alpha: 0.7),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// _AssetThumbnail — loads first photo from journal_assets
// =============================================================================

class _AssetThumbnail extends ConsumerWidget {
  const _AssetThumbnail({required this.journalId});

  final int journalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(journalRepositoryProvider);

    return FutureBuilder<List<JournalAsset>>(
      future: repo.getJournalAssets(journalId),
      builder: (context, snapshot) {
        final assets = snapshot.data;
        if (assets == null || assets.isEmpty) {
          return const SizedBox.shrink();
        }

        final firstAsset = assets.first;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              firstAsset.localPath,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
