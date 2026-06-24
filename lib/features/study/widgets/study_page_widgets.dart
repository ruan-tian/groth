part of '../study_page.dart';

//  图表用格式化?0m / 1.5h
String _formatMinutesCompact(int minutes) {
  if (minutes <= 0) return '0m';
  if (minutes < 60) return '${minutes}m';
  final h = minutes / 60;
  // 1 decimal, drop trailing .0
  return h == h.roundToDouble() ? '${h.round()}h' : '${h.toStringAsFixed(1)}h';
}

// =============================================================================
// 柱状图数据模型
// =============================================================================

class _BarData {
  const _BarData({
    required this.label,
    required this.value,
    this.date,
    this.subLabel,
    this.totalValue,
    this.avgValue,
  });

  final String label;
  final int value;
  final DateTime? date;

  /// Second line for x-axis (e.g. "6/2" or "6/1-6/7")
  final String? subLabel;

  /// Total minutes for month/week aggregation
  final int? totalValue;

  /// Daily average for month/week aggregation
  final int? avgValue;
}

// =============================================================================
// 学习趋势柱状图（fl_chart，支持周/?年）
// =============================================================================

class _StudyBarChart extends StatelessWidget {
  const _StudyBarChart({
    required this.stats,
    required this.totalHours,
    required this.totalDays,
    required this.range,
  });

  final List<_BarData> stats;
  final String totalHours;
  final int totalDays;
  final String range; // 'week' | 'month' | 'year'

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final totalMinutes = stats.fold<int>(0, (sum, bar) => sum + bar.value);
    final activeLabel = range == 'year' ? '活跃月份' : '学习天数';
    final activeUnit = range == 'year' ? '月' : '天';
    final points = stats
        .map((bar) {
          final rawLabel = range == 'month' && bar.avgValue != null
              ? '${_formatMinutesCompact(bar.value)} · 日均 ${_formatMinutesCompact(bar.avgValue!)}'
              : _formatMinutesCompact(bar.value);
          return GrowthChartPoint(
            label: bar.label,
            subLabel: bar.subLabel,
            date: bar.date,
            value: bar.value.toDouble(),
            rawLabel: rawLabel,
          );
        })
        .toList(growable: false);

    return GrowthChartCard(
      title: '学习趋势',
      subtitle:
          '总时长 ${_formatMinutesCompact(totalMinutes)} · $activeLabel $totalDays$activeUnit',
      icon: Icons.auto_graph_rounded,
      color: colors.study,
      legend: [GrowthChartLegendItem(color: colors.study, label: '学习时长')],
      child: GrowthAnimatedBarChart(
        key: ValueKey('study_${range}_${points.length}_$totalMinutes'),
        points: points,
        color: colors.study,
        valueFormatter: (value) => _formatMinutesCompact(value.round()),
        axisFormatter: (value) => _formatMinutesCompact(value.round()),
        height: 244,
      ),
    );
  }

  //  触摸交互
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 绉戠洰鍒嗗竷鍗＄墖锛堝乏楗煎浘 + 鍙冲浘渚嬶級
// =============================================================================

class _SubjectDistributionCard extends StatefulWidget {
  const _SubjectDistributionCard({required this.dist});

  final Map<String, int> dist;

  @override
  State<_SubjectDistributionCard> createState() =>
      _SubjectDistributionCardState();
}

class _DistributionData {
  const _DistributionData({
    required this.sorted,
    required this.total,
    required this.top5,
  });

  final List<MapEntry<String, int>> sorted;
  final int total;
  final List<MapEntry<String, int>> top5;
}

class _SubjectDistributionCardState extends State<_SubjectDistributionCard> {
  int _touchedIndex = -1;
  _DistributionData? _cachedDistData;

  @override
  void didUpdateWidget(_SubjectDistributionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.dist, oldWidget.dist)) {
      _cachedDistData = null;
    }
  }

  _DistributionData _computeDistributionData() {
    final total = widget.dist.values.fold<int>(0, (sum, v) => sum + v);
    final sorted = widget.dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();
    return _DistributionData(sorted: sorted, total: total, top5: top5);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final dist = _cachedDistData ??= _computeDistributionData();
    final total = dist.total;
    final top5 = dist.top5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.card.withValues(alpha: 0.98),
            colors.softBlue.withValues(alpha: 0.42),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //  左侧：饼?
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RepaintBoundary(
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 42,
                      sections: _buildSections(context, top5, total),
                    ),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.linear,
                  ),
                ),
                // 涓績鎬绘椂闀?
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatHours(total),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '总时长',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          //  右侧：图例列?
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(top5.length, (index) {
                final entry = top5[index];
                final color = _colorByIndex(context.growthColors, index);
                final percent = total > 0
                    ? (entry.value / total * 100).round()
                    : 0;
                final isSelected = _touchedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _touchedIndex = _touchedIndex == index ? -1 : index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        // 褰╄壊鍦嗙偣
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 10 : 8,
                          height: isSelected ? 10 : 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 科目名
                        SizedBox(
                          width: 36,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 杩涘害鏉?
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: total > 0 ? entry.value / total : 0.0,
                              minHeight: 6,
                              backgroundColor: color.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 鏃堕暱 + 鐧惧垎姣?
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatMinutes(entry.value),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    BuildContext context,
    List<MapEntry<String, int>> entries,
    int total,
  ) {
    final colors = context.growthColors;
    return List.generate(entries.length, (index) {
      final isTouched = _touchedIndex == index;
      final entry = entries[index];
      final color = _colorByIndex(context.growthColors, index);

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '',
        radius: isTouched ? 38 : 32,
        borderSide: isTouched
            ? BorderSide(color: colors.card, width: 2)
            : BorderSide(color: colors.card.withValues(alpha: 0.52), width: 1),
      );
    });
  }

  String _formatHours(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '$h.${(m * 10 / 60).round()}h' : '${h}h';
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h${m}m' : '${h}h';
  }
}
