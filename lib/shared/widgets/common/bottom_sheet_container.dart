import 'package:flutter/material.dart';
import '../../../app/design/design.dart';

/// Growth OS 底部弹窗容器
///
/// 顶部拖拽条 + 可选标题/关闭按钮 + 圆角顶部。
/// 用于筛选面板、详情弹窗等场景。
class BottomSheetContainer extends StatelessWidget {
  const BottomSheetContainer({
    super.key,
    required this.child,
    this.title,
    this.showCloseButton = false,
    this.onClose,
    this.topRadius = 28.0,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
  });

  /// 弹窗内容
  final Widget child;

  /// 可选标题
  final String? title;

  /// 是否显示关闭按钮
  final bool showCloseButton;

  /// 关闭回调
  final VoidCallback? onClose;

  /// 顶部圆角半径
  final double topRadius;

  /// 内容区域内边距
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.growthColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 顶部拖拽条 ──
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: context.growthColors.textHint.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // ── 标题栏 (可选) ──
          if (title != null || showCloseButton)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  // 标题
                  Expanded(
                    child: title != null
                        ? Text(
                            title!,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: context.growthColors.textPrimary,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // 关闭按钮
                  if (showCloseButton)
                    GestureDetector(
                      onTap: onClose ?? () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.growthColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: context.growthColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ── 内容区域 ──
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
