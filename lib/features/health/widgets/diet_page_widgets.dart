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
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      final weekEnd = w == 3
          ? monthEnd
          : weekStart.add(const Duration(days: 6));
      final actualEnd = weekEnd.isAfter(today) ? today : weekEnd;

      int totalCal = 0;
      int totalWater = 0;
      if (!actualEnd.isBefore(weekStart)) {
        var d = weekStart;
        while (!d.isAfter(actualEnd)) {
          final key = DateFormat('yyyy-MM-dd').format(d);
          totalCal += widget.calorieMap[key] ?? 0;
          totalWater += widget.waterMap[key] ?? 0;
          d = d.add(const Duration(days: 1));
        }
      }

      final startLabel = DateFormat('M/d').format(weekStart);
      final endLabel = DateFormat('M/d').format(weekEnd);

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
    return GrowthMultiLineChart(
      key: ValueKey('diet_${widget.days}_${points.length}'),
      color: calorieColor,
      height: 224,
      series: [
        GrowthChartSeries(
          name: '卡路里',
          unit: 'kcal',
          color: calorieColor,
          points: points
              .map(
                (point) => GrowthChartPoint(
                  label: point.label,
                  subLabel: point.subLabel,
                  value: point.calorie.toDouble(),
                  rawLabel: _formatCalorie(point.calorie),
                ),
              )
              .toList(growable: false),
          valueFormatter: (value) => _formatCalorie(value.round()),
        ),
        GrowthChartSeries(
          name: '饮水',
          unit: 'ml',
          color: waterColor,
          points: points
              .map(
                (point) => GrowthChartPoint(
                  label: point.label,
                  subLabel: point.subLabel,
                  value: point.water.toDouble(),
                  rawLabel: _formatWater(point.water),
                ),
              )
              .toList(growable: false),
          valueFormatter: (value) => _formatWater(value.round()),
        ),
      ],
    );
  }
}

class _DietEntryCard extends StatelessWidget {
  const _DietEntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: colors.border),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.smd),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
