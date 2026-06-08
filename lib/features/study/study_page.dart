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
import '../../shared/providers/settings_provider.dart';
import '../../shared/providers/study_provider.dart';
import '../../shared/widgets/common/common_widgets.dart';
import '../../shared/widgets/swipe_delete_tile.dart';
import '../pet/models/pet_scene_model.dart';
import '../pet/widgets/pet_scene_banner.dart';

// =============================================================================
// 科目颜色映射（沉稳蓝风格）
// =============================================================================

const _subjectColors = <String, Color>{
  '数学': AppColors.study,
  '英语': AppColors.success,
  '物理': Color(0xFF3B82F6),
  '化学': Color(0xFF06B6D4),
  '编程': AppColors.primaryDark,
  '语文': Color(0xFF4ADE80),
  '历史': Color(0xFF6366F1),
  '地理': Color(0xFF14B8A6),
  '生物': Color(0xFF0EA5E9),
  '其他': AppColors.textTertiary,
};

// =============================================================================
// StudyPage（沉稳蓝配色）
// =============================================================================

class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  String _selectedRange = 'week'; // 'week' | 'month' | 'year'
  bool _isRecentExpanded = false;

  @override
  Widget build(BuildContext context) {
    final todayMinutes = ref.watch(todayStudyMinutesProvider);
    final todayRecords = ref.watch(todayStudyRecordsProvider);
    final recentRecords = ref.watch(recentStudyRecordsProvider);
    final subjectDist = ref.watch(subjectDistributionProvider);
    final dailyGoals = ref.watch(dailyGoalsProvider);
    final studyGoal = dailyGoals.firstWhere(
      (g) => g.name == '学习',
      orElse: () => const DailyGoal(name: '学习', target: 120, unit: '分钟'),
    );

    return Scaffold(
      backgroundColor: AppColors.softBlue,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('学习', style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              )),
              centerTitle: false,
              backgroundColor: AppColors.softBlue,
              actions: [
                IconButton(
                  tooltip: '专注计时',
                  onPressed: () => context.push('/focus'),
                  icon: const Icon(Icons.timer_outlined, color: AppColors.primaryDark),
                ),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayStudyMinutesProvider);
          ref.invalidate(todayStudyRecordsProvider);
          ref.invalidate(weeklyStudyMinutesProvider);
          ref.invalidate(weeklyDailyStudyProvider);
          ref.invalidate(monthlyDailyStudyProvider);
          ref.invalidate(yearlyMonthlyStudyProvider);
          ref.invalidate(recentStudyRecordsProvider);
          ref.invalidate(subjectDistributionProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 小猫提示条 ──
              PetSceneBanner(
                module: PetModuleType.study,
                hasRecords: (todayMinutes.valueOrNull ?? 0) > 0,
                onTap: () => context.push('/pet-center'),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── 顶部数据卡片 ──
              _buildStatsCards(context, ref, todayMinutes, todayRecords, studyGoal),
              const SizedBox(height: AppSpacing.xl),

              // ── 学习趋势 ──
              _buildStudyTrendSection(context),
              const SizedBox(height: AppSpacing.xl),

              // ── 快捷操作 ──
              _buildQuickActions(context),
              const SizedBox(height: AppSpacing.xl),

              // ── 科目分布 ──
              _buildSubjectDistribution(context, subjectDist),
              const SizedBox(height: AppSpacing.xl),

              // ── 最近记录 ──
              _buildRecentRecords(context, ref, recentRecords),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plan/study/add'),
        backgroundColor: AppColors.study,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ── 顶部数据卡片（模块英雄卡片）──
  Widget _buildStatsCards(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<int> todayMinutes,
    AsyncValue<List<StudyRecord>> todayRecords,
    DailyGoal studyGoal,
  ) {
    return todayMinutes.when(
      data: (minutes) {
        final progress = studyGoal.target > 0 ? (minutes / studyGoal.target).clamp(0.0, 1.0) : 0.0;
        return ModuleHeroCard(
          icon: Icons.timer_rounded,
          title: '今日学习',
          primaryValue: _formatMinutes(minutes),
          primaryLabel: '今日已学习',
          color: AppColors.study,
          progress: progress,
          targetLabel: '目标 ${_formatMinutes(studyGoal.target)}',
          metrics: [
            ModuleMetricChip(
              icon: Icons.repeat_rounded,
              value: '${todayRecords.whenOrNull(data: (list) => list.length) ?? 0}次',
              label: '专注次数',
            ),
            ModuleMetricChip(
              icon: Icons.auto_stories_rounded,
              value: '${todayRecords.whenOrNull(data: (list) => list.map((r) => r.subject).toSet().length) ?? 0}科',
              label: '科目',
            ),
            ModuleMetricChip(
              icon: Icons.star_rounded,
              value: '+${todayRecords.whenOrNull(data: (list) => list.fold<int>(0, (s, r) => s + r.expGained)) ?? 0}',
              label: '今日经验',
            ),
          ],
          onTargetTap: () => _showGoalEditSheet(context, ref, studyGoal),
        );
      },
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ── 目标编辑弹窗 ──
  void _showGoalEditSheet(BuildContext context, WidgetRef ref, DailyGoal currentGoal) {
    GoalEditSheet.show(
      context: context,
      title: '设置每日学习目标',
      currentValue: currentGoal.target,
      unit: '分钟/天',
      min: 10,
      max: 480,
      step: 10,
      suggestion: '建议每天学习 60~180 分钟',
      color: AppColors.study,
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

  // ── 学习趋势区域（带时间范围选择器）──
  Widget _buildStudyTrendSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('学习趋势', style: AppTextStyles.sectionTitle),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // ── 时间范围选择器 ──
        _buildRangeSelector(),
        const SizedBox(height: AppSpacing.md),
        // ── 图表 ──
        _buildChartForRange(),
      ],
    );
  }

  // ── 时间范围选择器 ──
  Widget _buildRangeSelector() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          _buildRangeTab('week', '本周'),
          _buildRangeTab('month', '本月'),
          _buildRangeTab('year', '本年'),
        ],
      ),
    );
  }

  Widget _buildRangeTab(String value, String label) {
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
            color: isSelected ? AppColors.study : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.study.withValues(alpha: 0.3),
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
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ── 根据范围构建图表 ──
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
        final totalMinutes = list.fold<int>(0, (sum, d) => sum + d.studyMinutes);
        final hours = (totalMinutes / 60).toStringAsFixed(1);
        final days = list.where((d) => d.studyMinutes > 0).length;
        return _StudyBarChart(
          stats: list.map((d) => _BarData(
            label: _weekdayName(d.date),
            subLabel: '${d.date.month}/${d.date.day}',
            value: d.studyMinutes,
            date: d.date,
          )).toList(),
          totalHours: hours,
          totalDays: days,
          range: 'week',
        );
      },
      loading: () => _buildChartLoading(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildMonthChart() {
    final monthlyDaily = ref.watch(monthlyDailyStudyProvider);
    return monthlyDaily.when(
      data: (list) {
        // Aggregate into 4 weekly buckets
        final weeks = _aggregateWeeks(list);
        final totalMinutes = weeks.fold<int>(0, (sum, w) => sum + w.totalValue!);
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
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Aggregate daily stats into 4 weekly buckets for month view.
  List<_BarData> _aggregateWeeks(List<DailyStats> dailyList) {
    if (dailyList.isEmpty) {
      return List.generate(4, (i) => _BarData(
        label: '第${_weekCn(i)}周',
        subLabel: '',
        value: 0,
        totalValue: 0,
        avgValue: 0,
      ));
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
      // Week index: day 1-7 → 0, 8-14 → 1, 15-21 → 2, 22-31 → 3
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
          ? DateTime(year, month + 1, 0).day // last day of month
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
        final totalMinutes = list.fold<int>(0, (sum, m) => sum + m.studyMinutes);
        final hours = (totalMinutes / 60).toStringAsFixed(1);
        final activeMonths = list.where((m) => m.studyMinutes > 0).length;
        return _StudyBarChart(
          stats: list.map((m) => _BarData(
            label: _monthCn(m.month),
            value: m.studyMinutes,
            totalValue: m.studyMinutes,
          )).toList(),
          totalHours: hours,
          totalDays: activeMonths,
          range: 'year',
        );
      },
      loading: () => _buildChartLoading(),
      error: (_, _) => const SizedBox.shrink(),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  String _weekdayName(DateTime date) {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[date.weekday - 1];
  }

  // ── 快捷操作 ──
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_rounded,
            label: '添加记录',
            color: AppColors.study,
            onTap: () => context.push('/plan/study/add'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.timer_outlined,
            label: '专注计时',
            color: AppColors.success,
            onTap: () => context.push('/focus'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.history_rounded,
            label: '全部记录',
            color: AppColors.textTertiary,
            onTap: () => context.push('/plan/study/recent'),
          ),
        ),
      ],
    );
  }

  // ── 科目分布 ──
  Widget _buildSubjectDistribution(
    BuildContext context,
    AsyncValue<Map<String, int>> subjectDist,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('科目分布', style: AppTextStyles.sectionTitle),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/plan/study/subjects'),
              child: Row(
                children: [
                  Text('查看详情', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        subjectDist.when(
          data: (dist) {
            if (dist.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.pie_chart_outline,
                title: '暂无科目数据',
                subtitle: '开始学习后，科目分布将在此显示',
                accentColor: AppColors.study,
              );
            }
            return _SubjectDistributionCard(dist: dist);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── 最近记录 ──
  Widget _buildRecentRecords(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<StudyRecord>> recentRecords,
  ) {
    return recentRecords.when(
      data: (records) {
        if (records.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.menu_book_outlined,
            title: '还没有学习记录',
            subtitle: '点击右下角按钮开始学习',
            accentColor: AppColors.study,
          );
        }
        const maxVisible = 5;
        final visibleRecords = _isRecentExpanded ? records : records.take(maxVisible).toList();
        return ModuleRecordsCard(
          title: '最近记录',
          action: '查看全部',
          onActionTap: () => context.push('/plan/study/recent'),
          color: AppColors.study,
          recordCount: records.length,
          maxVisible: maxVisible,
          isExpanded: _isRecentExpanded,
          onToggleExpand: () => setState(() => _isRecentExpanded = !_isRecentExpanded),
          children: visibleRecords.map((record) {
            final date = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
            final dateStr = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
            return SwipeDeleteTile(
              key: ValueKey('study_${record.id}'),
              onConfirmDelete: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('删除确认'),
                    content: const Text('确定要删除这条学习记录吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
                  }
                }
                return false;
              },
              onDismissed: () {},
              child: RecentRecordTile(
                icon: record.mode == 'professional' ? Icons.school : Icons.menu_book,
                iconColor: Colors.white,
                iconBackgroundColor: AppColors.study,
                title: record.title,
                subtitle: '${record.subject ?? ''} · ${record.durationMinutes}分钟 · $dateStr',
                primaryBadge: '+${record.expGained} EXP',
                primaryBadgeColor: AppColors.study,
                secondaryBadge: null,
                onTap: () => _showStudyRecordDetail(context, record),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  // ─── 记录详情弹窗 ────────────────────────────────────────────────────────

  void _showStudyRecordDetail(BuildContext context, StudyRecord record) {
    final date = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    final weekday = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];
    final dateStr = '${date.year}年${date.month}月${date.day}日 $weekday';

    final detailItems = <DetailItem>[
      DetailItem(
        label: '科目',
        value: record.subject ?? '未分类',
        icon: Icons.book_outlined,
      ),
      DetailItem(
        label: '难度',
        value: record.difficultyLevel != null ? '${record.difficultyLevel} / 5' : '--',
        icon: Icons.signal_cellular_alt_rounded,
      ),
      DetailItem(
        label: '掌握度',
        value: record.masteryLevel != null ? '${record.masteryLevel} / 5' : '--',
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
              color: AppColors.study.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notes_rounded, size: 16, color: AppColors.study),
                    const SizedBox(width: 6),
                    Text(
                      '备注',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.study,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  record.note!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
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
        accentColor: AppColors.study,
        extraCard: noteCard,
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

// ── 图表用格式化：30m / 1.5h ──
String _formatMinutesCompact(int minutes) {
  if (minutes <= 0) return '0m';
  if (minutes < 60) return '${minutes}m';
  final h = minutes / 60;
  // 1 decimal, drop trailing .0
  return h == h.roundToDouble()
      ? '${h.round()}h'
      : '${h.toStringAsFixed(1)}h';
}

// =============================================================================
// 柱状图数据模型
// =============================================================================

class _BarData {
  const _BarData({
    required this.label,
    required this.value,
    this.date,
    this.subLabel,
    this.totalValue,
    this.avgValue,
  });

  final String label;
  final int value;
  final DateTime? date;

  /// Second line for x-axis (e.g. "6/2" or "6/1-6/7")
  final String? subLabel;

  /// Total minutes for month/week aggregation
  final int? totalValue;

  /// Daily average for month/week aggregation
  final int? avgValue;
}

// =============================================================================
// 学习趋势柱状图（fl_chart，支持周/月/年）
// =============================================================================

class _StudyBarChart extends StatefulWidget {
  const _StudyBarChart({
    required this.stats,
    required this.totalHours,
    required this.totalDays,
    required this.range,
  });

  final List<_BarData> stats;
  final String totalHours;
  final int totalDays;
  final String range; // 'week' | 'month' | 'year'

  @override
  State<_StudyBarChart> createState() => _StudyBarChartState();
}

class _StudyBarChartState extends State<_StudyBarChart> {
  int? _touchedIndex;

  static const _barColor = AppColors.study;
  static const _tooltipBg = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final minutesList = widget.stats.map((s) => s.value).toList();
    final scale = buildDurationChartScale(minutesList);
    final yMax = scale.maxY;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ── 顶部统计 ──
          Row(
            children: [
              _buildStat('总时长', _formatMinutesCompact(
                widget.stats.fold<int>(0, (s, b) => s + b.value),
              )),
              const SizedBox(width: AppSpacing.xl),
              _buildStat(
                widget.range == 'year' ? '活跃月份' : '学习天数',
                widget.range == 'year'
                    ? '${widget.totalDays} 月'
                    : '${widget.totalDays} 天',
              ),
              const Spacer(),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // ── 柱状图 + 顶部标签 ──
          ClipRect(
            child: SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: yMax * 1.25, // extra space for value labels
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: _buildTouchData(),
                  titlesData: _buildTitles(scale, yMax),
                  gridData: _buildGrid(scale),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(widget.stats.length, (i) {
                    return _buildBarGroup(i, yMax);
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 触摸交互 ──
  BarTouchData _buildTouchData() {
    final minutesList = widget.stats.map((s) => s.value).toList();
    final scale = buildDurationChartScale(minutesList);

    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => _tooltipBg,
        tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final bar = widget.stats[group.x];
          final title = bar.label;
          return BarTooltipItem(
            '$title\n',
            const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: scale.formatTooltipValue(bar.value.toDouble()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.range == 'month' && bar.avgValue != null) ...[
                const TextSpan(text: '\n'),
                TextSpan(
                  text: '日均 ${scale.formatTooltipValue(bar.avgValue!.toDouble())}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          );
        },
      ),
      touchCallback: (event, response) {
        if (event is FlLongPressEnd || event is FlPanEndEvent) {
          setState(() => _touchedIndex = null);
        } else if (response?.spot != null) {
          final index = response!.spot!.touchedBarGroupIndex;
          if (index != _touchedIndex) {
            setState(() => _touchedIndex = index);
          }
        }
      },
    );
  }

  // ── 坐标轴标题 ──
  FlTitlesData _buildTitles(DurationChartScale scale, double yMax) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: widget.range == 'week' ? 44 : 36,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= widget.stats.length) {
              return const SizedBox.shrink();
            }
            return _buildBottomLabel(index);
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          interval: scale.interval,
          getTitlesWidget: (value, meta) {
            if (value == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                scale.formatAxisLabel(value),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.right,
              ),
            );
          },
        ),
      ),
      // ── 顶部数值标签 ──
      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= widget.stats.length) {
              return const SizedBox.shrink();
            }
            final bar = widget.stats[index];
            if (bar.value == 0) return const SizedBox.shrink();
            return _ValueBubble(
              value: _formatMinutesCompact(bar.value),
              avgValue: bar.avgValue != null
                  ? _formatMinutesCompact(bar.avgValue!)
                  : null,
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  // ── 网格线 ──
  FlGridData _buildGrid(DurationChartScale scale) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: scale.interval,
      getDrawingHorizontalLine: (value) => FlLine(
        color: AppColors.border.withValues(alpha: 0.6),
        strokeWidth: 1,
        dashArray: [4, 4],
      ),
    );
  }

  // ── 单个柱子 ──
  BarChartGroupData _buildBarGroup(int index, double yMax) {
    final bar = widget.stats[index];
    final isTouched = index == _touchedIndex;
    final barColor = _isHighlighted(index) ? _barColor : _barColor.withValues(alpha: 0.3);

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: bar.value.toDouble(),
          color: barColor,
          width: _barWidth,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: yMax,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
        ),
      ],
      showingTooltipIndicators: isTouched ? [0] : [],
    );
  }

  // ── 底部标签（双行：主标签 + 日期/范围）──
  Widget _buildBottomLabel(int index) {
    final bar = widget.stats[index];
    final highlighted = _isHighlighted(index);

    final mainStyle = TextStyle(
      fontSize: _bottomLabelFontSize,
      fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
      color: highlighted ? _barColor : AppColors.textPrimary,
    );
    final subStyle = TextStyle(
      fontSize: 10,
      color: highlighted ? _barColor : AppColors.textTertiary,
    );

    if (widget.range == 'week') {
      // Two lines: 周一 / 6/2
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(bar.label, style: mainStyle),
            if (bar.subLabel != null) Text(bar.subLabel!, style: subStyle),
          ],
        ),
      );
    }

    if (widget.range == 'month') {
      // Two lines: 第一周 / 6/1-6/7
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(bar.label, style: mainStyle),
            if (bar.subLabel != null && bar.subLabel!.isNotEmpty)
              Text(bar.subLabel!, style: subStyle),
          ],
        ),
      );
    }

    // Year: single line
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(bar.label, style: mainStyle),
    );
  }

  double get _bottomLabelFontSize {
    switch (widget.range) {
      case 'week':
        return 11;
      case 'month':
        return 10;
      case 'year':
        return 11;
      default:
        return 11;
    }
  }

  // ── 图例 ──
  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _barColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '学习时长',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── 辅助方法 ──
  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  bool _isHighlighted(int index) {
    final bar = widget.stats[index];
    if (widget.range == 'week' && bar.date != null) {
      final now = DateTime.now();
      return bar.date!.year == now.year &&
          bar.date!.month == now.month &&
          bar.date!.day == now.day;
    }
    return false;
  }

  double get _barWidth {
    switch (widget.range) {
      case 'week':
        return 20;
      case 'month':
        return 28;
      case 'year':
        return 16;
      default:
        return 20;
    }
  }
}

// =============================================================================
// 柱顶数值气泡
// =============================================================================

class _ValueBubble extends StatelessWidget {
  const _ValueBubble({required this.value, this.avgValue});

  final String value;
  final String? avgValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.study,
            ),
          ),
        ),
        if (avgValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '日$avgValue',
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// 快捷操作卡片
// =============================================================================

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 科目分布卡片（左饼图 + 右图例）
// =============================================================================

class _SubjectDistributionCard extends StatefulWidget {
  const _SubjectDistributionCard({required this.dist});

  final Map<String, int> dist;

  @override
  State<_SubjectDistributionCard> createState() =>
      _SubjectDistributionCardState();
}

class _SubjectDistributionCardState extends State<_SubjectDistributionCard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.dist.values.fold<int>(0, (sum, v) => sum + v);
    final sorted = widget.dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 左侧：饼图 ──
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    sections: _buildSections(top5, total),
                  ),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.linear,
                ),
                // 中心总时长
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatHours(total),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '总时长',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ── 右侧：图例列表 ──
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(top5.length, (index) {
                final entry = top5[index];
                final color = _getSubjectColor(entry.key);
                final percent =
                    total > 0 ? (entry.value / total * 100).round() : 0;
                final isSelected = _touchedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _touchedIndex = _touchedIndex == index ? -1 : index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        // 彩色圆点
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 10 : 8,
                          height: isSelected ? 10 : 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 科目名
                        SizedBox(
                          width: 36,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 进度条
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: entry.value / total,
                              minHeight: 6,
                              backgroundColor: color.withValues(alpha: 0.1),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 时长 + 百分比
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatMinutes(entry.value),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<MapEntry<String, int>> entries,
    int total,
  ) {
    return List.generate(entries.length, (index) {
      final isTouched = _touchedIndex == index;
      final entry = entries[index];
      final color = _getSubjectColor(entry.key);

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '',
        radius: isTouched ? 38 : 32,
        borderSide: isTouched
            ? BorderSide(color: Colors.white, width: 2)
            : BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1),
      );
    });
  }

  String _formatHours(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}.${(m * 10 / 60).round()}h' : '${h}h';
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h${m}m' : '${h}h';
  }

  Color _getSubjectColor(String subject) {
    return _subjectColors[subject] ?? AppColors.study;
  }
}


