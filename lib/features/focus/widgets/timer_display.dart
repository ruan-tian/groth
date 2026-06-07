import 'package:flutter/material.dart';

/// 番茄钟计时器显示
///
/// 以圆环进度条 + 时间文本的方式展示剩余时间。
/// 进度条带动画，颜色随剩余时间比例变化：
/// - \>50% 绿色 → 25~50% 橙色 → <25% 红色
class TimerDisplay extends StatelessWidget {
  /// 剩余时间
  final Duration remaining;

  /// 总时长
  final Duration total;

  const TimerDisplay({
    super.key,
    required this.remaining,
    required this.total,
  });

  /// 将 Duration 格式化为 MM:SS
  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 根据进度比例返回对应颜色
  Color _progressColor(double progress, ColorScheme colorScheme) {
    if (progress > 0.5) return colorScheme.primary;
    if (progress > 0.25) return Colors.orange;
    return colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSeconds = total.inSeconds;
    final progress =
        totalSeconds > 0 ? (remaining.inSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;
    final color = _progressColor(progress, theme.colorScheme);

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景圆环
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 12,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          // 进度圆环（带动画）
          TweenAnimationBuilder<double>(
            tween: Tween(begin: progress, end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            builder: (context, value, _) {
              return SizedBox(
                width: 240,
                height: 240,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 12,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              );
            },
          ),
          // 时间文本
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(remaining),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
