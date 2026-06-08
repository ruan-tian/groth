import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../core/database/app_database.dart';
import '../pet/utils/pet_assets.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/journal_provider.dart';
import '../../shared/widgets/sort_button.dart';
import '../../shared/widgets/swipe_delete_tile.dart';
import '../pet/models/pet_scene_model.dart';
import '../../shared/providers/pet_scene_provider.dart';
import 'utils/journal_constants.dart';
import 'widgets/journal_colors.dart';
import '../statistics/widgets/heatmap_calendar.dart';

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
              title: const Text(
                '成长日记',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: JournalColors.textDark,
                ),
              ),
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
              const _TiantianCompanionCard(),
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
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [JournalColors.pinkSoft, JournalColors.pinkMain],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: JournalColors.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/plan/journal/write'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: JournalColors.textDark,
      ),
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

    return GestureDetector(
      onTap: () => context.push('/plan/journal/write'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: JournalColors.pinkBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: JournalColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // 第1层：完整底图
              Image.asset(
                PetAssets.journalTodayRecordBg,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: JournalColors.heroGradient,
                  ),
                ),
              ),
              // 第2层：文字覆盖（左侧，人物在右）
              Positioned(
                left: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/pet_center/deco/deco_pencil.png',
                          width: 16,
                          height: 16,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '今日记录',
                          style: TextStyle(
                            fontFamily: JournalColors.fontFamily,
                            fontSize: 18,
                            color: JournalColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Image.asset(
                          'assets/images/pet_center/deco/deco_star.png',
                          width: 14,
                          height: 14,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count > 0 ? '已记录 $count 篇' : '开始记录今天的成长',
                      style: TextStyle(
                        fontFamily: JournalColors.fontFamily,
                        fontSize: 12,
                        color: JournalColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: JournalColors.pinkMain,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/pet_center/deco/deco_pencil.png',
                            width: 14,
                            height: 14,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.edit_rounded,
                                    size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '开始写日记',
                            style: TextStyle(
                              fontFamily: JournalColors.fontFamily,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                  const Text(
                    '📅 写作热力图',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: JournalColors.textDark,
                    ),
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

class _TiantianCompanionCard extends ConsumerStatefulWidget {
  const _TiantianCompanionCard();

  @override
  ConsumerState<_TiantianCompanionCard> createState() =>
      _TiantianCompanionCardState();
}

class _TiantianCompanionCardState
    extends ConsumerState<_TiantianCompanionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(petSceneProvider(PetModuleType.journal).notifier)
          .initScene(hasRecords: false);
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sceneState = ref.watch(petSceneProvider(PetModuleType.journal));
    final bannerPath = sceneState.config.state.bannerPath;

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: JournalColors.pinkBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: JournalColors.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: Stack(
              key: ValueKey(bannerPath),
              children: [
                // 第1层：完整底图
                Image.asset(
                  bannerPath,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: JournalColors.companionGradient.colors.first,
                  ),
                ),
                // 第2层：文字（右侧留白区）
                Positioned(
                  right: 20,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '甜甜',
                        style: TextStyle(
                          fontFamily: JournalColors.fontFamily,
                          fontSize: 20,
                          color: JournalColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '记录一下今天的成长吧！',
                        style: TextStyle(
                          fontFamily: JournalColors.fontFamily,
                          fontSize: 12,
                          color: JournalColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _YearSelector
// =============================================================================

class _YearSelector extends StatelessWidget {
  const _YearSelector({
    required this.year,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  final int year;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          enabled: canGoBack,
          onTap: onBack,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$year年',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: JournalColors.textDark,
            ),
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          enabled: canGoForward,
          onTap: onForward,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? JournalColors.pinkBg
              : JournalColors.pinkBg.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? JournalColors.textDark : JournalColors.textMuted,
        ),
      ),
    );
  }
}

// =============================================================================
// _StatsRow
// =============================================================================

class _StatsRow extends StatelessWidget {
  const _StatsRow({
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
          child: _StatsCard(
            icon: Icons.bar_chart_rounded,
            label: '本月',
            value: monthlyCount.whenOrNull(data: (c) => c) ?? 0,
            unit: '篇',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatsCard(
            icon: Icons.calendar_month_rounded,
            label: '总计',
            value: totalCount.whenOrNull(data: (c) => c) ?? 0,
            unit: '篇',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatsCard(
            icon: Icons.local_fire_department_rounded,
            label: '连续',
            value: streak.whenOrNull(data: (s) => s) ?? 0,
            unit: '天',
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.icon,
    required this.label,
    required this.value,
    this.unit = '',
  });

  final IconData icon;
  final String label;
  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: JournalColors.pinkBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: JournalColors.pinkMain),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: JournalColors.textDark,
                  height: 1.1,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: JournalColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: JournalColors.textSecondary,
            ),
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
          color: selected ? JournalColors.pinkMain : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? JournalColors.pinkMain : JournalColors.pinkBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : JournalColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _JournalListItem
// =============================================================================

class _JournalListItem extends StatelessWidget {
  const _JournalListItem({required this.journal, required this.onTap});

  final DailyJournal journal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final moodEmoji = getMoodEmoji(journal.mood);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: JournalColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left icon ──
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: JournalColors.pinkBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  PetAssets.journalBook,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.pets_rounded,
                    size: 20,
                    color: JournalColors.pinkMain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    journal.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: JournalColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Preview
                  Text(
                    journal.content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: JournalColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Bottom row: mood + tags + word count + EXP
                  Row(
                    children: [
                      // Mood emoji
                      Text(moodEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),

                      // Tags
                      if (journal.tags != null) ...[
                        _buildTagsPreview(journal.tags!),
                      ],

                      const Spacer(),

                      // Word count
                      Text(
                        '${journal.wordCount}字',
                        style: const TextStyle(
                          fontSize: 11,
                          color: JournalColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // EXP badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: JournalColors.pinkBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${journal.expGained} EXP',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: JournalColors.pinkMain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Chevron ──
            const Padding(
              padding: EdgeInsets.only(left: 8, top: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: JournalColors.textMuted,
              ),
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
            color: JournalColors.pinkBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '#$tag',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: JournalColors.pinkMain,
            ),
          ),
        );
      }).toList(),
    );
  }
}
