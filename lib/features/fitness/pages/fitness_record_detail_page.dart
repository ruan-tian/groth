import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/constants/record_icon_assets.dart';
import '../models/fitness_data.dart';
import '../../fitness/providers/fitness_provider.dart';
import '../../../shared/providers/repository_providers.dart';

/// 健身记录详情页 — 重新设计
///
/// 橙色渐变 Header + 信息网格 + 动作列表 + 备注
class FitnessRecordDetailPage extends ConsumerWidget {
  const FitnessRecordDetailPage({super.key, required this.recordId});

  final int recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final recordAsync = ref.watch(fitnessRecordByIdProvider(recordId));
    final exercisesAsync = ref.watch(
      fitnessExercisesByRecordIdProvider(recordId),
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: recordAsync.when(
        data: (record) => _DetailBody(
          record: record,
          exercisesAsync: exercisesAsync,
          onDelete: () => _confirmDelete(context, ref, record),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, e),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object e) {
    final colors = context.growthColors;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.danger),
            const SizedBox(height: AppSpacing.md),
            Text('加载失败: $e', style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FitnessRecord record,
  ) async {
    final colors = context.growthColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除确认'),
        content: Text(
          '确定要删除这条训练记录吗？\n'
          '训练部位：${record.bodyPart}\n'
          '时长：${record.durationMinutes} 分钟\n\n'
          '此操作不可撤销。',
        ),
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
        await repo.deleteFitnessExercisesByRecordId(record.id);
        await repo.deleteFitnessRecord(record.id);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已删除')));
          context.pop();
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
// 详情主体
// =============================================================================

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.record,
    required this.exercisesAsync,
    required this.onDelete,
  });

