import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

/// 心情 emoji 映射
const _moodEmojiMap = {
  'happy': '😊',
  'neutral': '😐',
  'sad': '😢',
  'angry': '😡',
  'thinking': '🤔',
};

/// 成长日记列表项
///
/// 展示单条日记的标题、心情、标签、日期和字数。
/// 支持点击回调和滑动删除。
class JournalTile extends StatelessWidget {
  /// 日记数据
  final DailyJournal journal;

  /// 点击回调
  final VoidCallback onTap;

  /// 删除回调（为 null 时不显示滑动删除）
  final VoidCallback? onDelete;

  const JournalTile({
    super.key,
    required this.journal,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget tile = ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.tertiaryContainer,
        child: Text(
          _moodEmojiMap[journal.mood] ?? '📝',
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Text(
        journal.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitle(theme),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${journal.wordCount}字',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          _TagPreview(tags: _parseTags(journal.tags)),
        ],
      ),
      onTap: onTap,
    );

    if (onDelete != null) {
      tile = Dismissible(
        key: ValueKey(journal.id),
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

    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(journal.createdAt);
    final dateStr =
        '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
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

  /// 解析 JSON 标签字符串
  List<String> _parseTags(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) return const [];
    try {
      final list = jsonDecode(tagsJson) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }
}

/// 标签预览，最多显示 2 个标签
class _TagPreview extends StatelessWidget {
  final List<String> tags;

  const _TagPreview({required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final displayTags = tags.take(2).toList();
    final hasMore = tags.length > 2;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...displayTags.map(
          (tag) => Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '+${tags.length - 2}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}
