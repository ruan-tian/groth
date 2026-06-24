import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../core/constants/fitness_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/providers/repository_providers.dart';
import 'providers/fitness_dashboard_facade.dart';
import 'providers/fitness_provider.dart';
import '../../shared/providers/settings_facade.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/widgets/common/common_widgets.dart';
import '../../shared/widgets/swipe_delete_tile.dart';
import '../plan/utils/plan_module_assets.dart';
import '../plan/widgets/plan_module_visuals.dart';

part 'widgets/fitness_page_widgets.dart';

class FitnessPage extends ConsumerStatefulWidget {
  const FitnessPage({super.key, this.isEmbedded = false, this.capsuleNav});

  final bool isEmbedded;
  final Widget? capsuleNav;

  @override
  ConsumerState<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends ConsumerState<FitnessPage> {
  int _selectedRange = 30;
  bool _isRecordsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final todayMinutes = ref.watch(todayFitnessMinutesProvider);
    final weeklyCount = ref.watch(weeklyFitnessCountProvider);
    final recentRecords = ref.watch(recentFitnessRecordsProvider);
    final dailyGoals = ref.watch(dailyGoalsProvider);

    final fitnessGoal = dailyGoals.firstWhere(
      (goal) => goal.name == '健身',
      orElse: () => const DailyGoal(name: '健身', target: 45, unit: '分钟'),
    );
    final weeklyGoal = ref.watch(weeklyFitnessGoalProvider);

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                '健身',
                style: AppTextStyles.pageTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              centerTitle: false,
              backgroundColor: colors.paper,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  tooltip: '身体数据',
                  onPressed: () =>
                      context.push('/plan/fitness/body-metric/detail'),
                  icon: Icon(
                    Icons.monitor_weight_outlined,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
      body: ModulePageSurface(
        color: colors.fitness,
        child: RefreshIndicator(
          color: colors.fitness,
          onRefresh: () async {
            ref.invalidate(todayFitnessMinutesProvider);
            ref.invalidate(weeklyFitnessCountProvider);
            ref.invalidate(recentFitnessRecordsProvider);
            ref.invalidate(fitnessChartDataProvider(_selectedRange));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.capsuleNav != null) widget.capsuleNav!,
                // [1] 宠物陪伴
                PlanModuleVisualHeader(
                  module: PlanModuleType.fitness,
                  color: colors.fitness,
                ),
                const SizedBox(height: 12),
                // [2] 今日训练 HeroCard
                _buildTodayTrainingCard(todayMinutes, fitnessGoal),
                const SizedBox(height: 16),
                // [3] 双列功能入口
                _buildDualEntryCards(context),
                const SizedBox(height: 16),
                // [4] 本周训练数据卡
                _buildWeeklyTrainingCard(weeklyCount, weeklyGoal),
                const SizedBox(height: 12),
                // [5] 健身趋势图表
                _buildWeightCurveCard(),
                const SizedBox(height: 12),
                // [6] 最近训练记录
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
                      color: colors.fitness,
                      recordCount: records.length,
                      maxVisible: 5,
                      isExpanded: _isRecordsExpanded,
                      onToggleExpand: () => setState(
                        () => _isRecordsExpanded = !_isRecordsExpanded,
                      ),
                      children: records.take(displayCount).map((record) {
                        final createdAt = DateTime.fromMillisecondsSinceEpoch(
                          record.createdAt,
                        );
                        final dateStr =
                            '${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
                        return SwipeDeleteTile(
                          key: ValueKey('fitness_${record.id}'),
                          onConfirmDelete: () async {
                            _deleteRecord(context, ref, record);
                            return false;
                          },
                          onDismissed: () {},
                          child: RecentRecordTile(
                            icon: Icons.fitness_center,
                            iconColor: colors.textOnAccent,
                            iconBackgroundColor: colors.fitness,
                            title: record.title ?? record.bodyPart,
                            subtitle:
                                '${record.bodyPart} · ${record.durationMinutes}分钟 · $dateStr',
                            primaryBadge: '+${record.expGained} EXP',
                            primaryBadgeColor: colors.fitness,
                            secondaryBadge: record.mode == 'professional'
                                ? '专业'
                                : '简单',
                            secondaryBadgeColor: colors.textSecondary,
                            onTap: () =>
                                _showFitnessRecordDetail(context, record),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(color: colors.fitness),
                    ),
                  ),
                  error: (error, _) => Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Center(
                      child: Text(
                        '加载训练记录失败: $error',
                        style: AppTextStyles.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
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
        backgroundColor: colors.fitness,
        child: Icon(Icons.add, color: colors.textOnAccent),
      ),
    );
  }

  Widget _buildTodayTrainingCard(
    AsyncValue<int> todayMinutes,
    DailyGoal fitnessGoal,
  ) {
    final colors = context.growthColors;
    return todayMinutes.when(
      data: (minutes) {
        final progress = fitnessGoal.target > 0
            ? (minutes / fitnessGoal.target).clamp(0.0, 1.0)
            : 0.0;
        final calories = FitnessConstants.estimateCalories(minutes);
        final hasData = minutes > 0;
        return ModuleHeroCard(
          icon: Icons.fitness_center_rounded,
          title: hasData ? '今日训练' : '开始今日训练',
          primaryValue: hasData ? '$minutes分钟' : '--',
          primaryLabel: hasData ? '今日已训练' : '还没有训练记录',
          color: colors.fitness,
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
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Center(child: CircularProgressIndicator(color: colors.fitness)),
      ),
      error: (_, _) => const ErrorRetryWidget(),
    );
  }

  Widget _buildDualEntryCards(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      children: [
        Expanded(
          child: _FitnessEntryCard(
            icon: Icons.timer_rounded,
            title: '开始训练',
            subtitle: '计时记录',
            color: colors.fitness,
            onTap: () => context.push('/plan/fitness/timer'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FitnessEntryCard(
            icon: Icons.edit_note_rounded,
            title: '记录训练',
            subtitle: '手动添加',
            color: colors.fitness,
            onTap: () => context.push('/plan/fitness/add'),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrainingCard(AsyncValue<int> weeklyCount, int weeklyGoal) {
    final colors = context.growthColors;
    return PlanModuleWeeklyCard(
      color: colors.fitness,
      icon: Icons.calendar_month_rounded,
      title: '本周训练',
      count: weeklyCount.whenOrNull(data: (count) => count),
      goal: weeklyGoal,
      unit: '次',
      onTap: () => context.push('/plan/fitness/weekly'),
      onLongPress: () => _showWeeklyGoalEditSheet(weeklyGoal),
    );
  }

  void _showWeeklyGoalEditSheet(int currentGoal) {
    final colors = context.growthColors;
    GoalEditSheet.show(
      context: context,
      title: '设置每周训练目标',
      currentValue: currentGoal,
      unit: '次/周',
      min: 1,
      max: 14,
      step: 1,
      suggestion: '建议每周训练 3~5 次',
      color: colors.fitness,
      onSave: (value) async {
        await ref.read(settingsFacadeProvider).setWeeklyFitnessGoal(value);
      },
    );
  }

  Widget _buildWeightCurveCard() {
    final colors = context.growthColors;
    final chartData = ref.watch(fitnessChartDataProvider(_selectedRange));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRangeSelector(),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          button: true,
          label: '查看身体数据趋势详情',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/plan/fitness/body-metric/detail'),
            child: GrowthChartCard(
              title: '健身趋势',
              subtitle: _rangeSubtitle(),
              icon: Icons.show_chart_rounded,
              color: colors.fitness,
              legend: [
                GrowthChartLegendItem(color: colors.fitness, label: '锻炼(分钟)'),
                GrowthChartLegendItem(color: colors.warning, label: '消耗(kcal)'),
                GrowthChartLegendItem(
                  color: colors.textTertiary,
                  label: '体重(kg)',
                ),
              ],
              child: chartData.when(
                data: (data) {
                  if (data.isEmpty) {
                    return _buildWeightEmptyState();
                  }
                  return _FitnessTrendChart(data: data, range: _selectedRange);
                },
                loading: () => SizedBox(
                  height: 244,
                  child: Center(
                    child: CircularProgressIndicator(color: colors.fitness),
                  ),
                ),
                error: (_, _) => _buildWeightEmptyState(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeSelector() {
    return GrowthChartRangeSelector<int>(
      color: context.growthColors.fitness,
      selected: _selectedRange,
      options: const [
        GrowthChartRangeOption(value: 7, label: '周'),
        GrowthChartRangeOption(value: 30, label: '月'),
        GrowthChartRangeOption(value: 365, label: '年'),
      ],
      onChanged: (value) => setState(() => _selectedRange = value),
    );
  }

  Widget _buildWeightEmptyState() {
    final colors = context.growthColors;
    return SizedBox(
      height: 244,
      child: GrowthChartEmpty(color: colors.fitness, label: '记录后显示健身趋势'),
    );
  }

  String _rangeSubtitle() {
    return switch (_selectedRange) {
      7 => '近 7 天',
      30 => '近 30 天',
      _ => '本年',
    };
  }

  Widget _buildEmptyState() {
    final colors = context.growthColors;
    return EmptyStateWidget(
      icon: Icons.fitness_center,
      title: '还没有训练记录',
      subtitle: '开始你的第一次训练吧',
      accentColor: colors.fitness,
    );
  }

  void _showGoalEditSheet(BuildContext context, DailyGoal currentGoal) {
    final colors = context.growthColors;
    int tempGoal = currentGoal.target;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '设置今日训练目标',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
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
                      color: colors.fitness,
                    ),
                    const SizedBox(width: 24),
                    Column(
                      children: [
                        Text(
                          '$tempGoal',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: colors.fitness,
                          ),
                        ),
                        Text(
                          '分钟/天',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
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
                      color: colors.fitness,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '建议日常训练 30~60 分钟',
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _saveDailyGoal(tempGoal);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.fitness,
                      foregroundColor: colors.textOnAccent,
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
    await ref
        .read(settingsFacadeProvider)
        .updateDailyGoal(name: '健身', target: minutes, unit: '分钟');
  }

  void _showAddRecordMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomSheetContainer(
        title: '添加训练记录',
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

  void _showFitnessRecordDetail(BuildContext context, FitnessRecord record) {
    final colors = context.growthColors;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    final dateStr = GrowthDateUtils.formatDateChineseFull(createdAt);

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
              color: colors.fitness.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notes_rounded, size: 16, color: colors.fitness),
                    const SizedBox(width: 6),
                    Text(
                      '备注',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.fitness,
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
        primaryMetricLabel: '训练时长',
        primaryMetricValue: '${record.durationMinutes} 分钟',
        detailItems: detailItems,
        accentColor: colors.fitness,
        extraCards: noteCard,
      ),
    );
  }

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    FitnessRecord record,
  ) async {
    final colors = context.growthColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.paper,
        title: Text('删除确认', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          '确定要删除「${record.title ?? record.bodyPart}」吗？',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: colors.danger),
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
        ref.read(fitnessDashboardFacadeProvider).refreshDashboard();
        ref.invalidate(fitnessChartDataProvider(7));
        ref.invalidate(fitnessChartDataProvider(30));
        ref.invalidate(fitnessChartDataProvider(365));
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已删除')));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
        }
      }
    }
  }
}
