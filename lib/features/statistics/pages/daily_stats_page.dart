import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/services/statistics_service.dart';
import '../../../core/utils/stats_formatters.dart';
import '../../../shared/providers/service_providers.dart';
import '../../../shared/providers/repository_providers.dart';
import '../widgets/stats_skeleton.dart';
import '../../../shared/widgets/common/error_retry_widget.dart';

// =============================================================================
// Providers
// =============================================================================

/// 当前选中的日期
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 每日统计数据 Provider（根据选中日期自动刷新）
final todayStatsProvider = FutureProvider<DailyStats>((ref) async {
  final statsService = ref.watch(statisticsServiceProvider);
  final date = ref.watch(selectedDateProvider);
  final range = await statsService.getDailyStatsRange(date, date);
  return range.isNotEmpty ? range.first : DailyStats.empty(date);
});

/// 今日知识卡复习统计
final todayKnowledgeReviewProvider = FutureProvider<KnowledgeReviewDayStats>((
  ref,
) async {
  final repo = ref.watch(knowledgeCardRepositoryProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startMs = startOfDay.millisecondsSinceEpoch;
  final endMs = startOfDay.add(const Duration(days: 1)).millisecondsSinceEpoch;

  final todayLogs = await repo.getReviewLogsInRange(
    startMs: startMs,
    endMs: endMs,
  );

  final reviewCount = todayLogs.length;
  final goodCount = todayLogs.where((log) => log.quality >= 2).length;
  final accuracy = reviewCount > 0 ? goodCount / reviewCount : 0.0;

  final cards = await repo.getAllCards();
  final dueCards = cards
      .where(
        (card) => !card.archived && card.dueAt <= now.millisecondsSinceEpoch,
      )
      .length;

  return KnowledgeReviewDayStats(
    reviewCount: reviewCount,
    accuracy: accuracy,
    dueCards: dueCards,
  );
});

class KnowledgeReviewDayStats {
  const KnowledgeReviewDayStats({
    required this.reviewCount,
    required this.accuracy,
    required this.dueCards,
  });
  final int reviewCount;
  final double accuracy;
  final int dueCards;
}

/// 当前连续打卡天数（基于最近 90 天数据）
final currentStreakProvider = FutureProvider<int>((ref) async {
  final statsService = ref.watch(statisticsServiceProvider);
  final now = DateTime.now();
  final stats = await statsService.getDailyStatsRange(
    now.subtract(const Duration(days: 90)),
    now,
  );
  return statsService.calculateStreak(stats);
});

// =============================================================================
// DailyStatsPage
// =============================================================================

/// 日统计页面
///
/// 展示指定日期的学习时长、健身时长、日记篇数、饮食记录、睡眠时长、专注时长。
/// 顶部日期导航可切换前后天，卡片网格展示 6 项核心指标。
class DailyStatsPage extends ConsumerWidget {
  const DailyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayStats = ref.watch(todayStatsProvider);

    return todayStats.when(
      loading: () => const StatsSkeleton(),
      error: (error, stack) => _ErrorView(
        message: '加载失败: $error',
        onRetry: () => ref.invalidate(todayStatsProvider),
      ),
      data: (stats) => _DailyStatsContent(stats: stats),
    );
  }
}

// =============================================================================
// Content
// =============================================================================

class _DailyStatsContent extends StatelessWidget {
  const _DailyStatsContent({required this.stats});

  final DailyStats stats;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // 由父级 ConsumerWidget 处理刷新
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── 日期导航 ──
          _DateNavigator(),
          const SizedBox(height: AppSpacing.md),

          // ── 连续打卡 ──
          const _StreakBanner(),
          const SizedBox(height: AppSpacing.lg),

          // ── 统计卡片网格 ──
          _StatsGrid(stats: stats),
          const SizedBox(height: AppSpacing.lg),

          // ── 知识卡复习 ──
          const _KnowledgeReviewCard(),
          const SizedBox(height: AppSpacing.lg),

          // ── 今日总结 ──
          _DailySummary(stats: stats),
        ],
      ),
    );
  }
}

// =============================================================================
// 日期导航
// =============================================================================

class _DateNavigator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final date = ref.watch(selectedDateProvider);
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return Row(
      children: [
        // 左箭头 — 前一天
        IconButton(
          onPressed: () {
            ref.read(selectedDateProvider.notifier).state = date.subtract(
              const Duration(days: 1),
            );
          },
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: '前一天',
        ),

        // 日期显示 "6月8日 · 周日"
        Expanded(
          child: Text(
            formatFullDate(date),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // 右箭头 — 后一天（今天时禁用）
        IconButton(
          onPressed: isToday
              ? null
              : () {
                  ref.read(selectedDateProvider.notifier).state = date.add(
                    const Duration(days: 1),
                  );
                },
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: '后一天',
        ),

        // 今天按钮（仅非今天时显示）
        if (!isToday)
          TextButton(
            onPressed: () {
              ref.read(selectedDateProvider.notifier).state = DateTime.now();
            },
            child: const Text('今天'),
          ),
      ],
    );
  }
}

