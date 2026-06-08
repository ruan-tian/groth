import 'package:flutter/material.dart';

import '../../../app/theme.dart';

// =============================================================================
// HeatmapCalendar Widget
// =============================================================================

/// GitHub 风格的热力图日历组件
///
/// 每个单元格代表一天，颜色深浅表示活动强度。
/// 默认显示最近 3 个月，可通过 [monthsToShow] 自定义。
///
/// ## 使用示例
/// ```dart
/// HeatmapCalendar(
///   data: {
///     DateTime(2026, 6, 1): 2,
///     DateTime(2026, 6, 2): 4,
///     DateTime(2026, 6, 3): 1,
///   },
/// )
/// ```
class HeatmapCalendar extends StatelessWidget {
  const HeatmapCalendar({
    super.key,
    required this.data,
    this.monthsToShow = 3,
    this.cellSize = 14,
    this.cellSpacing = 3,
    this.baseColor,
    this.maxColor,
    this.showLegend = true,
    this.onDayTap,
  });

  /// 日期 → 强度值 (0~4) 的映射。
  ///
  /// 强度值会被 clamp 到 [0, 4] 范围内。
  /// 值为 0 或不在 map 中的日期显示为最低色阶。
  final Map<DateTime, int> data;

  /// 显示的月数（默认 3 个月）。
  final int monthsToShow;

  /// 每个单元格的边长（默认 14）。
  final double cellSize;

  /// 单元格间距（默认 3）。
  final double cellSpacing;

  /// 无活动时的基础颜色（默认灰色）。
  final Color? baseColor;

  /// 最高活动强度颜色（默认绿色）。
  final Color? maxColor;

  /// 是否显示图例（默认 true）。
  final bool showLegend;

  /// 点击某一天的回调，参数为该天的日期。
  final ValueChanged<DateTime>? onDayTap;

  // ── 强度色阶 (0~4) ──

