import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../models/health_data.dart';
import '../providers/diet_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/delete_confirm_dialog.dart';

/// 饮食记录详情页
///
/// 橙色渐变 Header + 信息网格 + 食物详情 + 备注
class DietRecordDetailPage extends ConsumerWidget {
  const DietRecordDetailPage({super.key, required this.recordId});

  final int recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final recordAsync = ref.watch(dietRecordByIdProvider(recordId));

    return Scaffold(
      backgroundColor: colors.background,
      body: recordAsync.when(
        data: (record) {
          if (record == null) {
            return _buildError(context, '记录不存在');
          }
          return _DetailBody(
            record: record,
            onDelete: () => _confirmDelete(context, ref, record),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, '加载失败: $e'),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final colors = context.growthColors;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: AppTextStyles.body),
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
    DietRecord record,
  ) async {
    final confirmed = await DeleteConfirmDialog.show(
      context: context,
      title: '删除饮食记录',
      message: '确定要删除这条饮食记录吗？\n'
          '餐次：${_mealTypeLabel(record.mealType)}\n'
          '食物：${record.foodText}\n\n'
          '此操作不可撤销。',
      tiantianMessage: '删除后无法恢复哦，请确认一下~',
    );

    if (confirmed && context.mounted) {
      try {
        final repo = ref.read(dietRepositoryProvider);
        await repo.deleteDietRecord(record.id);
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
          ).showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
        }
      }
    }
  }

  static String _mealTypeLabel(String type) {
    switch (type) {
      case 'breakfast':
        return '早餐';
      case 'lunch':
        return '午餐';
      case 'dinner':
        return '晚餐';
      case 'snack':
        return '加餐';
      default:
        return type;
    }
  }
}

// =============================================================================
// 详情主体
// =============================================================================

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.record, required this.onDelete});

  final DietRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final createdDt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);

    return CustomScrollView(
      slivers: [
        // ── 橙色渐变 Header ──
        SliverToBoxAdapter(
          child: _GradientHeader(
            mealType: record.mealType,
            healthScore: record.healthScore,
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
                    icon: Icons.restaurant_rounded,
                    label: '餐次',
                    value: DietRecordDetailPage._mealTypeLabel(record.mealType),
                  ),
                  _InfoItem(
                    icon: Icons.straighten_rounded,
                    label: '份量',
                    value: _portionLabel(record.portionLevel),
                  ),
                  _InfoItem(
                    icon: Icons.local_fire_department_rounded,
                    label: '热量',
                    value: _calorieLabel(record.calorieLevel),
                  ),
                  _InfoItem(
                    icon: Icons.egg_outlined,
                    label: '蛋白质',
                    value: _proteinLabel(record.proteinLevel),
                  ),
                ],
              ),

              // ── 健康评分 ──
              const SizedBox(height: 28),
              _SectionHeader(icon: Icons.health_and_safety_outlined, title: '健康评分'),
              const SizedBox(height: 12),
              _HealthScoreCard(score: record.healthScore),

              // ── 食物详情 ──
              if (record.foodText.isNotEmpty) ...[
                const SizedBox(height: 28),
                _SectionHeader(icon: Icons.fastfood_outlined, title: '食物详情'),
                const SizedBox(height: 12),
                _NoteCard(text: record.foodText),
              ],

              // ── 日期信息 ──
              const SizedBox(height: 28),
              _SectionHeader(icon: Icons.calendar_today_outlined, title: '记录信息'),
              const SizedBox(height: 12),
              _InfoGrid(
                items: [
                  _InfoItem(
                    icon: Icons.calendar_today_outlined,
                    label: '日期',
                    value: record.mealDate,
                  ),
                  _InfoItem(
                    icon: Icons.access_time_rounded,
                    label: '记录时间',
                    value: _formatDateTime(createdDt),
                  ),
                ],
              ),

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

  static String _portionLabel(String level) {
    switch (level) {
      case 'small':
        return '少量';
      case 'normal':
        return '正常';
      case 'large':
        return '大量';
      default:
        return level;
    }
  }

  static String _calorieLabel(String level) {
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

  static String _proteinLabel(String level) {
    switch (level) {
      case 'low':
        return '低蛋白';
      case 'medium':
        return '中等';
      case 'high':
        return '高蛋白';
      default:
        return level;
    }
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// 渐变 Header
// =============================================================================

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.mealType,
    required this.healthScore,
    required this.onDelete,
  });

  final String mealType;
  final int healthScore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.diet, colors.diet.withValues(alpha: 0.78)],
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
                Icons.restaurant_rounded,
                color: colors.textOnAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            // 标题
            Text(
              DietRecordDetailPage._mealTypeLabel(mealType),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textOnAccent,
              ),
            ),
            const SizedBox(height: 12),

            // 评分徽章
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                    '健康评分 $healthScore/5',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textOnAccent,
                    ),
                  ),
                ],
              ),
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
              color: colors.diet.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: colors.diet, size: 18),
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
        Icon(icon, size: 18, color: colors.diet),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.diet,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 健康评分卡片
// =============================================================================

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({required this.score});

  final int score;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i < score ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 28,
              color: i < score ? colors.warning : colors.textTertiary,
            ),
          );
        }),
      ),
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
