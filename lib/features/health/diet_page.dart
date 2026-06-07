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
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../../shared/widgets/common/recent_record_tile.dart';
import '../../../shared/widgets/swipe_delete_tile.dart';
import 'package:go_router/go_router.dart';
import '../pet/models/pet_scene_model.dart';
import '../pet/widgets/pet_scene_banner.dart';

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
                  color: Color(0xFF2D5016),
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: const Color(0xFF2D5016),
                onPressed: () => context.pop(),
              ),
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayDietRecordsProvider);
          ref.invalidate(todayDietCountProvider);
          ref.invalidate(todayAvgHealthScoreProvider);
          ref.invalidate(recentDietRecordsProvider(10));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 甜甜提醒 ──
              PetSceneBanner(
                module: PetModuleType.diet,
                hasRecords: todayCount.whenOrNull(data: (c) => c) != null && (todayCount.whenOrNull(data: (c) => c) ?? 0) > 0,
                onTap: () => context.push('/pet-center'),
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
              SectionHeader(
                title: '最近饮食',
                action: '查看全部',
                onActionTap: () => context.push('/plan/diet/records'),
              ),
              _buildRecentRecords(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plan/diet/add'),
        backgroundColor: const Color(0xFF6B8E23),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 最近饮食记录
  // ---------------------------------------------------------------------------

  Widget _buildRecentRecords() {
    final recentRecords = ref.watch(recentDietRecordsProvider(10));

    return recentRecords.when(
      data: (records) {
        if (records.isEmpty) return _buildEmptyState();
        final displayRecords =
            _recentRecordsExpanded ? records : records.take(5).toList();
        return Column(
          children: [
            ...displayRecords.map(
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
                  iconBackgroundColor: const Color(0xFF6B8E23),
                  title: r.foodText,
                  subtitle:
                      '${_mealTypeLabel(r.mealType)} · ${_portionLabel(r.portionLevel)}',
                  primaryBadge:
                      '${'★' * r.healthScore}${'☆' * (5 - r.healthScore)}',
                  primaryBadgeColor: const Color(0xFF6B8E23),
                  secondaryBadge: null,
                  secondaryBadgeColor: AppColors.textSecondary,
                  onTap: () => _showDietDetailSheet(context, r),
                ),
              ),
            ),
            if (records.length > 5)
              GestureDetector(
                onTap: () => setState(() {
                  _recentRecordsExpanded = !_recentRecordsExpanded;
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _recentRecordsExpanded ? '收起' : '查看更多',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B8E23),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _recentRecordsExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: const Color(0xFF6B8E23),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
        accentColor: const Color(0xFF6B8E23),
        primaryMetricLabel: '健康评分',
        primaryMetricValue: '${record.healthScore}/5',
        detailItems: [
          DetailItem(label: '餐次', value: _mealTypeLabel(record.mealType), icon: Icons.restaurant_rounded),
          DetailItem(label: '份量', value: _portionLabel(record.portionLevel), icon: Icons.scale_outlined),
          DetailItem(label: '热量', value: _calorieLabel(record.calorieLevel), icon: Icons.local_fire_department_outlined),
          DetailItem(label: '蛋白质', value: _proteinLabel(record.proteinLevel), icon: Icons.bolt_outlined),
        ],
        extraCard: (record.note != null && record.note!.isNotEmpty)
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
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.note_outlined, color: Color(0xFF86909C), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('备注', style: TextStyle(fontSize: 13, color: Color(0xFF86909C))),
                const SizedBox(height: 4),
                Text(note, style: const TextStyle(fontSize: 14, color: Color(0xFF1F2329))),
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

    // 计算总卡路里（估算）
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B8E23).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // 标题行
          Row(
            children: [
              const Text(
                '今日统计',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showGoalSettings,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B8E23).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.settings_rounded, size: 14, color: Color(0xFF6B8E23)),
                      SizedBox(width: 4),
                      Text(
                        '设定目标',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B8E23),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计卡片
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.restaurant_rounded,
                  label: '餐次',
                  value: '$count',
                  unit: '餐',
                  color: const Color(0xFF6B8E23),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_fire_department_rounded,
                  label: '卡路里',
                  value: '$totalCalories',
                  unit: 'kcal',
                  color: const Color(0xFFFF8C00),
                  progress: totalCalories / calorieGoal,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.star_rounded,
                  label: '健康评分',
                  value: score.toStringAsFixed(1),
                  unit: '/5',
                  color: const Color(0xFFDAA520),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    double? progress,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8B8B83),
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8B8B83),
                ),
              ),
            ],
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ],
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
        border: Border.all(
          color: const Color(0xFF4A90D9).withValues(alpha: 0.2),
        ),
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
                  color: const Color(0xFF4A90D9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Color(0xFF4A90D9),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '饮水量',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D5016),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showWaterGoalSettings,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90D9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '目标 ${waterGoal}ml',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4A90D9),
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
              backgroundColor: const Color(0xFF4A90D9).withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90D9)),
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
                  color: Color(0xFF4A90D9),
                ),
              ),
              Text(
                '${((_currentWater / waterGoal) * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B8B83),
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        saveWaterIntake(ref, amount);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4A90D9).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF4A90D9).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, size: 14, color: Color(0xFF4A90D9)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A90D9),
              ),
            ),
          ],
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
        border: Border.all(
          color: const Color(0xFF6B8E23).withValues(alpha: 0.2),
        ),
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
                  color: const Color(0xFF6B8E23).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF6B8E23),
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
                  color: const Color(0xFF2D5016),
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
      child: GestureDetector(
        onTap: () => setState(() => _selectedRange = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6B8E23) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : const Color(0xFF8B8B83),
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
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8B8B83),
          ),
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
        accentColor: const Color(0xFF6B8E23),
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
      color: const Color(0xFF4A90D9),
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
class _ChartPoint {
  const _ChartPoint({
    required this.x,
    required this.calorie,
    required this.water,
    required this.label,
    required this.subLabel,
  });