  final FitnessRecord record;
  final AsyncValue<List<FitnessExercise>> exercisesAsync;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isProfessional = record.mode == 'professional';
    final startDt = DateTime.fromMillisecondsSinceEpoch(record.startTime);
    final endDt = DateTime.fromMillisecondsSinceEpoch(record.endTime);
    final createdDt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);

    return CustomScrollView(
      slivers: [
        // ── 橙色渐变 Header ──
        SliverToBoxAdapter(
          child: _GradientHeader(
            title: record.title ?? record.bodyPart,
            bodyPart: record.bodyPart,
            expGained: record.expGained,
            isProfessional: isProfessional,
            onDelete: onDelete,
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList.list(
            children: [
              // ── 信息网格 ──
              const SizedBox(height: 24),
              _InfoGrid(
                items: [
                  _InfoItem(
                    icon: Icons.access_time_rounded,
                    label: '时长',
                    value: '${record.durationMinutes} 分钟',
                  ),
                  _InfoItem(
                    icon: Icons.play_circle_outline,
                    label: '开始',
                    value: _formatTime(startDt),
                  ),
                  _InfoItem(
                    icon: Icons.stop_circle_outlined,
                    label: '结束',
                    value: _formatTime(endDt),
                  ),
                  _InfoItem(
                    icon: Icons.calendar_today_outlined,
                    label: '记录',
                    value: _formatDate(createdDt),
                  ),
                ],
              ),

              // ── 专业模式信息 ──
              if (isProfessional) ...[
                const SizedBox(height: 28),
                _SectionHeader(
                  icon: Icons.workspace_premium_outlined,
                  title: '专业信息',
                ),
                const SizedBox(height: 12),
                if (record.intensityLevel != null ||
                    record.fatigueLevel != null)
                  _ProfessionalMetrics(
                    intensityLevel: record.intensityLevel,
                    fatigueLevel: record.fatigueLevel,
                  ),
              ],

              // ── 训练动作列表 ──
              if (isProfessional) ...[
                const SizedBox(height: 28),
                _SectionHeader(icon: Icons.format_list_numbered, title: '训练动作'),
                const SizedBox(height: 12),
                exercisesAsync.when(
                  data: (exercises) {
                    if (exercises.isEmpty) {
                      return _EmptyCard(
                        icon: Icons.sports_gymnastics,
                        text: '无动作记录',
                      );
                    }
                    return Column(
                      children: exercises
                          .map((e) => _ExerciseCard(exercise: e))
                          .toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) =>
                      Text('加载动作失败: $e', style: AppTextStyles.caption),
                ),
              ],

              // ── 训练感受 ──
              if (record.feeling != null && record.feeling!.isNotEmpty) ...[
                const SizedBox(height: 28),
                _SectionHeader(icon: Icons.favorite_outline, title: '训练感受'),
                const SizedBox(height: 12),
                _NoteCard(text: record.feeling!),
              ],

              // ── 备注 ──
              if (record.note != null && record.note!.isNotEmpty) ...[
                const SizedBox(height: 28),
                _SectionHeader(icon: Icons.notes_outlined, title: '备注'),
                const SizedBox(height: 12),
                _NoteCard(text: record.note!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// 渐变 Header
// =============================================================================

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.title,
    required this.bodyPart,
    required this.expGained,
    required this.isProfessional,
    required this.onDelete,
  });

  final String title;
  final String bodyPart;
  final int expGained;
  final bool isProfessional;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.fitness, colors.fitness.withValues(alpha: 0.78)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 顶部栏：返回 + 删除
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colors.textOnAccent,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colors.textOnAccent.withValues(alpha: 0.7),
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),

            // 图标
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.textOnAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                color: colors.textOnAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            // 标题
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textOnAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // 部位
            Text(
              bodyPart,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textOnAccent.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),

            // EXP + 模式标签
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // EXP 徽章
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.textOnAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: colors.warning, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '+$expGained EXP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textOnAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isProfessional) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.textOnAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '专业模式',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textOnAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 信息网格
// =============================================================================

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: items.map((item) => _InfoTile(item: item)).toList(),
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.fitness.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: colors.fitness, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: AppTextStyles.caption, maxLines: 1),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 章节标题
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.fitness),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.fitness,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 专业模式指标
// =============================================================================

class _ProfessionalMetrics extends StatelessWidget {
  const _ProfessionalMetrics({
    required this.intensityLevel,
    required this.fatigueLevel,
  });

  final int? intensityLevel;
  final int? fatigueLevel;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          if (intensityLevel != null)
            Expanded(
              child: _MetricItem(
                label: '训练强度',
                level: intensityLevel!,
                maxLevel: 5,
                color: colors.fitness,
              ),
            ),
          if (intensityLevel != null && fatigueLevel != null)
            Container(
              width: 1,
              height: 48,
              color: colors.textTertiary.withValues(alpha: 0.3),
            ),
          if (fatigueLevel != null)
            Expanded(
              child: _MetricItem(
                label: '疲劳程度',
                level: fatigueLevel!,
                maxLevel: 5,
                color: colors.warning,
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.level,
    required this.maxLevel,
    required this.color,
  });

  final String label;
  final int level;
  final int maxLevel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(maxLevel, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                i < level ? Icons.circle : Icons.circle_outlined,
                size: 10,
                color: i < level ? color : colors.textTertiary,
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          '$level/$maxLevel',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 动作卡片
// =============================================================================

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});

  final FitnessExercise exercise;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 动作名称
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.fitness.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    RecordIconAssets.fitness,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.sports_gymnastics,
                      color: colors.fitness,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 参数网格
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (exercise.weight != null)
                _ExerciseParam(label: '重量', value: '${exercise.weight} kg'),
              _ExerciseParam(label: '组数', value: '${exercise.sets}'),
              _ExerciseParam(label: '次数', value: '${exercise.reps}'),
              if (exercise.restSeconds != null)
                _ExerciseParam(label: '休息', value: '${exercise.restSeconds}s'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseParam extends StatelessWidget {
  const _ExerciseParam({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 备注卡片
// =============================================================================

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: colors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }
}

// =============================================================================
// 空卡片占位
// =============================================================================

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: colors.textTertiary),
          const SizedBox(height: 8),
          Text(text, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
