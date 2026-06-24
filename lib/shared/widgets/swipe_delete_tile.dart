import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../app/design/design.dart';

/// 滑动删除组件
///
/// 使用 flutter_slidable 实现流畅的滑动删除体验。
/// 支持：
/// - 从右向左滑动显示删除按钮
/// - 震动反馈
/// - 柔和的红色背景
/// - 弹性动画
class SwipeDeleteTile extends StatelessWidget {
  const SwipeDeleteTile({
    super.key,
    required this.child,
    required this.onDismissed,
    this.onConfirmDelete,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onDismissed;
  final Future<bool> Function()? onConfirmDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final colors = context.growthColors;

    return Slidable(
      key: key ?? UniqueKey(),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) async {
              HapticFeedback.lightImpact();
              if (onConfirmDelete != null) {
                final confirmed = await onConfirmDelete!();
                if (confirmed) onDismissed();
              } else {
                onDismissed();
              }
            },
            backgroundColor: colors.danger.withValues(alpha: 0.15),
            foregroundColor: colors.danger,
            icon: Icons.delete_outline_rounded,
            label: '删除',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: child,
    );
  }
}
