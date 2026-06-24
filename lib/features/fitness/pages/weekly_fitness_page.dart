import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../models/fitness_data.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/fitness_dashboard_facade.dart';
import '../../fitness/providers/fitness_provider.dart';
import '../../../shared/providers/settings_facade.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../../shared/widgets/swipe_delete_tile.dart';

/// 本周训练详情页
///
/// 展示本周所有训练记录 + 设置每周训练目标
class WeeklyFitnessPage extends ConsumerStatefulWidget {
  const WeeklyFitnessPage({super.key});

  @override
  ConsumerState<WeeklyFitnessPage> createState() => _WeeklyFitnessPageState();
}

class _WeeklyFitnessPageState extends ConsumerState<WeeklyFitnessPage> {
  Future<void> _saveWeeklyGoal(int goal) async {
    await ref.read(settingsFacadeProvider).setWeeklyFitnessGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final weeklyGoal = ref.watch(weeklyFitnessGoalProvider);
    final weeklyCount = ref.watch(weeklyFitnessCountProvider);
    final recentRecords = ref.watch(sortedRecentFitnessRecordsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('本周训练', style: AppTextStyles.pageTitle),
        centerTitle: false,
        backgroundColor: colors.background,
        actions: [
          IconButton(
            tooltip: '设置周目标',
            onPressed: () => _showWeeklyGoalSheet(context),
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weeklyFitnessCountProvider);
          ref.invalidate(sortedRecentFitnessRecordsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── 周进度概览 ──
            _buildWeeklyProgressCard(weeklyCount, weeklyGoal),
            const SizedBox(height: AppSpacing.lg),

            // ── 7天详情 ──
            _buildWeekDayGrid(),
            const SizedBox(height: AppSpacing.lg),

            // ── 本周记录列表 ──
            _buildWeeklyRecordsList(recentRecords),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressCard(AsyncValue<int> weeklyCount, int weeklyGoal) {
    final colors = context.growthColors;
    return weeklyCount.when(
      data: (count) {
        final progress = weeklyGoal > 0
            ? (count / weeklyGoal).clamp(0.0, 1.0)
            : 0.0;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.fitness, colors.fitness.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.fitness.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '本周训练进度',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textOnAccent.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count / $weeklyGoal 次',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: colors.textOnAccent,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.textOnAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textOnAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: colors.textOnAccent.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.textOnAccent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 140),
      error: (_, _) => const ErrorRetryWidget(),
    );
  }

  Widget _buildWeekDayGrid() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return GrowthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本周详情', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = weekStart.add(Duration(days: index));
              final isToday =
                  day.year == now.year &&
                  day.month == now.month &&
                  day.day == now.day;
              final isPast = day.isBefore(now) && !isToday;
              final dayNames = ['一', '二', '三', '四', '五', '六', '日'];

              return _WeekDayItem(
                dayName: dayNames[index],
                dayNum: day.day,
                isToday: isToday,
                isPast: isPast,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyRecordsList(
    AsyncValue<List<FitnessRecord>> recentRecords,
  ) {
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('本周记录', style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpacing.md),
        recentRecords.when(
          data: (records) {
            // Filter to this week
            final now = DateTime.now();
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final weekStartMs = DateTime(
              weekStart.year,
              weekStart.month,
              weekStart.day,
            ).millisecondsSinceEpoch;

            final weekRecords = records
                .where((r) => r.startTime >= weekStartMs)
                .toList();

            if (weekRecords.isEmpty) {
              return GrowthCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: colors.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('本周还没有训练记录', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: weekRecords
                  .map(
                    (r) => SwipeDeleteTile(
                      key: ValueKey('weekly_fitness_${r.id}'),
                      onConfirmDelete: () async {
                        _deleteRecord(context, ref, r);
                        return false;
                      },
                      onDismissed: () {},
                      child: _WeeklyRecordTile(
                        record: r,
                        onTap: () =>
                            context.push('/plan/fitness/detail/${r.id}'),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('加载失败: $e'),
        ),
      ],
    );
  }

  void _showWeeklyGoalSheet(BuildContext context) {
    final colors = context.growthColors;
    int tempGoal = ref.read(weeklyFitnessGoalProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: colors.paper,
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
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '设置每周训练目标',
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
                        if (tempGoal > 1) {
                          setSheetState(() => tempGoal--);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline, size: 32),
                      color: colors.fitness,
                    ),
                    const SizedBox(width: 24),
                    Text(
                      '$tempGoal',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: colors.fitness,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '次/周',
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: () {
                        if (tempGoal < 14) {
                          setSheetState(() => tempGoal++);
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 32),
                      color: colors.fitness,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('建议每周训练 3~5 次', style: AppTextStyles.caption),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _saveWeeklyGoal(tempGoal);
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

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    FitnessRecord record,
  ) async {
    final colors = context.growthColors;
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
        ref.invalidate(weeklyFitnessCountProvider);
        ref.invalidate(sortedRecentFitnessRecordsProvider);
        ref.invalidate(recentFitnessRecordsProvider);
        ref.invalidate(todayFitnessMinutesProvider);
        ref.read(fitnessDashboardFacadeProvider).refreshDashboard();
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

/// 周日期项
class _WeekDayItem extends StatelessWidget {
  const _WeekDayItem({
    required this.dayName,
    required this.dayNum,
    required this.isToday,
    required this.isPast,
  });

  final String dayName;
  final int dayNum;
  final bool isToday;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      children: [
        Text(
          dayName,
          style: TextStyle(
            fontSize: 12,
            color: isToday ? colors.fitness : colors.textTertiary,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isToday
                ? colors.fitness
                : isPast
                ? colors.fitness.withValues(alpha: 0.1)
                : colors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$dayNum',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday
                    ? colors.textOnAccent
                    : isPast
                    ? colors.fitness
                    : colors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 本周记录列表项
class _WeeklyRecordTile extends StatelessWidget {
  const _WeeklyRecordTile({required this.record, required this.onTap});

  final FitnessRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final dt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dayName = dayNames[dt.weekday - 1];
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return GrowthCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.softOrange,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.fitness_center, color: colors.fitness),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title ?? record.bodyPart,
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$dayName $timeStr · ${record.bodyPart} · ${record.durationMinutes}分钟',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.softOrange,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '+${record.expGained} EXP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.fitness,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
