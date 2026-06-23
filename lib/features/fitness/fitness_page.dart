import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../core/constants/fitness_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/chart_scale_utils.dart';
import '../../core/utils/date_utils.dart';
import 'dashboard_providers.dart';
import 'fitness_providers.dart';
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
      backgroundColor: colors.background,
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
              backgroundColor: colors.background,
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
                PlanModuleVisualHeader(
                  module: PlanModuleType.fitness,
                  color: colors.fitness,
                ),
                const SizedBox(height: AppSpacing.md),
                PlanModuleActionImageCard(
                  module: PlanModuleType.fitness,
                  color: colors.fitness,
                  onTap: () => context.push('/plan/fitness/timer'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildTodayTrainingCard(todayMinutes, fitnessGoal),
                const SizedBox(height: AppSpacing.lg),
                _buildRecordTrainingEntry(context),
                const SizedBox(height: AppSpacing.lg),
                _buildWeeklyTrainingCard(weeklyCount, weeklyGoal),
                const SizedBox(height: AppSpacing.lg),
                _buildWeightCurveCard(),
                const SizedBox(height: AppSpacing.lg),
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

  Widget _buildRecordTrainingEntry(BuildContext context) {
    final colors = context.growthColors;
    return PlanModuleRecordEntryCard(
      color: colors.fitness,
      icon: Icons.edit_note_rounded,
      title: '记录训练',
      subtitle: '手动添加训练记录',
      buttonLabel: '添加',
      onTap: () => context.push('/plan/fitness/add'),
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.paper.withValues(alpha: 0.98),
            colors.fitness.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: colors.fitness.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.22),
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
            // ── 标题行（可点击跳转详情）──
            Semantics(
              button: true,
              label: '查看身体数据趋势详情',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/plan/fitness/body-metric/detail'),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.softOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.show_chart_rounded,
                        size: 15,
                        color: colors.fitness,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '健身趋势',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: colors.textTertiary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── 范围选择器（独立，不被外层吞掉点击）──
            _buildRangeSelector(),
            const SizedBox(height: 12),
            // ── 图例 ──
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildChartLegend(colors.fitness, '锻炼(分钟)'),
                _buildChartLegend(colors.warning, '消耗(kcal)'),
                _buildChartLegend(colors.textTertiary, '体重(kg)'),
              ],
            ),
            const SizedBox(height: 12),
            // ── 图表（可点击跳转详情）──
            Semantics(
              button: true,
              label: '查看身体数据趋势详情',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/plan/fitness/body-metric/detail'),
                child: chartData.when(
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
                  loading: () => SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(color: colors.fitness),
                    ),
                  ),
                  error: (_, _) => _buildWeightEmptyState(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    final colors = context.growthColors;
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
        Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
      ],
    );
  }

  Widget _buildRangeSelector() {
    final colors = context.growthColors;
    const ranges = [
      {'label': '周', 'days': 7},
      {'label': '月', 'days': 30},
      {'label': '年', 'days': 365},
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.softOrange.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ranges.map((range) {
          final isSelected = _selectedRange == range['days'];
          final label = range['label'] as String;
          return Semantics(
            button: true,
            label: '切换到$label趋势',
            selected: isSelected,
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedRange = range['days'] as int),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colors.fitness : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colors.textOnAccent
                        : colors.textSecondary,
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
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 40,
              color: colors.textTertiary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              '体重数据积累中',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '记录至少 2 次体重后显示趋势',
              style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
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
        ref.invalidate(dashboardProvider);
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
