import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/design/design.dart';
import '../../../core/constants/date_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../health/providers/diet_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../shared/providers/settings_facade.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../../shared/widgets/swipe_delete_tile.dart';
import '../plan/utils/plan_module_assets.dart';
import '../plan/widgets/plan_module_visuals.dart';
import 'models/drink_recommendation.dart';
import 'providers/water_plan_provider.dart';

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
    final colors = context.growthColors;
    final todayRecords = ref.watch(todayDietRecordsProvider);
    final todayCount = ref.watch(todayDietCountProvider);
    final todayScore = ref.watch(todayAvgHealthScoreProvider);

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                '饮食记录',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              centerTitle: false,
              backgroundColor: colors.paper,
              elevation: 0,
            ),
      body: ModulePageSurface(
        color: colors.diet,
        child: RefreshIndicator(
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
                  color: colors.diet,
                ),
                const SizedBox(height: 12),
                _buildDrinkRecommendationEntry(),
                const SizedBox(height: 12),
                PlanModuleActionImageCard(
                  module: PlanModuleType.diet,
                  color: colors.diet,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plan/diet/add'),
        backgroundColor: colors.diet,
        foregroundColor: colors.textOnAccent,
        child: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 今天想喝点什么
  // ---------------------------------------------------------------------------

  Widget _buildDrinkRecommendationEntry() {
    final drink = DrinkCatalog.todayRecommendation();
    final colors = context.growthColors;

    return GrowthCard(
      onTap: () => context.push('/plan/diet/drink-recommendation'),
      semanticLabel: '今天想喝点什么',
      padding: EdgeInsets.zero,
      borderRadius: 22,
      borderColor: colors.diet.withValues(alpha: 0.16),
      backgroundColor: colors.card,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.softGold,
                colors.diet.withValues(alpha: 0.12),
                colors.card,
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: colors.diet.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.local_cafe_rounded,
                              color: colors.diet,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '今天想喝点什么',
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${drink.brand} · ${drink.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '随机挑一杯今日饮品灵感',
                        style: AppTextStyles.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 108,
                height: 112,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.diet.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          drink.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return ColoredBox(
                              color: colors.softOrange,
                              child: Icon(
                                Icons.local_drink_outlined,
                                color: colors.diet,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 最近饮食记录
  // ---------------------------------------------------------------------------

  Widget _buildRecentRecordsInline() {
    final colors = context.growthColors;
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
          color: colors.diet,
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
                    iconColor: colors.textOnAccent,
                    iconBackgroundColor: colors.diet,
                    title: r.foodText,
                    subtitle:
                        '${_mealTypeLabel(r.mealType)} · ${_portionLabel(r.portionLevel)}',
                    primaryBadge:
                        '${'★' * r.healthScore}${'☆' * (5 - r.healthScore)}',
                    primaryBadgeColor: colors.diet,
                    secondaryBadge: null,
                    secondaryBadgeColor: colors.textSecondary,
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
    final colors = context.growthColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => RecordDetailSheet(
        title: _formatDietDate(record),
        accentColor: colors.diet,
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
    return GrowthDateUtils.formatDateChineseFull(date);
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
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note_outlined, color: colors.textTertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '备注',
                  style: TextStyle(fontSize: 13, color: colors.textTertiary),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
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
    final colors = context.growthColors;
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
            style: TextButton.styleFrom(foregroundColor: colors.danger),
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
          ).showSnackBar(SnackBar(content: Text('删除失败，请重试')));
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
    final colors = context.growthColors;
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
      color: colors.diet,
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
    final waterPlan = ref.watch(waterPlanProvider);
    final waterGoal = waterPlan.goalMl;
    final currentWater = waterPlan.currentWaterMl;
    final progress = waterGoal > 0
        ? (currentWater / waterGoal).clamp(0.0, 1.0)
        : 0.0;
    final reminderLabel = waterPlan.reminderEnabled
        ? '${waterPlan.reminderWindowLabel} / '
              '${waterPlan.intervalMinutes}\u5206\u949f'
        : '\u63d0\u9192\u5df2\u5173\u95ed';
    final colors = context.growthColors;
    return GrowthCard(
      onTap: () => context.push('/plan/diet/water-reminder'),
      padding: const EdgeInsets.all(18),
      borderRadius: AppRadius.xxxl,
      backgroundColor: colors.card,
      borderColor: colors.diet.withValues(alpha: 0.16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u996e\u6c34\u91cf',
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 16,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reminderLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: '\u8bbe\u7f6e\u996e\u6c34\u76ee\u6807',
                child: GestureDetector(
                  onTap: _showWaterGoalSettings,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        colors.primary.withValues(alpha: 0.10),
                        colors.card,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      '\u76ee\u6807 ${waterGoal}ml',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Color.alphaBlend(
                colors.primary.withValues(alpha: 0.14),
                colors.card,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentWater ml',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildWaterAddButton(100, '100ml')),
              const SizedBox(width: 8),
              Expanded(child: _buildWaterAddButton(250, '250ml')),
              const SizedBox(width: 8),
              Expanded(child: _buildWaterAddButton(500, '500ml')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterAddButton(int amount, String label) {
    final colors = context.growthColors;
    return Semantics(
      button: true,
      label: '添加$label饮水',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _recordWaterFromDiet(amount);
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: colors.primary.withValues(alpha: 0.24)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 14, color: colors.primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _recordWaterFromDiet(int amount) async {
    await ref.read(waterPlanProvider.notifier).recordDrinkAmount(amount);
    ref.invalidate(dailyCalorieWaterProvider(7));
    ref.invalidate(dailyCalorieWaterProvider(30));
    ref.invalidate(dailyCalorieWaterProvider(365));
  }

  // ---------------------------------------------------------------------------
  // 卡路里和饮水量变化图表 (fl_chart)
  // ---------------------------------------------------------------------------

  Widget _buildCalorieWaterChart() {
    final nutritionData = ref.watch(dailyCalorieWaterProvider(_selectedRange));
    final colors = context.growthColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.card, colors.diet.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: colors.diet.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
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
                  color: colors.diet.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.smd),
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  color: colors.diet,
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
                  color: colors.textPrimary,
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
              _buildLegend(colors.diet, '卡路里'),
              const SizedBox(width: 24),
              _buildLegend(colors.primary, '饮水量'),
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
    final colors = context.growthColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.diet.withValues(alpha: 0.10)),
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
    final colors = context.growthColors;
    return Expanded(
      child: Semantics(
        button: true,
        label: '显示$label数据',
        selected: isSelected,
        child: GestureDetector(
          onTap: () => setState(() => _selectedRange = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colors.diet : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colors.textOnAccent : colors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    final colors = context.growthColors;
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
        Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 空状态
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: EmptyStateWidget(
        icon: Icons.restaurant_rounded,
        title: '还没有饮食记录',
        subtitle: '点击右下角按钮记录饮食',
        accentColor: colors.diet,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 弹窗
  // ---------------------------------------------------------------------------

  void _showGoalSettings() {
    final colors = context.growthColors;
    GoalEditSheet.show(
      context: context,
      title: '设置每日卡路里目标',
      currentValue: ref.read(dailyCalorieGoalProvider),
      unit: 'kcal/天',
      min: 500,
      max: 5000,
      step: 100,
      suggestion: '建议每天摄入 1500~2500 kcal',
      color: colors.diet,
      onSave: (value) async {
        await ref.read(settingsFacadeProvider).setDailyCalorieGoal(value);
      },
    );
  }

  void _showWaterGoalSettings() {
    final colors = context.growthColors;
    GoalEditSheet.show(
      context: context,
      title: '设置每日饮水目标',
      currentValue: ref.read(dailyWaterGoalProvider),
      unit: 'ml/天',
      min: 500,
      max: 5000,
      step: 100,
      suggestion: '建议每天饮水 1500~2500 ml',
      color: colors.softBlue,
      onSave: (value) async {
        await ref.read(waterPlanProvider.notifier).setGoal(value);
      },
    );
  }
}

// =============================================================================
// 卡路里和饮水量变化图表 (fl_chart)
// =============================================================================

/// 图表数据点
