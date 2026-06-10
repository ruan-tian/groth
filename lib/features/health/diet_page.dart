import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/design/app_colors.dart';
import '../../../app/design/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/diet_provider.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../../shared/widgets/swipe_delete_tile.dart';
import '../plan/utils/plan_module_assets.dart';
import '../plan/widgets/plan_module_visuals.dart';

part 'widgets/diet_page_widgets.dart';

/// 饮食记录首页（牛油果绿风格）
class DietPage extends ConsumerStatefulWidget {
  const DietPage({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  ConsumerState<DietPage> createState() => _DietPageState();
}

class _DietPageState extends ConsumerState<DietPage> {
  int _selectedRange = 7; // 图表时间范围: 7/30/365
  bool _recentRecordsExpanded = false;

  @override
  void initState() {
    super.initState();
    // 从数据库加载目标值和饮水量
    Future.microtask(() {
      ref.read(dailyCalorieGoalInitProvider);
      ref.read(dailyWaterGoalInitProvider);
      ref.read(todayWaterIntakeInitProvider);
    });
  }

  /// 获取今日饮水量
  int get _currentWater {
    final waterMap = ref.watch(dailyWaterIntakeProvider);
    return getTodayWaterIntake(waterMap);
  }

  @override
  Widget build(BuildContext context) {
    final todayRecords = ref.watch(todayDietRecordsProvider);
    final todayCount = ref.watch(todayDietCountProvider);
    final todayScore = ref.watch(todayAvgHealthScoreProvider);

    return Scaffold(
      backgroundColor: AppColors.softGreen,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text(
                '饮食记录',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: AppColors.textPrimary,
                onPressed: () => context.pop(),
              ),
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayDietRecordsProvider);
          ref.invalidate(todayDietCountProvider);
          ref.invalidate(todayAvgHealthScoreProvider);
          ref.invalidate(recentDietRecordsProvider(10));
          ref.invalidate(dailyCalorieWaterProvider(7));
          ref.invalidate(dailyCalorieWaterProvider(30));
          ref.invalidate(dailyCalorieWaterProvider(365));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 甜甜提醒 ──
              PlanModuleVisualHeader(
                module: PlanModuleType.diet,
                color: AppColors.diet,
              ),
              const SizedBox(height: 12),
              PlanModuleActionImageCard(
                module: PlanModuleType.diet,
                color: AppColors.diet,
                onTap: () => context.push('/plan/diet/water-reminder'),
              ),
              const SizedBox(height: 16),

              // ── 今日统计（可设定目标） ──
              _buildTodayStats(todayRecords, todayCount, todayScore),
              const SizedBox(height: 16),

              // ── 饮水量追踪 ──
              _buildWaterTracker(),
              const SizedBox(height: 16),

              // ── 卡路里和饮水量变化图表 ──
              _buildCalorieWaterChart(),
              const SizedBox(height: 16),

              // ── 最近饮食记录 ──
              _buildRecentRecordsInline(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plan/diet/add'),
        backgroundColor: AppColors.diet,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 最近饮食记录
  // ---------------------------------------------------------------------------

  Widget _buildRecentRecordsInline() {
    final recentRecords = ref.watch(recentDietRecordsProvider(10));
    return recentRecords.when(
      data: (records) {
        if (records.isEmpty) return _buildEmptyState();
        final displayRecords = _recentRecordsExpanded
            ? records
            : records.take(5).toList();
        return ModuleRecordsCard(
          title: '最近饮食',
          action: '查看全部',
          onActionTap: () => context.push('/plan/diet/records'),
          color: AppColors.diet,
          recordCount: records.length,
          maxVisible: 5,
          isExpanded: _recentRecordsExpanded,
          onToggleExpand: () =>
              setState(() => _recentRecordsExpanded = !_recentRecordsExpanded),
          children: displayRecords
              .map(
                (r) => SwipeDeleteTile(
                  key: ValueKey('diet_${r.id}'),
                  onConfirmDelete: () async {
                    _deleteDietRecord(context, ref, r);
                    return false;
                  },
                  onDismissed: () {},
                  child: RecentRecordTile(
                    icon: Icons.restaurant_rounded,
                    iconColor: Colors.white,
                    iconBackgroundColor: AppColors.diet,
                    title: r.foodText,
                    subtitle:
                        '${_mealTypeLabel(r.mealType)} · ${_portionLabel(r.portionLevel)}',
                    primaryBadge:
                        '${'★' * r.healthScore}${'☆' * (5 - r.healthScore)}',
                    primaryBadgeColor: AppColors.diet,
                    secondaryBadge: null,
                    secondaryBadgeColor: AppColors.textSecondary,
                    onTap: () => _showDietDetailSheet(context, r),
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text('加载失败: $e')),
      ),
    );
  }

  String _mealTypeLabel(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return '早餐';
      case 'lunch':
        return '午餐';
      case 'dinner':
        return '晚餐';
      case 'snack':
        return '加餐';
      default:
        return mealType;
    }
  }

  String _portionLabel(String portion) {
    switch (portion) {
      case 'small':
        return '少量';
      case 'normal':
        return '正常';
      case 'large':
        return '大量';
      default:
        return portion;
    }
  }

  void _showDietDetailSheet(BuildContext context, DietRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => RecordDetailSheet(
        title: _formatDietDate(record),
        accentColor: AppColors.diet,
        primaryMetricLabel: '健康评分',
        primaryMetricValue: '${record.healthScore}/5',
        detailItems: [
          DetailItem(
            label: '餐次',
            value: _mealTypeLabel(record.mealType),
            icon: Icons.restaurant_rounded,
          ),
          DetailItem(
            label: '份量',
            value: _portionLabel(record.portionLevel),
            icon: Icons.scale_outlined,
          ),
          DetailItem(
            label: '热量',
            value: _calorieLabel(record.calorieLevel),
            icon: Icons.local_fire_department_outlined,
          ),
          DetailItem(
            label: '蛋白质',
            value: _proteinLabel(record.proteinLevel),
            icon: Icons.bolt_outlined,
          ),
        ],
        extraCards: (record.note != null && record.note!.isNotEmpty)
            ? _buildNoteExtraCard(record.note!)
            : null,
      ),
    );
  }

  String _formatDietDate(DietRecord record) {
    final date = DateTime.parse(record.mealDate);
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${date.year}年${date.month}月${date.day}日 ${weekdays[date.weekday - 1]}';
  }

  String _calorieLabel(String level) {
    switch (level) {
      case 'low':
        return '低热量';
      case 'normal':
        return '正常';
      case 'high':
        return '高热量';
      default:
        return level;
    }
  }

  String _proteinLabel(String level) {
    switch (level) {
      case 'low':
        return '低蛋白';
      case 'medium':
        return '中蛋白';
      case 'high':
        return '高蛋白';
      default:
        return level;
    }
  }

  Widget _buildNoteExtraCard(String note) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.note_outlined,
            color: AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '备注',
                  style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
          ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDietRecord(
    BuildContext context,
    WidgetRef ref,
    DietRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除「${record.foodText}」吗？'),
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
        final repo = ref.read(dietRepositoryProvider);
        await repo.deleteDietRecord(record.id);
        ref.invalidate(recentDietRecordsProvider(10));
        ref.invalidate(todayDietRecordsProvider);
        ref.invalidate(todayDietCountProvider);
        ref.invalidate(todayAvgHealthScoreProvider);
        ref.invalidate(dashboardProvider);
        ref.invalidate(dailyCalorieWaterProvider(7));
        ref.invalidate(dailyCalorieWaterProvider(30));
        ref.invalidate(dailyCalorieWaterProvider(365));
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

  // ---------------------------------------------------------------------------
  // 今日统计（可设定目标）
  // ---------------------------------------------------------------------------

  Widget _buildTodayStats(
    AsyncValue<List<DietRecord>> todayRecords,
    AsyncValue<int> todayCount,
    AsyncValue<double?> todayScore,
  ) {
    final records = todayRecords.whenOrNull(data: (r) => r) ?? [];
    final count = todayCount.whenOrNull(data: (c) => c) ?? 0;
    final score = todayScore.whenOrNull(data: (s) => s) ?? 0;
    final calorieGoal = ref.watch(dailyCalorieGoalProvider);

    int totalCalories = 0;
    for (final r in records) {
      switch (r.calorieLevel) {
        case 'low':
          totalCalories += 300;
          break;
        case 'normal':
          totalCalories += 500;
          break;
        case 'high':
          totalCalories += 800;
          break;
      }
    }

    final calorieProgress = calorieGoal > 0
        ? (totalCalories / calorieGoal).clamp(0.0, 1.0)
        : 0.0;

    return ModuleHeroCard(
      icon: Icons.restaurant_rounded,
      title: '今日统计',
      primaryValue: '${score.toStringAsFixed(1)}/5',
      primaryLabel: '今日健康评分',
      color: AppColors.diet,
      progress: calorieProgress,
      targetLabel: '卡路里 $totalCalories/${calorieGoal}kcal',
      metrics: [
        ModuleMetricChip(
          icon: Icons.restaurant_rounded,
          value: '$count餐',
          label: '餐次',
        ),
        ModuleMetricChip(
          icon: Icons.local_fire_department_rounded,
          value: '${(calorieProgress * 100).toInt()}%',
          label: '热量达成',
        ),
        ModuleMetricChip(
          icon: Icons.water_drop_rounded,
          value: '${_currentWater}ml',
          label: '饮水',
        ),
      ],
      onTargetTap: _showGoalSettings,
    );
  }

  // ---------------------------------------------------------------------------
  // 饮水量追踪
  // ---------------------------------------------------------------------------

  Widget _buildWaterTracker() {
    final waterGoal = ref.watch(dailyWaterGoalProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.info,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '饮水量',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: '设置饮水目标',
                child: GestureDetector(
                  onTap: _showWaterGoalSettings,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '目标 ${waterGoal}ml',
                      style: const TextStyle(fontSize: 11, color: AppColors.info),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_currentWater / waterGoal).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: AppColors.info.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
            ),
          ),
          const SizedBox(height: 8),

          // 数量显示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_currentWater ml',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
              Text(
                '${((_currentWater / waterGoal) * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 快捷添加按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWaterAddButton(100, '100ml'),
              _buildWaterAddButton(250, '250ml'),
              _buildWaterAddButton(500, '500ml'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterAddButton(int amount, String label) {
    return Semantics(
      button: true,
      label: '添加$label饮水',
      child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        saveWaterIntake(ref, amount);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, size: 14, color: AppColors.info),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  // ---------------------------------------------------------------------------
  // 卡路里和饮水量变化图表 (fl_chart)
  // ---------------------------------------------------------------------------

  Widget _buildCalorieWaterChart() {
    final nutritionData = ref.watch(dailyCalorieWaterProvider(_selectedRange));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.diet.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.diet.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.diet,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _selectedRange == 7
                    ? '本周趋势'
                    : _selectedRange == 30
                    ? '本月趋势'
                    : '今年趋势',
                style: AppTextStyles.cardTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 时间范围选择器
          _buildRangeSelector(),
          const SizedBox(height: 12),

          // 图例
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(const Color(0xFFFF7D00), '卡路里'),
              const SizedBox(width: 24),
              _buildLegend(const Color(0xFF5D68F2), '饮水量'),
            ],
          ),
          const SizedBox(height: 12),

          // 图表
          ClipRect(
            child: SizedBox(
              height: 220,
              child: nutritionData.when(
                data: (data) => _CalorieWaterChart(
                  calorieMap: data.calorieMap,
                  waterMap: data.waterMap,
                  days: _selectedRange,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF0),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          _buildRangeChip('周', 7),
          _buildRangeChip('月', 30),
          _buildRangeChip('年', 365),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, int value) {
    final isSelected = _selectedRange == value;
    return Expanded(
      child: Semantics(
        button: true,
        label: '显示$label数据',
        selected: isSelected,
        child: GestureDetector(
        onTap: () => setState(() => _selectedRange = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.diet : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 空状态
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: EmptyStateWidget(
        icon: Icons.restaurant_rounded,
        title: '还没有饮食记录',
        subtitle: '点击右下角按钮记录饮食',
        accentColor: AppColors.diet,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 弹窗
  // ---------------------------------------------------------------------------

  void _showGoalSettings() {
    GoalEditSheet.show(
      context: context,
      title: '设置每日卡路里目标',
      currentValue: ref.read(dailyCalorieGoalProvider),
      unit: 'kcal/天',
      min: 500,
      max: 5000,
      step: 100,
      suggestion: '建议每天摄入 1500~2500 kcal',
      color: AppColors.diet,
      onSave: (value) async {
        ref.read(dailyCalorieGoalProvider.notifier).state = value;
        final repo = ref.read(settingRepositoryProvider);
        await repo.setSetting('daily_calorie_goal', value.toString());
      },
    );
  }

  void _showWaterGoalSettings() {
    GoalEditSheet.show(
      context: context,
      title: '设置每日饮水目标',
      currentValue: ref.read(dailyWaterGoalProvider),
      unit: 'ml/天',
      min: 500,
      max: 5000,
      step: 100,
      suggestion: '建议每天饮水 1500~2500 ml',
      color: AppColors.info,
      onSave: (value) async {
        ref.read(dailyWaterGoalProvider.notifier).state = value;
        final repo = ref.read(settingRepositoryProvider);
        await repo.setSetting('daily_water_goal', value.toString());
      },
    );
  }
}

// =============================================================================
// 卡路里和饮水量变化图表 (fl_chart)
// =============================================================================

/// 图表数据点
