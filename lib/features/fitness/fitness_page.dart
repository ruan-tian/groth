import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

import '../../app/design/design.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/chart_scale_utils.dart';
import '../../shared/providers/dashboard_provider.dart'
    hide fitnessRepositoryProvider, settingRepositoryProvider;
import '../../shared/providers/fitness_provider.dart';
import '../../shared/providers/repository_providers.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/widgets/common/common_widgets.dart';
import '../../shared/widgets/swipe_delete_tile.dart';
import '../plan/utils/plan_module_assets.dart';
import '../plan/widgets/plan_module_visuals.dart';

part 'widgets/fitness_page_widgets.dart';

/// 健身首页
class FitnessPage extends ConsumerStatefulWidget {
  const FitnessPage({super.key, this.isEmbedded = false, this.capsuleNav});

  final bool isEmbedded;
  final Widget? capsuleNav;

  @override
  ConsumerState<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends ConsumerState<FitnessPage> {
  int _selectedRange = 30; // 7=week, 30=month, 365=year
  bool _isRecordsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final todayMinutes = ref.watch(todayFitnessMinutesProvider);
    final weeklyCount = ref.watch(weeklyFitnessCountProvider);
    final recentRecords = ref.watch(recentFitnessRecordsProvider);
    final dailyGoals = ref.watch(dailyGoalsProvider);

    final fitnessGoal = dailyGoals.firstWhere(
      (g) => g.name == '健身',
      orElse: () => DailyGoal(name: '健身', target: 45, unit: '分钟'),
    );
    final weeklyGoal = ref.watch(weeklyFitnessGoalProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text('健身', style: AppTextStyles.pageTitle),
              centerTitle: false,
              backgroundColor: AppColors.paper,
              actions: [
                IconButton(
                  tooltip: '身体数据',
                  onPressed: () =>
                      context.push('/plan/fitness/body-metric/detail'),
                  icon: const Icon(Icons.monitor_weight_outlined),
                ),
              ],
            ),
      body: ModulePageSurface(
        color: AppColors.fitness,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayFitnessMinutesProvider);
            ref.invalidate(weeklyFitnessCountProvider);
            ref.invalidate(recentFitnessRecordsProvider);
            ref.invalidate(fitnessChartDataProvider(7));
            ref.invalidate(fitnessChartDataProvider(30));
            ref.invalidate(fitnessChartDataProvider(365));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.capsuleNav != null) widget.capsuleNav!,

