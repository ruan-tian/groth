import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import '../../../core/utils/growth_chart_utils.dart';

class GrowthChartLegendItem {
  const GrowthChartLegendItem({required this.color, required this.label});

  final Color color;
  final String label;
}

class GrowthChartRangeOption<T> {
  const GrowthChartRangeOption({required this.value, required this.label});

  final T value;
  final String label;
}

class GrowthChartRangeSelector<T> extends StatelessWidget {
  const GrowthChartRangeSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  final List<GrowthChartRangeOption<T>> options;
  final T selected;
  final Color color;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option.value == selected;
          return Expanded(
            child: Semantics(
              button: true,
              selected: isSelected,
              label: option.label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isSelected ? null : () => onChanged(option.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.24),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? colors.textOnAccent
                          : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class GrowthChartCard extends StatelessWidget {
  const GrowthChartCard({
    super.key,
    required this.title,
    required this.color,
    required this.child,
    this.icon,
    this.subtitle,
    this.legend = const [],
    this.rangeSelector,
    this.height,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color color;
  final Widget child;
  final List<GrowthChartLegendItem> legend;
  final Widget? rangeSelector;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.card.withValues(alpha: 0.98),
            Color.alphaBlend(color.withValues(alpha: 0.075), colors.card),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (rangeSelector != null) ...[
            const SizedBox(height: 12),
            rangeSelector!,
          ],
          if (legend.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: legend.map((item) => _LegendPill(item: item)).toList(),
            ),
          ],
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: SizedBox(
              key: ValueKey(
                title + (subtitle ?? '') + child.hashCode.toString(),
              ),
              height: height,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.item});

  final GrowthChartLegendItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          item.label,
          style: TextStyle(
            fontSize: 11,
            color: colors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class GrowthChartEmpty extends StatelessWidget {
  const GrowthChartEmpty({super.key, required this.color, this.label});

  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart_rounded, color: color.withValues(alpha: 0.45)),
          const SizedBox(height: 8),
          Text(
            label ?? '暂无数据',
            style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class GrowthAnimatedBarChart extends StatefulWidget {
  const GrowthAnimatedBarChart({
    super.key,
    required this.points,
    required this.color,
    required this.valueFormatter,
    this.axisFormatter,
    this.height = 240,
  });

  final List<GrowthChartPoint> points;
  final Color color;
  final String Function(double value) valueFormatter;
  final String Function(double value)? axisFormatter;
  final double height;

  @override
  State<GrowthAnimatedBarChart> createState() => _GrowthAnimatedBarChartState();
}

class _GrowthAnimatedBarChartState extends State<GrowthAnimatedBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    if (widget.points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: GrowthChartEmpty(color: widget.color),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final values = widget.points.map((point) => point.value).toList();
        final scale = ChartAxisScale.fromValues(
          values,
          minVisibleRange: values.length <= 7 ? 30 : 1,
          headroom: 0.28,
        );
        final density = ChartDensityPolicy.resolve(
          width: constraints.maxWidth,
          pointCount: widget.points.length,
        );
        final labels = ChartValueLabelPolicy.visibleIndexes(
          values,
          touchedIndex: _touchedIndex,
          maxLabels: constraints.maxWidth < 380 ? 2 : 3,
        );

        return RepaintBoundary(
          child: SizedBox(
            height: widget.height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 560),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) {
                return BarChart(
                  BarChartData(
                    minY: scale.min,
                    maxY: scale.max,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: _softGrid(colors, scale.interval),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: _barTooltipData(colors),
                      touchCallback: (event, response) {
                        if (event is FlPanEndEvent ||
                            event is FlLongPressEnd ||
                            response?.spot == null) {
                          if (_touchedIndex != null) {
                            setState(() => _touchedIndex = null);
                          }
                          return;
                        }
                        final index = response!.spot!.touchedBarGroupIndex;
                        if (_touchedIndex != index) {
                          setState(() => _touchedIndex = index);
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (!labels.contains(index) ||
                                index < 0 ||
                                index >= widget.points.length) {
                              return const SizedBox.shrink();
                            }
                            return _ValueBadge(
                              text: widget.valueFormatter(
                                widget.points[index].value,
                              ),
                              color: widget.color,
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: scale.interval,
                          getTitlesWidget: (value, meta) {
                            if (value <= scale.min) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              widget.axisFormatter?.call(value) ??
                                  formatCompactNumber(value),
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textTertiary,
                              ),
                              textAlign: TextAlign.right,
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= widget.points.length) {
                              return const SizedBox.shrink();
                            }
                            if (!ChartValueLabelPolicy.shouldShowAxisLabel(
                              index,
                              widget.points.length,
                              density.labelStep,
                            )) {
                              return const SizedBox.shrink();
                            }
                            final point = widget.points[index];
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    point.label,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  if (point.subLabel?.isNotEmpty == true)
                                    Text(
                                      point.subLabel!,
                                      style: TextStyle(
                                        fontSize: 9.5,
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
                    barGroups: List.generate(widget.points.length, (index) {
                      final point = widget.points[index];
                      final touched = _touchedIndex == index;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: point.value * progress,
                            width: density.barWidth,
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                widget.color.withValues(
                                  alpha: touched ? 0.92 : 0.48,
                                ),
                                widget.color.withValues(
                                  alpha: touched ? 1.0 : 0.76,
                                ),
                              ],
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: scale.max,
                              color: widget.color.withValues(alpha: 0.07),
                            ),
                          ),
                        ],
                        showingTooltipIndicators: touched ? [0] : [],
                      );
                    }),
                  ),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
          ),
        );
      },
    );
  }

  BarTouchTooltipData _barTooltipData(AppThemeColors colors) {
    return BarTouchTooltipData(
      getTooltipColor: (_) => colors.surfaceVariant,
      tooltipBorderRadius: BorderRadius.circular(10),
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipItem: (group, groupIndex, rod, rodIndex) {
        final point = widget.points[group.x];
        return BarTooltipItem(
          '${point.label}\n',
          TextStyle(
            color: colors.textOnAccent.withValues(alpha: 0.72),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(
              text: point.rawLabel ?? widget.valueFormatter(point.value),
              style: TextStyle(
                color: colors.textOnAccent,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        );
      },
    );
  }
}

class GrowthMultiLineChart extends StatefulWidget {
  const GrowthMultiLineChart({
    super.key,
    required this.series,
    required this.color,
    this.axisFormatter,
    this.height = 220,
  });

  final List<GrowthChartSeries> series;
  final Color color;
  final String Function(double value)? axisFormatter;
  final double height;

  @override
  State<GrowthMultiLineChart> createState() => _GrowthMultiLineChartState();
}

class _GrowthMultiLineChartState extends State<GrowthMultiLineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final visibleSeries = widget.series
        .where((series) => series.points.isNotEmpty)
        .toList();
    if (visibleSeries.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: GrowthChartEmpty(color: widget.color),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = visibleSeries
            .map((s) => s.points.length)
            .fold<int>(0, math.max);
        final density = ChartDensityPolicy.resolve(
          width: constraints.maxWidth,
          pointCount: count,
        );
        final scales = {
          for (final series in visibleSeries)
            series.name: ChartAxisScale.fromValues(
              series.points.map((point) => point.value),
              minVisibleRange: 1,
              headroom: 0.22,
            ),
        };

        return RepaintBoundary(
          child: SizedBox(
            height: widget.height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 620),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) {
                return LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (count - 1).clamp(1, 366).toDouble(),
                    minY: 0,
                    maxY: 1,
                    clipData: FlClipData.all(),
                    gridData: _softGrid(colors, 0.25),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchSpotThreshold: 22,
                      handleBuiltInTouches: true,
                      getTouchLineStart: (_, _) => 0,
                      getTouchLineEnd: (_, _) => double.infinity,
                      getTouchedSpotIndicator: (barData, spotIndexes) {
                        return spotIndexes.map((index) {
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: colors.border.withValues(alpha: 0.55),
                              strokeWidth: 1.2,
                              dashArray: const [4, 4],
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                    radius: 5.5,
                                    color: colors.card,
                                    strokeWidth: 2.8,
                                    strokeColor: barData.color ?? widget.color,
                                  ),
                            ),
                          );
                        }).toList();
                      },
                      touchCallback: (event, response) {
                        if (event is FlPanEndEvent ||
                            event is FlLongPressEnd ||
                            response?.lineBarSpots == null ||
                            response!.lineBarSpots!.isEmpty) {
                          if (_touchedIndex != null) {
                            setState(() => _touchedIndex = null);
                          }
                          return;
                        }
                        final index = response.lineBarSpots!.first.x.round();
                        if (_touchedIndex != index) {
                          setState(() => _touchedIndex = index);
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => colors.surfaceVariant,
                        tooltipBorderRadius: BorderRadius.circular(10),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        maxContentWidth: 220,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (spots) {
                          return spots
                              .map((spot) {
                                final series = visibleSeries[spot.barIndex];
                                final index = spot.x.round();
                                if (index < 0 ||
                                    index >= series.points.length) {
                                  return null;
                                }
                                final point = series.points[index];
                                return LineTooltipItem(
                                  '${series.name} ${point.rawLabel ?? series.valueFormatter(point.value)}',
                                  TextStyle(
                                    color: series.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                );
                              })
                              .whereType<LineTooltipItem>()
                              .toList();
                        },
                      ),
                    ),
                    titlesData: _lineTitles(
                      colors,
                      visibleSeries,
                      density,
                      widget.axisFormatter,
                    ),
                    lineBarsData: List.generate(visibleSeries.length, (sIndex) {
                      final series = visibleSeries[sIndex];
                      final scale = scales[series.name]!;
                      final revealCount = (series.points.length * progress)
                          .ceil()
                          .clamp(1, series.points.length);
                      final points = series.points
                          .take(revealCount)
                          .toList(growable: false);
                      return LineChartBarData(
                        spots: List.generate(points.length, (index) {
                          return FlSpot(
                            index.toDouble(),
                            scale.normalize(points[index].value),
                          );
                        }),
                        isCurved: true,
                        preventCurveOverShooting: true,
                        curveSmoothness: _curveSmoothness(points),
                        color: series.color,
                        barWidth: sIndex == 0 ? 2.8 : 2.3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: density.showDots || _touchedIndex != null,
                          getDotPainter: (spot, percent, barData, index) {
                            final touched = _touchedIndex == spot.x.round();
                            return FlDotCirclePainter(
                              radius: touched ? 5.5 : 3.0,
                              color: touched ? colors.card : series.color,
                              strokeColor: series.color,
                              strokeWidth: touched ? 2.8 : 1.2,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: sIndex == 0,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              series.color.withValues(alpha: 0.13),
                              series.color.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
          ),
        );
      },
    );
  }

  FlTitlesData _lineTitles(
    AppThemeColors colors,
    List<GrowthChartSeries> series,
    ChartDensityPolicy density,
    String Function(double value)? axisFormatter,
  ) {
    final primary = series.first;
    final primaryScale = ChartAxisScale.fromValues(
      primary.points.map((point) => point.value),
      minVisibleRange: 1,
      headroom: 0.22,
    );
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          interval: 0.25,
          getTitlesWidget: (value, meta) {
            if (value <= 0) return const SizedBox.shrink();
            final rawValue = primaryScale.denormalize(value);
            return Text(
              axisFormatter?.call(rawValue) ?? primary.valueFormatter(rawValue),
              style: TextStyle(fontSize: 10, color: colors.textTertiary),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (index < 0 || index >= primary.points.length) {
              return const SizedBox.shrink();
            }
            if (!ChartValueLabelPolicy.shouldShowAxisLabel(
              index,
              primary.points.length,
              density.labelStep,
            )) {
              return const SizedBox.shrink();
            }
            final point = primary.points[index];
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    point.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  if (point.subLabel?.isNotEmpty == true)
                    Text(
                      point.subLabel!,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: colors.textTertiary,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class GrowthSleepComboChart extends StatefulWidget {
  const GrowthSleepComboChart({
    super.key,
    required this.durationSeries,
    required this.qualitySeries,
    required this.durationColor,
    required this.qualityColor,
    required this.goalHours,
    this.height = 240,
  });

  final GrowthChartSeries durationSeries;
  final GrowthChartSeries qualitySeries;
  final Color durationColor;
  final Color qualityColor;
  final int goalHours;
  final double height;

  @override
  State<GrowthSleepComboChart> createState() => _GrowthSleepComboChartState();
}

class _GrowthSleepComboChartState extends State<GrowthSleepComboChart> {
  @override
  Widget build(BuildContext context) {
    final points = widget.durationSeries.points;
    if (points.isEmpty || points.every((point) => point.value <= 0)) {
      return SizedBox(
        height: widget.height,
        child: GrowthChartEmpty(color: widget.durationColor),
      );
    }
    final qualityByLabel = {
      for (final point in widget.qualitySeries.points) point.label: point,
    };
    final mergedQuality = points
        .map((point) => qualityByLabel[point.label]?.value ?? 0)
        .toList();

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          GrowthAnimatedBarChart(
            points: points,
            color: widget.durationColor,
            valueFormatter: widget.durationSeries.valueFormatter,
            height: widget.height,
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 42,
                  right: 8,
                  top: 40,
                  bottom: 42,
                ),
                child: GrowthMultiLineChart(
                  series: [
                    GrowthChartSeries(
                      name: widget.qualitySeries.name,
                      unit: widget.qualitySeries.unit,
                      color: widget.qualityColor,
                      points: List.generate(points.length, (index) {
                        return GrowthChartPoint(
                          label: points[index].label,
                          subLabel: points[index].subLabel,
                          value: mergedQuality[index],
                          rawLabel: widget.qualitySeries.valueFormatter(
                            mergedQuality[index],
                          ),
                        );
                      }),
                      valueFormatter: widget.qualitySeries.valueFormatter,
                    ),
                  ],
                  color: widget.qualityColor,
                  height: widget.height - 82,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GrowthHeatmapCalendar extends StatelessWidget {
  const GrowthHeatmapCalendar({
    super.key,
    required this.data,
    required this.startDate,
    required this.endDate,
    required this.baseColor,
    required this.maxColor,
    this.onDayTap,
  });

  final Map<DateTime, int> data;
  final DateTime startDate;
  final DateTime endDate;
  final Color baseColor;
  final Color maxColor;
  final ValueChanged<DateTime>? onDayTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final weeks = _buildWeeks(startDate, endDate);
    final maxValue = data.values.isEmpty ? 1 : data.values.reduce(math.max);
    return LayoutBuilder(
      builder: (context, constraints) {
        const weekdayWidth = 28.0;
        const gridGap = 5.0;
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - weekdayWidth - gridGap,
        );
        final visibleWeeks = constraints.maxWidth < 380 ? 16.0 : 18.0;
        final cell = (availableWidth / visibleWeeks).clamp(11.0, 17.0);
        final spacing = (cell * 0.20).clamp(2.0, 3.25);
        return RepaintBoundary(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeatmapMonthRow(
                        weeks: weeks,
                        cell: cell,
                        spacing: spacing,
                        leftOffset: weekdayWidth + gridGap,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeatmapWeekdayColumn(
                            cell: cell,
                            spacing: spacing,
                            width: weekdayWidth,
                          ),
                          const SizedBox(width: gridGap),
                          ...List.generate(weeks.length, (weekIndex) {
                            return Column(
                              children: List.generate(7, (dayIndex) {
                                final date = weeks[weekIndex][dayIndex];
                                if (date == null) {
                                  return SizedBox(
                                    width: cell + spacing,
                                    height: cell + spacing,
                                  );
                                }
                                final value = data[_normalize(date)] ?? 0;
                                final level = value <= 0
                                    ? 0
                                    : ((value / maxValue) * 4).ceil().clamp(
                                        1,
                                        4,
                                      );
                                final isToday = _sameDay(date, DateTime.now());
                                final isPeak = value > 0 && value == maxValue;
                                final delay = (weekIndex * 0.025).clamp(
                                  0.0,
                                  0.24,
                                );
                                final localProgress =
                                    ((progress - delay) / (1 - delay)).clamp(
                                      0.0,
                                      1.0,
                                    );
                                return Transform.scale(
                                  scale: 0.86 + 0.14 * localProgress,
                                  child: Opacity(
                                    opacity: localProgress,
                                    child: Tooltip(
                                      message:
                                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}  $value',
                                      child: GestureDetector(
                                        onTap: onDayTap == null
                                            ? null
                                            : () => onDayTap!(date),
                                        child: Container(
                                          width: cell,
                                          height: cell,
                                          margin: EdgeInsets.all(spacing / 2),
                                          decoration: BoxDecoration(
                                            color: _heatColor(level),
                                            borderRadius: BorderRadius.circular(
                                              cell * 0.28,
                                            ),
                                            border: isToday
                                                ? Border.all(
                                                    color: colors.primary,
                                                    width: 1.8,
                                                  )
                                                : isPeak
                                                ? Border.all(
                                                    color: maxColor.withValues(
                                                      alpha: 0.55,
                                                    ),
                                                    width: 1.2,
                                                  )
                                                : null,
                                            boxShadow: isToday || isPeak
                                                ? [
                                                    BoxShadow(
                                                      color: maxColor
                                                          .withValues(
                                                            alpha: 0.22,
                                                          ),
                                                      blurRadius: 6,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          }),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Color _heatColor(int level) {
    if (level <= 0) return baseColor;
    return Color.lerp(baseColor, maxColor, (0.18 + level * 0.205).clamp(0, 1))!;
  }

  static DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<List<DateTime?>> _buildWeeks(DateTime start, DateTime end) {
    final normalizedStart = _normalize(start);
    final normalizedEnd = _normalize(end);
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
}

class _HeatmapMonthRow extends StatelessWidget {
  const _HeatmapMonthRow({
    required this.weeks,
    required this.cell,
    required this.spacing,
    required this.leftOffset,
  });

  final List<List<DateTime?>> weeks;
  final double cell;
  final double spacing;
  final double leftOffset;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    var lastMonth = 0;
    return Padding(
      padding: EdgeInsets.only(left: leftOffset),
      child: Row(
        children: List.generate(weeks.length, (index) {
          final dates = weeks[index].whereType<DateTime>().toList();
          var text = '';
          if (dates.isNotEmpty) {
            DateTime? marker;
            for (final date in dates) {
              if (date.month != lastMonth && date.day <= 7) {
                marker = date;
                break;
              }
            }
            marker ??= dates.first.month != lastMonth ? dates.first : null;
            if (marker != null) {
              text = '${marker.month}月';
              lastMonth = marker.month;
            }
          }
          return SizedBox(
            width: cell + spacing,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: colors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HeatmapWeekdayColumn extends StatelessWidget {
  const _HeatmapWeekdayColumn({
    required this.cell,
    required this.spacing,
    required this.width,
  });

  final double cell;
  final double spacing;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    const labels = ['一', '', '三', '', '五', '', '日'];
    return Column(
      children: List.generate(7, (index) {
        return SizedBox(
          width: width,
          height: cell + spacing,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              labels[index],
              style: TextStyle(fontSize: 10, color: colors.textTertiary),
            ),
          ),
        );
      }),
    );
  }
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      constraints: const BoxConstraints(maxHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.08), colors.card),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color.withValues(alpha: 0.9),
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

FlGridData _softGrid(AppThemeColors colors, double interval) {
  return FlGridData(
    show: true,
    drawVerticalLine: false,
    horizontalInterval: interval,
    getDrawingHorizontalLine: (value) => FlLine(
      color: colors.border.withValues(alpha: 0.46),
      strokeWidth: 0.7,
      dashArray: const [4, 5],
    ),
  );
}

double _curveSmoothness(List<GrowthChartPoint> points) {
  if (points.length < 3) return 0.18;
  final values = points.map((point) => point.value).toList();
  final max = values.reduce(math.max);
  final min = values.reduce(math.min);
  if (max == min) return 0.12;
  var biggestDelta = 0.0;
  for (var i = 1; i < values.length; i++) {
    biggestDelta = math.max(biggestDelta, (values[i] - values[i - 1]).abs());
  }
  final ratio = biggestDelta / (max - min);
  if (ratio > 0.72) return 0.12;
  if (ratio > 0.42) return 0.22;
  return 0.34;
}
