import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

/// 按日期分组记录
///
/// 返回一个 Map，key 为日期标签（今天/昨天/YYYY-MM-DD），
/// value 为该日期下的记录列表。保持插入顺序。
Map<String, List<T>> groupRecordsByDate<T>(
  List<T> records,
  DateTime Function(T) getDate,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final groups = <String, List<T>>{};
  for (final record in records) {
    final date = getDate(record);
    final dateOnly = DateTime(date.year, date.month, date.day);

    String key;
    if (dateOnly == today) {
      key = '今天';
    } else if (dateOnly == yesterday) {
      key = '昨天';
    } else {
      key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    groups.putIfAbsent(key, () => []).add(record);
  }
  return groups;
}

/// 日期分组标题 Widget
class DateGroupHeader extends StatelessWidget {
  const DateGroupHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.growthColors.textSecondary,
        ),
      ),
    );
  }
}
