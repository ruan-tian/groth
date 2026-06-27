/// Growth OS 双Y轴坐标空间变换器
///
/// 用于在同一个 fl_chart 图表中显示两个不同量程的数据系列。
/// fl_chart 原生不支持双Y轴，因此需要将次轴数据线性映射到主轴坐标空间。
///
/// 原理：设主轴范围 [pMin, pMax]，次轴范围 [sMin, sMax]，
/// 对于次轴数据 y_s，映射到主轴空间的公式为：
///   y' = pMin + ((y_s - sMin) / (sMax - sMin)) * (pMax - pMin)
///
/// 反向映射（用于右侧标签还原）：
///   y_s = sMin + ((y' - pMin) / (pMax - pMin)) * (sMax - sMin)
///
/// 使用方式：
/// ```dart
/// final transformer = DualYAxisTransformer(
///   pMin: 0, pMax: 180,   // 主轴（左）：心率
///   sMin: 25, sMax: 65,   // 次轴（右）：摄氧量
/// );
///
/// // 将次轴数据映射到主轴空间
/// final mappedY = transformer.toPrimary(vo2Value);
///
/// // 将主轴坐标还原为次轴标签
/// final realVo2 = transformer.toSecondary(axisValue);
/// ```
class DualYAxisTransformer {
  const DualYAxisTransformer({
    required this.pMin,
    required this.pMax,
    required this.sMin,
    required this.sMax,
  });

  /// 主轴（左Y轴）最小值
  final double pMin;

  /// 主轴（左Y轴）最大值
  final double pMax;

  /// 次轴（右Y轴）最小值
  final double sMin;

  /// 次轴（右Y轴）最大值
  final double sMax;

  /// 正向映射：将次轴的真实数据转换为主轴的虚拟坐标
  ///
  /// 用于将次轴数据点绘制在主轴坐标系中。
  double toPrimary(double value) {
    final range = sMax - sMin;
    if (range == 0) return pMin;
    return pMin + ((value - sMin) / range) * (pMax - pMin);
  }

  /// 逆向映射：将主轴的虚拟坐标还原为次轴的真实标签
  ///
  /// 用于在右侧 SideTitles 中显示次轴的真实数值。
  double toSecondary(double value) {
    final range = pMax - pMin;
    if (range == 0) return sMin;
    return sMin + ((value - pMin) / range) * (sMax - sMin);
  }

  /// 格式化次轴标签（用于右侧 SideTitles）
  ///
  /// [value] 是主轴坐标系中的值，需要逆向映射为次轴真实值。
  /// [formatter] 自定义格式化函数，默认保留1位小数。
  String formatSecondaryLabel(
    double value, {
    String Function(double)? formatter,
  }) {
    final realValue = toSecondary(value);
    if (formatter != null) return formatter(realValue);
    return realValue.toStringAsFixed(1);
  }
}
