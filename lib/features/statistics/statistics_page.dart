import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/daily_stats_page.dart';
import 'pages/weekly_stats_page.dart';
import 'pages/monthly_stats_page.dart';
import 'pages/yearly_stats_page.dart';

// =============================================================================
// StatisticsPage
// =============================================================================

/// 统计模块主页面
///
/// 使用 [TabBar] 切换四个子页面：
/// - 日统计：今日概览
/// - 周统计：最近 7 天趋势
/// - 月统计：当前月趋势
/// - 年统计：年度概览
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
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(text: '日'),
            Tab(text: '周'),
            Tab(text: '月'),
            Tab(text: '年'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DailyStatsPage(),
          WeeklyStatsPage(),
          MonthlyStatsPage(),
          YearlyStatsPage(),
        ],
      ),
    );
  }
}
