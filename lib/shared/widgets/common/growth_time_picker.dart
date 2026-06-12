import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/design/design.dart';

/// 时间预设快捷按钮
enum TimePreset {
  now('现在'),
  onTheHour('整点'),
  halfPast('半点'),
  nextHour('下一小时');

  const TimePreset(this.label);
  final String label;
}

/// 显示自定义时间滚轮选择器
///
/// 返回选中的 [TimeOfDay]，取消返回 null。
Future<TimeOfDay?> showGrowthTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  List<TimePreset> presets = const [
    TimePreset.now,
    TimePreset.onTheHour,
    TimePreset.halfPast,
  ],
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GrowthTimePickerSheet(
      initialTime: initialTime,
      presets: presets,
    ),
  );
}

// ── 弹性吸附物理 ──
/// iOS 风格弹性滚动 + 自动吸附到最近 item
class _BouncySnapPhysics extends ScrollPhysics {
  const _BouncySnapPhysics({required this.itemExtent, super.parent});

  final double itemExtent;

  @override
  _BouncySnapPhysics applyTo(ScrollPhysics? ancestor) {
    return _BouncySnapPhysics(
      itemExtent: itemExtent,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // 弹性边界
    if (position.outOfRange) {
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: toleranceFor(position),
      );
    }

    // 吸附到最近 item
    final double maxScroll = position.maxScrollExtent;
    final double current = position.pixels;

    // 计算最近 item 索引
    int targetItem = (current / itemExtent).round();
    targetItem = targetItem.clamp(0, (maxScroll / itemExtent).round());

    final double targetPixels = targetItem * itemExtent;

    // 如果已经在目标位置且速度很小，不需要动画
    if ((current - targetPixels).abs() < 1 && velocity.abs() < 50) {
      return null;
    }

    return BouncingScrollSimulation(
      spring: spring,
      position: current,
      velocity: velocity,
      leadingExtent: math.min(targetPixels, position.minScrollExtent),
      trailingExtent: math.max(targetPixels, position.maxScrollExtent),
      tolerance: toleranceFor(position),
    );
  }

  @override
  Tolerance toleranceFor(ScrollMetrics position) {
    return const Tolerance(velocity: 50, distance: 0.5);
  }
}

class _GrowthTimePickerSheet extends StatefulWidget {
  const _GrowthTimePickerSheet({
    required this.initialTime,
    required this.presets,
  });

  final TimeOfDay initialTime;
  final List<TimePreset> presets;

  @override
  State<_GrowthTimePickerSheet> createState() => _GrowthTimePickerSheetState();
}

class _GrowthTimePickerSheetState extends State<_GrowthTimePickerSheet> {
  late int _hour;
  late int _minute;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _setTime(int hour, int minute) {
    HapticFeedback.lightImpact();
    setState(() {
      _hour = hour;
      _minute = minute;
    });
    _hourController.animateToItem(
      hour,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    _minuteController.animateToItem(
      minute,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _applyPreset(TimePreset preset) {
    final now = TimeOfDay.now();
    switch (preset) {
      case TimePreset.now:
        _setTime(now.hour, now.minute);
      case TimePreset.onTheHour:
        _setTime(now.hour, 0);
      case TimePreset.halfPast:
        _setTime(now.hour, 30);
      case TimePreset.nextHour:
        final next = (now.hour + 1) % 24;
        _setTime(next, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // 把手
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            // 标题
            const Text('选择时间', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 16),
            // 快捷按钮
            if (widget.presets.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: widget.presets
                      .map(
                        (p) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _PresetButton(
                              label: p.label,
                              onTap: () => _applyPreset(p),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            // 滚轮区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    // 分隔线（上）
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 78,
                      child: Container(
                        height: 0.5,
                        color: AppColors.border,
                      ),
                    ),
                    // 分隔线（下）
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 122,
                      child: Container(
                        height: 0.5,
                        color: AppColors.border,
                      ),
                    ),
                    // 选中行背景高亮
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 78,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.fitness.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    // 滚轮
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _WheelColumn(
                            controller: _hourController,
                            itemCount: 24,
                            selectedValue: _hour,
                            onSelected: (v) => setState(() => _hour = v),
                            labelBuilder: (v) => v.toString().padLeft(2, '0'),
                          ),
                        ),
                        // 分隔符
                        SizedBox(
                          width: 32,
                          child: Center(
                            child: Text(
                              ':',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: _WheelColumn(
                            controller: _minuteController,
                            itemCount: 60,
                            selectedValue: _minute,
                            onSelected: (v) => setState(() => _minute = v),
                            labelBuilder: (v) => v.toString().padLeft(2, '0'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 底部按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _BottomButton(
                      label: '取消',
                      filled: false,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BottomButton(
                      label: '确定',
                      filled: true,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(
                          context,
                          TimeOfDay(hour: _hour, minute: _minute),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── 滚轮列 ──

class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.controller,
    required this.itemCount,
    required this.selectedValue,
    required this.onSelected,
    required this.labelBuilder,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedValue;
  final ValueChanged<int> onSelected;
  final String Function(int) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 44,
      diameterRatio: 1.4,
      perspective: 0.003,
      physics: const _BouncySnapPhysics(itemExtent: 44),
      onSelectedItemChanged: (index) {
        HapticFeedback.selectionClick();
        onSelected(index);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isSelected = index == selectedValue;
          return Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 120),
              style: TextStyle(
                fontSize: isSelected ? 26 : 17,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
                letterSpacing: -0.5,
              ),
              child: Text(labelBuilder(index)),
            ),
          );
        },
      ),
    );
  }
}

// ── 快捷按钮 ──

class _PresetButton extends StatelessWidget {
  const _PresetButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.softOrange,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fitness.withValues(alpha: 0.15)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.fitness,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 底部按钮 ──

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? AppColors.fitness : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
