import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/constants/record_icon_assets.dart';
import '../models/health_data.dart';
import '../../health/providers/diet_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../../shared/widgets/sort_button.dart';
import '../../../shared/widgets/swipe_delete_tile.dart';

/// 全部饮食记录页面
///
/// 显示所有饮食记录，支持排序和按日期分组浏览。
/// 从 diet_page 的「查看全部」导航进入。
class AllDietRecordsPage extends ConsumerStatefulWidget {
  const AllDietRecordsPage({super.key});

  @override
  ConsumerState<AllDietRecordsPage> createState() => _AllDietRecordsPageState();
}

class _AllDietRecordsPageState extends ConsumerState<AllDietRecordsPage> {
  // ── 饮食主题色（橙色） ──
  static const _accent = Color(0xFFB66A00);

  SortOption _sortOption = SortOption.newest;

  /// 当前已加载的记录数量上限（分批加载）
  int _loadLimit = 50;

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recentDietRecordsProvider(_loadLimit));

    return Scaffold(
      backgroundColor: context.growthColors.background,
      appBar: AppBar(
        title: Text(
          '全部饮食记录',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.growthColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.growthColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: context.growthColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          SortButton<SortOption>.legacy(
            currentSort: _sortOption,
            onSortChanged: (option) => setState(() => _sortOption = option),
            accentColor: _accent,
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return _buildEmptyState();
          }
          return _buildRecordList(records);
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _accent)),
        error: (e, _) => Center(
          child: Text(
            '加载失败: $e',
            style: TextStyle(color: context.growthColors.textSecondary),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 记录列表（按日期分组）
  // ---------------------------------------------------------------------------

  Widget _buildRecordList(List<DietRecord> records) {
    // 客户端排序
    final sorted = _sortRecords(records);

    // 按日期分组
    final groups = groupRecordsByDate(
      sorted,
      (r) => DateTime.parse(r.mealDate),
    );

    // 展平为带分组头 + 加载更多的列表
    final items = <_ListItem>[];
    for (final entry in groups.entries) {
      items.add(_ListItem.header(entry.key));
      for (final record in entry.value) {
        items.add(_ListItem.record(record));
      }
    }

    // 统计数据
    final totalCount = sorted.length;
    final avgScore = totalCount > 0
        ? (sorted.map((r) => r.healthScore).reduce((a, b) => a + b) /
                  totalCount)
              .toStringAsFixed(1)
        : '0.0';
    final todayCount = sorted.where((r) {
      final date = DateTime.parse(r.mealDate);
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recentDietRecordsProvider(_loadLimit));
      },
      color: _accent,
      child: CustomScrollView(
        slivers: [
          // ── 统计摘要卡片 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _buildStatsSummary(totalCount, avgScore, todayCount),
            ),
          ),

          // ── 记录列表 ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: items.length + 1, // +1 for "加载更多"
              itemBuilder: (context, index) {
                // 最后一项：加载更多按钮
                if (index == items.length) {
                  return _buildLoadMoreButton();
                }

                final item = items[index];
                if (item.isHeader) {
                  return DateGroupHeader(label: item.headerLabel!);
                }

                final record = item.record!;
                return SwipeDeleteTile(
                  key: ValueKey('diet_all_${record.id}'),
                  onConfirmDelete: () async {
                    await _deleteDietRecord(record);
                    return false;
                  },
                  onDismissed: () {},
                  child: _DietRecordTile(
                    record: record,
                    onTap: () => context.push('/plan/diet/detail/${record.id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 统计摘要
  // ---------------------------------------------------------------------------

  Widget _buildStatsSummary(int totalCount, String avgScore, int todayCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB66A00), Color(0xFFD48800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: '总记录',
            value: '$totalCount',
            icon: Icons.restaurant_rounded,
          ),
          _StatItem(label: '平均评分', value: avgScore, icon: Icons.star_rounded),
          _StatItem(
            label: '今日记录',
            value: '$todayCount',
            icon: Icons.today_rounded,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 排序
  // ---------------------------------------------------------------------------

  List<DietRecord> _sortRecords(List<DietRecord> records) {
    final sorted = List<DietRecord>.from(records);
    switch (_sortOption) {
      case SortOption.newest:
        sorted.sort((a, b) => b.mealDate.compareTo(a.mealDate));
        break;
      case SortOption.oldest:
        sorted.sort((a, b) => a.mealDate.compareTo(b.mealDate));
        break;
      case SortOption.highestExp:
        sorted.sort((a, b) => b.healthScore.compareTo(a.healthScore));
        break;
    }
    return sorted;
  }

  // ---------------------------------------------------------------------------
  // 加载更多
  // ---------------------------------------------------------------------------

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: GestureDetector(
          onTap: () => setState(() => _loadLimit += 50),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.expand_more_rounded, size: 18, color: _accent),
                SizedBox(width: 4),
                Text(
                  '加载更多',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 空状态
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: EmptyStateWidget(
          icon: Icons.restaurant_rounded,
          title: '还没有饮食记录',
          subtitle: '去记录你的每一餐吧',
          accentColor: _accent,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 删除
  // ---------------------------------------------------------------------------

  Future<void> _deleteDietRecord(DietRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '删除确认',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.growthColors.textPrimary,
          ),
        ),
        content: Text(
          '确定要删除「${record.foodText}」吗？',
          style: TextStyle(
            fontSize: 14,
            color: context.growthColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '取消',
              style: TextStyle(color: context.growthColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: context.growthColors.danger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(dietRepositoryProvider);
      await repo.deleteDietRecord(record.id);
      if (!mounted) return;

      ref.invalidate(recentDietRecordsProvider(_loadLimit));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已删除')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败，请重试')));
    }
  }

  // ---------------------------------------------------------------------------
  // 辅助方法
  // ---------------------------------------------------------------------------
}

// =============================================================================
// 统计项
// =============================================================================

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: context.growthColors.textOnAccent.withValues(alpha: 0.85),
          size: 22,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.growthColors.textOnAccent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.growthColors.textOnAccent.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 饮食记录卡片
// =============================================================================

class _DietRecordTile extends StatelessWidget {
  const _DietRecordTile({required this.record, required this.onTap});

  final DietRecord record;
  final VoidCallback onTap;

  static const _accent = Color(0xFF6B8E23);
  static const _accentLight = Color(0xFFEAF8F0);

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(record.mealDate);
    final weekday = [
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六',
      '周日',
    ][date.weekday - 1];
    final dateStr = '${date.month}月${date.day}日 $weekday';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.growthColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: _accent.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            // ── 左侧图标 ──
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _accentLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.asset(
                  RecordIconAssets.dietByMealType(record.mealType),
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.restaurant_rounded,
                    color: _accent,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // ── 中间内容 ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.foodText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.growthColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$dateStr · ${_mealTypeLabel(record.mealType)} · ${_portionLabel(record.portionLevel)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.growthColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ── 右侧评分 ──
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: _accentLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: _accent, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    '${record.healthScore}/5',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accent,
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
}

// =============================================================================
// 列表项模型（分组头或记录）
// =============================================================================

class _ListItem {
  _ListItem.header(this.headerLabel) : record = null, isHeader = true;
  _ListItem.record(this.record) : headerLabel = null, isHeader = false;

  final String? headerLabel;
  final DietRecord? record;
  final bool isHeader;
}
