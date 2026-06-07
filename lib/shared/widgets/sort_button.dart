import 'package:flutter/material.dart';

/// 排序方式枚举
enum SortOption {
  /// 按时间最新排序
  newest,
  /// 按时间最早排序
  oldest,
  /// 按经验值最高排序
  highestExp,
}

/// 通用排序按钮组件
///
/// 显示当前排序方式，点击弹出排序选项菜单。
class SortButton extends StatelessWidget {
  const SortButton({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  /// 当前排序方式
  final SortOption currentSort;

  /// 排序方式改变回调
  final ValueChanged<SortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      icon: const Icon(Icons.sort),
      tooltip: '排序方式',
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        _buildItem(
          SortOption.newest,
          Icons.access_time,
          '时间最新',
        ),
        _buildItem(
          SortOption.oldest,
          Icons.history,
          '时间最早',
        ),
        _buildItem(
          SortOption.highestExp,
          Icons.star,
          '经验值最高',
        ),
      ],
    );
  }

  PopupMenuItem<SortOption> _buildItem(
    SortOption option,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
          if (currentSort == option) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16),
          ],
        ],
      ),
    );
  }
}