  final double x;
  final int calorie;
  final int water;
  final String label;
  final String subLabel;
}

class _CalorieWaterChart extends StatefulWidget {
  const _CalorieWaterChart({
    required this.calorieMap,
    required this.waterMap,
    required this.days,
  });

  final Map<String, int> calorieMap;
  final Map<String, int> waterMap;
  final int days;

  @override
  State<_CalorieWaterChart> createState() => _CalorieWaterChartState();
}

class _CalorieWaterChartState extends State<_CalorieWaterChart> {
  int? _touchedIndex;

  // ── 颜色常量 ──
  static const Color _calorieColor = Color(0xFFFF7D00);
  static const Color _waterColor = Color(0xFF5D68F2);

  // ── 格式化工具 ──

  /// 卡路里格式：<1000 显示 "800"，≥1000 显示 "1.5k"
  static String _formatCalorie(int v) {
    if (v <= 0) return '0';
    if (v < 1000) return '$v';
    final k = v / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
  }

  /// 饮水量格式：<1000ml 显示 "500ml"，≥1000 显示 "1.5L"
  static String _formatWater(int ml) {
    if (ml <= 0) return '0ml';
    if (ml < 1000) return '${ml}ml';
    final l = ml / 1000;
    return '${l.toStringAsFixed(l >= 10 ? 0 : 1)}L';
  }

  // ── 数据聚合 ──

