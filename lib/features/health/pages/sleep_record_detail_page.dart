import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../models/health_data.dart';
import '../providers/sleep_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/delete_confirm_dialog.dart';

/// 睡眠记录详情页
///
/// 紫色渐变 Header + 信息网格 + 梦境 + 备注
class SleepRecordDetailPage extends ConsumerWidget {
  const SleepRecordDetailPage({super.key, required this.recordId});

  final int recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final recordAsync = ref.watch(sleepRecordByIdProvider(recordId));

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
    SleepRecord record,
  ) async {
    final confirmed = await DeleteConfirmDialog.show(
      context: context,
      title: '删除睡眠记录',
      message: '确定要删除这条睡眠记录吗？\n'
          '日期：$record.sleepDate\n'
          '时长：${_formatDuration(record.durationMinutes)}\n\n'
          '此操作不可撤销。',
      tiantianMessage: '删除后无法恢复哦，请确认一下~',
    );

    if (confirmed && context.mounted) {
      try {
        final repo = ref.read(sleepRepositoryProvider);
        await repo.deleteSleepRecord(record.id);
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

  static String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}小时${m}分钟' : '${h}小时';
  }
}

// =============================================================================
// 详情主体
// =============================================================================

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.record, required this.onDelete});

  final SleepRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final createdDt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);

    return CustomScrollView(
      slivers: [
        // ── 紫色渐变 Header ──
        SliverToBoxAdapter(
          child: _GradientHeader(
            qualityLevel: record.qualityLevel,
            durationMinutes: record.durationMinutes,
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
                    icon: Icons.bedtime_rounded,
                    label: '入睡时间',
                    value: record.sleepTime,
                  ),
                  _InfoItem(
                    icon: Icons.wb_sunny_outlined,
                    label: '起床时间',
                    value: record.wakeTime,
                  ),
                  _InfoItem(
                    icon: Icons.access_time_rounded,
                    label: '睡眠时长',
                    value: SleepRecordDetailPage._formatDuration(
                      record.durationMinutes,
                    ),
                  ),
                  _InfoItem(
                    icon: Icons.speed_rounded,
                    label: '入睡耗时',
                    value: '${record.fallAsleepMinutes} 分钟',
                  ),
                ],
              ),

              // ── 睡眠质量 ──
              const SizedBox(height: 28),
              _SectionHeader(
                icon: Icons.health_and_safety_outlined,
                title: '睡眠质量',
              ),
              const SizedBox(height: 12),
              _QualityCard(
                qualityLevel: record.qualityLevel,
                energyLevel: record.energyLevel,
                wakeCount: record.wakeCount,
              ),

              // ── 梦境 ──
              if (record.dreamNote != null && record.dreamNote!.isNotEmpty) ...[
                const SizedBox(height: 28),
                _SectionHeader(icon: Icons.cloud_outlined, title: '梦境记录'),
                const SizedBox(height: 12),
                _NoteCard(text: record.dreamNote!),
              ],

              // ── 日期信息 ──
              const SizedBox(height: 28),
              _SectionHeader(
                icon: Icons.calendar_today_outlined,
                title: '记录信息',
              ),
              const SizedBox(height: 12),
              _InfoGrid(
                items: [
                  _InfoItem(
                    icon: Icons.calendar_today_outlined,
                    label: '睡眠日期',
                    value: record.sleepDate,
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

  static String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// 渐变 Header
// =============================================================================

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.qualityLevel,
    required this.durationMinutes,
    required this.onDelete,
  });

  final int qualityLevel;
  final int durationMinutes;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.sleep, colors.sleep.withValues(alpha: 0.78)],
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
                Icons.bedtime_rounded,
                color: colors.textOnAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            // 标题
            Text(
              SleepRecordDetailPage._formatDuration(durationMinutes),
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
                    '睡眠质量 $qualityLevel/5',
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
              color: colors.sleep.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: colors.sleep, size: 18),
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
        Icon(icon, size: 18, color: colors.sleep),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.sleep,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 睡眠质量卡片
// =============================================================================

class _QualityCard extends StatelessWidget {
  const _QualityCard({
    required this.qualityLevel,
    required this.energyLevel,
    required this.wakeCount,
  });

  final int qualityLevel;
  final int energyLevel;
  final int wakeCount;

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
      child: Column(
        children: [
          // 睡眠质量
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '睡眠质量',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              ...List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < qualityLevel
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 20,
                    color: i < qualityLevel
                        ? colors.warning
                        : colors.textTertiary,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          // 醒后精力 + 夜醒次数
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: '醒后精力',
                  level: energyLevel,
                  maxLevel: 5,
                  color: colors.sleep,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: colors.textTertiary.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _MetricItem(
                  label: '夜醒次数',
                  value: '$wakeCount 次',
                  color: colors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    this.level,
    this.maxLevel,
    this.value,
    required this.color,
  });

  final String label;
  final int? level;
  final int? maxLevel;
  final String? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 6),
        if (level != null && maxLevel != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxLevel!, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  i < level! ? Icons.circle : Icons.circle_outlined,
                  size: 10,
                  color: i < level! ? color : colors.textTertiary,
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
        ] else if (value != null) ...[
          Text(
            value!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
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
