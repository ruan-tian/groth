import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/design/design.dart';

/// 日期预设快捷按钮
enum DatePreset {
  today('今天'),
  yesterday('昨天'),
  dayBefore('前天'),
  thisMonday('本周一'),
  firstOfMonth('本月1号');

  const DatePreset(this.label);
  final String label;
}

/// 显示自定义日期选择器（日历网格）
///
/// 返回选中的 [DateTime]，取消返回 null。
Future<DateTime?> showGrowthDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  List<DatePreset> presets = const [
    DatePreset.today,
    DatePreset.yesterday,
    DatePreset.thisMonday,
  ],
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GrowthDatePickerSheet(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now(),
      presets: presets,
    ),
  );
}

class _GrowthDatePickerSheet extends StatefulWidget {
  const _GrowthDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.presets,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<DatePreset> presets;

  @override
  State<_GrowthDatePickerSheet> createState() => _GrowthDatePickerSheetState();
}

class _GrowthDatePickerSheetState extends State<_GrowthDatePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _displayMonth;
  late PageController _monthPageController;

  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  // 从 firstDate 所在月到 lastDate 所在月的总月数
  late final int _totalMonths;
  // firstDate 所在月作为基准
  late final DateTime _baseMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _baseMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    _totalMonths = (lastMonth.year - _baseMonth.year) * 12 +
        (lastMonth.month - _baseMonth.month) +
        1;
    _displayMonth = DateTime(_selectedDate.year, _selectedDate.month);
    final initialPage =
        (_displayMonth.year - _baseMonth.year) * 12 +
        (_displayMonth.month - _baseMonth.month);
    _monthPageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  void _goToMonth(DateTime month) {
    final page = (month.year - _baseMonth.year) * 12 +
        (month.month - _baseMonth.month);
    _monthPageController.animateToPage(
      page.clamp(0, _totalMonths - 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _applyPreset(DatePreset preset) {
    final now = DateTime.now();
    DateTime date;
    switch (preset) {
      case DatePreset.today:
        date = now;
      case DatePreset.yesterday:
        date = now.subtract(const Duration(days: 1));
      case DatePreset.dayBefore:
        date = now.subtract(const Duration(days: 2));
      case DatePreset.thisMonday:
        date = now.subtract(Duration(days: now.weekday - 1));
      case DatePreset.firstOfMonth:
        date = DateTime(now.year, now.month, 1);
    }
    if (!_isInRange(date)) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDate = date;
      _displayMonth = DateTime(date.year, date.month);
    });
    _goToMonth(_displayMonth);
  }

  bool _isInRange(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final f = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );
    final l = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );
    return !d.isBefore(f) && !d.isAfter(l);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  String get _weekdayName {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[_selectedDate.weekday - 1];
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
            // 标题 + 选中日期
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_selectedDate.month}月${_selectedDate.day}日',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fitness.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _weekdayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fitness,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 快捷按钮
            if (widget.presets.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.presets
                      .map(
                        (p) => _PresetButton(
                          label: p.label,
                          onTap: () => _applyPreset(p),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // 月份导航
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _NavArrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: () {
                      final prev = DateTime(
                        _displayMonth.year,
                        _displayMonth.month - 1,
                      );
                      if (!prev.isBefore(_baseMonth)) {
                        setState(() => _displayMonth = prev);
                        _goToMonth(prev);
                      }
                    },
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        '${_displayMonth.year}年${_displayMonth.month}月',
                        key: ValueKey(
                          '${_displayMonth.year}-${_displayMonth.month}',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  _NavArrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: () {
                      final next = DateTime(
                        _displayMonth.year,
                        _displayMonth.month + 1,
                      );
                      final lastMonth = DateTime(
                        widget.lastDate.year,
                        widget.lastDate.month,
                      );
                      if (!next.isAfter(lastMonth)) {
                        setState(() => _displayMonth = next);
                        _goToMonth(next);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 星期标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: _weekdays
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            // 日历网格（PageView 支持左右滑动切换月份）
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: _monthPageController,
                itemCount: _totalMonths,
                onPageChanged: (page) {
                  final month = DateTime(
                    _baseMonth.year,
                    _baseMonth.month + page,
                  );
                  setState(() => _displayMonth = month);
                },
                itemBuilder: (context, page) {
                  final month = DateTime(
                    _baseMonth.year,
                    _baseMonth.month + page,
                  );
                  return _CalendarGrid(
                    month: month,
                    selectedDate: _selectedDate,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    isToday: _isToday,
                    isSelected: _isSelected,
                    isInRange: _isInRange,
                    onDateSelected: (date) {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedDate = date);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
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
                        Navigator.pop(context, _selectedDate);
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

// ── 日历网格 ──

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.isToday,
    required this.isSelected,
    required this.isInRange,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool Function(DateTime) isToday;
  final bool Function(DateTime) isSelected;
  final bool Function(DateTime) isInRange;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    // 周一为 0
    final startWeekday = (firstDay.weekday - 1) % 7;
    final totalDays = lastDay.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: startWeekday + totalDays,
        itemBuilder: (context, index) {
          if (index < startWeekday) {
            return const SizedBox.shrink();
          }
          final day = index - startWeekday + 1;
          final date = DateTime(month.year, month.month, day);
          final inRange = isInRange(date);
          final today = isToday(date);
          final selected = isSelected(date);

          return GestureDetector(
            onTap: inRange ? () => onDateSelected(date) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.fitness
                    : today
                        ? AppColors.fitness.withValues(alpha: 0.08)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected || today
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: !inRange
                        ? AppColors.textHint
                        : selected
                            ? Colors.white
                            : today
                                ? AppColors.fitness
                                : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 月份导航箭头 ──

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.softOrange,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.fitness),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.softOrange,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fitness.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.fitness,
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