  static const _defaultBase = Color(0xFFEBEDF0);
  static const _defaultMax = Color(0xFF216E39);
  static const _levels = [
    Color(0xFFEBEDF0), // 0: 无活动
    Color(0xFF9BE9A8), // 1: 低
    Color(0xFF40C463), // 2: 中
    Color(0xFF30A14E), // 3: 高
    Color(0xFF216E39), // 4: 极高
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // 计算起始日期（monthsToShow 个月前的第一天）
    final startDate = DateTime(now.year, now.month - monthsToShow + 1, 1);
    // 计算结束日期（当月最后一天）
    final endDate = DateTime(now.year, now.month + 1, 0);

    // 构建日期网格（按周排列，每周 7 天）
    final weeks = _buildWeeks(startDate, endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 月份标签 ──
        _MonthLabels(
          weeks: weeks,
          cellSize: cellSize,
          cellSpacing: cellSpacing,
        ),

        // ── 热力图网格 ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 星期标签列
              _WeekdayLabels(cellSize: cellSize, cellSpacing: cellSpacing),
              const SizedBox(width: 4),
              // 网格
              ...weeks.map((week) => _buildWeekColumn(week)),
            ],
          ),
        ),

        // ── 图例 ──
        if (showLegend) ...[
          const SizedBox(height: AppTheme.spaceMd),
          _HeatmapLegend(
            baseColor: baseColor ?? _defaultBase,
            maxColor: maxColor ?? _defaultMax,
          ),
        ],
      ],
    );
  }

  /// 构建一周的列（7 行）
  Widget _buildWeekColumn(List<DateTime?> week) {
    return Column(
      children: List.generate(7, (dayIndex) {
        final date = week[dayIndex];
        if (date == null) {
          // 空白占位
          return Container(
            width: cellSize,
            height: cellSize,
            margin: EdgeInsets.all(cellSpacing / 2),
          );
        }

        final normalized = _normalizeDate(date);
        final intensity = (data[normalized] ?? 0).clamp(0, 4);
        final color = _colorForIntensity(intensity);

        final isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        return GestureDetector(
          onTap: onDayTap != null ? () => onDayTap!(date) : null,
          child: Tooltip(
            message: _tooltipText(date, intensity),
            child: Container(
              width: cellSize,
              height: cellSize,
              margin: EdgeInsets.all(cellSpacing / 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                border: isToday ? Border.all(color: Colors.white, width: 2) : null,
                boxShadow: isToday ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ] : null,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// 根据强度值返回对应颜色
  Color _colorForIntensity(int intensity) {
    if (intensity <= 0) return baseColor ?? _defaultBase;
    if (intensity >= 4) return maxColor ?? _defaultMax;
    return _levels[intensity];
  }

  /// 工具提示文本
  String _tooltipText(DateTime date, int intensity) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (intensity == 0) return '$dateStr: 无活动';
    final labels = ['', '低', '中', '高', '极高'];
    return '$dateStr: ${labels[intensity]}活动';
  }

  /// 将日期归一化为当天 0 点（忽略时分秒）
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 构建按周排列的日期网格
  ///
  /// 返回值：每个元素是一周 (`List<DateTime?>`)，长度为 7，
  /// 索引 0 = 周一，索引 6 = 周日。不在该周范围内的日期为 null。
  static List<List<DateTime?>> _buildWeeks(
    DateTime startDate,
    DateTime endDate,
  ) {
    final weeks = <List<DateTime?>>[];
    List<DateTime?> currentWeek = List.filled(7, null);

    // 找到 startDate 所在周的周一
    final startMonday = startDate.subtract(
      Duration(days: (startDate.weekday - 1) % 7),
    );

    var current = startMonday;
    while (current.isBefore(endDate) || _isSameDay(current, endDate)) {
      final weekdayIndex = (current.weekday - 1) % 7; // 0=周一, 6=周日

      // 如果是周一且当前周非空，开始新的一周
      if (weekdayIndex == 0 && currentWeek.any((d) => d != null)) {
        weeks.add(currentWeek);
        currentWeek = List.filled(7, null);
      }

      // 只填充 endDate 之前（含）的日期
      if (!current.isAfter(endDate)) {
        currentWeek[weekdayIndex] = current;
      }

      current = current.add(const Duration(days: 1));
    }

    // 添加最后一周
    if (currentWeek.any((d) => d != null)) {
      weeks.add(currentWeek);
    }

    return weeks;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 从 DailyStats 列表生成热力图数据
  static Map<DateTime, int> fromDailyStats(List<dynamic> stats) {
    final data = <DateTime, int>{};
    for (final stat in stats) {
      // Use activeModules as intensity (0-6)
      final intensity = stat.activeModules as int;
      if (intensity > 0) {
        data[stat.date as DateTime] = intensity;
      }
    }
    return data;
  }
}

// =============================================================================
// 月份标签
// =============================================================================

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
    final labels = <Widget>[];

    // 星期标签列的宽度偏移
    const weekdayLabelWidth = 28.0;

    for (var i = 0; i < weeks.length; i++) {
      final week = weeks[i];
      // 找到该周第一个有效日期
      final firstDate = week.firstWhere((d) => d != null, orElse: () => null);
      if (firstDate == null) continue;

      // 只在每月第一周显示月份标签
      if (firstDate.day <= 7) {
        final monthNames = [
          '', '1月', '2月', '3月', '4月', '5月', '6月',
          '7月', '8月', '9月', '10月', '11月', '12月',
        ];
        labels.add(
          Positioned(
            left: weekdayLabelWidth + i * (cellSize + cellSpacing),
            child: Text(
              monthNames[firstDate.month],
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
        );
      }
    }

    return SizedBox(
      height: 16,
      child: Stack(children: labels),
    );
  }
}

// =============================================================================
// 星期标签
// =============================================================================

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels({
    required this.cellSize,
    required this.cellSpacing,
  });

  final double cellSize;
  final double cellSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayLabels = ['一', '二', '三', '四', '五', '六', '日'];
    // 只显示奇数天（周一、周三、周五、周日）以节省空间
    final visibleIndices = [0, 2, 4, 6];

    return Column(
      children: List.generate(7, (index) {
        final isvisible = visibleIndices.contains(index);
        return SizedBox(
          width: 24,
          height: cellSize + cellSpacing,
          child: isvisible
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

// =============================================================================
// 图例
// =============================================================================

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend({
    required this.baseColor,
    required this.maxColor,
  });

  final Color baseColor;
  final Color maxColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        ...List.generate(5, (i) {
          final colors = [
            baseColor,
            const Color(0xFF9BE9A8),
            const Color(0xFF40C463),
            const Color(0xFF30A14E),
            maxColor,
          ];
          return Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: colors[i],
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
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
