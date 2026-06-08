import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/design/design.dart';

/// 快捷操作菜单
///
/// 右下角垂直排列5个16px圆角矩形按钮：
/// - 每个按钮：彩色图标 + 白色文字
/// - 底部关闭按钮（紫色圆形+白色叉号）
class QuickActionMenu extends StatefulWidget {
  const QuickActionMenu({super.key});

  /// 显示快捷操作菜单
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭快捷菜单',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const QuickActionMenu();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<QuickActionMenu> createState() => _QuickActionMenuState();
}

class _QuickActionMenuState extends State<QuickActionMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 点击空白区域关闭
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // 快捷操作按钮组
          Positioned(
            right: 20,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: Icons.menu_book_rounded,
                  label: '添加学习',
                  color: AppColors.study,
                  onTap: () => _navigateTo(context, RoutePaths.plan),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.fitness_center_rounded,
                  label: '添加健身',
                  color: AppColors.fitness,
                  onTap: () => _navigateTo(context, RoutePaths.plan),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.restaurant_rounded,
                  label: '记录饮食',
                  color: AppColors.diet,
                  onTap: () => _navigateTo(context, RoutePaths.plan),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.bedtime_rounded,
                  label: '记录睡眠',
                  color: AppColors.sleep,
                  onTap: () => _navigateTo(context, RoutePaths.plan),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.edit_note_rounded,
                  label: '写日记',
                  color: AppColors.primary,
                  onTap: () => _navigateTo(context, RoutePaths.plan),
                ),
                const SizedBox(height: 24),

                // 关闭按钮（紫色圆形+白色叉号）
                _buildCloseButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 关闭按钮（紫色圆形+白色叉号）
  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// 导航到指定页面
  void _navigateTo(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.go(path);
  }
}
