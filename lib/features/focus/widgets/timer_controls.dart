import 'package:flutter/material.dart';

/// 番茄钟计时器控制按钮组
///
/// 根据计时器状态（未开始 / 运行中 / 暂停）展示不同的操作按钮：
/// - 未开始：开始按钮
/// - 运行中：暂停 + 取消按钮
/// - 已暂停：继续 + 取消按钮
///
/// 所有按钮为圆形图标按钮，主操作按钮尺寸更大。
class TimerControls extends StatelessWidget {
  /// 计时器是否正在运行
  final bool isRunning;

  /// 计时器是否已暂停
  final bool isPaused;

  /// 开始计时回调
  final VoidCallback onStart;

  /// 暂停计时回调
  final VoidCallback onPause;

  /// 继续计时回调
  final VoidCallback onResume;

  /// 取消计时回调
  final VoidCallback onCancel;

  const TimerControls({
    super.key,
    required this.isRunning,
    required this.isPaused,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 未开始状态：只显示开始按钮
    if (!isRunning && !isPaused) {
      return _buildStartButton(theme);
    }

    // 运行中或暂停状态：显示主操作按钮 + 取消按钮
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 取消按钮
        _CircleIconButton(
          icon: Icons.stop_rounded,
          size: 56,
          iconSize: 28,
          backgroundColor: theme.colorScheme.errorContainer,
          foregroundColor: theme.colorScheme.onErrorContainer,
          onTap: onCancel,
        ),
        const SizedBox(width: 32),
        // 暂停 / 继续按钮
        _CircleIconButton(
          icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          size: 72,
          iconSize: 36,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          onTap: isPaused ? onResume : onPause,
        ),
      ],
    );
  }

  /// 构建开始按钮（大号圆形）
  Widget _buildStartButton(ThemeData theme) {
    return Center(
      child: _CircleIconButton(
        icon: Icons.play_arrow_rounded,
        size: 80,
        iconSize: 40,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        onTap: onStart,
      ),
    );
  }
}

/// 圆形图标按钮（内部复用组件）
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: foregroundColor,
        ),
      ),
    );
  }
}
