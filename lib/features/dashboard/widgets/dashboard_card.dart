import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/settings_provider.dart';

/// 首页概览卡片组件
///
/// 支持：
/// - 显示图标、数值、进度条
/// - 长按触发删除回调
/// - 进入/退出动画
class DashboardCard extends StatefulWidget {
  const DashboardCard({
    super.key,
    required this.config,
    required this.currentValue,
    required this.targetValue,
    this.onLongPress,
    this.animationController,
  });

  /// 卡片配置
  final DashboardCardConfig config;

  /// 当前值
  final int currentValue;

  /// 目标值
  final int targetValue;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 入场动画控制器（外部传入用于统一管理）
  final AnimationController? animationController;

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _localAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // 使用外部传入的控制器或创建本地控制器
    _localAnimController = widget.animationController ??
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 400),
        );

    // 缩放动画：从 0.8 到 1.0，带弹性效果
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _localAnimController,
      curve: Curves.easeOutBack,
    ));

    // 淡入动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _localAnimController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // 滑入动画：从下方滑入
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _localAnimController,
      curve: Curves.easeOutCubic,
    ));

    // 如果使用外部控制器则不由这里控制动画；否则直接跳到 1.0 避免回退时反复缩放
    if (widget.animationController == null) {
      _localAnimController.value = 1.0;
    }
  }

  @override
  void dispose() {
    // 只有本地创建的控制器才需要 dispose
    if (widget.animationController == null) {
      _localAnimController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.targetValue > 0
        ? (widget.currentValue / widget.targetValue).clamp(0.0, 1.0)
        : 0.0;

    return AnimatedBuilder(
      animation: _localAnimController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress?.call();
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.border,
                width: 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.config.color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部：图标 + 长按提示
                _buildHeader(),
                const SizedBox(height: 8),

                // 数值
                _buildValue(),
                const SizedBox(height: 8),

                // 进度条
                _buildProgressBar(progress),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // 图标容器
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.config.softColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.config.icon,
            size: 18,
            color: widget.config.color,
          ),
        ),
        const Spacer(),
        // 长按删除提示（小圆点）
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.textHint,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }

  Widget _buildValue() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // 数值（带动画）
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: widget.currentValue),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: widget.config.color,
                height: 1.1,
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        // 单位
        Text(
          widget.config.unit,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: widget.config.color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 进度条
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: widget.config.softColor,
                valueColor: AlwaysStoppedAnimation<Color>(widget.config.color),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        // 目标文字
        Text(
          '目标 ${widget.targetValue}${widget.config.unit}',
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// 添加卡片按钮
class AddDashboardCardButton extends StatefulWidget {
  const AddDashboardCardButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<AddDashboardCardButton> createState() => _AddDashboardCardButtonState();
}

class _AddDashboardCardButtonState extends State<AddDashboardCardButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.border,
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 虚线圆形 + 图标
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textHint,
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '添加',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
