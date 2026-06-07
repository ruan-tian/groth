import 'package:flutter/material.dart';
import '../../../app/design/design.dart';

/// Growth OS 评分选择器
///
/// 星星图标行，支持自定义最大值和颜色。
/// 用于日记心情评分、训练强度评分等。
class RatingSelector extends StatelessWidget {
  const RatingSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 5,
    this.iconSize = 28.0,
    this.activeColor = AppColors.ratingActive,
    this.inactiveColor = AppColors.ratingInactive,
    this.icon = Icons.star_rounded,
  });

  /// 当前选中值 (1-based)
  final int value;

  /// 选中回调
  final ValueChanged<int> onChanged;

  /// 最大评分值
  final int max;

  /// 图标大小
  final double iconSize;

  /// 选中颜色
  final Color activeColor;

  /// 未选中颜色
  final Color inactiveColor;

  /// 图标
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (index) {
        final rating = index + 1;
        final isActive = rating <= value;

        return GestureDetector(
          onTap: () => onChanged(rating),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedScale(
              scale: isActive ? 1.0 : 0.85,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              child: Icon(
                icon,
                size: iconSize,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ),
        );
      }),
    );
  }
}
