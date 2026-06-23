import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/settings_provider.dart';

/// 添加首页卡片弹窗
class AddCardSheet extends StatefulWidget {
  const AddCardSheet({
    super.key,
    required this.currentCardIds,
    required this.onCardAdded,
  });

  /// 当前已添加的卡片 ID 列表
  final List<String> currentCardIds;

  /// 卡片添加回调
  final Future<void> Function(String cardId) onCardAdded;

  @override
  State<AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<AddCardSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 获取可添加的卡片列表
  List<DashboardCardConfig> get _availableCards {
    return availableDashboardCards
        .where((c) => !widget.currentCardIds.contains(c.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final available = _availableCards;

    return Container(
      decoration: BoxDecoration(
        color: context.growthColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖拽条
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: context.growthColors.textHint.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 20),

          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.growthColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add_circle_outline_rounded,
                    size: 20,
                    color: context.growthColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '添加首页卡片',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.growthColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '选择要在首页显示的数据卡片',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.growthColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 关闭按钮
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.growthColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: context.growthColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 卡片列表
          if (available.isEmpty)
            _buildEmptyState()
          else
            _buildCardGrid(available),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: context.growthColors.success.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            '所有卡片都已添加',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.growthColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '长按首页卡片可以移除',
            style: TextStyle(
              fontSize: 13,
              color: context.growthColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid(List<DashboardCardConfig> cards) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return _AddableCardItem(
            config: card,
            animationDelay: index * 60,
            onTap: () async {
              HapticFeedback.lightImpact();
              await widget.onCardAdded(card.id);
              if (context.mounted) Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}

/// 可添加的卡片项
class _AddableCardItem extends StatefulWidget {
  const _AddableCardItem({
    required this.config,
    required this.animationDelay,
    required this.onTap,
  });

  final DashboardCardConfig config;
  final int animationDelay;
  final Future<void> Function() onTap;

  @override
  State<_AddableCardItem> createState() => _AddableCardItemState();
}

class _AddableCardItemState extends State<_AddableCardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // 延迟启动动画，实现交错效果
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
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
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(scale: _scaleAnimation, child: child),
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
          scale: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: widget.config.softColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: widget.config.color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 图标
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.config.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.config.icon,
                    size: 22,
                    color: widget.config.color,
                  ),
                ),
                const SizedBox(height: 8),
                // 名称
                Text(
                  widget.config.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.config.color,
                  ),
                ),
                const SizedBox(height: 2),
                // 默认目标
                Text(
                  widget.config.defaultTarget > 0
                      ? '${widget.config.defaultTarget}${widget.config.unit}'
                      : widget.config.unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.config.color.withValues(alpha: 0.6),
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
