import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../app/design/design.dart';
import 'common/delete_confirm_dialog.dart';

/// 滑动删除组件
///
/// 使用 flutter_slidable 实现流畅的滑动删除体验。
/// 支持：
/// - 从右向左滑动显示删除按钮
/// - 震动反馈
/// - 柔和的红色背景
/// - 弹性动画
/// - 统一的删除确认弹窗
class SwipeDeleteTile extends StatelessWidget {
  const SwipeDeleteTile({
    super.key,
    required this.child,
    required this.onDismissed,
    this.onConfirmDelete,
    this.enabled = true,
    this.deleteTitle = '确认删除',
    this.deleteMessage = '删除后数据无法恢复',
    this.tiantianMessage = '甜甜会帮你记住这段成长～',
  });

  final Widget child;
  final VoidCallback onDismissed;
  final Future<bool> Function()? onConfirmDelete;
  final bool enabled;

  /// 删除确认弹窗标题
  final String deleteTitle;

  /// 删除确认弹窗描述
  final String deleteMessage;

  /// 甜甜温馨提醒
  final String? tiantianMessage;

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
              bool confirmed;
              if (onConfirmDelete != null) {
                confirmed = await onConfirmDelete!();
              } else {
                confirmed = await DeleteConfirmDialog.show(
                  context: context,
                  title: deleteTitle,
                  message: deleteMessage,
                  tiantianMessage: tiantianMessage,
                );
              }
              if (confirmed) onDismissed();
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
