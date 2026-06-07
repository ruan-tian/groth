import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

/// 健身记录列表项
///
/// 展示单条健身记录的标题、时长、训练部位、模式和创建时间。
/// 支持点击回调和滑动删除。
class FitnessRecordTile extends StatelessWidget {
  /// 健身记录数据
  final FitnessRecord record;

  /// 点击回调
  final VoidCallback onTap;

  /// 删除回调（为 null 时不显示滑动删除）
  final VoidCallback? onDelete;

  const FitnessRecordTile({
    super.key,
    required this.record,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProfessional = record.mode == 'professional';

    Widget tile = ListTile(
      leading: CircleAvatar(
        backgroundColor: isProfessional
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer,
        child: Icon(
          isProfessional ? Icons.fitness_center : Icons.sports_gymnastics,
          color: isProfessional
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSecondaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        record.title ?? record.bodyPart,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitle(theme),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${record.durationMinutes}分钟',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          _ModeChip(isProfessional: isProfessional),
        ],
      ),
      onTap: onTap,
    );

    if (onDelete != null) {
      tile = Dismissible(
        key: ValueKey(record.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: theme.colorScheme.error,
          child: Icon(
            Icons.delete,
            color: theme.colorScheme.onError,
          ),
        ),
        confirmDismiss: (_) async {
          onDelete!();
          return false;
        },
        child: tile,
      );
    }

    return tile;
  }

  Widget? _buildSubtitle(ThemeData theme) {
    final parts = <String>[];

    parts.add(record.bodyPart);

    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    final dateStr =
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
    parts.add(dateStr);

    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final bool isProfessional;

  const _ModeChip({required this.isProfessional});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isProfessional
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isProfessional ? '专业' : '简单',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isProfessional
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
