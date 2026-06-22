import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../core/database/app_database.dart';
import '../../core/services/statistics_service.dart';
import '../../core/utils/chart_scale_utils.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/knowledge_v3_provider.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/providers/study_provider.dart';
import '../../shared/widgets/common/common_widgets.dart';
import '../../shared/widgets/swipe_delete_tile.dart';
import '../plan/utils/plan_module_assets.dart';
import '../plan/widgets/plan_module_visuals.dart';

part 'widgets/study_page_widgets.dart';

// =============================================================================
// 科目调色板（按排序 index 分配颜色，最多 15 色）
// =============================================================================

List<Color> _subjectPalette(AppThemeColors c) => [
  c.danger, // 1 红
  c.fitness, // 2 橙
  c.diet, // 3 琥珀
  c.accent, // 4 金
  const Color(0xFF65A30D), // 5 黄绿
  const Color(0xFF059669), // 6 翠绿
  c.focus, // 7 青
  const Color(0xFF2563EB), // 8 钢蓝
  c.study, // 9 蓝
  c.sleep, // 10 紫
  const Color(0xFF7C3AED), // 11 紫罗兰
  const Color(0xFFDB2777), // 12 品红
  const Color(0xFFBE185D), // 13 玫红
  c.journal, // 14 玫粉
  c.primaryLight, // 15 浅靛
];

Color _colorByIndex(AppThemeColors colors, int index) {
  final palette = _subjectPalette(colors);
  return palette[index % palette.length];
}

// =============================================================================
// StudyPage锛堟矇绋宠摑閰嶈壊锛?
// =============================================================================

