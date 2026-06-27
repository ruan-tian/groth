import 'package:flutter/material.dart';

import '../../app/design/design.dart';

/// 排序方式枚举（向后兼容）
enum SortOption {
  /// 按时间最新排序
  newest,

  /// 按时间最早排序
  oldest,

  /// 按经验值最高排序
  highestExp,
}

/// 排序选项数据
class SortButtonItem<T> {
  const SortButtonItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final T value;
  final String label;
  final IconData icon;
}

/// 泛型排序按钮组件
///
/// 显示当前排序方式，点击弹出排序选项菜单。
/// 支持自定义排序选项、标签和图标。
class SortButton<T> extends StatelessWidget {
  /// 泛型构造函数
  const SortButton({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    required this.items,
    this.accentColor,
  });

  /// 向后兼容构造函数（使用 SortOption 枚举）
  SortButton.legacy({
    super.key,
    required SortOption currentSort,
    required ValueChanged<SortOption> onSortChanged,
    Color? accentColor,
  }) : currentSort = currentSort as T,
       onSortChanged = onSortChanged as ValueChanged<T>,
       accentColor = accentColor,
       items = [
         SortButtonItem(
           value: SortOption.newest as T,
           label: '时间最新',
           icon: Icons.access_time_rounded,
         ),
         SortButtonItem(
           value: SortOption.oldest as T,
           label: '时间最早',
           icon: Icons.history_rounded,
         ),
         SortButtonItem(
           value: SortOption.highestExp as T,
           label: '经验值最高',
           icon: Icons.star_rounded,
         ),
       ];

  /// 当前排序方式
  final T currentSort;

  /// 排序方式改变回调
  final ValueChanged<T> onSortChanged;

  /// 排序选项列表
  final List<SortButtonItem<T>> items;

  /// 主题色（可选，默认使用 textSecondary）
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final effectiveColor = accentColor ?? colors.textSecondary;

    return PopupMenuButton<T>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(Icons.sort_rounded, color: effectiveColor, size: 20),
      ),
      tooltip: '排序方式',
      onSelected: onSortChanged,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      elevation: 4,
      itemBuilder: (context) => items
          .map((item) => _buildItem(context, item, colors))
          .toList(),
    );
  }

  PopupMenuItem<T> _buildItem(
    BuildContext context,
    SortButtonItem<T> item,
    AppThemeColors colors,
  ) {
    final isSelected = currentSort == item.value;
    return PopupMenuItem(
      value: item.value,
      child: Row(
        children: [
          Icon(
            item.icon,
            size: 18,
            color: isSelected
                ? (accentColor ?? colors.study)
                : colors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? (accentColor ?? colors.study)
                    : colors.textPrimary,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_rounded,
              size: 18,
              color: accentColor ?? colors.study,
            ),
        ],
      ),
    );
  }
}