  List<_ChartPoint> _buildWeekPoints() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: 6));
    final points = <_ChartPoint>[];
    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      points.add(_ChartPoint(
        x: i.toDouble(),
        calorie: widget.calorieMap[key] ?? 0,
        water: widget.waterMap[key] ?? 0,
        label: weekDays[date.weekday - 1],
        subLabel: DateFormat('M/d').format(date),
      ));
    }
    return points;
  }

  List<_ChartPoint> _buildMonthPoints() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 本月1号
    final monthStart = DateTime(now.year, now.month, 1);
    final points = <_ChartPoint>[];

    for (int w = 0; w < 4; w++) {
      final weekStart = monthStart.add(Duration(days: w * 7));
      // 不超过今天
      final weekEnd = weekStart.add(const Duration(days: 6));
      final actualEnd = weekEnd.isAfter(today) ? today : weekEnd;

      int totalCal = 0;
      int totalWater = 0;
      var d = weekStart;
      while (!d.isAfter(actualEnd)) {
        final key = DateFormat('yyyy-MM-dd').format(d);
        totalCal += widget.calorieMap[key] ?? 0;
        totalWater += widget.waterMap[key] ?? 0;
        d = d.add(const Duration(days: 1));
      }

      final startLabel = DateFormat('M/d').format(weekStart);
      final endLabel = DateFormat('M/d').format(actualEnd);

      points.add(_ChartPoint(
        x: w.toDouble(),
        calorie: totalCal,
        water: totalWater,
        label: '第${w + 1}周',
        subLabel: '$startLabel-$endLabel',
      ));
    }
    return points;
  }

  List<_ChartPoint> _buildYearPoints() {
    final now = DateTime.now();
    final points = <_ChartPoint>[];

    for (int m = 0; m < 12; m++) {
      final monthStart = DateTime(now.year, m + 1, 1);
      final monthEnd = DateTime(now.year, m + 2, 0); // 月末
      final actualEnd = monthEnd.isAfter(now) ? now : monthEnd;

      int totalCal = 0;
      int totalWater = 0;
      var d = monthStart;
      while (!d.isAfter(actualEnd)) {
        final key = DateFormat('yyyy-MM-dd').format(d);
        totalCal += widget.calorieMap[key] ?? 0;
        totalWater += widget.waterMap[key] ?? 0;
        d = d.add(const Duration(days: 1));
      }

      points.add(_ChartPoint(
        x: m.toDouble(),
        calorie: totalCal,
        water: totalWater,
        label: '${m + 1}月',
        subLabel: '',
      ));
    }
    return points;
  }

  List<_ChartPoint> _buildPoints() {
    if (widget.days <= 7) return _buildWeekPoints();
    if (widget.days <= 30) return _buildMonthPoints();
    return _buildYearPoints();
  }

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();
    if (points.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(fontSize: 12, color: Color(0xFF8B8B83))),
      );
    }

    // 计算 Y 轴范围
    final maxCalorie = points.map((p) => p.calorie).fold<int>(0, (a, b) => a > b ? a : b);
    final maxWater = points.map((p) => p.water).fold<int>(0, (a, b) => a > b ? a : b);
    // 至少留 20% 余量，最小值 1000
    final calTop = ((maxCalorie * 1.2).ceil() / 500).ceil() * 500;
    final waterTop = maxWater > 0
        ? ((maxWater * 1.2).ceil() / 500).ceil() * 500
        : 2000;
    final calTopD = calTop.toDouble();
    final waterTopD = waterTop.toDouble();

    // 归一化到 0-1
    FlSpot calSpot(_ChartPoint p) =>
        FlSpot(p.x, calTopD > 0 ? p.calorie / calTopD : 0);
    FlSpot waterSpot(_ChartPoint p) =>
        FlSpot(p.x, waterTopD > 0 ? p.water / waterTopD : 0);

    final calSpots = points.map(calSpot).toList();
    final waterSpots = points.map(waterSpot).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1.0,
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
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((_) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: barData.color?.withValues(alpha: 0.3) ?? _calorieColor,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bd, idx) =>
                      FlDotCirclePainter(
                    radius: 5,
                    color: bd.color ?? _calorieColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              );
            }).toList();
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
              if (idx < 0 || idx >= points.length) return [];
              final p = points[idx];

              final items = <LineTooltipItem>[];

              // 卡路里
              final calSpot = touchedSpots.where((s) => s.barIndex == 0).firstOrNull;
              if (calSpot != null) {
                items.add(LineTooltipItem(
                  '${p.label} 卡路里 ${_formatCalorie(p.calorie)}',
                  const TextStyle(
                    color: _calorieColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ));
              }

              // 饮水量
              final waterSpot = touchedSpots.where((s) => s.barIndex == 1).firstOrNull;
              if (waterSpot != null) {
                items.add(LineTooltipItem(
                  '${p.label} 饮水 ${_formatWater(p.water)}',
                  const TextStyle(
                    color: _waterColor,
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
          // 卡路里线
          LineChartBarData(
            spots: calSpots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: _calorieColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: _touchedIndex == index ? 5 : 3,
                color: _calorieColor,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _calorieColor.withValues(alpha: 0.06),
            ),
          ),
          // 饮水量线
          LineChartBarData(
            spots: waterSpots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: _waterColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: _touchedIndex == index ? 5 : 3,
                color: _waterColor,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _waterColor.withValues(alpha: 0.06),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          // 左 Y 轴：卡路里
          leftTitles: AxisTitles(
            axisNameWidget: const Text(
              'kcal',
              style: TextStyle(fontSize: 9, color: _calorieColor),
            ),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: 0.25,
              getTitlesWidget: (value, meta) {
                final kcal = (value * calTopD).round();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _formatCalorie(kcal),
                    style: const TextStyle(fontSize: 9, color: _calorieColor),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          // 右 Y 轴：饮水量
          rightTitles: AxisTitles(
            axisNameWidget: const Text(
              'ml',
              style: TextStyle(fontSize: 9, color: _waterColor),
            ),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: 0.25,
              getTitlesWidget: (value, meta) {
                final ml = (value * waterTopD).round();
                return Text(
                  _formatWater(ml),
                  style: const TextStyle(fontSize: 9, color: _waterColor),
                  textAlign: TextAlign.left,
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          // X 轴：双行标签
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                final p = points[idx];
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D5016),
                        ),
                      ),
                      if (p.subLabel.isNotEmpty)
                        Text(
                          p.subLabel,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Color(0xFF8B8B83),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFFE0E0D8),
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        // ── 每个点上方的数值标签 ──
        extraLinesData: ExtraLinesData(
          horizontalLines: [],
        ),
      ),
      duration: const Duration(milliseconds: 200),
    );
  }
}

