import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

// ─── 睡眠组合图表（fl_chart 柱状图+折线图）──────────────────────────────────

class SleepCombinedChart extends StatefulWidget {
  const SleepCombinedChart({
    super.key,
    required this.durationData,
    required this.qualityData,
    required this.durationColor,
    required this.qualityColor,
    required this.goalHours,
    required this.selectedRange,
  });

  final List<Map> durationData;
  final List<Map> qualityData;
  final Color durationColor;
  final Color qualityColor;
  final int goalHours;
  final int selectedRange;

  @override
  State<SleepCombinedChart> createState() => _SleepCombinedChartState();
}

class _SleepCombinedChartState extends State<SleepCombinedChart> {
  int? _touchedBarIndex;
  int? _touchedLineIndex;
  List<Map<String, dynamic>>? _cachedProcessedData;

  @override
  void didUpdateWidget(SleepCombinedChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.durationData, oldWidget.durationData) ||
        !identical(widget.qualityData, oldWidget.qualityData) ||
        widget.selectedRange != oldWidget.selectedRange) {
      _cachedProcessedData = null;
    }
  }

  String _formatDurationValue(double minutes) {
    if (minutes < 60) return '${minutes.round()}m';
    final h = minutes / 60;
    return '${h.toStringAsFixed(h == h.roundToDouble() ? 0 : 1)}h';
  }

  String _formatQualityValue(double quality) {
    return '${quality.toStringAsFixed(1)}分';
  }

  List<Map<String, dynamic>> _mergeData() {
    final map = <String, Map<String, dynamic>>{};
    for (final d in widget.durationData) {
      final date = d['date'] as String? ?? '';
      map[date] = {'date': date, 'duration': d['duration'], 'quality': null};
    }
    for (final q in widget.qualityData) {
      final date = q['date'] as String? ?? '';
      if (map.containsKey(date)) {
        map[date]!['quality'] = q['quality'];
      } else {
        map[date] = {'date': date, 'duration': null, 'quality': q['quality']};
      }
    }
    return map.values.toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  List<Map<String, dynamic>> _aggregateByWeek(
    List<Map<String, dynamic>> daily,
  ) {
    if (daily.isEmpty) return [];
    final weeks = <Map<String, dynamic>>[];
    for (var i = 0; i < daily.length; i += 7) {
      final chunk = daily.sublist(i, (i + 7).clamp(0, daily.length));
      final durValues = chunk
          .map((e) => (e['duration'] as num?)?.toDouble())
          .where((v) => v != null)
          .cast<double>()
          .toList();
      final qualValues = chunk
          .map((e) => (e['quality'] as num?)?.toDouble())
          .where((v) => v != null)
          .cast<double>()
          .toList();
      final startDate = chunk.first['date'] as String;
      final endDate = chunk.last['date'] as String;
      weeks.add({
        'date': startDate,
        'endDate': endDate,
        'duration': durValues.isNotEmpty
            ? durValues.reduce((a, b) => a + b) / durValues.length
            : 0.0,
        'quality': qualValues.isNotEmpty
            ? qualValues.reduce((a, b) => a + b) / qualValues.length
            : null,
      });
    }
    return weeks;
  }

  List<Map<String, dynamic>> _aggregateByMonth(
    List<Map<String, dynamic>> daily,
  ) {
    if (daily.isEmpty) return [];
    final monthMap = <String, List<Map<String, dynamic>>>{};
    for (final d in daily) {
      final date = d['date'] as String? ?? '';
      if (date.length >= 7) {
        final key = date.substring(0, 7);
        monthMap.putIfAbsent(key, () => []).add(d);
      }
    }
    final sortedKeys = monthMap.keys.toList()..sort();
    return sortedKeys.map((key) {
      final chunk = monthMap[key]!;
      final durValues = chunk
          .map((e) => (e['duration'] as num?)?.toDouble())
          .where((v) => v != null)
          .cast<double>()
          .toList();
      final qualValues = chunk
          .map((e) => (e['quality'] as num?)?.toDouble())
          .where((v) => v != null)
          .cast<double>()
          .toList();
      return {
        'date': key,
        'duration': durValues.isNotEmpty
            ? durValues.reduce((a, b) => a + b) / durValues.length
            : 0.0,
        'quality': qualValues.isNotEmpty
            ? qualValues.reduce((a, b) => a + b) / qualValues.length
            : null,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _processData() {
    final merged = _mergeData();
    if (widget.selectedRange == 30) return _aggregateByWeek(merged);
    if (widget.selectedRange == 365) return _aggregateByMonth(merged);
    return merged;
  }

  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  String _weekMainLabel(Map<String, dynamic> d) {
    final date = d['date'] as String? ?? '';
    if (date.length < 10) return '';
    final dt = DateTime.tryParse(date);
    if (dt == null) return date.substring(8, 10);
    return _weekdays[dt.weekday - 1];
  }

  String _weekSubLabel(Map<String, dynamic> d) {
    final date = d['date'] as String? ?? '';
    if (date.length < 10) return date;
    final dt = DateTime.tryParse(date);
    if (dt == null) return date.substring(8, 10);
    return '${dt.month}/${dt.day}';
  }

  String _monthMainLabel(int index) {
    const labels = ['第一周', '第二周', '第三周', '第四周', '第五周'];
    return index < labels.length ? labels[index] : '第${index + 1}周';
  }

  String _monthSubLabel(Map<String, dynamic> d) {
    final start = d['date'] as String? ?? '';
    final end = d['endDate'] as String? ?? '';
    String fmt(String s) {
      if (s.length < 10) return s;
      final dt = DateTime.tryParse(s);
      if (dt == null) return s.substring(5, 10);
      return '${dt.month}/${dt.day}';
    }

    return '${fmt(start)}-${fmt(end)}';
  }

  String _yearMainLabel(Map<String, dynamic> d) {
    final date = d['date'] as String? ?? '';
    if (date.length < 7) return date;
    final month = int.tryParse(date.substring(5, 7)) ?? 0;
    return '$month月';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final data = _cachedProcessedData ??= _processData();
    if (data.isEmpty) return const SizedBox.shrink();

    final maxY = (widget.goalHours).toDouble() + 1;
    final n = data.length;

    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (i) {
              final value = maxY - (maxY / 4) * i;
              return Text(
                value == value.roundToDouble()
                    ? '${value.toInt()}h'
                    : '${value.toStringAsFixed(1)}h',
                style: TextStyle(fontSize: 11, color: widget.durationColor),
              );
            }),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRect(
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      right: 4,
                      top: 8,
                      bottom: 0,
                    ),
                    child: RepaintBoundary(
                      child: BarChart(
                        BarChartData(
                          maxY: maxY,
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(
                            enabled: true,
                            longPressDuration: const Duration(
                              milliseconds: 100,
                            ),
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => widget.durationColor,
                              tooltipBorderRadius: BorderRadius.circular(8),
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    final d = data[group.x];
                                    final dur =
                                        (d['duration'] as num?)?.toDouble() ??
                                        0;
                                    final qual = (d['quality'] as num?)
                                        ?.toDouble();
                                    final lines = <String>[
                                      _formatDurationValue(dur),
                                    ];
                                    if (qual != null) {
                                      lines.add(_formatQualityValue(qual));
                                    }
                                    return BarTooltipItem(
                                      lines.join('\n'),
                                      TextStyle(
                                        color: colors.textOnAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                            ),
                            touchCallback: (event, response) {
                              setState(() {
                                if (response != null &&
                                    response.spot != null &&
                                    event is FlLongPressEnd) {
                                  _touchedBarIndex = null;
                                } else if (response != null &&
                                    response.spot != null) {
                                  _touchedBarIndex =
                                      response.spot!.touchedBarGroupIndex;
                                }
                              });
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= n) {
                                    return const SizedBox.shrink();
                                  }
                                  final d = data[idx];
                                  String main;
                                  String sub;
                                  if (widget.selectedRange == 7) {
                                    main = _weekMainLabel(d);
                                    sub = _weekSubLabel(d);
                                  } else if (widget.selectedRange == 30) {
                                    main = _monthMainLabel(idx);
                                    sub = _monthSubLabel(d);
                                  } else {
                                    main = _yearMainLabel(d);
                                    sub = '';
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          main,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                        if (sub.isNotEmpty)
                                          Text(
                                            sub,
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
                            horizontalInterval: maxY / 4,
                            getDrawingHorizontalLine: (value) =>
                                FlLine(color: colors.divider, strokeWidth: 0.5),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(n, (i) {
                            final dur =
                                (data[i]['duration'] as num?)?.toDouble() ?? 0;
                            final hours = dur / 60;
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: hours,
                                  color: widget.durationColor.withValues(
                                    alpha: _touchedBarIndex == i ? 1.0 : 0.75,
                                  ),
                                  width: n > 14 ? 8 : (n > 7 ? 12 : 20),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxY,
                                    color: widget.durationColor.withValues(
                                      alpha: 0.06,
                                    ),
                                  ),
                                ),
                              ],
                              showingTooltipIndicators: _touchedBarIndex == i
                                  ? [0]
                                  : [],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      right: 4,
                      top: 8,
                      bottom: 0,
                    ),
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 5.5,
                        clipData: FlClipData.all(),
                        lineTouchData: LineTouchData(
                          enabled: true,
                          longPressDuration: const Duration(milliseconds: 100),
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => widget.qualityColor,
                            tooltipBorderRadius: BorderRadius.circular(8),
                            getTooltipItems: (spots) {
                              return spots.map((spot) {
                                final d = spot.x.toInt() < data.length
                                    ? data[spot.x.toInt()]
                                    : null;
                                final dur = d != null
                                    ? _formatDurationValue(
                                        (d['duration'] as num?)?.toDouble() ??
                                            0,
                                      )
                                    : '';
                                return LineTooltipItem(
                                  '${_formatQualityValue(spot.y)}${dur.isNotEmpty ? '\n$dur' : ''}',
                                  TextStyle(
                                    color: colors.textOnAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                          touchCallback: (event, response) {
                            setState(() {
                              if (event is FlLongPressEnd) {
                                _touchedLineIndex = null;
                              } else if (response != null &&
                                  response.lineBarSpots != null &&
                                  response.lineBarSpots!.isNotEmpty) {
                                _touchedLineIndex =
                                    response.lineBarSpots!.first.spotIndex;
                              }
                            });
                          },
                        ),
                        titlesData: FlTitlesData(show: false),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(n, (i) {
                              final quality = (data[i]['quality'] as num?)
                                  ?.toDouble();
                              return FlSpot(i.toDouble(), quality ?? 0);
                            }),
                            isCurved: true,
                            preventCurveOverShooting: true,
                            curveSmoothness: 0.3,
                            color: widget.qualityColor,
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) {
                                final isTouched = _touchedLineIndex == index;
                                return FlDotCirclePainter(
                                  radius: isTouched ? 5 : 3.5,
                                  color: colors.card,
                                  strokeWidth: isTouched ? 3 : 2,
                                  strokeColor: widget.qualityColor,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 250),
                    ),
                  ),
                  CustomPaint(
                    size: Size.infinite,
                    painter: _ChartLabelPainter(
                      data: data,
                      maxY: maxY,
                      barColor: widget.durationColor,
                      lineColor: widget.qualityColor,
                      touchedBarIndex: _touchedBarIndex,
                      touchedLineIndex: _touchedLineIndex,
                      formatDuration: _formatDurationValue,
                      formatQuality: _formatQualityValue,
                      labelBackgroundColor: colors.card.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(6, (i) {
              return Text(
                '${5 - i}',
                style: TextStyle(fontSize: 11, color: widget.qualityColor),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ChartLabelPainter extends CustomPainter {
  _ChartLabelPainter({
    required this.data,
    required this.maxY,
    required this.barColor,
    required this.lineColor,
    required this.touchedBarIndex,
    required this.touchedLineIndex,
    required this.formatDuration,
    required this.formatQuality,
    required this.labelBackgroundColor,
  });

  final List<Map<String, dynamic>> data;
  final double maxY;
  final Color barColor;
  final Color lineColor;
  final int? touchedBarIndex;
  final int? touchedLineIndex;
  final String Function(double) formatDuration;
  final String Function(double) formatQuality;
  final Color labelBackgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final n = data.length;
    if (n == 0) return;

    const chartPadLeft = 4.0;
    const chartPadRight = 4.0;
    const chartPadTop = 8.0;
    const chartPadBottom = 0.0;

    final chartW = size.width - chartPadLeft - chartPadRight;
    final chartH = size.height - chartPadTop - chartPadBottom;
    final barWidth = n > 14 ? 8.0 : (n > 7 ? 12.0 : 20.0);
    final extraSpace = (chartW - n * barWidth) / n;
    final eachSpace = barWidth + extraSpace;

    double valueToY(double value) {
      final ratio = (value / maxY).clamp(0.0, 1.0);
      return chartPadTop + chartH * (1 - ratio);
    }

    for (var i = 0; i < n; i++) {
      final centerX = chartPadLeft + eachSpace * 0.5 + i * eachSpace;
      final dur = (data[i]['duration'] as num?)?.toDouble() ?? 0;
      final qual = (data[i]['quality'] as num?)?.toDouble();
      final hours = dur / 60;
      final isBarTouched = touchedBarIndex == i;
      final isLineTouched = touchedLineIndex == i;
      final barTopY = valueToY(hours);

      _drawLabel(
        canvas,
        centerX,
        barTopY - (isBarTouched ? 14 : 12),
        formatDuration(dur),
        barColor,
        bold: isBarTouched,
      );

      if (qual != null) {
        final pointY = valueToY(qual * maxY / 5.5);
        _drawLabel(
          canvas,
          centerX,
          pointY - (isLineTouched ? 16 : 14),
          formatQuality(qual),
          lineColor,
          bold: isLineTouched,
        );
      }
    }
  }

  void _drawLabel(
    Canvas canvas,
    double cx,
    double cy,
    String text,
    Color color, {
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = cx - tp.width / 2;
    final dy = cy - tp.height / 2;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dx - 3, dy - 1, tp.width + 6, tp.height + 2),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, Paint()..color = labelBackgroundColor);
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _ChartLabelPainter old) =>
      touchedBarIndex != old.touchedBarIndex ||
      touchedLineIndex != old.touchedLineIndex ||
      data != old.data;
}