                // ── 1. 提示条 ──
                PlanModuleVisualHeader(
                  module: PlanModuleType.fitness,
                  color: AppColors.fitness,
                ),
                const SizedBox(height: AppSpacing.md),
                PlanModuleActionImageCard(
                  module: PlanModuleType.fitness,
                  color: AppColors.fitness,
                  onTap: () => context.push('/plan/fitness/timer'),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── 2. 今日训练（合并计时器）──
                _buildTodayTrainingCard(todayMinutes, fitnessGoal),
                const SizedBox(height: AppSpacing.lg),

                // ── 3. 记练训练入口 ──
                _buildRecordTrainingEntry(context),
                const SizedBox(height: AppSpacing.lg),

                // ── 4. 本周训练 ──
                _buildWeeklyTrainingCard(weeklyCount, weeklyGoal),
                const SizedBox(height: AppSpacing.lg),

                // ── 5. 今日进度 ──
                _buildTodayProgress(todayMinutes, fitnessGoal),
                const SizedBox(height: AppSpacing.lg),

                // ── 6. 体重曲线 ──
                _buildWeightCurveCard(),
                const SizedBox(height: AppSpacing.lg),

                // ── 7. 最近记录 ──
                recentRecords.when(
                  data: (records) {
                    if (records.isEmpty) {
                      return _buildEmptyState();
                    }
                    final displayCount = _isRecordsExpanded
                        ? records.length
                        : (records.length > 5 ? 5 : records.length);
                    return ModuleRecordsCard(
                      title: '最近训练',
                      action: '查看全部',
                      onActionTap: () => context.push('/plan/fitness/records'),
                      color: AppColors.fitness,
                      recordCount: records.length,
                      maxVisible: 5,
                      isExpanded: _isRecordsExpanded,
                      onToggleExpand: () => setState(
                        () => _isRecordsExpanded = !_isRecordsExpanded,
                      ),
                      children: records.take(displayCount).map((r) {
                        final dt = DateTime.fromMillisecondsSinceEpoch(
                          r.createdAt,
                        );
                        final dateStr =
                            '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                        return SwipeDeleteTile(
                          key: ValueKey('fitness_${r.id}'),
                          onConfirmDelete: () async {
                            _deleteRecord(context, ref, r);
                            return false;
                          },
                          onDismissed: () {},
                          child: RecentRecordTile(
                            icon: Icons.fitness_center,
                            iconColor: Colors.white,
                            iconBackgroundColor: AppColors.fitness,
                            title: r.title ?? r.bodyPart,
                            subtitle:
                                '${r.bodyPart} · ${r.durationMinutes}分钟 · $dateStr',
                            primaryBadge: '+${r.expGained} EXP',
                            primaryBadgeColor: AppColors.fitness,
                            secondaryBadge: r.mode == 'professional'
                                ? '专业'
                                : '简单',
                            secondaryBadgeColor: AppColors.textSecondary,
                            onTap: () => _showFitnessRecordDetail(context, r),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Center(
                      child: Text('加载失败: $e', style: AppTextStyles.caption),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordMenu(context),
        backgroundColor: AppColors.fitness,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ─── 今日训练卡片（合并计时器）────────────────────────────────────────────

  Widget _buildTodayTrainingCard(
    AsyncValue<int> todayMinutes,
    DailyGoal fitnessGoal,
  ) {
    return todayMinutes.when(
      data: (minutes) {
        final progress = fitnessGoal.target > 0
            ? (minutes / fitnessGoal.target).clamp(0.0, 1.0)
            : 0.0;
        final calories = (minutes * 7.5).toInt();
        final hasData = minutes > 0;
        return ModuleHeroCard(
          icon: Icons.fitness_center_rounded,
          title: hasData ? '今日训练' : '开始今日训练',
          primaryValue: hasData ? '$minutes分钟' : '--',
          primaryLabel: hasData ? '今日已训练' : '还没有训练记录',
          color: AppColors.fitness,
          progress: hasData ? progress : null,
          targetLabel: hasData ? '目标 ${fitnessGoal.target}分钟' : null,
          metrics: hasData
              ? [
                  ModuleMetricChip(
                    icon: Icons.local_fire_department_outlined,
                    value: '$calories',
                    label: 'kcal',
                  ),
                  ModuleMetricChip(
                    icon: Icons.track_changes_outlined,
                    value: '${(progress * 100).toInt()}%',
                    label: '达成率',
                  ),
                  ModuleMetricChip(
                    icon: Icons.timer_outlined,
                    value: '${fitnessGoal.target}',
                    label: '目标分钟',
                  ),
                ]
              : [],
          onTargetTap: () => _showGoalEditSheet(context, fitnessGoal),
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
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  // ─── 记录训练入口 ────────────────────────────────────────────────────────

  Widget _buildRecordTrainingEntry(BuildContext context) {
    return PlanModuleRecordEntryCard(
      color: AppColors.fitness,
      icon: Icons.edit_note_rounded,
      title: '记录训练',
      subtitle: '手动添加训练记录',
      buttonLabel: '添加',
      onTap: () => context.push('/plan/fitness/add'),
    );
  }

  // ─── 本周训练卡片 ────────────────────────────────────────────────────────

  Widget _buildWeeklyTrainingCard(AsyncValue<int> weeklyCount, int weeklyGoal) {
    return PlanModuleWeeklyCard(
      color: AppColors.fitness,
      icon: Icons.calendar_month_rounded,
      title: '本周训练',
      count: weeklyCount.whenOrNull(data: (count) => count),
      goal: weeklyGoal,
      unit: '次',
      onTap: () => context.push('/plan/fitness/weekly'),
      onLongPress: () => _showWeeklyGoalEditSheet(weeklyGoal),
    );
  }

  // ─── 周目标编辑弹窗 ──────────────────────────────────────────────────────

  void _showWeeklyGoalEditSheet(int currentGoal) {
    GoalEditSheet.show(
      context: context,
      title: '设置每周训练目标',
      currentValue: currentGoal,
      unit: '次/周',
      min: 1,
      max: 14,
      step: 1,
      suggestion: '建议每周训练 3~5 次',
      color: AppColors.fitness,
      onSave: (value) async {
        ref.read(weeklyFitnessGoalProvider.notifier).state = value;
        final repo = ref.read(settingRepositoryProvider);
        await repo.setSetting('weekly_fitness_goal', value.toString());
      },
    );
  }

  // ─── 训练目标细节 ────────────────────────────────────────────────────────

  Widget _buildTodayProgress(
    AsyncValue<int> todayMinutes,
    DailyGoal fitnessGoal,
  ) {
    return Semantics(
      button: true,
      label: '训练目标进度，点击编辑目标',
      child: GestureDetector(
        onTap: () => _showGoalEditSheet(context, fitnessGoal),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.98),
                AppColors.fitness.withValues(alpha: 0.045),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
            border: Border.all(
              color: AppColors.fitness.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.fitness.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.softOrange,
                      borderRadius: BorderRadius.circular(AppRadius.smd),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      size: 15,
                      color: AppColors.fitness,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('训练目标', style: AppTextStyles.cardTitle),
                  const Spacer(),
                  Icon(
                    Icons.edit_outlined,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              todayMinutes.when(
                data: (minutes) {
                  final progress = fitnessGoal.target > 0
                      ? (minutes / fitnessGoal.target).clamp(0.0, 1.0)
                      : 0.0;
                  return Column(
                    children: [
                      _ProgressBar(
                        label: '训练时长',
                        current: minutes,
                        target: fitnessGoal.target,
                        color: AppColors.fitness,
                        progress: progress,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ProgressBar(
                        label: '消耗卡路里',
                        current: (minutes * 7.5).toInt(),
                        target: (fitnessGoal.target * 7.5).toInt(),
                        color: AppColors.warning,
                        progress: progress,
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(value: 0),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 健身趋势图表（锻炼时间 + 消耗 + 体重）──────────────────────────────

  Widget _buildWeightCurveCard() {
    final chartData = ref.watch(fitnessChartDataProvider(_selectedRange));

    return Semantics(
      button: true,
      label: '健身趋势，查看详情',
      child: GestureDetector(
        onTap: () => context.push('/plan/fitness/body-metric/detail'),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.98),
                AppColors.fitness.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
            border: Border.all(
              color: AppColors.fitness.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.fitness.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.softOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.show_chart_rounded,
                        size: 15,
                        color: AppColors.fitness,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('健身趋势', style: AppTextStyles.cardTitle),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ── 时间范围选择器 ──
                _buildRangeSelector(),
                const SizedBox(height: 12),
                // ── 图例 ──
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildChartLegend(AppColors.fitness, '锻炼(分钟)'),
                    _buildChartLegend(AppColors.warning, '消耗(kcal)'),
                    _buildChartLegend(AppColors.textTertiary, '体重(kg)'),
                  ],
                ),
                const SizedBox(height: 12),
                chartData.when(
                  data: (data) {
                    if (data.isEmpty) {
                      return _buildWeightEmptyState();
                    }
                    return ClipRect(
                      child: SizedBox(
                        height: 180,
                        child: _FitnessTrendChart(data: data),
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => _buildWeightEmptyState(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildRangeSelector() {
    const ranges = [
      {'label': '周', 'days': 7},
      {'label': '月', 'days': 30},
      {'label': '年', 'days': 365},
    ];

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.softOrange.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ranges.map((r) {
          final isSelected = _selectedRange == r['days'];
          return Semantics(
            button: true,
            label: '显示${r['label']}数据',
            selected: isSelected,
            child: GestureDetector(
              onTap: () => setState(() => _selectedRange = r['days'] as int),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.fitness : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  r['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeightEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 40,
              color: AppColors.textTertiary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text('体重数据积累中', style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text('记录至少2次体重后显示趋势', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.fitness_center,
      title: '还没有训练记录',
      subtitle: '开始你的第一次训练吧！',
      accentColor: AppColors.fitness,
    );
  }

  // ─── 目标编辑弹窗 ────────────────────────────────────────────────────────

  void _showGoalEditSheet(BuildContext context, DailyGoal currentGoal) {
    int tempGoal = currentGoal.target;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '设置每日健身目标',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2329),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (tempGoal > 5) setSheetState(() => tempGoal -= 5);
                      },
                      icon: const Icon(Icons.remove_circle_outline, size: 32),
                      color: AppColors.fitness,
                    ),
                    const SizedBox(width: 24),
                    Column(
                      children: [
                        Text(
                          '$tempGoal',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: AppColors.fitness,
                          ),
                        ),
                        Text(
                          '分钟/天',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: () {
                        if (tempGoal < 180) setSheetState(() => tempGoal += 5);
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 32),
                      color: AppColors.fitness,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('建议每天运动 30~60 分钟', style: AppTextStyles.caption),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _saveDailyGoal(tempGoal);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fitness,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveDailyGoal(int minutes) async {
    final goals = ref.read(dailyGoalsProvider);
    final newGoals = goals.map((g) {
      if (g.name == '健身') {
        return DailyGoal(name: '健身', target: minutes, unit: '分钟');
      }
      return g;
    }).toList();

    ref.read(dailyGoalsProvider.notifier).state = newGoals;

    final repo = ref.read(settingRepositoryProvider);
    final jsonStr = newGoals.map((g) => g.toJson()).toList();
    await repo.setSetting('daily_goals', jsonEncode(jsonStr));
  }

  // ─── 添加记录菜单 ────────────────────────────────────────────────────────

  void _showAddRecordMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomSheetContainer(
        title: '选择记录模式',
        child: Column(
          children: [
            _ModeOption(
              icon: Icons.speed,
              title: '简单模式',
              subtitle: '快速记录训练部位和时长',
              onTap: () {
                Navigator.pop(context);
                context.push('/plan/fitness/add?mode=simple');
              },
            ),
            _ModeOption(
              icon: Icons.analytics,
              title: '专业模式',
              subtitle: '详细记录动作、组数、重量',
              onTap: () {
                Navigator.pop(context);
                context.push('/plan/fitness/add?mode=professional');
              },
            ),
            _ModeOption(
              icon: Icons.monitor_weight_outlined,
              title: '记录身体数据',
              subtitle: '体重、体脂、围度等',
              onTap: () {
                Navigator.pop(context);
                context.push('/plan/fitness/body-metric/add');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── 健身记录详情弹窗 ──────────────────────────────────────────────────

  void _showFitnessRecordDetail(BuildContext context, FitnessRecord record) {
    final dt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateStr =
        '${dt.year}年${dt.month}月${dt.day}日 ${weekdays[dt.weekday - 1]}';

    final detailItems = <DetailItem>[
      DetailItem(
        label: '训练部位',
        value: record.bodyPart,
        icon: Icons.fitness_center,
      ),
      DetailItem(
        label: '模式',
        value: record.mode == 'professional' ? '专业' : '简单',
        icon: Icons.speed,
      ),
      DetailItem(
        label: '强度',
        value: record.intensityLevel != null
            ? '${record.intensityLevel} / 5'
            : '--',
        icon: Icons.trending_up,
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
              color: AppColors.fitness.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 16,
                      color: AppColors.fitness,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '备注',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.fitness,
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
        primaryMetricLabel: '训练时长',
        primaryMetricValue: '${record.durationMinutes} 分钟',
        detailItems: detailItems,
        accentColor: AppColors.fitness,
        extraCards: noteCard,
      ),
    );
  }

  // ─── 删除记录 ────────────────────────────────────────────────────────────

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    FitnessRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除「${record.title ?? record.bodyPart}」吗？'),
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
        final repo = ref.read(fitnessRepositoryProvider);
        await repo.deleteFitnessRecord(record.id);
        ref.invalidate(recentFitnessRecordsProvider);
        ref.invalidate(todayFitnessMinutesProvider);
        ref.invalidate(weeklyFitnessCountProvider);
        ref.invalidate(dashboardProvider);
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
