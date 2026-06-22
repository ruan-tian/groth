import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

/// Growth OS 热力图日历组件
///
/// 参考 GitHub Contribution Graph 设计，支持：
/// - 月份标签跟随网格同步滚动（修复月份错位问题）
/// - 自定义颜色范围
/// - 今日高亮
/// - 触摸回调
class HeatmapCalendar extends StatelessWidget {
  const HeatmapCalendar({
    super.key,
    required this.data,
    this.monthsToShow = 3,
    this.cellSize = 16,
    this.cellSpacing = 3,
    this.baseColor,
    this.maxColor,
    this.showLegend = true,
    this.onDayTap,
    this.startDate,
    this.endDate,
  });

  final Map<DateTime, int> data;
  final int monthsToShow;
  final double cellSize;
  final double cellSpacing;
  final Color? baseColor;
  final Color? maxColor;
  final bool showLegend;
  final ValueChanged<DateTime>? onDayTap;
  final DateTime? startDate;
  final DateTime? endDate;

  static const _defaultMax = Color(0xFF216E39);
  static const _levels = [
    Color(0xFFEBEDF0),
    Color(0xFF9BE9A8),
    Color(0xFF40C463),
    Color(0xFF30A14E),
    Color(0xFF216E39),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final colors = context.growthColors;
    final rangeStart =
        startDate ?? DateTime(now.year, now.month - monthsToShow + 1);
    final rangeEnd = endDate ?? DateTime(now.year, now.month + 1, 0);
    final weeks = _buildWeeks(rangeStart, rangeEnd);

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 可滚动区域（月份标签 + 网格）──
          // 月份标签和网格放在同一个 SingleChildScrollView 内，确保同步滚动
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 月份标签（跟随滚动）
                _MonthLabels(
                  weeks: weeks,
                  cellSize: cellSize,
                  cellSpacing: cellSpacing,
                ),
                const SizedBox(height: 4),
                // 网格
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WeekdayLabels(
                      cellSize: cellSize,
                      cellSpacing: cellSpacing,
                    ),
                    const SizedBox(width: 4),
                    ...weeks.map((week) => _buildWeekColumn(context, week)),
                  ],
                ),
              ],
            ),
          ),
          // ── 图例 ──
          if (showLegend) ...[
            const SizedBox(height: AppSpacing.md),
            _HeatmapLegend(
              baseColor: baseColor ?? colors.surfaceVariant,
              maxColor: maxColor ?? _defaultMax,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekColumn(BuildContext context, List<DateTime?> week) {
    final colors = context.growthColors;

    return Column(
      children: List.generate(7, (dayIndex) {
        final date = week[dayIndex];
        if (date == null) {
          return SizedBox(
            width: cellSize + cellSpacing,
            height: cellSize + cellSpacing,
          );
        }

        final normalized = _normalizeDate(date);
        final intensity = (data[normalized] ?? 0).clamp(0, 4);
        final isToday = _isSameDay(date, DateTime.now());

        return GestureDetector(
          onTap: onDayTap == null ? null : () => onDayTap!(date),
          child: Tooltip(
            message: _tooltipText(date, intensity),
            child: Container(
              width: cellSize,
              height: cellSize,
              margin: EdgeInsets.all(cellSpacing / 2),
              decoration: BoxDecoration(
                color: _colorForIntensity(context, intensity),
                borderRadius: BorderRadius.circular(AppRadius.xxs),
                border: isToday
                    ? Border.all(color: colors.primary, width: 2)
                    : null,
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _colorForIntensity(BuildContext context, int intensity) {
    if (intensity <= 0) return baseColor ?? context.growthColors.surfaceVariant;
    if (intensity >= 4) return maxColor ?? _defaultMax;
    return _levels[intensity];
  }

  String _tooltipText(DateTime date, int intensity) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (intensity == 0) return '$dateStr: 无记录';
    const labels = ['', '少量', '中等', '较多', '很多'];
    return '$dateStr: ${labels[intensity]}记录';
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static List<List<DateTime?>> _buildWeeks(
    DateTime startDate,
    DateTime endDate,
  ) {
    final normalizedStart = _normalizeDate(startDate);
    final normalizedEnd = _normalizeDate(endDate);
    final gridStart = normalizedStart.subtract(
      Duration(days: normalizedStart.weekday - 1),
    );
    final gridEnd = normalizedEnd.add(
      Duration(days: 7 - normalizedEnd.weekday),
    );
    final weeks = <List<DateTime?>>[];
    var cursor = gridStart;

    while (!cursor.isAfter(gridEnd)) {
      final week = <DateTime?>[];
      for (var i = 0; i < 7; i++) {
        final inRange =
            !cursor.isBefore(normalizedStart) && !cursor.isAfter(normalizedEnd);
        week.add(inRange ? cursor : null);
        cursor = cursor.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return weeks;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Map<DateTime, int> fromDailyStats(List<dynamic> stats) {
    final data = <DateTime, int>{};
    for (final stat in stats) {
      final intensity = stat.activeModules as int;
      if (intensity > 0) {
        final date = stat.date as DateTime;
        data[_normalizeDate(date)] = intensity;
      }
    }
    return data;
  }
}

/// 月份标签组件
///
/// 使用 Row 布局，跟随网格同步滚动。
/// 跨年边界处显示年份（如 "2024年12月" → "1月"）。
class _MonthLabels extends StatelessWidget {
  const _MonthLabels({
    required this.weeks,
    required this.cellSize,
    required this.cellSpacing,
  });

  final List<List<DateTime?>> weeks;
  final double cellSize;
  final double cellSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const weekdayLabelWidth = 28.0;
    final labels = <Widget>[];
    var lastMonth = 0;
    var lastYear = 0;

    for (var i = 0; i < weeks.length; i++) {
      final dates = weeks[i].whereType<DateTime>().toList();
      if (dates.isEmpty) continue;

      final monthDate = dates.firstWhere(
        (date) => date.day <= 7 || date.month != lastMonth,
        orElse: () => dates.first,
      );

      if (monthDate.month == lastMonth && monthDate.year == lastYear) {
        continue;
      }

      // 判断是否需要显示年份（跨年边界）
      final showYear =
          monthDate.year != lastYear && (lastMonth > 0 && monthDate.month <= lastMonth);
      lastMonth = monthDate.month;
      lastYear = monthDate.year;

      // 添加月份标签（用 SizedBox 占位，保持与网格对齐）
      labels.add(
        SizedBox(
          width: i == 0
              ? weekdayLabelWidth + i * (cellSize + cellSpacing)
              : (cellSize + cellSpacing),
          child: i == 0
              ? Padding(
                  padding: EdgeInsets.only(
                    left: weekdayLabelWidth + i * (cellSize + cellSpacing) - (cellSize + cellSpacing),
                  ),
                  child: Text(
                    showYear
                        ? '${monthDate.year}年${monthDate.month}月'
                        : '${monthDate.month}月',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                )
              : null,
        ),
      );
    }

    // 使用 Row 布局，让标签跟随滚动
    return SizedBox(
      height: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _buildLabelRow(weeks, theme),
      ),
    );
  }

  /// 构建月份标签行（使用 Spacer 占位对齐）
  List<Widget> _buildLabelRow(
    List<List<DateTime?>> weeks,
    ThemeData theme,
  ) {
    final result = <Widget>[];
    var lastMonth = 0;
    var lastYear = 0;

    for (var i = 0; i < weeks.length; i++) {
      final dates = weeks[i].whereType<DateTime>().toList();
      if (dates.isEmpty) {
        continue;
      }

      final monthDate = dates.firstWhere(
        (date) => date.day <= 7 || date.month != lastMonth,
        orElse: () => dates.first,
      );

      if (monthDate.month != lastMonth || monthDate.year != lastYear) {
        // 判断是否需要显示年份
        final showYear = monthDate.year != lastYear &&
            (lastMonth > 0 && monthDate.month <= lastMonth);
        lastMonth = monthDate.month;
        lastYear = monthDate.year;

        // 添加标签
        result.add(
          Text(
            showYear
                ? '${monthDate.year}年${monthDate.month}月'
                : '${monthDate.month}月',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        );
      }
    }

    return result;
  }
}

/// 星期标签组件（周一到周日）
class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels({required this.cellSize, required this.cellSpacing});

  final double cellSize;
  final double cellSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const dayLabels = ['一', '二', '三', '四', '五', '六', '日'];
    const visibleIndices = [0, 2, 4, 6];

    return Column(
      children: List.generate(7, (index) {
        final visible = visibleIndices.contains(index);
        return SizedBox(
          width: 24,
          height: cellSize + cellSpacing,
          child: visible
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      dayLabels[index],
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : null,
        );
      }),
    );
  }
}

/// 热力图图例组件
class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend({required this.baseColor, required this.maxColor});

  final Color baseColor;
  final Color maxColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      baseColor,
      const Color(0xFF9BE9A8),
      const Color(0xFF40C463),
      const Color(0xFF30A14E),
      maxColor,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '少',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        ...colors.map(
          (color) => Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '多',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
