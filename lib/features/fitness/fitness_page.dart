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
import '../../shared/widgets/common/recent_record_tile.dart';
import '../../shared/widgets/swipe_delete_tile.dart';
import 'pages/training_timer_sheet.dart';
import 'package:go_router/go_router.dart';
import '../pet/models/pet_scene_model.dart';
import '../pet/widgets/pet_scene_banner.dart';

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
      backgroundColor: AppColors.background,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text('健身', style: AppTextStyles.pageTitle),
              centerTitle: false,
              backgroundColor: AppColors.background,
              actions: [
                IconButton(
                  tooltip: '身体数据',
                  onPressed: () => context.push('/plan/fitness/body-metric/detail'),
                  icon: const Icon(Icons.monitor_weight_outlined),
                ),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayFitnessMinutesProvider);
          ref.invalidate(weeklyFitnessCountProvider);
          ref.invalidate(recentFitnessRecordsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.capsuleNav != null) widget.capsuleNav!,

              // ── 1. 提示条 ──
              PetSceneBanner(
                module: PetModuleType.fitness,
                hasRecords: (todayMinutes.whenOrNull(data: (m) => m) ?? 0) > 0,
                onTap: () => context.push('/pet-center'),
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
              SectionHeader(
                title: '最近训练',
                action: '查看全部',
                onActionTap: () => context.push('/plan/fitness/records'),
              ),
              recentRecords.when(
                data: (records) {
                  if (records.isEmpty) {
                    return _buildEmptyState();
                  }

                  final displayCount = _isRecordsExpanded
                      ? records.length
                      : (records.length > 5 ? 5 : records.length);

                  return AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: [
                        ...records.take(displayCount).map(
                          (r) {
                            final dt = DateTime.fromMillisecondsSinceEpoch(
                              r.createdAt,
                            );
                            final dateStr =
                                '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
                                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
                                secondaryBadge:
                                    '${r.mode == 'professional' ? '专业' : '简单'}',
                                secondaryBadgeColor: AppColors.textSecondary,
                                onTap: () =>
                                    _showFitnessRecordDetail(context, r),
                              ),
                            );
                          },
                        ),
                        if (records.length > 5)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isRecordsExpanded = !_isRecordsExpanded),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: AppColors.softOrange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isRecordsExpanded ? '收起' : '查看更多',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.fitness,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _isRecordsExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: AppColors.fitness,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                loading: () => Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Center(child: Text('加载失败: $e', style: AppTextStyles.caption)),
                ),
              ),
            ],
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

        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.warmGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.fitness.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── 上半部分：今日数据 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasData ? '今日训练' : '开始今日训练',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (hasData)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '已完成 $minutes 分钟',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (hasData) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatChip(Icons.timer_outlined, '$minutes', '分钟'),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.local_fire_department_outlined,
                            '$calories',
                            'kcal',
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.track_changes_outlined,
                            '${(progress * 100).toInt()}',
                            '%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 进度条
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── 分割线 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),

              // ── 下半部分：计时器入口 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: GestureDetector(
                  onTap: () => TrainingTimerSheet.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '选择部位开始计时',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: AppColors.warmGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String unit) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  // ─── 记录训练入口 ────────────────────────────────────────────────────────

  Widget _buildRecordTrainingEntry(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/plan/fitness/add'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fitness.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.fitness.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.softOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_note_rounded, color: AppColors.fitness, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '记录训练',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '手动添加训练记录',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.fitness,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    '添加',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 本周训练卡片 ────────────────────────────────────────────────────────

  Widget _buildWeeklyTrainingCard(AsyncValue<int> weeklyCount, int weeklyGoal) {
    return GestureDetector(
      onTap: () => context.push('/plan/fitness/weekly'),
      onLongPress: () => _showWeeklyGoalEditSheet(weeklyGoal),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today, size: 15, color: AppColors.fitness),
                ),
                const SizedBox(width: 10),
                Text('本周训练', style: AppTextStyles.cardTitle),
                const Spacer(),
                weeklyCount.when(
                  data: (count) => Text(
                    '$count/$weeklyGoal 次',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fitness,
                    ),
                  ),
                  loading: () => Text('--', style: AppTextStyles.caption),
                  error: (_, _) => Text('--', style: AppTextStyles.caption),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isCompleted =
                    index < (weeklyCount.whenOrNull(data: (c) => c) ?? 0);
                return _DayDot(
                  label: ['一', '二', '三', '四', '五', '六', '日'][index],
                  completed: isCompleted,
                );
              }),
            ),
          ],
        ),
      ),
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

  // ─── 今日进度卡片 ────────────────────────────────────────────────────────

  Widget _buildTodayProgress(AsyncValue<int> todayMinutes, DailyGoal fitnessGoal) {
    return GestureDetector(
      onTap: () => _showGoalEditSheet(context, fitnessGoal),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.trending_up, size: 15, color: AppColors.fitness),
                ),
                const SizedBox(width: 10),
                Text('今日进度', style: AppTextStyles.cardTitle),
                const Spacer(),
                Icon(Icons.edit_outlined, color: AppColors.textTertiary, size: 18),
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
    );
  }

  // ─── 健身趋势图表（锻炼时间 + 消耗 + 体重）──────────────────────────────

  Widget _buildWeightCurveCard() {
    final chartData = ref.watch(fitnessChartDataProvider(_selectedRange));

    return GestureDetector(
      onTap: () => context.push('/plan/fitness/body-metric/detail'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
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
                  Text(
                    '健身趋势',
                    style: AppTextStyles.cardTitle,
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              // ── 时间范围选择器 ──
              _buildRangeSelector(),
              const SizedBox(height: 12),
              // ── 图例 ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildChartLegend(AppColors.fitness, '锻炼(分钟)'),
                  const SizedBox(width: 16),
                  _buildChartLegend(AppColors.warning, '消耗(kcal)'),
                  const SizedBox(width: 16),
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
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
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
          return GestureDetector(
            onTap: () => setState(() => _selectedRange = r['days'] as int),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeightEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              color: Colors.white,
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
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                    Icon(Icons.notes_rounded, size: 16, color: AppColors.fitness),
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
        extraCard: noteCard,
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已删除')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }
}

// ─── 私有 Widget ────────────────────────────────────────────────────────────

class _DayDot extends StatelessWidget {
  const _DayDot({required this.label, required this.completed});

  final String label;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: completed ? AppColors.fitness : AppColors.softOrange,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    label,
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.progress,
  });

  final String label;
  final int current;
  final int target;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(
              '$current / $target',
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}



class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.softOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.fitness),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 健身趋势图表（锻炼时间 + 消耗 + 体重）──────────────────────────────────

class _FitnessTrendChart extends StatefulWidget {
  const _FitnessTrendChart({required this.data});

  final List<FitnessChartData> data;

  @override
  State<_FitnessTrendChart> createState() => _FitnessTrendChartState();
}

class _FitnessTrendChartState extends State<_FitnessTrendChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      _buildChartData(),
      duration: const Duration(milliseconds: 200),
    );
  }

  LineChartData _buildChartData() {
    final data = widget.data;

    // 使用 DurationChartScale 计算健身时长的缩放
    final minutesList = data.map((d) => d.minutes).toList();
    final scale = buildDurationChartScale(minutesList);

    // 计算卡路里和体重的归一化范围
    final maxCalories = data.map((d) => d.calories).fold<int>(0, (a, b) => a > b ? a : b);
    final weights = data.where((d) => d.weight != null).map((d) => d.weight!).toList();
    final maxWeight = weights.isNotEmpty
        ? weights.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final minWeight = weights.isNotEmpty
        ? weights.reduce((a, b) => a < b ? a : b)
        : 0.0;

    // 卡路里和体重归一化到 scale.maxY 范围内
    final caloriesTop = maxCalories > 0 ? maxCalories.toDouble() : 500.0;
    final weightRange = maxWeight - minWeight;
    final weightPadding = weightRange < 0.5 ? 1.0 : weightRange * 0.15;
    final weightMin = (minWeight - weightPadding).floorToDouble();
    final weightMax = (maxWeight + weightPadding).ceilToDouble();

    FlSpot minutesSpot(FitnessChartData d, int i) =>
        FlSpot(i.toDouble(), scale.convertMinutes(d.minutes));

    FlSpot caloriesSpot(FitnessChartData d, int i) =>
        FlSpot(i.toDouble(), caloriesTop > 0 ? (d.calories / caloriesTop) * scale.maxY : 0);

    FlSpot weightSpot(FitnessChartData d, int i) {
      if (d.weight == null || weightMax == weightMin) {
        return FlSpot(i.toDouble(), scale.maxY * 0.5);
      }
      return FlSpot(i.toDouble(), ((d.weight! - weightMin) / (weightMax - weightMin)) * scale.maxY);
    }

    final minutesSpots = <FlSpot>[];
    final caloriesSpots = <FlSpot>[];
    final weightSpots = <FlSpot>[];

    for (int i = 0; i < data.length; i++) {
      minutesSpots.add(minutesSpot(data[i], i));
      caloriesSpots.add(caloriesSpot(data[i], i));
      if (data[i].weight != null) {
        weightSpots.add(weightSpot(data[i], i));
      }
    }

    return LineChartData(
      minY: 0,
      maxY: scale.maxY,
      // ── 触摸交互 ──
      lineTouchData: LineTouchData(
        touchSpotThreshold: 20,
        handleBuiltInTouches: true,
        touchCallback: (event, response) {
          setState(() {
            if (event is FlPanEndEvent || event is FlLongPressEnd) {
              _touchedIndex = null;
            } else if (response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              _touchedIndex = response.lineBarSpots!.first.x.toInt();
            }
          });
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 10,
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          maxContentWidth: 200,
          getTooltipColor: (_) => Colors.white.withValues(alpha: 0.95),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];
            final idx = touchedSpots.first.x.toInt();
            if (idx < 0 || idx >= data.length) return [];
            final d = data[idx];
            final dateStr = '${d.date.month}/${d.date.day}';

            final items = <LineTooltipItem>[];

            // 锻炼时间
            final minutesSpot = touchedSpots.where((s) => s.barIndex == 0).firstOrNull;
            if (minutesSpot != null) {
              items.add(LineTooltipItem(
                '$dateStr 锻炼 ${scale.formatTooltipValue(d.minutes.toDouble())}',
                TextStyle(
                  color: AppColors.fitness,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ));
            }

            // 消耗
            final caloriesSpot = touchedSpots.where((s) => s.barIndex == 1).firstOrNull;
            if (caloriesSpot != null) {
              items.add(LineTooltipItem(
                '$dateStr 消耗 ${d.calories}kcal',
                TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ));
            }

            // 体重
            final wSpot = touchedSpots.where((s) => s.barIndex == 2).firstOrNull;
            if (wSpot != null && d.weight != null) {
              items.add(LineTooltipItem(
                '$dateStr 体重 ${d.weight!.toStringAsFixed(1)}kg',
                TextStyle(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ));
            }

            return items;
          },
        ),
      ),
      lineBarsData: [
        // 锻炼时间线
        LineChartBarData(
          spots: minutesSpots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: AppColors.fitness,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: _touchedIndex == index ? 5 : 3,
              color: AppColors.fitness,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.fitness.withValues(alpha: 0.06),
          ),
        ),
        // 消耗线
        LineChartBarData(
          spots: caloriesSpots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: AppColors.warning,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: _touchedIndex == index ? 5 : 3,
              color: AppColors.warning,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.warning.withValues(alpha: 0.06),
          ),
        ),
        // 体重线
        if (weightSpots.isNotEmpty)
          LineChartBarData(
            spots: weightSpots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppColors.textTertiary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: _touchedIndex == index ? 5 : 3,
                color: AppColors.textTertiary,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.textTertiary.withValues(alpha: 0.06),
            ),
          ),
      ],
      titlesData: FlTitlesData(
        // 左 Y 轴：分钟
        leftTitles: AxisTitles(
          axisNameWidget: Text(
            scale.useHours ? '小时' : '分钟',
            style: const TextStyle(fontSize: 9, color: AppColors.fitness),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: scale.interval,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  scale.formatAxisLabel(value),
                  style: const TextStyle(fontSize: 9, color: AppColors.fitness),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
        // 右 Y 轴：kcal
        rightTitles: AxisTitles(
          axisNameWidget: const Text(
            'kcal',
            style: TextStyle(fontSize: 9, color: AppColors.warning),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: scale.interval,
            getTitlesWidget: (value, meta) {
              final kcal = (value / scale.maxY * caloriesTop).round();
              return Text(
                '$kcal',
                style: const TextStyle(fontSize: 9, color: AppColors.warning),
                textAlign: TextAlign.left,
              );
            },
          ),
        ),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        // X 轴：日期标签
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= data.length) {
                return const SizedBox.shrink();
              }
              final d = data[idx];
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${d.date.month}/${d.date.day}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: scale.interval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.border.withValues(alpha: 0.5),
          strokeWidth: 0.5,
        ),
      ),
      borderData: FlBorderData(show: false),
    );
  }
}
