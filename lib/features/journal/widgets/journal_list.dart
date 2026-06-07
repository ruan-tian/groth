import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import 'journal_tile.dart';

/// 日记列表
///
/// 展示一组成长日记，每条记录可点击查看详情。
/// 列表为空时显示占位提示。
class JournalList extends StatelessWidget {
  /// 日记列表
  final List<DailyJournal> journals;

  /// 记录点击回调
  final void Function(DailyJournal journal)? onJournalTap;

  /// 记录删除回调
  final void Function(DailyJournal journal)? onJournalDelete;

  const JournalList({
    super.key,
    required this.journals,
    this.onJournalTap,
    this.onJournalDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (journals.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      itemCount: journals.length,
      itemBuilder: (context, index) {
        final journal = journals[index];
        return JournalTile(
          journal: journal,
          onTap: () => onJournalTap?.call(journal),
          onDelete: onJournalDelete != null
              ? () => onJournalDelete!.call(journal)
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
            Icons.edit_note_outlined,
            size: 64,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无成长日记',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '写下今天的复盘，记录会显示在这里',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
