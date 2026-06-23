import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../shared/providers/settings_facade.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../fitness/providers/fitness_provider.dart';
import 'dashboard_card.dart';
import 'add_card_sheet.dart';

/// 首页今日概览组件
///
/// 支持：
/// - 动态显示用户自定义的卡片
/// - 长按删除卡片
/// - 点击添加按钮添加新卡片
/// - 卡片进入/退出动画
class TodayOverview extends ConsumerStatefulWidget {
  const TodayOverview({super.key});

  @override
  ConsumerState<TodayOverview> createState() => _TodayOverviewState();
}

class _TodayOverviewState extends ConsumerState<TodayOverview>
    with TickerProviderStateMixin {
  /// 卡片动画控制器列表
  final List<AnimationController> _cardControllers = [];

  /// 删除动画控制器
  AnimationController? _deleteController;
  String? _deletingCardId;

  /// 折叠/展开状态
  bool _isExpanded = false;

  @override
  void dispose() {
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    _deleteController?.dispose();
    super.dispose();
  }

  /// 获取卡片对应的当前值
  int _getCardValue(String cardId, DashboardData data) {
    switch (cardId) {
      case 'study':
        return data.todayStudyMinutes;
      case 'fitness':
        return data.todayFitnessMinutes;
      case 'diet':
        return data.todayDietCount;
      case 'sleep':
        return data.lastNightSleepDuration ?? 0;
      case 'journal':
        return data.todayJournalCount;
      case 'water':
        final waterMap = ref.watch(dailyWaterIntakeProvider);
        return getTodayWaterIntake(waterMap);
      case 'focus':
        return data.todayFocusMinutes;
      case 'weight':
        final latestMetric = ref.watch(latestBodyMetricProvider).valueOrNull;
        return latestMetric?.weight?.round() ?? 0;
      default:
        return 0;
    }
  }

  /// 获取卡片目标值
  ///
  /// 学习/健身/写日记 从 [dailyGoalsProvider] 读取用户自定义目标，
  /// 其余卡片使用默认值或各自独立的 Provider。
  int _getCardTarget(String cardId) {
    final dailyGoals = ref.watch(dailyGoalsProvider);

    switch (cardId) {
      case 'study':
        return dailyGoals
            .firstWhere(
              (g) => g.name == '学习',
              orElse: () =>
                  const DailyGoal(name: '学习', target: 120, unit: '分钟'),
            )
            .target;
      case 'fitness':
        return dailyGoals
            .firstWhere(
              (g) => g.name == '健身',
              orElse: () => const DailyGoal(name: '健身', target: 45, unit: '分钟'),
            )
            .target;
      case 'diet':
        return 3;
      case 'sleep':
        return ref.watch(sleepGoalProvider) * 60;
      case 'journal':
        return dailyGoals
            .firstWhere(
              (g) => g.name == '写日记',
              orElse: () => const DailyGoal(name: '写日记', target: 1, unit: '篇'),
            )
            .target;
      case 'water':
        return ref.watch(dailyWaterGoalProvider);
      case 'focus':
        return 60;
      case 'weight':
        return 0;
      default:
        return 0;
    }
  }

  /// 删除卡片
  void _removeCard(String cardId) {
    setState(() {
      _deletingCardId = cardId;
    });

    // 创建删除动画控制器
    _deleteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _deleteController!.forward().then((_) async {
      // 动画完成后移除卡片
      final currentIds = ref.read(dashboardCardIdsProvider);
      final newIds = currentIds.where((id) => id != cardId).toList();
      await ref.read(settingsFacadeProvider).saveDashboardCardIds(newIds);

      if (!mounted) return;

      setState(() {
        _deletingCardId = null;
        _deleteController?.dispose();
        _deleteController = null;
      });
    });
  }

  /// 显示删除确认弹窗
  void _showDeleteConfirm(String cardId, String cardName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.growthColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.remove_circle_outline_rounded,
                size: 20,
                color: context.growthColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            const Text('移除卡片'),
          ],
        ),
        content: Text(
          '确定要移除「$cardName」卡片吗？\n移除后可随时重新添加。',
          style: TextStyle(
            fontSize: 14,
            color: context.growthColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _removeCard(cardId);
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.growthColors.danger,
            ),
            child: const Text('确定移除'),
          ),
        ],
      ),
    );
  }

  /// 显示添加卡片弹窗
  void _showAddCardSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddCardSheet(
        currentCardIds: ref.read(dashboardCardIdsProvider),
        onCardAdded: (cardId) async {
          final currentIds = ref.read(dashboardCardIdsProvider);
          final newIds = [...currentIds, cardId];
          await ref.read(settingsFacadeProvider).saveDashboardCardIds(newIds);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final cardIds = ref.watch(dashboardCardIdsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        _buildHeader(cardIds.length),
        const SizedBox(height: AppSpacing.md),

        // 卡片网格（根据折叠状态显示）
        dashboardAsync.when(
          loading: () => _buildLoadingGrid(cardIds.length),
          error: (_, _) => _buildErrorCard(),
          data: (data) => _isExpanded
              ? _buildCardGrid(cardIds, data)
              : _buildCompactGrid(cardIds, data),
        ),
      ],
    );
  }

  Widget _buildHeader(int cardCount) {
    final colors = context.growthColors;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.softPink,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: colors.border),
          ),
          child: Icon(Icons.grid_view_rounded, color: colors.journal, size: 19),
        ),
        const SizedBox(width: 10),
        Text(
          '今日概览',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            '$cardCount/8',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 折叠/展开按钮
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _showAddCardSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 14, color: colors.primary),
                const SizedBox(width: 4),
                Text(
                  '添加',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardGrid(List<String> cardIds, DashboardData data) {
    if (cardIds.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.12,
      ),
      itemCount: cardIds.length + (cardIds.length < 8 ? 1 : 0),
      itemBuilder: (context, index) {
        // 最后一个是添加按钮（如果未满8个）
        if (index == cardIds.length) {
          return AddDashboardCardButton(onTap: _showAddCardSheet);
        }

        final cardId = cardIds[index];
        final config = getCardConfigById(cardId);
        if (config == null) return const SizedBox.shrink();

        final currentValue = _getCardValue(cardId, data);
        final targetValue = _getCardTarget(cardId);

        // 判断是否正在删除
        final isDeleting = _deletingCardId == cardId;

        if (isDeleting && _deleteController != null) {
          // 删除动画
          return AnimatedBuilder(
            animation: _deleteController!,
            builder: (context, child) {
              return FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                  CurvedAnimation(
                    parent: _deleteController!,
                    curve: Curves.easeInBack,
                  ),
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 0.8).animate(
                    CurvedAnimation(
                      parent: _deleteController!,
                      curve: Curves.easeIn,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: DashboardCard(
              config: config,
              currentValue: currentValue,
              targetValue: targetValue,
            ),
          );
        }

        return DashboardCard(
          key: ValueKey(cardId),
          config: config,
          currentValue: currentValue,
          targetValue: targetValue,
          onLongPress: () => _showDeleteConfirm(cardId, config.name),
        );
      },
    );
  }

  /// 构建紧凑网格（折叠状态）
  Widget _buildCompactGrid(List<String> cardIds, DashboardData data) {
    if (cardIds.isEmpty) return _buildEmptyState();
    final colors = context.growthColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 4,
          childAspectRatio: 4.0,
        ),
        itemCount: cardIds.length,
        itemBuilder: (context, index) {
          final cardId = cardIds[index];
          final config = getCardConfigById(cardId);
          if (config == null) return const SizedBox.shrink();

          final currentValue = _getCardValue(cardId, data);
          return _CompactCard(
            icon: config.icon,
            name: config.name,
            value: currentValue,
            unit: config.unit,
            color: config.color,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.growthColors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.dashboard_customize_outlined,
            size: 48,
            color: colors.textHint,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '首页暂无卡片',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '点击下方按钮添加数据卡片',
            style: TextStyle(fontSize: 13, color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _showAddCardSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('添加卡片'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid(int count) {
    final colors = context.growthColors;
    final itemCount = count > 0 ? count : 4;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.24,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        itemCount,
        (_) => Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.border, width: 0.6),
          ),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    final colors = context.growthColors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border, width: 0.6),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: colors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '加载失败',
              style: TextStyle(color: context.growthColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 紧凑卡片组件（折叠状态）
class _CompactCard extends StatelessWidget {
  const _CompactCard({
    required this.icon,
    required this.name,
    required this.value,
    required this.unit,
    required this.color,
  });

  final IconData icon;
  final String name;
  final int value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(name, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
        const Spacer(),
        Text(
          '$value$unit',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