class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  String _selectedRange = 'week'; // 'week' | 'month' | 'year'
  int _subjectDistDays = 30; // 科目分布范围: 1/7/30
  bool _isRecentExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final todayMinutes = ref.watch(todayStudyMinutesProvider);
    final todayRecords = ref.watch(todayStudyRecordsProvider);
    final recentRecords = ref.watch(recentStudyRecordsProvider);
    final subjectDist = ref.watch(
      subjectDistributionByRangeProvider(_subjectDistDays),
    );
    final knowledgeOverview = ref.watch(knowledgeWorkspaceOverviewV3Provider);
    final dailyGoals = ref.watch(dailyGoalsProvider);
    final studyGoal = dailyGoals.firstWhere(
      (g) => g.name == '学习',
      orElse: () => const DailyGoal(name: '学习', target: 120, unit: '分钟'),
    );

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                '学习',
                style: AppTextStyles.pageTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              centerTitle: false,
              backgroundColor: colors.paper,
              surfaceTintColor: Colors.transparent,
              actions: [
                IconButton(
                  tooltip: '专注计时',
                  onPressed: () => context.push('/focus'),
                  icon: Icon(Icons.timer_outlined, color: colors.study),
                ),
              ],
            ),
      body: ModulePageSurface(
        color: colors.study,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayStudyMinutesProvider);
            ref.invalidate(todayStudyRecordsProvider);
            ref.invalidate(weeklyStudyMinutesProvider);
            ref.invalidate(weeklyDailyStudyProvider);
            ref.invalidate(monthlyDailyStudyProvider);
            ref.invalidate(yearlyMonthlyStudyProvider);
            ref.invalidate(recentStudyRecordsProvider);
            ref.invalidate(subjectDistributionProvider);
            ref.invalidate(knowledgeWorkspaceOverviewV3Provider);
            ref.invalidate(
              subjectDistributionByRangeProvider(_subjectDistDays),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //  小猫提示?
                PlanModuleVisualHeader(
                  module: PlanModuleType.study,
                  color: colors.study,
                ),
                const SizedBox(height: AppSpacing.md),
                PlanModuleActionImageCard(
                  module: PlanModuleType.study,
                  color: colors.study,
                  onTap: () => context.push('/focus'),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildKnowledgeReviewEntry(context, knowledgeOverview),
                const SizedBox(height: AppSpacing.lg),

                //  顶部数据卡片 
                _buildStatsCards(
                  context,
                  ref,
                  todayMinutes,
                  todayRecords,
                  studyGoal,
                ),
                const SizedBox(height: AppSpacing.xl),

                //  学习趋势 
                //  忍操作 
                _buildQuickActions(context),
                const SizedBox(height: AppSpacing.xl),

                //  科目分布 
                //  近?
                _buildRecentRecords(context, ref, recentRecords),
                const SizedBox(height: AppSpacing.xl),

                _buildStudyTrendSection(context),
                const SizedBox(height: AppSpacing.xl),

                _buildSubjectDistribution(context, subjectDist),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plan/study/add'),
        backgroundColor: colors.study,
        foregroundColor: colors.textOnAccent,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildKnowledgeReviewEntry(
    BuildContext context,
    AsyncValue<KnowledgeWorkspaceOverviewV3> overview,
  ) {
    final colors = context.growthColors;
    return overview.when(
      data: (item) {
        final hasMaterials = item.materialCount > 0;
        final hasCards = item.cardCount > 0;
        final title = item.dueCount > 0 ? '继续抽卡复习' : '知识空间';
        final subtitle = item.dueCount > 0
            ? '今日 ${item.dueCount} 张待复习，共 ${item.cardCount} 张知识卡'
            : hasCards
            ? '共 ${item.cardCount} 张知识卡，${item.weakCount} 张薄弱卡'
            : hasMaterials
            ? '${item.materialCount} 份资料已导入，可生成知识卡'
            : '导入资料，让甜甜帮你生成知识卡';
        final action = item.dueCount > 0
            ? '开始抽卡'
            : hasCards
            ? '进入空间'
            : hasMaterials
            ? '生成知识卡'
            : '导入资料';
        final actionIcon = item.dueCount > 0
            ? Icons.style_rounded
            : hasCards || hasMaterials
            ? Icons.auto_awesome_rounded
            : Icons.upload_file_rounded;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/plan/study/flash-review'),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: colors.study.withValues(alpha: 0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.study.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '甜甜知识空间',
                            style: AppTextStyles.caption.copyWith(
                              color: colors.study,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: colors.study,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                actionIcon,
                                color: colors.textOnAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                action,
                                style: TextStyle(
                                  color: colors.textOnAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    width: 92,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school_rounded,
                          color: colors.study,
                          size: 28,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _knowledgeMiniStat(
                          value: '${item.cardCount}',
                          label: '卡片',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _knowledgeMiniStat(
                          value: '${item.dueCount}',
                          label: '待复习',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Container(
        height: 150,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _knowledgeMiniStat({required String value, required String label}) {
    final colors = context.growthColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  //  顶部数据卡片（模块英雄卡片）
  Widget _buildStatsCards(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<int> todayMinutes,
    AsyncValue<List<StudyRecord>> todayRecords,
    DailyGoal studyGoal,
  ) {
    final colors = context.growthColors;
    return todayMinutes.when(
      data: (minutes) {
        final progress = studyGoal.target > 0
            ? (minutes / studyGoal.target).clamp(0.0, 1.0)
            : 0.0;
        return ModuleHeroCard(
          icon: Icons.timer_rounded,
          title: '今日学习',
          primaryValue: _formatMinutes(minutes),
          primaryLabel: '今日已学习',
          color: colors.study,
          progress: progress,
          targetLabel: '目标 ${_formatMinutes(studyGoal.target)}',
          metrics: [
            ModuleMetricChip(
              icon: Icons.repeat_rounded,
              value:
                  '${todayRecords.whenOrNull(data: (list) => list.length) ?? 0}次',
              label: '专注次数',
            ),
            ModuleMetricChip(
              icon: Icons.auto_stories_rounded,
              value:
                  '${todayRecords.whenOrNull(data: (list) => list.map((r) => r.subject).toSet().length) ?? 0}科',
              label: '科目',
            ),
            ModuleMetricChip(
              icon: Icons.star_rounded,
              value:
                  '+${todayRecords.whenOrNull(data: (list) => list.fold<int>(0, (s, r) => s + r.expGained)) ?? 0}',
              label: '今日经验',
            ),
          ],
          onTargetTap: () => _showGoalEditSheet(context, ref, studyGoal),
        );
      },
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Center(child: CircularProgressIndicator(color: colors.study)),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildSubjectDistRangeSelector() {
    final colors = context.growthColors;
    const ranges = [
      {'label': '日', 'days': 1},
      {'label': '周', 'days': 7},
      {'label': '月', 'days': 30},
    ];

    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ranges.map((range) {
          final isSelected = _subjectDistDays == range['days'];
          return GestureDetector(
            onTap: () =>
                setState(() => _subjectDistDays = range['days'] as int),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? colors.study : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                range['label'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? colors.textOnAccent
                      : colors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  //  盠编辑弹窗 
  void _showGoalEditSheet(
    BuildContext context,
    WidgetRef ref,
    DailyGoal currentGoal,
  ) {
    final colors = context.growthColors;
    GoalEditSheet.show(
      context: context,
      title: '设置每日学习目标',
      currentValue: currentGoal.target,
      unit: '分钟/天',
      min: 10,
      max: 480,
      step: 10,
      suggestion: '建议每天学习 60~180 分钟',
      color: colors.study,
      onSave: (value) async {
        final goals = ref.read(dailyGoalsProvider);
        final newGoals = goals.map((g) {
          if (g.name == '学习') {
            return DailyGoal(name: '学习', target: value, unit: '分钟');
          }
          return g;
        }).toList();
        ref.read(dailyGoalsProvider.notifier).state = newGoals;
        final repo = ref.read(settingRepositoryProvider);
        await repo.setSetting('daily_goals', _encodeGoals(newGoals));
      },
    );
  }

  String _encodeGoals(List<DailyGoal> goals) {
    return jsonEncode(goals.map((g) => g.toJson()).toList());
  }

  //  学习趋势区域（带时间范围选择噼
  Widget _buildStudyTrendSection(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '学习趋势',
              style: AppTextStyles.sectionTitle.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        //  时间范围选择?
        _buildRangeSelector(context),
        const SizedBox(height: AppSpacing.md),
        //  图表 
        _buildChartForRange(),
      ],
    );
  }

  //  时间范围选择?
  Widget _buildRangeSelector(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _buildRangeTab(context, 'week', '本周'),
          _buildRangeTab(context, 'month', '本月'),
          _buildRangeTab(context, 'year', '本年'),
        ],
      ),
    );
  }

  Widget _buildRangeTab(BuildContext context, String value, String label) {
    final colors = context.growthColors;
    final isSelected = _selectedRange == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedRange != value) {
            setState(() => _selectedRange = value);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? colors.study : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.24),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? colors.textOnAccent : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  //  根据范围构建图表 
  Widget _buildChartForRange() {
    switch (_selectedRange) {
      case 'week':
        return _buildWeekChart();
      case 'month':
        return _buildMonthChart();
      case 'year':
        return _buildYearChart();
      default:
        return _buildWeekChart();
    }
  }

  Widget _buildWeekChart() {
    final weeklyDaily = ref.watch(weeklyDailyStudyProvider);
    return weeklyDaily.when(
      data: (list) {
        final totalMinutes = list.fold<int>(
          0,
          (sum, d) => sum + d.studyMinutes,
        );
        final hours = (totalMinutes / 60).toStringAsFixed(1);
        final days = list.where((d) => d.studyMinutes > 0).length;
        return _StudyBarChart(
          stats: list
              .map(
                (d) => _BarData(
                  label: _weekdayName(d.date),
                  subLabel: '${d.date.month}/${d.date.day}',
                  value: d.studyMinutes,
                  date: d.date,
                ),
              )
              .toList(),
          totalHours: hours,
          totalDays: days,
          range: 'week',
        );
      },
      loading: () => _buildChartLoading(),
      error: (_, _) => const ErrorRetryWidget(),
    );
  }

  Widget _buildMonthChart() {
    final monthlyDaily = ref.watch(monthlyDailyStudyProvider);
    return monthlyDaily.when(
      data: (list) {
        // Aggregate into 4 weekly buckets
        final weeks = _aggregateWeeks(list);
        final totalMinutes = weeks.fold<int>(
          0,
          (sum, w) => sum + w.totalValue!,
        );
        final hours = (totalMinutes / 60).toStringAsFixed(1);
        final days = list.where((d) => d.studyMinutes > 0).length;
        return _StudyBarChart(
          stats: weeks,
          totalHours: hours,
          totalDays: days,
          range: 'month',
        );
      },
      loading: () => _buildChartLoading(),
      error: (_, _) => const ErrorRetryWidget(),
    );
  }

  /// Aggregate daily stats into 4 weekly buckets for month view.
  List<_BarData> _aggregateWeeks(List<DailyStats> dailyList) {
    if (dailyList.isEmpty) {
      return List.generate(
        4,
        (i) => _BarData(
          label: '第${_weekCn(i)}周',
          subLabel: '',
          value: 0,
          totalValue: 0,
          avgValue: 0,
        ),
      );
    }

    // Sort by date ascending
    final sorted = List<DailyStats>.from(dailyList)
      ..sort((a, b) => a.date.compareTo(b.date));

    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    // Build 4 week buckets based on calendar weeks within the month
    final List<List<DailyStats>> buckets = [[], [], [], []];
    for (final d in sorted) {
      // Week index: day 1-7 鈫?0, 8-14 鈫?1, 15-21 鈫?2, 22-31 鈫?3
      final weekIdx = ((d.date.day - 1) / 7).floor().clamp(0, 3);
      buckets[weekIdx].add(d);
    }

    return List.generate(4, (i) {
      final bucket = buckets[i];
      final total = bucket.fold<int>(0, (s, d) => s + d.studyMinutes);
      final dayCount = bucket.length;
      final avg = dayCount > 0 ? (total / dayCount).round() : 0;

      // Calculate date range for subLabel
      final startDay = i * 7 + 1;
      final endDay = (i == 3)
          ? DateTime(year, month + 1, 0)
                .day // last day of month
          : (i + 1) * 7;
      final subLabel = '$month/$startDay-$month/$endDay';

      return _BarData(
        label: '第${_weekCn(i)}周',
        subLabel: subLabel,
        value: total,
        totalValue: total,
        avgValue: avg,
      );
    });
  }

  String _weekCn(int index) {
    const names = ['一', '二', '三', '四'];
    return names[index];
  }

  Widget _buildYearChart() {
    final yearlyMonthly = ref.watch(yearlyMonthlyStudyProvider);
    return yearlyMonthly.when(
      data: (list) {
        final totalMinutes = list.fold<int>(
          0,
          (sum, m) => sum + m.studyMinutes,
        );
        final hours = (totalMinutes / 60).toStringAsFixed(1);
        final activeMonths = list.where((m) => m.studyMinutes > 0).length;
        return _StudyBarChart(
          stats: list
              .map(
                (m) => _BarData(
                  label: _monthCn(m.month),
                  value: m.studyMinutes,
                  totalValue: m.studyMinutes,
                ),
              )
              .toList(),
          totalHours: hours,
          totalDays: activeMonths,
          range: 'year',
        );
      },
      loading: () => _buildChartLoading(),
      error: (_, _) => const ErrorRetryWidget(),
    );
  }

  String _monthCn(String monthStr) {
    final parts = monthStr.split('-');
    if (parts.length == 2) {
      final m = int.tryParse(parts[1]) ?? 1;
      return '$m月';
    }
    return monthStr;
  }

  Widget _buildChartLoading() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: context.growthColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.growthColors.border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  String _weekdayName(DateTime date) {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[date.weekday - 1];
  }

  //  忍操作 
  Widget _buildQuickActions(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_rounded,
            label: '添加记录',
            color: colors.study,
            onTap: () => context.push('/plan/study/add'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.timer_outlined,
            label: '专注计时',
            color: colors.success,
            onTap: () => context.push('/focus'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.history_rounded,
            label: '全部记录',
            color: colors.textTertiary,
            onTap: () => context.push('/plan/study/recent'),
          ),
        ),
      ],
    );
  }

  //  科目分布 
  Widget _buildSubjectDistribution(
    BuildContext context,
    AsyncValue<Map<String, int>> subjectDist,
  ) {
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '科目分布',
              style: AppTextStyles.sectionTitle.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            _buildSubjectDistRangeSelector(),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/plan/study/subjects'),
              child: Row(
                children: [
                  Text(
                    '详情',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        subjectDist.when(
          data: (dist) {
            if (dist.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.pie_chart_outline,
                title: '暂无科目数据',
                subtitle: '开始学习后，科目分布会显示在这里',
                accentColor: colors.study,
              );
            }
            return _SubjectDistributionCard(dist: dist);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const ErrorRetryWidget(),
        ),
      ],
    );
  }

  //  近?
  Widget _buildRecentRecords(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<StudyRecord>> recentRecords,
  ) {
    final colors = context.growthColors;
    return recentRecords.when(
      data: (records) {
        if (records.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.menu_book_outlined,
            title: '还没有学习记录',
            subtitle: '点击右下角按钮开始学习',
            accentColor: colors.study,
          );
        }
        const maxVisible = 5;
        final visibleRecords = _isRecentExpanded
            ? records
            : records.take(maxVisible).toList();
        return ModuleRecordsCard(
          title: '最近记录',
          action: '查看全部',
          onActionTap: () => context.push('/plan/study/recent'),
          color: colors.study,
          recordCount: records.length,
          maxVisible: maxVisible,
          isExpanded: _isRecentExpanded,
          onToggleExpand: () =>
              setState(() => _isRecentExpanded = !_isRecentExpanded),
          children: visibleRecords.map((record) {
            final date = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
            final dateStr =
                '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
            return SwipeDeleteTile(
              key: ValueKey('study_${record.id}'),
              onConfirmDelete: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: colors.card,
                    surfaceTintColor: colors.card,
                    title: Text(
                      '删除确认',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    content: Text(
                      '确定要删除这条学习记录吗？',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.danger,
                        ),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  final repo = ref.read(studyRepositoryProvider);
                  await repo.deleteStudyRecord(record.id);
                  ref.invalidate(recentStudyRecordsProvider);
                  ref.invalidate(todayStudyMinutesProvider);
                  ref.invalidate(todayStudyRecordsProvider);
                  ref.invalidate(dashboardProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('已删除')));
                  }
                  return true;
                }
                return false;
              },
              onDismissed: () {},
              child: RecentRecordTile(
                icon: record.mode == 'professional'
                    ? Icons.school
                    : Icons.menu_book,
                iconColor: colors.textOnAccent,
                iconBackgroundColor: colors.study,
                title: record.title,
                subtitle:
                    '${record.subject ?? ''} · ${record.durationMinutes}分钟 · $dateStr',
                primaryBadge: '+${record.expGained} EXP',
                primaryBadgeColor: colors.study,
                secondaryBadge: null,
                onTap: () => _showStudyRecordDetail(context, record),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('加载失败：$e', style: TextStyle(color: colors.textSecondary)),
      ),
    );
  }

  //  记录详情弹窗 

  void _showStudyRecordDetail(BuildContext context, StudyRecord record) {
    final colors = context.growthColors;
    final date = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    final weekday = const [
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六',
      '周日',
    ][date.weekday - 1];
    final dateStr = '${date.year}年${date.month}月${date.day}日 $weekday';

    final detailItems = <DetailItem>[
      DetailItem(
        label: '科目',
        value: record.subject ?? '未分类',
        icon: Icons.book_outlined,
      ),
      DetailItem(
        label: '难度',
        value: record.difficultyLevel != null
            ? '${record.difficultyLevel} / 5'
            : '--',
        icon: Icons.signal_cellular_alt_rounded,
      ),
      DetailItem(
        label: '掌握度',
        value: record.masteryLevel != null
            ? '${record.masteryLevel} / 5'
            : '--',
        icon: Icons.check_circle_outline,
      ),
      DetailItem(
        label: '经验值',
        value: '+${record.expGained} EXP',
        icon: Icons.star_outline,
      ),
    ];

    final noteCard = (record.note != null && record.note!.isNotEmpty)
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.softBlue.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notes_rounded, size: 16, color: colors.study),
                    const SizedBox(width: 6),
                    Text(
                      '备注',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.study,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  record.note!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => RecordDetailSheet(
        title: dateStr,
        primaryMetricLabel: '学习时长',
        primaryMetricValue: '${record.durationMinutes} 分钟',
        detailItems: detailItems,
        accentColor: colors.study,
        extraCards: noteCard,
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}
