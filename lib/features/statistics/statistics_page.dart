import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/services/statistics_service.dart';
import '../../shared/providers/service_providers.dart';
import 'pages/daily_stats_page.dart';
import 'pages/weekly_stats_page.dart';
import 'widgets/stats_chart.dart';

// =============================================================================
// Providers
// =============================================================================

/// 最近 30 天每日统计 Provider
final monthlyStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  final statsService = ref.watch(statisticsServiceProvider);
  return statsService.getMonthlyStats();
});

// =============================================================================
// StatisticsPage
// =============================================================================

/// 统计模块主页面
///
/// 使用 [TabBar] 切换三个子页面：
/// - 日统计：今日概览
/// - 周统计：最近 7 天趋势
/// - 月统计：最近 30 天趋势
class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '日统计'),
            Tab(text: '周统计'),
            Tab(text: '月统计'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DailyTab(),
          _WeeklyTab(),
          _MonthlyTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab Content Wrappers
// =============================================================================

/// 日统计 Tab
class _DailyTab extends ConsumerWidget {
  const _DailyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DailyStatsPage();
  }
}

/// 周统计 Tab
class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WeeklyStatsPage();
  }
}

/// 月统计 Tab
///
/// 展示最近 30 天趋势，复用 [StatsChart] 绘制折线图。
class _MonthlyTab extends ConsumerWidget {
  const _MonthlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyStats = ref.watch(monthlyStatsProvider);

    return monthlyStats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(monthlyStatsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      data: (stats) {
        if (stats.isEmpty) {
          return const Center(child: Text('暂无数据'));
        }
        return _MonthlyContent(stats: stats);
      },
    );
  }
}

// =============================================================================
// Monthly Content
// =============================================================================

class _MonthlyContent extends StatelessWidget {
  const _MonthlyContent({required this.stats});

  final List<DailyStats> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 计算汇总
    final totalStudy = stats.fold<int>(0, (sum, d) => sum + d.studyMinutes);
    final totalFitness = stats.fold<int>(0, (sum, d) => sum + d.fitnessMinutes);
    final totalExp = stats.fold<int>(0, (sum, d) => sum + d.expGained);

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      children: [
        // 标题
        Text(
          '月统计',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXs),
        Text(
          '最近 30 天',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),

        // 汇总卡片
        Row(
          children: [
            Expanded(
              child: _MonthlySummaryCard(
                label: '总学习',
                value: _formatHours(totalStudy),
                color: GrowthColors.studyPrimary,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: _MonthlySummaryCard(
                label: '总健身',
                value: _formatHours(totalFitness),
                color: GrowthColors.fitnessPrimary,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: _MonthlySummaryCard(
                label: '总经验',
                value: '$totalExp',
                color: GrowthColors.expFill,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLg),

        // 趋势折线图
        StatsChart(
          data: stats,
          showStudy: true,
          showFitness: true,
          showExp: true,
          height: 200,
        ),
      ],
    );
  }

  static String _formatHours(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes / 60;
    return '${hours.toStringAsFixed(1)}h';
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSm,
          vertical: AppTheme.spaceMd,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
