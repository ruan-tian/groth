part of '../study_page.dart';

//  图表用格式化: 0m / 1.5h
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
// 学习趋势柱状图（fl_chart，支持周/月/年）
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
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: colors.border),
            boxShadow: AppShadows.sm,
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
// 科目分布卡片（左环形图 + 右图例）— 蓝色同色系
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: const Color(0xFFEEF1FA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF485CB4).withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧：环形图
          _buildDonutChart(context, top5, total, colors),
          const SizedBox(width: 24),
          // 右侧：图例列表
          Expanded(
            child: _buildLegend(context, top5, total, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(
    BuildContext context,
    List<MapEntry<String, int>> entries,
    int total,
    AppThemeColors colors,
  ) {
    return SizedBox(
      width: 150,
      height: 150,
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
                centerSpaceRadius: 48,
                sections: _buildSections(context, entries, total),
              ),
              duration: const Duration(milliseconds: 150),
              curve: Curves.linear,
            ),
          ),
          // 中心文字
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatMinutes(total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '总学习',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    List<MapEntry<String, int>> entries,
    int total,
    AppThemeColors colors,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final isUncategorized = entry.key == '未分类';
        final color = isUncategorized
            ? _uncategorizedColor()
            : _colorByIndex(colors, index);
        final percent =
            total > 0 ? (entry.value / total * 100).round() : 0;
        final isSelected = _touchedIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _touchedIndex = _touchedIndex == index ? -1 : index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // 科目名
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    // 时长
                    Text(
                      _formatMinutes(entry.value),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 胶囊进度条
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? entry.value / total : 0.0,
                          minHeight: 6,
                          backgroundColor: color.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
      final isUncategorized = entry.key == '未分类';
      final color = isUncategorized
          ? _uncategorizedColor()
          : _colorByIndex(colors, index);

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '',
        radius: isTouched ? 30 : 27,
        borderSide: BorderSide(
          color: colors.card.withValues(alpha: 0.8),
          width: 1.5,
        ),
      );
    });
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h${m}m' : '${h}h';
  }
}
