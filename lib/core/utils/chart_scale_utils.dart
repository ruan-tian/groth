/// 时长类图表统一缩放工具
///
/// 根据数据自动判断使用分钟 or 小时显示，提供统一的格式化方法。
class DurationChartScale {
  const DurationChartScale({
    required this.useHours,
    required this.maxY,
    required this.interval,
    required this.unit,
  });

  /// 是否使用小时模式
  final bool useHours;

  /// Y 轴最大值
  final double maxY;

  /// Y 轴间隔
  final double interval;

  /// 单位文本
  final String unit;

  /// 将分钟数转换为图表 Y 值
  double convertMinutes(num minutes) {
    final value = minutes.toDouble();
    return useHours ? value / 60.0 : value;
  }

  /// 格式化 Y 轴标签
  String formatAxisLabel(double value) {
    if (useHours) {
      if (value == value.roundToDouble()) {
        return '${value.toInt()}h';
      }
      return '${value.toStringAsFixed(1)}h';
    }
    return '${value.toInt()}';
  }

  /// 格式化 tooltip 数值
  String formatTooltipValue(double value) {
    if (useHours) {
      return '${value.toStringAsFixed(1)}h';
    }
    return '${value.toInt()}min';
  }
}

/// 根据分钟数据列表构建缩放配置
DurationChartScale buildDurationChartScale(List<num> minutesList) {
  if (minutesList.isEmpty) {
    return const DurationChartScale(
      useHours: false,
      maxY: 60,
      interval: 15,
      unit: 'min',
    );
  }

  final maxMinutes =
      minutesList.map((e) => e.toDouble()).reduce((a, b) => a > b ? a : b);

  final useHours = maxMinutes >= 180;

  if (useHours) {
    final maxHours = maxMinutes / 60.0;
    final maxY = _roundUpHours(maxHours * 1.15);

    final interval = maxY <= 4
        ? 1.0
        : maxY <= 8
            ? 2.0
            : maxY <= 12
                ? 3.0
                : 4.0;

    return DurationChartScale(
      useHours: true,
      maxY: maxY,
      interval: interval,
      unit: 'h',
    );
  }

  final maxY = _roundUpMinutes(maxMinutes * 1.15);

  final interval = maxY <= 60
      ? 15.0
      : maxY <= 180
          ? 30.0
          : 60.0;

  return DurationChartScale(
    useHours: false,
    maxY: maxY,
    interval: interval,
    unit: 'min',
  );
}

double _roundUpMinutes(double value) {
  if (value <= 30) return 30;
  if (value <= 60) return 60;
  if (value <= 120) return 120;
  if (value <= 180) return 180;
  if (value <= 240) return 240;
  if (value <= 360) return 360;
  if (value <= 480) return 480;
  if (value <= 600) return 600;
  if (value <= 720) return 720;
  return ((value / 120).ceil() * 120).toDouble();
}

double _roundUpHours(double value) {
  if (value <= 1) return 1;
  if (value <= 2) return 2;
  if (value <= 3) return 3;
  if (value <= 4) return 4;
  if (value <= 6) return 6;
  if (value <= 8) return 8;
  if (value <= 10) return 10;
  if (value <= 12) return 12;
  if (value <= 16) return 16;
  if (value <= 20) return 20;
  return ((value / 4).ceil() * 4).toDouble();
}
