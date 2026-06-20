import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/fitness_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../../shared/widgets/sort_button.dart';
import '../../../shared/widgets/swipe_delete_tile.dart';

/// 全部训练记录页面 — 重新设计
///
/// 顶部渐变统计摘要 + 按日期分组的卡片列表，保持排序与删除功能。
class AllFitnessRecordsPage extends ConsumerStatefulWidget {
  const AllFitnessRecordsPage({super.key});

  @override
  ConsumerState<AllFitnessRecordsPage> createState() =>
      _AllFitnessRecordsPageState();
}

class _AllFitnessRecordsPageState extends ConsumerState<AllFitnessRecordsPage> {
  SortOption _sortOption = SortOption.newest;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(sortedRecentFitnessRecordsProvider);

    return Scaffold(
      backgroundColor: context.growthColors.background,
      appBar: AppBar(
        title: Text('全部训练记录', style: AppTextStyles.pageTitle),
        centerTitle: false,
        backgroundColor: context.growthColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort, color: context.growthColors.textSecondary),
            onSelected: (option) {
              setState(() => _sortOption = option);
              ref.read(fitnessSortProvider.notifier).state = option;
            },
            itemBuilder: (context) => [
              _buildSortItem(SortOption.newest, '最新优先'),
              _buildSortItem(SortOption.oldest, '最早优先'),
              _buildSortItem(SortOption.highestExp, '经验值最高'),
            ],
          ),
        ],
      ),
      body: records.when(
        data: (records) {
          if (records.isEmpty) return _buildEmptyState();
          return _buildContent(records);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 排序菜单
  // ---------------------------------------------------------------------------

  PopupMenuItem<SortOption> _buildSortItem(SortOption option, String text) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Text(text, style: AppTextStyles.body),
          if (_sortOption == option) ...[
            const Spacer(),
            Icon(Icons.check, size: 16, color: context.growthColors.fitness),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 主内容：统计摘要 + 记录列表
  // ---------------------------------------------------------------------------

  Widget _buildContent(List<FitnessRecord> records) {
    // 计算统计
    final totalCount = records.length;
    final totalMinutes = records.fold<int>(
      0,
      (sum, r) => sum + r.durationMinutes,
    );
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);
    final totalExp = records.fold<int>(0, (sum, r) => sum + r.expGained);

    // 按日期分组
    final groups = groupRecordsByDate(
      records,
      (r) => DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    );

    final items = <_ListItem>[];
    for (final entry in groups.entries) {
      items.add(_ListItem.header(entry.key));
      for (final record in entry.value) {
        items.add(_ListItem.record(record));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: items.length + 1, // +1 for stats header
      itemBuilder: (context, index) {
        // 首项 = 统计摘要
        if (index == 0) {
          return _buildStatsSummary(
            totalCount: totalCount,
            totalHours: totalHours,
            totalExp: totalExp,
          );
        }

        final item = items[index - 1];
        if (item.isHeader) {
          return DateGroupHeader(label: item.headerLabel!);
        }

        final record = item.record!;
        return SwipeDeleteTile(
          key: ValueKey('all_fitness_${record.id}'),
          onConfirmDelete: () async {
            _deleteRecord(context, ref, record);
            return false;
          },
          onDismissed: () {},
          child: _RecordCard(
            record: record,
            onTap: () => context.push('/plan/fitness/detail/${record.id}'),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 渐变统计摘要
  // ---------------------------------------------------------------------------

  Widget _buildStatsSummary({
    required int totalCount,
    required String totalHours,
    required int totalExp,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.growthColors.fitness,
            context.growthColors.fitness.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.growthColors.fitness.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.fitness_center,
            label: '总训练',
            value: '$totalCount',
          ),
          Container(
            width: 1,
            height: 40,
            color: context.growthColors.textOnAccent.withValues(alpha: 0.3),
          ),
          _StatItem(
            icon: Icons.timer_outlined,
            label: '总时长',
            value: '${totalHours}h',
          ),
          Container(
            width: 1,
            height: 40,
            color: context.growthColors.textOnAccent.withValues(alpha: 0.3),
          ),
          _StatItem(icon: Icons.star_outline, label: '总经验', value: '$totalExp'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 空状态
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.growthColors.fitness.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center,
              size: 40,
              color: context.growthColors.fitness,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('暂无训练记录', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text('开始你的第一次训练吧！', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 删除
  // ---------------------------------------------------------------------------

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
            style: TextButton.styleFrom(
              foregroundColor: context.growthColors.danger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(fitnessRepositoryProvider);
        await repo.deleteFitnessRecord(record.id);
        ref.invalidate(sortedRecentFitnessRecordsProvider);
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
          ).showSnackBar(SnackBar(content: Text('删除失败，请重试')));
        }
      }
    }
  }
}

// =============================================================================
// 统计单项
// =============================================================================

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: context.growthColors.textOnAccent, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.growthColors.textOnAccent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.growthColors.textOnAccent.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 记录卡片（统一风格）
// =============================================================================

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.onTap});

  final FitnessRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fitness = context.growthColors.fitness;
    final fitnessFaded = fitness.withValues(alpha: 0.1);

    final dt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    final dateStr =
        '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final isProfessional = record.mode == 'professional';

    return GrowthCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      borderColor: fitnessFaded,
      onTap: onTap,
      child: Row(
        children: [
          // 图标容器
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: fitnessFaded,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.fitness_center, color: fitness, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),

          // 中间信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.title ?? record.bodyPart,
                        style: AppTextStyles.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isProfessional)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: fitnessFaded,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '专业',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: fitness,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // 详情行
                Text(
                  '${record.bodyPart} · ${record.durationMinutes}分钟 · $dateStr',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // EXP 徽章
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: fitnessFaded,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '+${record.expGained} EXP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fitness,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 列表项模型
// =============================================================================

class _ListItem {
  _ListItem.header(this.headerLabel) : record = null, isHeader = true;
  _ListItem.record(this.record) : headerLabel = null, isHeader = false;

  final String? headerLabel;
  final FitnessRecord? record;
  final bool isHeader;
}
