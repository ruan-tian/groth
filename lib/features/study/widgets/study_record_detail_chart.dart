part of '../pages/study_record_detail_page.dart';

class _StudyTrendChart extends ConsumerStatefulWidget {
  const _StudyTrendChart({required this.record});

  final StudyRecord record;

  @override
  ConsumerState<_StudyTrendChart> createState() => _StudyTrendChartState();
}

class _StudyTrendChartState extends ConsumerState<_StudyTrendChart> {
  String _selectedRange = 'week';

  Color get _barColor => context.growthColors.study;
  Color get _barColorLight => context.growthColors.study.withValues(alpha: 0.3);
  static const _tooltipBg = Color(0xFF1E293B);

  // ── 周/月/年中文名 ──
  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const _months = [
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.growthColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: context.growthColors.study.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.growthColors.study.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRangeSelector(),
          const SizedBox(height: AppSpacing.lg),
          _buildChart(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 范围选择器
  // ---------------------------------------------------------------------------

  Widget _buildRangeSelector() {
    const options = [('week', '本周'), ('month', '本月'), ('year', '本年')];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.growthColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: options.map((opt) {
          final selected = _selectedRange == opt.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRange = opt.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _barColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                ),
                child: Text(
                  opt.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? context.growthColors.card
                        : context.growthColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 图表主体
  // ---------------------------------------------------------------------------

  Widget _buildChart() {
    switch (_selectedRange) {
      case 'week':
        return _buildWeekChart();
      case 'month':
        return _buildMonthChart();
      case 'year':
        return _buildYearChart();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── 本周图表 ──
  Widget _buildWeekChart() {
    final async = ref.watch(weeklyDailyStudyProvider);
    return async.when(
      data: (stats) {
        final now = DateTime.now();
        // 构建 7 天数据（周一到周日）
        final weekday = now.weekday; // 1=Mon
        final monday = now.subtract(Duration(days: weekday - 1));
        final days = List.generate(7, (i) => monday.add(Duration(days: i)));

        final barData = days.map((day) {
          final match = stats.where(
            (s) =>
                s.date.year == day.year &&
                s.date.month == day.month &&
                s.date.day == day.day,
          );
          return _TrendBarData(
            label: _weekdays[day.weekday - 1],
            subLabel: '${day.month}/${day.day}',
            value: match.isNotEmpty ? match.first.studyMinutes : 0,
            date: day,
          );
        }).toList();

        return _buildBarChart(
          barData: barData,
          range: 'week',
          emptyHint: '本周暂无学习数据',
        );
      },
      loading: () => SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _barColor),
        ),
      ),
      error: (e, _) => SizedBox(
        height: 240,
        child: Center(child: Text('加载失败: $e', style: AppTextStyles.caption)),
      ),
    );
  }

  // ── 本月图表 ──
  Widget _buildMonthChart() {
    final async = ref.watch(monthlyDailyStudyProvider);
    return async.when(
      data: (stats) {
        // 聚合为 4 周
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final weeks = <_TrendBarData>[];

        for (int w = 0; w < 4; w++) {
          final weekStart = monthStart.add(Duration(days: w * 7));
          final weekEnd = w == 3
              ? DateTime(now.year, now.month + 1, 0)
              : weekStart.add(const Duration(days: 6));
          final weekStats = stats.where(
            (s) => !s.date.isBefore(weekStart) && !s.date.isAfter(weekEnd),
          );
          final total = weekStats.fold<int>(
            0,
            (sum, s) => sum + s.studyMinutes,
          );

          final startStr = '${weekStart.month}/${weekStart.day}';
          final endStr = '${weekEnd.month}/${weekEnd.day}';
          weeks.add(
            _TrendBarData(
              label: '第${w + 1}周',
              subLabel: '$startStr-$endStr',
              value: total,
            ),
          );
        }

        return _buildBarChart(
          barData: weeks,
          range: 'month',
          emptyHint: '本月暂无学习数据',
        );
      },
      loading: () => SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _barColor),
        ),
      ),
      error: (e, _) => SizedBox(
        height: 240,
        child: Center(child: Text('加载失败: $e', style: AppTextStyles.caption)),
      ),
    );
  }

  // ── 本年图表 ──
  Widget _buildYearChart() {
    final async = ref.watch(yearlyMonthlyStudyProvider);
    return async.when(
      data: (stats) {
        final barData = stats.map((s) {
          // month 格式: YYYY-MM
          final parts = s.month.split('-');
          final monthIndex = int.tryParse(parts.last) ?? 1;
          return _TrendBarData(
            label: _months[monthIndex - 1],
            value: s.studyMinutes,
          );
        }).toList();

        return _buildBarChart(
          barData: barData,
          range: 'year',
          emptyHint: '本年暂无学习数据',
        );
      },
      loading: () => SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _barColor),
        ),
      ),
      error: (e, _) => SizedBox(
        height: 240,
        child: Center(child: Text('加载失败: $e', style: AppTextStyles.caption)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 通用柱状图
  // ---------------------------------------------------------------------------

  Widget _buildBarChart({
    required List<_TrendBarData> barData,
    required String range,
    required String emptyHint,
  }) {
    if (barData.isEmpty || barData.every((d) => d.value == 0)) {
      return SizedBox(
        height: 240,
        child: Center(child: Text(emptyHint, style: AppTextStyles.caption)),
      );
    }

    final minutesList = barData.map((d) => d.value).toList();
    final scale = buildDurationChartScale(minutesList);
    final yMax = scale.maxY;

    return ClipRect(
      child: SizedBox(
        height: 240,
        child: RepaintBoundary(
          child: BarChart(
            BarChartData(
              maxY: yMax * 1.25,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: _buildTouchData(barData, scale),
              titlesData: _buildTitles(barData, scale, yMax, range),
              gridData: _buildGrid(scale),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(barData.length, (i) {
                return _buildBarGroup(i, barData, yMax, range);
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ── 触摸交互 ──
  BarTouchData _buildTouchData(
    List<_TrendBarData> barData,
    DurationChartScale scale,
  ) {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => _tooltipBg,
        tooltipBorderRadius: BorderRadius.circular(8),
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final bar = barData[group.x];
          final title = bar.subLabel ?? bar.label;
          return BarTooltipItem(
            '$title\n',
            TextStyle(
              color: context.growthColors.textOnAccent.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: scale.formatTooltipValue(bar.value.toDouble()),
                style: TextStyle(
                  color: context.growthColors.textOnAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── 坐标轴标题 ──
  FlTitlesData _buildTitles(
    List<_TrendBarData> barData,
    DurationChartScale scale,
    double yMax,
    String range,
  ) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: range == 'week' ? 44 : 36,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= barData.length) {
              return const SizedBox.shrink();
            }
            return _buildBottomLabel(index, barData, range);
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          interval: scale.interval,
          getTitlesWidget: (value, meta) {
            if (value == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                scale.formatAxisLabel(value),
                style: TextStyle(
                  fontSize: 11,
                  color: context.growthColors.textTertiary,
                ),
                textAlign: TextAlign.right,
              ),
            );
          },
        ),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= barData.length) {
              return const SizedBox.shrink();
            }
            final bar = barData[index];
            if (bar.value == 0) return const SizedBox.shrink();
            // 当数据点过多时，只显示首尾和最大值
            if (barData.length > 10) {
              if (index != 0 && index != barData.length - 1) {
                final maxValue = barData
                    .map((b) => b.value)
                    .reduce((a, b) => a > b ? a : b);
                if (bar.value != maxValue) return const SizedBox.shrink();
              }
            }
            return _TrendValueBubble(value: _formatMinutesCompact(bar.value));
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  // ── 网格线 ──
  FlGridData _buildGrid(DurationChartScale scale) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: scale.interval,
      getDrawingHorizontalLine: (value) => FlLine(
        color: context.growthColors.border.withValues(alpha: 0.6),
        strokeWidth: 1,
        dashArray: [4, 4],
      ),
    );
  }

  // ── 单个柱子 ──
  BarChartGroupData _buildBarGroup(
    int index,
    List<_TrendBarData> barData,
    double yMax,
    String range,
  ) {
    final bar = barData[index];
    final highlighted = _isHighlighted(index, barData, range);
    final barWidth = range == 'week'
        ? 20.0
        : range == 'month'
        ? 28.0
        : 16.0;

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: bar.value.toDouble(),
          color: highlighted ? _barColor : _barColorLight,
          width: barWidth,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: yMax,
            color: context.growthColors.border.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  // ── 底部标签 ──
  Widget _buildBottomLabel(
    int index,
    List<_TrendBarData> barData,
    String range,
  ) {
    final bar = barData[index];
    final highlighted = _isHighlighted(index, barData, range);

    final mainStyle = TextStyle(
      fontSize: range == 'month' ? 10 : 11,
      fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
      color: highlighted ? _barColor : context.growthColors.textPrimary,
    );
    final subStyle = TextStyle(
      fontSize: 11,
      color: highlighted ? _barColor : context.growthColors.textTertiary,
    );

    if (range == 'week') {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(bar.label, style: mainStyle),
            if (bar.subLabel != null) Text(bar.subLabel!, style: subStyle),
          ],
        ),
      );
    }

    if (range == 'month') {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(bar.label, style: mainStyle),
            if (bar.subLabel != null && bar.subLabel!.isNotEmpty)
              Text(bar.subLabel!, style: subStyle),
          ],
        ),
      );
    }

    // Year: single line
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(bar.label, style: mainStyle),
    );
  }

  // ── 辅助方法 ──
  bool _isHighlighted(int index, List<_TrendBarData> barData, String range) {
    if (range == 'week' && barData[index].date != null) {
      final now = DateTime.now();
      final d = barData[index].date!;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }
    return false;
  }

  String _formatMinutesCompact(int minutes) {
    if (minutes <= 0) return '0';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '$h.${(m * 10 / 60).round()}h';
  }
}

// =============================================================================
// 趋势图柱状数据
// =============================================================================

class _TrendBarData {
  const _TrendBarData({
    required this.label,
    required this.value,
    this.subLabel,
    this.date,
  });

  final String label;
  final int value;
  final String? subLabel;
  final DateTime? date;
}

// =============================================================================
// 趋势图柱顶数值气泡
// =============================================================================

class _TrendValueBubble extends StatelessWidget {
  const _TrendValueBubble({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: context.growthColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.growthColors.border),
        boxShadow: [
          BoxShadow(
            color: context.growthColors.shadow.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.growthColors.study,
        ),
      ),
    );
  }
}
