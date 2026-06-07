import 'package:flutter/material.dart';
import '../../../app/design/design.dart';

/// Growth OS 分段选择器
///
/// 药丸形状背景，选中项白色背景 + 阴影。
/// 用于切换简单/专业模式、日/周/月统计等。
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 40.0,
    this.backgroundColor = const Color(0xFFF0F1F6),
    this.selectedColor = Colors.white,
    this.borderRadius = 12.0,
  });

  /// tab 标签列表
  final List<String> tabs;

  /// 当前选中索引
  final int selectedIndex;

  /// 选中回调
  final ValueChanged<int> onChanged;

  /// 组件高度
  final double height;

  /// 背景色
  final Color backgroundColor;

  /// 选中项颜色
  final Color selectedColor;

  /// 圆角半径
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(borderRadius - 3),
                  boxShadow: isSelected
                      ? [
                          const BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
