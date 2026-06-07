import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import 'study_record_tile.dart';

/// 学习记录列表
///
/// 展示一组学习记录，每条记录可点击查看详情。
/// 列表为空时显示占位提示。
class StudyRecordList extends StatelessWidget {
  /// 学习记录列表
  final List<StudyRecord> records;

  /// 记录点击回调
  final void Function(StudyRecord record)? onRecordTap;

  /// 记录删除回调
  final void Function(StudyRecord record)? onRecordDelete;

  const StudyRecordList({
    super.key,
    required this.records,
    this.onRecordTap,
    this.onRecordDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return StudyRecordTile(
          record: record,
          onTap: () => onRecordTap?.call(record),
          onDelete: onRecordDelete != null
              ? () => onRecordDelete!.call(record)
              : null,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无学习记录',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始学习后，记录会显示在这里',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
