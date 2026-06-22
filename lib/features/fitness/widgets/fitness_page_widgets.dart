part of '../fitness_page.dart';

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.softOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colors.fitness),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FitnessTrendChart extends StatefulWidget {
  const _FitnessTrendChart({required this.data});

  final List<FitnessChartData> data;

  @override
  State<_FitnessTrendChart> createState() => _FitnessTrendChartState();
}

class _FitnessTrendChartState extends State<_FitnessTrendChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return RepaintBoundary(
      child: LineChart(
        _buildChartData(colors),
        duration: const Duration(milliseconds: 200),
      ),
    );
  }

  LineChartData _buildChartData(AppThemeColors colors) {
    final data = widget.data;
    final minutesList = data.map((d) => d.minutes).toList();
    final scale = buildDurationChartScale(minutesList);

    final maxCalories = data
        .map((d) => d.calories)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final weights = data
        .where((d) => d.weight != null)
        .map((d) => d.weight!)
        .toList();
    final maxWeight = weights.isNotEmpty
        ? weights.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final minWeight = weights.isNotEmpty
        ? weights.reduce((a, b) => a < b ? a : b)
        : 0.0;

    final caloriesTop = maxCalories > 0 ? maxCalories.toDouble() : 500.0;
    final weightRange = maxWeight - minWeight;
    final weightPadding = weightRange < 0.5 ? 1.0 : weightRange * 0.15;
    final weightMin = (minWeight - weightPadding).floorToDouble();
    final weightMax = (maxWeight + weightPadding).ceilToDouble();

    // 首日日期，用于计算 X 轴日期差
    final firstDate = data.first.date;

    // 将日期转换为距首日的天数差（X 轴真实日期位置）
    double dayX(DateTime date) => date
        .difference(DateTime(firstDate.year, firstDate.month, firstDate.day))
        .inDays
        .toDouble();

    FlSpot minutesSpot(FitnessChartData d) =>
        FlSpot(dayX(d.date), scale.convertMinutes(d.minutes));

    FlSpot caloriesSpot(FitnessChartData d) => FlSpot(
      dayX(d.date),
      caloriesTop > 0 ? (d.calories / caloriesTop) * scale.maxY : 0,
    );

    FlSpot weightSpot(FitnessChartData d) {
      if (d.weight == null || weightMax == weightMin) {
        return FlSpot(dayX(d.date), scale.maxY * 0.5);
      }
      return FlSpot(
        dayX(d.date),
        ((d.weight! - weightMin) / (weightMax - weightMin)) * scale.maxY,
      );
    }

    final minutesSpots = <FlSpot>[];
    final caloriesSpots = <FlSpot>[];
    final weightSpots = <FlSpot>[];

    for (int i = 0; i < data.length; i++) {
      minutesSpots.add(minutesSpot(data[i]));
      caloriesSpots.add(caloriesSpot(data[i]));
      if (data[i].weight != null) {
        weightSpots.add(weightSpot(data[i]));
      }
    }

    return LineChartData(
      minY: 0,
      maxY: scale.maxY,
      lineTouchData: LineTouchData(
        touchSpotThreshold: 20,
        handleBuiltInTouches: true,
        getTouchLineStart: (barData, spotIndex) => 0,
        getTouchLineEnd: (barData, spotIndex) => double.infinity,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: colors.border.withValues(alpha: 0.4),
                strokeWidth: 1.5,
                dashArray: const [4, 4],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 6,
                  color: colors.card,
                  strokeColor: barData.color ?? colors.fitness,
                  strokeWidth: 3,
                ),
              ),
            );
          }).toList();
        },
        touchCallback: (event, response) {
          setState(() {
            if (event is FlPanEndEvent || event is FlLongPressEnd) {
              _touchedIndex = null;
            } else if (response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              _touchedIndex = response.lineBarSpots!.first.x.toInt();
            }
          });
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipBorderRadius: BorderRadius.circular(10),
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          maxContentWidth: 200,
          getTooltipColor: (_) => colors.paper.withValues(alpha: 0.95),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];
            final dayOffset = touchedSpots.first.x.toInt();
            final date = firstDate.add(Duration(days: dayOffset));
            // 查找对应日期的数据
            final d = data
                .where(
                  (item) =>
                      item.date.year == date.year &&
                      item.date.month == date.month &&
                      item.date.day == date.day,
                )
                .firstOrNull;
            if (d == null) return [];
            final dateStr = '${d.date.month}/${d.date.day}';

            final items = <LineTooltipItem>[];
            final minutesSpot = touchedSpots
                .where((s) => s.barIndex == 0)
                .firstOrNull;
            if (minutesSpot != null) {
              items.add(
                LineTooltipItem(
                  '$dateStr 锻炼 ${scale.formatTooltipValue(d.minutes.toDouble())}',
                  TextStyle(
                    color: colors.fitness,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }

            final caloriesSpot = touchedSpots
                .where((s) => s.barIndex == 1)
                .firstOrNull;
            if (caloriesSpot != null) {
              items.add(
                LineTooltipItem(
                  '$dateStr 消耗 ${d.calories}kcal',
                  TextStyle(
                    color: colors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }

            final weightSpot = touchedSpots
                .where((s) => s.barIndex == 2)
                .firstOrNull;
            if (weightSpot != null && d.weight != null) {
              items.add(
                LineTooltipItem(
                  '$dateStr 体重 ${d.weight!.toStringAsFixed(1)}kg',
                  TextStyle(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }

            return items;
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: minutesSpots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: colors.fitness,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: _touchedIndex == spot.x.toInt() ? 5 : 3,
                  color: colors.fitness,
                  strokeWidth: 1.5,
                  strokeColor: colors.paper,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: colors.fitness.withValues(alpha: 0.06),
          ),
        ),
        LineChartBarData(
          spots: caloriesSpots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: colors.warning,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: _touchedIndex == spot.x.toInt() ? 5 : 3,
                  color: colors.warning,
                  strokeWidth: 1.5,
                  strokeColor: colors.paper,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: colors.warning.withValues(alpha: 0.06),
          ),
        ),
        if (weightSpots.isNotEmpty)
          LineChartBarData(
            spots: weightSpots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: colors.textTertiary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: _touchedIndex == spot.x.toInt() ? 5 : 3,
                    color: colors.textTertiary,
                    strokeWidth: 1.5,
                    strokeColor: colors.paper,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: colors.textTertiary.withValues(alpha: 0.06),
            ),
          ),
      ],
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          axisNameWidget: Text(
            scale.useHours ? '小时' : '分钟',
            style: TextStyle(fontSize: 11, color: colors.fitness),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: scale.interval,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  scale.formatAxisLabel(value),
                  style: TextStyle(fontSize: 11, color: colors.fitness),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(
          axisNameWidget: Text(
            'kcal',
            style: TextStyle(fontSize: 11, color: colors.warning),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: scale.interval,
            getTitlesWidget: (value, meta) {
              final kcal = (value / scale.maxY * caloriesTop).round();
              return Text(
                '$kcal',
                style: TextStyle(fontSize: 11, color: colors.warning),
                textAlign: TextAlign.left,
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              // X 值是距首日的天数差，转换回日期
              final date = firstDate.add(Duration(days: value.toInt()));
              // 只在有数据的日期附近显示标签
              final hasData = data.any(
                (d) =>
                    d.date.year == date.year &&
                    d.date.month == date.month &&
                    d.date.day == date.day,
              );
              if (!hasData && data.length > 7) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${date.month}/${date.day}',
                  style: TextStyle(fontSize: 11, color: colors.textTertiary),
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: scale.interval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: colors.border.withValues(alpha: 0.5),
          strokeWidth: 0.5,
        ),
      ),
      borderData: FlBorderData(show: false),
    );
  }
}
