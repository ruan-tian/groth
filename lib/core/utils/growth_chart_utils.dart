import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class GrowthChartPoint {
  const GrowthChartPoint({
    required this.label,
    required this.value,
    this.date,
    this.subLabel,
    this.rawLabel,
  });

  final String label;
  final double value;
  final DateTime? date;
  final String? subLabel;
  final String? rawLabel;
}

class GrowthChartSeries {
  const GrowthChartSeries({
    required this.name,
    required this.unit,
    required this.color,
    required this.points,
    required this.valueFormatter,
  });

  final String name;
  final String unit;
  final Color color;
  final List<GrowthChartPoint> points;
  final String Function(double value) valueFormatter;
}

class GrowthChartPalette {
  const GrowthChartPalette({
    required this.moduleColor,
    required this.accentColors,
    required this.gridColor,
    required this.labelColor,
    required this.surfaceColor,
  });

  final Color moduleColor;
  final List<Color> accentColors;
  final Color gridColor;
  final Color labelColor;
  final Color surfaceColor;
}

class ChartAxisScale {
  const ChartAxisScale({
    required this.min,
    required this.max,
    required this.interval,
  });

  final double min;
  final double max;
  final double interval;

  double normalize(double value) {
    final span = max - min;
    if (span <= 0) return 0.5;
    return ((value - min) / span).clamp(0.0, 1.0);
  }

  double denormalize(double value) => min + (max - min) * value;

  static ChartAxisScale fromValues(
    Iterable<num> values, {
    double minVisibleRange = 1,
    bool includeZero = true,
    double headroom = 0.16,
  }) {
    final list = values.map((value) => value.toDouble()).toList();
    if (list.isEmpty || list.every((value) => value == 0)) {
      final max = math.max(minVisibleRange, _niceCeil(minVisibleRange));
      return ChartAxisScale(min: 0, max: max, interval: _niceInterval(max));
    }

    var minValue = list.reduce(math.min);
    var maxValue = list.reduce(math.max);
    if (includeZero) {
      minValue = math.min(0, minValue);
    }

    var range = maxValue - minValue;
    if (range < minVisibleRange) {
      final center = (maxValue + minValue) / 2;
      range = minVisibleRange;
      minValue = includeZero ? 0 : center - range / 2;
      maxValue = center + range / 2;
    }

    final padding = range * headroom;
    final rawMin = includeZero ? math.min(0, minValue) : minValue - padding;
    final rawMax = maxValue + padding;
    final niceMax = _niceCeil(rawMax);
    final niceMin = includeZero ? 0.0 : _niceFloor(rawMin.toDouble());
    final interval = _niceInterval(niceMax - niceMin);
    return ChartAxisScale(min: niceMin, max: niceMax, interval: interval);
  }

  static double _niceCeil(double value) {
    if (value <= 0) return 1;
    final exponent = math.pow(10, math.log(value) / math.ln10.floor()).toDouble();
    final normalized = value / exponent;
    final nice = normalized <= 1
        ? 1.0
        : normalized <= 2
        ? 2.0
        : normalized <= 5
        ? 5.0
        : 10.0;
    return nice * exponent;
  }

  static double _niceFloor(double value) {
    if (value >= 0) return 0;
    return -_niceCeil(value.abs());
  }

  static double _niceInterval(double range) {
    if (range <= 0) return 1;
    final rough = range / 4;
    final exponent = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
    final normalized = rough / exponent;
    final nice = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    return nice * exponent;
  }
}

class ChartDensityPolicy {
  const ChartDensityPolicy({
    required this.labelStep,
    required this.barWidth,
    required this.showDots,
  });

  final int labelStep;
  final double barWidth;
  final bool showDots;

  static ChartDensityPolicy resolve({
    required double width,
    required int pointCount,
  }) {
    if (pointCount <= 7) {
      return ChartDensityPolicy(
        labelStep: 1,
        barWidth: width < 380 ? 18 : 22,
        showDots: true,
      );
    }
    if (pointCount <= 12) {
      return ChartDensityPolicy(
        labelStep: width < 380 ? 2 : 1,
        barWidth: width < 380 ? 12 : 16,
        showDots: true,
      );
    }
    if (pointCount <= 31) {
      return ChartDensityPolicy(
        labelStep: width < 380 ? 7 : 5,
        barWidth: width < 380 ? 7 : 9,
        showDots: false,
      );
    }
    return ChartDensityPolicy(
      labelStep: 1,
      barWidth: width < 380 ? 8 : 10,
      showDots: false,
    );
  }
}

class ChartValueLabelPolicy {
  const ChartValueLabelPolicy._();

  static Set<int> visibleIndexes(
    List<double> values, {
    int? touchedIndex,
    int maxLabels = 3,
  }) {
    final result = <int>{};
    if (values.isEmpty) return result;
    if (touchedIndex != null && touchedIndex >= 0 && touchedIndex < values.length) {
      result.add(touchedIndex);
    }

    var maxIndex = 0;
    var minIndex = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[maxIndex]) maxIndex = i;
      if (values[i] > 0 && (values[minIndex] == 0 || values[i] < values[minIndex])) {
        minIndex = i;
      }
    }
    result.add(maxIndex);
    result.add(values.length - 1);
    if (values.length <= 7 && values[minIndex] > 0) result.add(minIndex);

    return result.take(maxLabels).toSet();
  }

  static bool shouldShowAxisLabel(int index, int length, int step) {
    if (length <= 1) return true;
    return index == 0 || index == length - 1 || index % step == 0;
  }
}

String formatCompactNumber(double value, {String suffix = ''}) {
  final abs = value.abs();
  if (abs >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(abs >= 10000000 ? 0 : 1)}m$suffix';
  }
  if (abs >= 1000) {
    return '${(value / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}k$suffix';
  }
  if (value == value.roundToDouble()) return '${value.toInt()}$suffix';
  return '${value.toStringAsFixed(1)}$suffix';
}
