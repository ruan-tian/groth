part of '../fitness_page.dart';

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.progress,
  });

  final String label;
  final int current;
  final int target;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(
              '$current / $target',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
                    color: AppColors.softOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.fitness),
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 健身趋势图表（锻炼时间 + 消耗 + 体重）──────────────────────────────────

class _FitnessTrendChart extends StatefulWidget {
  const _FitnessTrendChart({required this.data});

  final List<FitnessChartData> data;

  @override
  State<_FitnessTrendChart> createState() => _FitnessTrendChartState();
}

class _FitnessTrendChartState extends State<_FitnessTrendChart> {
  int? _touchedIndex;
  LineChartData? _cachedChartData;

  @override
  void didUpdateWidget(_FitnessTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.data, oldWidget.data)) {
      _cachedChartData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LineChart(
        _cachedChartData ??= _buildChartData(),
        duration: const Duration(milliseconds: 200),
      ),
    );
  }

  LineChartData _buildChartData() {
    final data = widget.data;

    // 使用 DurationChartScale 计算健身时长的缩放
    final minutesList = data.map((d) => d.minutes).toList();
    final scale = buildDurationChartScale(minutesList);

    // 计算卡路里和体重的归一化范围
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

    // 卡路里和体重归一化到 scale.maxY 范围内
    final caloriesTop = maxCalories > 0 ? maxCalories.toDouble() : 500.0;
    final weightRange = maxWeight - minWeight;
    final weightPadding = weightRange < 0.5 ? 1.0 : weightRange * 0.15;
    final weightMin = (minWeight - weightPadding).floorToDouble();
    final weightMax = (maxWeight + weightPadding).ceilToDouble();

    FlSpot minutesSpot(FitnessChartData d, int i) =>
        FlSpot(i.toDouble(), scale.convertMinutes(d.minutes));

    FlSpot caloriesSpot(FitnessChartData d, int i) => FlSpot(
      i.toDouble(),
      caloriesTop > 0 ? (d.calories / caloriesTop) * scale.maxY : 0,
    );

    FlSpot weightSpot(FitnessChartData d, int i) {
      if (d.weight == null || weightMax == weightMin) {
        return FlSpot(i.toDouble(), scale.maxY * 0.5);
      }
      return FlSpot(
        i.toDouble(),
        ((d.weight! - weightMin) / (weightMax - weightMin)) * scale.maxY,
      );
    }

    final minutesSpots = <FlSpot>[];
    final caloriesSpots = <FlSpot>[];
    final weightSpots = <FlSpot>[];

    for (int i = 0; i < data.length; i++) {
      minutesSpots.add(minutesSpot(data[i], i));
      caloriesSpots.add(caloriesSpot(data[i], i));
      if (data[i].weight != null) {
        weightSpots.add(weightSpot(data[i], i));
      }
    }

    return LineChartData(
      minY: 0,
      maxY: scale.maxY,
      // ── 触摸交互 ──
      lineTouchData: LineTouchData(
        touchSpotThreshold: 20,
        handleBuiltInTouches: true,
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
          tooltipRoundedRadius: 10,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          maxContentWidth: 200,
          getTooltipColor: (_) => Colors.white.withValues(alpha: 0.95),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];
            final idx = touchedSpots.first.x.toInt();
            if (idx < 0 || idx >= data.length) return [];
            final d = data[idx];
            final dateStr = '${d.date.month}/${d.date.day}';

            final items = <LineTooltipItem>[];

            // 锻炼时间
            final minutesSpot = touchedSpots
                .where((s) => s.barIndex == 0)
                .firstOrNull;
            if (minutesSpot != null) {
              items.add(
                LineTooltipItem(
                  '$dateStr 锻炼 ${scale.formatTooltipValue(d.minutes.toDouble())}',
                  TextStyle(
                    color: AppColors.fitness,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }

            // 消耗
            final caloriesSpot = touchedSpots
                .where((s) => s.barIndex == 1)
                .firstOrNull;
            if (caloriesSpot != null) {
              items.add(
                LineTooltipItem(
                  '$dateStr 消耗 ${d.calories}kcal',
                  TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }

            // 体重
            final wSpot = touchedSpots
                .where((s) => s.barIndex == 2)
                .firstOrNull;
            if (wSpot != null && d.weight != null) {
              items.add(
                LineTooltipItem(
                  '$dateStr 体重 ${d.weight!.toStringAsFixed(1)}kg',
                  TextStyle(
                    color: AppColors.textTertiary,
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
        // 锻炼时间线
        LineChartBarData(
          spots: minutesSpots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: AppColors.fitness,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: _touchedIndex == index ? 5 : 3,
                  color: AppColors.fitness,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.fitness.withValues(alpha: 0.06),
          ),
        ),
        // 消耗线
        LineChartBarData(
          spots: caloriesSpots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: AppColors.warning,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: _touchedIndex == index ? 5 : 3,
                  color: AppColors.warning,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.warning.withValues(alpha: 0.06),
          ),
        ),
        // 体重线
        if (weightSpots.isNotEmpty)
          LineChartBarData(
            spots: weightSpots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppColors.textTertiary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: _touchedIndex == index ? 5 : 3,
                    color: AppColors.textTertiary,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.textTertiary.withValues(alpha: 0.06),
            ),
          ),
      ],
      titlesData: FlTitlesData(
        // 左 Y 轴：分钟
        leftTitles: AxisTitles(
          axisNameWidget: Text(
            scale.useHours ? '小时' : '分钟',
            style: const TextStyle(fontSize: 9, color: AppColors.fitness),
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
                  style: const TextStyle(fontSize: 9, color: AppColors.fitness),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
        // 右 Y 轴：kcal
        rightTitles: AxisTitles(
          axisNameWidget: const Text(
            'kcal',
            style: TextStyle(fontSize: 9, color: AppColors.warning),
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
                style: const TextStyle(fontSize: 9, color: AppColors.warning),
                textAlign: TextAlign.left,
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        // X 轴：日期标签
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= data.length) {
                return const SizedBox.shrink();
              }
              final d = data[idx];
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${d.date.month}/${d.date.day}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
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
          color: AppColors.border.withValues(alpha: 0.5),
          strokeWidth: 0.5,
        ),
      ),
      borderData: FlBorderData(show: false),
    );
  }
}
