import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/services/statistics_service.dart';
import '../../../shared/providers/service_providers.dart';

// =============================================================================
// Providers
// =============================================================================

/// 今日统计数据 Provider
final todayStatsProvider = FutureProvider<TodayStats>((ref) async {
  final statsService = ref.watch(statisticsServiceProvider);
  return statsService.getTodayStats();
});

// =============================================================================
// DailyStatsPage
// =============================================================================

/// 日统计页面
///
/// 展示今日学习时长、健身时长、日记篇数、获得经验值。
/// 使用卡片布局，每个指标一张卡片。
class DailyStatsPage extends ConsumerWidget {
  const DailyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayStats = ref.watch(todayStatsProvider);

    return todayStats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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

  final TodayStats stats;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // 由父级 ConsumerWidget 处理刷新
      },
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        children: [
          // ── 日期标题 ──
          _DateHeader(),
          const SizedBox(height: AppTheme.spaceLg),

          // ── 统计卡片网格 ──
          _StatsGrid(stats: stats),
          const SizedBox(height: AppTheme.spaceLg),

          // ── 今日总结 ──
          _DailySummary(stats: stats),
        ],
      ),
    );
  }
}

// =============================================================================
// 日期标题
// =============================================================================

class _DateHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${now.month} 月 ${now.day} 日',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXs),
        Text(
          '${weekdays[now.weekday - 1]} · ${now.year}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 统计卡片网格
// =============================================================================

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final TodayStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.spaceSm,
      crossAxisSpacing: AppTheme.spaceSm,
      childAspectRatio: 1.3,
      children: [
        _StatCard(
          icon: Icons.menu_book_rounded,
          label: '学习时长',
          value: _formatMinutes(stats.studyMinutes),
          color: GrowthColors.studyPrimary,
          backgroundColor: GrowthColors.studyLight,
        ),
        _StatCard(
          icon: Icons.fitness_center_rounded,
          label: '健身时长',
          value: _formatMinutes(stats.fitnessMinutes),
          color: GrowthColors.fitnessPrimary,
          backgroundColor: GrowthColors.fitnessLight,
        ),
        _StatCard(
          icon: Icons.edit_note_rounded,
          label: '日记篇数',
          value: '${stats.journalCount}',
          unit: '篇',
          color: GrowthColors.journalPrimary,
          backgroundColor: GrowthColors.journalLight,
        ),
        _StatCard(
          icon: Icons.star_rounded,
          label: '获得经验',
          value: '${stats.totalExp}',
          unit: 'EXP',
          color: GrowthColors.expFill,
          backgroundColor: GrowthColors.expBackground,
        ),
      ],
    );
  }

  /// 将分钟格式化为 "Xmin" 或 "Xh Ym"
  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h${m}m' : '${h}h';
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
    this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 图标
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSm),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),

            // 数值 + 单位
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
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
// 今日总结
// =============================================================================

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.stats});

  final TodayStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMinutes = stats.studyMinutes + stats.fitnessMinutes;

    String summary;
    if (totalMinutes == 0 && stats.journalCount == 0) {
      summary = '今天还没有记录，开始你的成长之旅吧！';
    } else if (totalMinutes >= 120) {
      summary = '今天投入了 ${_formatMinutes(totalMinutes)}，表现优秀！继续保持！';
    } else if (totalMinutes >= 60) {
      summary = '今天活跃了 ${_formatMinutes(totalMinutes)}，不错的开始！';
    } else {
      summary = '今天活跃了 ${_formatMinutes(totalMinutes)}，加油！';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: GrowthColors.expFill,
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Text('今日总结', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
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

  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes 分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '$h 小时 $m 分钟' : '$h 小时';
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppTheme.spaceMd),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spaceMd),
            FilledButton(
              onPressed: onRetry,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