// =============================================================================
// 连续打卡横幅
// =============================================================================

class _StreakBanner extends ConsumerWidget {
  const _StreakBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(currentStreakProvider);
    final theme = Theme.of(context);

    return streakAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const ErrorRetryWidget(),
      data: (streak) {
        if (streak <= 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '连续打卡 $streak 天',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.growthColors.warning,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// 统计卡片网格 (6 模块 × 3 列)
// =============================================================================

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final DailyStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.2,
      children: [
        // 学习时长 (blue)
        _StatCard(
          icon: Icons.menu_book_rounded,
          label: '学习时长',
          value: formatMinutes(stats.studyMinutes),
          color: context.growthColors.study,
          backgroundColor: context.growthColors.softBlue,
        ),
        // 健身时长 (orange)
        _StatCard(
          icon: Icons.fitness_center_rounded,
          label: '健身时长',
          value: formatMinutes(stats.fitnessMinutes),
          color: context.growthColors.fitness,
          backgroundColor: context.growthColors.softOrange,
        ),
        // 日记篇数 (pink)
        _StatCard(
          icon: Icons.edit_note_rounded,
          label: '日记篇数',
          value: '${stats.journalCount}篇',
          color: context.growthColors.journal,
          backgroundColor: context.growthColors.softPink,
        ),
        // 饮食记录 (green)
        _StatCard(
          icon: Icons.restaurant_rounded,
          label: '饮食记录',
          value: '${stats.dietCount}次',
          color: context.growthColors.success,
          backgroundColor: context.growthColors.softGreen,
        ),
        // 睡眠时长 (purple)
        _StatCard(
          icon: Icons.bedtime_rounded,
          label: '睡眠时长',
          value: formatMinutes(stats.sleepMinutes),
          color: context.growthColors.sleep,
          backgroundColor: context.growthColors.softPurple,
        ),
        // 专注时长 (teal)
        _StatCard(
          icon: Icons.timer_rounded,
          label: '专注时长',
          value: formatMinutes(stats.focusMinutes),
          color: context.growthColors.focus,
          backgroundColor: context.growthColors.softGreen,
        ),
      ],
    );
  }
}

// =============================================================================
// 单个统计卡片
// =============================================================================

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 图标
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Icon(icon, color: color, size: 20),
            ),

            // 数值 + 单位
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // 标签
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 知识卡复习卡片
// =============================================================================

class _KnowledgeReviewCard extends ConsumerWidget {
  const _KnowledgeReviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(todayKnowledgeReviewProvider);
    final theme = Theme.of(context);
    final colors = context.growthColors;

    return reviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.reviewCount == 0 && data.dueCards == 0) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 20,
                      color: colors.study,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('知识卡复习', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _ReviewStat(
                      label: '已复习',
                      value: '${data.reviewCount}',
                      color: colors.study,
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    _ReviewStat(
                      label: '正确率',
                      value: '${(data.accuracy * 100).round()}%',
                      color: data.accuracy >= 0.8
                          ? colors.success
                          : data.accuracy >= 0.5
                          ? colors.warning
                          : colors.danger,
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    _ReviewStat(
                      label: '待复习',
                      value: '${data.dueCards}',
                      color: data.dueCards > 0
                          ? colors.warning
                          : colors.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewStat extends StatelessWidget {
  const _ReviewStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 今日总结
// =============================================================================

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.stats});

  final DailyStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 总活跃时长 = 学习 + 健身 + 专注
    final totalMinutes =
        stats.studyMinutes + stats.fitnessMinutes + stats.focusMinutes;

    // 拼接总结各段
    final parts = <String>[];
    if (totalMinutes > 0) {
      parts.add('活跃 ${formatMinutes(totalMinutes)}');
    }
    if (stats.expGained > 0) {
      parts.add('获得 ${formatExp(stats.expGained)} EXP');
    }
    if (stats.taskTotal > 0) {
      parts.add('任务完成 ${stats.taskCompleted}/${stats.taskTotal}');
    }

    final summary = parts.isEmpty ? '今天还没有记录，开始你的成长之旅吧！' : parts.join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: context.growthColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('今日总结', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Error View
// =============================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
