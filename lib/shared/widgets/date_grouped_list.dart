import 'package:flutter/material.dart';

/// 按日期分组的列表组件
///
/// 将项目按日期分组显示，支持自定义日期提取和项目构建。
class DateGroupedList<T> extends StatelessWidget {
  const DateGroupedList({
    super.key,
    required this.items,
    required this.dateExtractor,
    required this.itemBuilder,
    this.groupPadding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  /// 要显示的项目列表
  final List<T> items;

  /// 从项目中提取日期的函数
  final DateTime Function(T) dateExtractor;

  /// 构建每个项目的函数
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// 日期组的内边距
  final EdgeInsets groupPadding;

  /// 每个项目的内边距
  final EdgeInsets itemPadding;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    // 按日期分组
    final grouped = <DateTime, List<T>>{};
    for (final item in items) {
      final date = dateExtractor(item);
      final dateOnly = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(dateOnly, () => []).add(item);
    }

    // 按日期排序（最新在前）
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final groupItems = grouped[date]!;
        return _buildGroup(context, date, groupItems);
      },
    );
  }

  Widget _buildGroup(BuildContext context, DateTime date, List<T> groupItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Padding(
          padding: groupPadding,
          child: Row(
            children: [
              Text(
                _formatDate(date),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '${groupItems.length} 条记录',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        // 该组的所有项目
        ...groupItems.map((item) => Padding(
              padding: itemPadding,
              child: itemBuilder(context, item),
            )),
        // 组间分隔线
        if (date != _today && date != _yesterday)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return '今天';
    } else if (date == yesterday) {
      return '昨天';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _yesterday {
    return _today.subtract(const Duration(days: 1));
  }
}
