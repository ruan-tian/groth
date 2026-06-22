part of '../diet_page.dart';

class _ChartPoint {
  const _ChartPoint({
    required this.x,
    required this.calorie,
    required this.water,
    required this.label,
    required this.subLabel,
  });

  final double x;
  final int calorie;
  final int water;
  final String label;
  final String subLabel;
}

class _CalorieWaterChart extends StatefulWidget {
  const _CalorieWaterChart({
    required this.calorieMap,
    required this.waterMap,
    required this.days,
  });

  final Map<String, int> calorieMap;
  final Map<String, int> waterMap;
  final int days;

  @override
  State<_CalorieWaterChart> createState() => _CalorieWaterChartState();
}

class _CalorieWaterChartState extends State<_CalorieWaterChart> {
  int? _touchedIndex;
  List<_ChartPoint>? _cachedPoints;

  @override
  void didUpdateWidget(_CalorieWaterChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.calorieMap, oldWidget.calorieMap) ||
        !identical(widget.waterMap, oldWidget.waterMap) ||
        widget.days != oldWidget.days) {
      _cachedPoints = null;
    }
  }

  // ── 格式化工具 ──

  /// 卡路里格式：<1000 显示 "800"，≥1000 显示 "1.5k"
  static String _formatCalorie(int v) {
    if (v <= 0) return '0';
    if (v < 1000) return '$v';
    final k = v / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
  }

  /// 饮水量格式：<1000ml 显示 "500ml"，≥1000 显示 "1.5L"
  static String _formatWater(int ml) {
    if (ml <= 0) return '0ml';
    if (ml < 1000) return '${ml}ml';
    final l = ml / 1000;
    return '${l.toStringAsFixed(l >= 10 ? 0 : 1)}L';
  }

  // ── 数据聚合 ──

  List<_ChartPoint> _buildWeekPoints() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: 6));
    final points = <_ChartPoint>[];

    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      points.add(
        _ChartPoint(
          x: i.toDouble(),
          calorie: widget.calorieMap[key] ?? 0,
          water: widget.waterMap[key] ?? 0,
          label: DateConstants.weekdayName(date.weekday),
          subLabel: DateFormat('M/d').format(date),
        ),
      );
    }
    return points;
  }

  List<_ChartPoint> _buildMonthPoints() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 本月1号
    final monthStart = DateTime(now.year, now.month, 1);
    final points = <_ChartPoint>[];

    for (int w = 0; w < 4; w++) {
      final weekStart = monthStart.add(Duration(days: w * 7));
      // 不超过今天
      final weekEnd = weekStart.add(const Duration(days: 6));
      final actualEnd = weekEnd.isAfter(today) ? today : weekEnd;

      int totalCal = 0;
      int totalWater = 0;
      var d = weekStart;
      while (!d.isAfter(actualEnd)) {
        final key = DateFormat('yyyy-MM-dd').format(d);
        totalCal += widget.calorieMap[key] ?? 0;
        totalWater += widget.waterMap[key] ?? 0;
        d = d.add(const Duration(days: 1));
      }

      final startLabel = DateFormat('M/d').format(weekStart);
      final endLabel = DateFormat('M/d').format(actualEnd);

      points.add(
        _ChartPoint(
          x: w.toDouble(),
          calorie: totalCal,
          water: totalWater,
          label: '第${w + 1}周',
          subLabel: '$startLabel-$endLabel',
        ),
      );
    }
    return points;
  }

  List<_ChartPoint> _buildYearPoints() {
    final now = DateTime.now();
    final points = <_ChartPoint>[];

    for (int m = 0; m < 12; m++) {
      final monthStart = DateTime(now.year, m + 1, 1);
      final monthEnd = DateTime(now.year, m + 2, 0); // 月末
      final actualEnd = monthEnd.isAfter(now) ? now : monthEnd;

      int totalCal = 0;
      int totalWater = 0;
      var d = monthStart;
      while (!d.isAfter(actualEnd)) {
        final key = DateFormat('yyyy-MM-dd').format(d);
        totalCal += widget.calorieMap[key] ?? 0;
        totalWater += widget.waterMap[key] ?? 0;
        d = d.add(const Duration(days: 1));
      }

      points.add(
        _ChartPoint(
          x: m.toDouble(),
          calorie: totalCal,
          water: totalWater,
          label: '${m + 1}月',
          subLabel: '',
        ),
      );
    }
    return points;
  }

  List<_ChartPoint> _buildPoints() {
    if (widget.days <= 7) return _buildWeekPoints();
    if (widget.days <= 30) return _buildMonthPoints();
    return _buildYearPoints();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final calorieColor = colors.diet;
    final waterColor = colors.primary;
    final points = _cachedPoints ??= _buildPoints();
    if (points.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(fontSize: 12, color: colors.textTertiary),
        ),
      );
    }

    // 计算 Y 轴范围
    final maxCalorie = points
        .map((p) => p.calorie)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final maxWater = points
        .map((p) => p.water)
        .fold<int>(0, (a, b) => a > b ? a : b);
    // 至少留 20% 余量，最小值 1000
    final calTop = ((maxCalorie * 1.2).ceil() / 500).ceil() * 500;
    final waterTop = maxWater > 0
        ? ((maxWater * 1.2).ceil() / 500).ceil() * 500
        : 2000;
    final calTopD = calTop.toDouble();
    final waterTopD = waterTop.toDouble();

    // 归一化到 0-1
    FlSpot calSpot(_ChartPoint p) =>
        FlSpot(p.x, calTopD > 0 ? p.calorie / calTopD : 0);
    FlSpot waterSpot(_ChartPoint p) =>
        FlSpot(p.x, waterTopD > 0 ? p.water / waterTopD : 0);

    final calSpots = points.map(calSpot).toList();
    final waterSpots = points.map(waterSpot).toList();

    return RepaintBoundary(
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 1.0,
          // ── 触摸交互 ──
          lineTouchData: LineTouchData(
            touchSpotThreshold: 20,
            handleBuiltInTouches: true,
            getTouchLineStart: (barData, spotIndex) => 0,
            getTouchLineEnd: (barData, spotIndex) => double.infinity,
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
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((_) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color:
                        barData.color?.withValues(alpha: 0.3) ?? calorieColor,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bd, idx) =>
                        FlDotCirclePainter(
                          radius: 5,
                          color: bd.color ?? calorieColor,
                          strokeWidth: 2,
                          strokeColor: colors.card,
                        ),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(10),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              maxContentWidth: 200,
              getTooltipColor: (_) => colors.card,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                if (touchedSpots.isEmpty) return [];
                final idx = touchedSpots.first.x.toInt();
                if (idx < 0 || idx >= points.length) return [];
                final p = points[idx];

                final items = <LineTooltipItem>[];

                // 卡路里
                final calSpot = touchedSpots
                    .where((s) => s.barIndex == 0)
                    .firstOrNull;
                if (calSpot != null) {
                  items.add(
                    LineTooltipItem(
                      '${p.label} 卡路里 ${_formatCalorie(p.calorie)}',
                      TextStyle(
                        color: calorieColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                // 饮水量
                final waterSpot = touchedSpots
                    .where((s) => s.barIndex == 1)
                    .firstOrNull;
                if (waterSpot != null) {
                  items.add(
                    LineTooltipItem(
                      '${p.label} 饮水 ${_formatWater(p.water)}',
                      TextStyle(
                        color: waterColor,
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
            // 卡路里线
            LineChartBarData(
              spots: calSpots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: calorieColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: _touchedIndex == index ? 5 : 3,
                      color: calorieColor,
                      strokeWidth: 1.5,
                      strokeColor: colors.card,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: calorieColor.withValues(alpha: 0.06),
              ),
            ),
            // 饮水量线
            LineChartBarData(
              spots: waterSpots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: waterColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: _touchedIndex == index ? 5 : 3,
                      color: waterColor,
                      strokeWidth: 1.5,
                      strokeColor: colors.card,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: waterColor.withValues(alpha: 0.06),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            // 左 Y 轴：卡路里
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                'kcal',
                style: TextStyle(fontSize: 11, color: calorieColor),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: 0.25,
                getTitlesWidget: (value, meta) {
                  final kcal = (value * calTopD).round();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _formatCalorie(kcal),
                      style: TextStyle(fontSize: 11, color: calorieColor),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            // 右 Y 轴：饮水量
            rightTitles: AxisTitles(
              axisNameWidget: Text(
                'ml',
                style: TextStyle(fontSize: 11, color: waterColor),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: 0.25,
                getTitlesWidget: (value, meta) {
                  final ml = (value * waterTopD).round();
                  return Text(
                    _formatWater(ml),
                    style: TextStyle(fontSize: 11, color: waterColor),
                    textAlign: TextAlign.left,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            // X 轴：双行标签
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final p = points[idx];
                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (p.subLabel.isNotEmpty)
                          Text(
                            p.subLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.25,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: colors.divider, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          // ── 每个点上方的数值标签 ──
          extraLinesData: ExtraLinesData(horizontalLines: []),
        ),
        duration: const Duration(milliseconds: 200),
      ),
    );
  }
}
