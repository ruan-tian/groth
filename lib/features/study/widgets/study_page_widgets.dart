part of '../study_page.dart';

// ── 图表用格式化：30m / 1.5h ──
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

class _StudyBarChart extends StatefulWidget {
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
  State<_StudyBarChart> createState() => _StudyBarChartState();
}

class _StudyBarChartState extends State<_StudyBarChart> {
  int? _touchedIndex;
  DurationChartScale? _cachedScale;

  @override
  void didUpdateWidget(_StudyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.stats, oldWidget.stats)) {
      _cachedScale = null;
    }
  }

  static const _barColor = AppColors.study;
  static const _tooltipBg = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final minutesList = widget.stats.map((s) => s.value).toList();
    final scale = _cachedScale ??= buildDurationChartScale(minutesList);
    final yMax = scale.maxY;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.98),
            AppColors.study.withValues(alpha: 0.045),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: AppColors.study.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.study.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 顶部统计 ──
          Row(
            children: [
              _buildStat(
                '总时长',
                _formatMinutesCompact(
                  widget.stats.fold<int>(0, (s, b) => s + b.value),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              _buildStat(
                widget.range == 'year' ? '活跃月份' : '学习天数',
                widget.range == 'year'
                    ? '${widget.totalDays} 月'
                    : '${widget.totalDays} 天',
              ),
              const Spacer(),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // ── 柱状图 + 顶部标签 ──
          ClipRect(
            child: SizedBox(
              height: 240,
              child: RepaintBoundary(
                child: BarChart(
                  BarChartData(
                    maxY: yMax * 1.25, // extra space for value labels
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: _buildTouchData(),
                    titlesData: _buildTitles(scale, yMax),
                    gridData: _buildGrid(scale),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(widget.stats.length, (i) {
                      return _buildBarGroup(i, yMax);
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 触摸交互 ──
  BarTouchData _buildTouchData() {
    final minutesList = widget.stats.map((s) => s.value).toList();
    final scale = buildDurationChartScale(minutesList);

    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => _tooltipBg,
        tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final bar = widget.stats[group.x];
          final title = bar.label;
          return BarTooltipItem(
            '$title\n',
            const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: scale.formatTooltipValue(bar.value.toDouble()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.range == 'month' && bar.avgValue != null) ...[
                const TextSpan(text: '\n'),
                TextSpan(
                  text:
                      '日均 ${scale.formatTooltipValue(bar.avgValue!.toDouble())}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ],
          );
        },
      ),
      touchCallback: (event, response) {
        if (event is FlLongPressEnd || event is FlPanEndEvent) {
          setState(() => _touchedIndex = null);
        } else if (response?.spot != null) {
          final index = response!.spot!.touchedBarGroupIndex;
          if (index != _touchedIndex) {
            setState(() => _touchedIndex = index);
          }
        }
      },
    );
  }

  // ── 坐标轴标题 ──
  FlTitlesData _buildTitles(DurationChartScale scale, double yMax) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: widget.range == 'week' ? 44 : 36,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= widget.stats.length) {
              return const SizedBox.shrink();
            }
            return _buildBottomLabel(index);
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          interval: scale.interval,
          getTitlesWidget: (value, meta) {
            if (value == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                scale.formatAxisLabel(value),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.right,
              ),
            );
          },
        ),
      ),
      // ── 顶部数值标签 ──
      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= widget.stats.length) {
              return const SizedBox.shrink();
            }
            final bar = widget.stats[index];
            if (bar.value == 0) return const SizedBox.shrink();
            return _ValueBubble(
              value: _formatMinutesCompact(bar.value),
              avgValue: bar.avgValue != null
                  ? _formatMinutesCompact(bar.avgValue!)
                  : null,
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  // ── 网格线 ──
  FlGridData _buildGrid(DurationChartScale scale) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: scale.interval,
      getDrawingHorizontalLine: (value) => FlLine(
        color: AppColors.border.withValues(alpha: 0.6),
        strokeWidth: 1,
        dashArray: [4, 4],
      ),
    );
  }

  // ── 单个柱子 ──
  BarChartGroupData _buildBarGroup(int index, double yMax) {
    final bar = widget.stats[index];
    final isTouched = index == _touchedIndex;
    final barColor = _isHighlighted(index)
        ? _barColor
        : _barColor.withValues(alpha: 0.3);

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: bar.value.toDouble(),
          color: barColor,
          width: _barWidth,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: yMax,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
        ),
      ],
      showingTooltipIndicators: isTouched ? [0] : [],
    );
  }

  // ── 底部标签（双行：主标签 + 日期/范围）──
  Widget _buildBottomLabel(int index) {
    final bar = widget.stats[index];
    final highlighted = _isHighlighted(index);

    final mainStyle = TextStyle(
      fontSize: _bottomLabelFontSize,
      fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
      color: highlighted ? _barColor : AppColors.textPrimary,
    );
    final subStyle = TextStyle(
      fontSize: 10,
      color: highlighted ? _barColor : AppColors.textTertiary,
    );

    if (widget.range == 'week') {
      // Two lines: 周一 / 6/2
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(bar.label, style: mainStyle),
            if (bar.subLabel != null) Text(bar.subLabel!, style: subStyle),
          ],
        ),
      );
    }

    if (widget.range == 'month') {
      // Two lines: 第一周 / 6/1-6/7
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(bar.label, style: mainStyle),
            if (bar.subLabel != null && bar.subLabel!.isNotEmpty)
              Text(bar.subLabel!, style: subStyle),
          ],
        ),
      );
    }

    // Year: single line
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(bar.label, style: mainStyle),
    );
  }

  double get _bottomLabelFontSize {
    switch (widget.range) {
      case 'week':
        return 11;
      case 'month':
        return 10;
      case 'year':
        return 11;
      default:
        return 11;
    }
  }

  // ── 图例 ──
  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _barColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '学习时长',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ── 辅助方法 ──
  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  bool _isHighlighted(int index) {
    final bar = widget.stats[index];
    if (widget.range == 'week' && bar.date != null) {
      final now = DateTime.now();
      return bar.date!.year == now.year &&
          bar.date!.month == now.month &&
          bar.date!.day == now.day;
    }
    return false;
  }

  double get _barWidth {
    switch (widget.range) {
      case 'week':
        return 20;
      case 'month':
        return 28;
      case 'year':
        return 16;
      default:
        return 20;
    }
  }
}

// =============================================================================
// 柱顶数值气泡
// =============================================================================

class _ValueBubble extends StatelessWidget {
  const _ValueBubble({required this.value, this.avgValue});

  final String value;
  final String? avgValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.study,
            ),
          ),
        ),
        if (avgValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '日$avgValue',
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// 快捷操作卡片
// =============================================================================

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: color.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
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
    );
  }
}

// =============================================================================
// 科目分布卡片（左饼图 + 右图例）
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
            Colors.white.withValues(alpha: 0.98),
            AppColors.study.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: AppColors.study.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.study.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 左侧：饼图 ──
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
                      sections: _buildSections(top5, total),
                    ),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.linear,
                  ),
                ),
                // 中心总时长
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatHours(total),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '总时长',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ── 右侧：图例列表 ──
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(top5.length, (index) {
                final entry = top5[index];
                final color = _getSubjectColor(entry.key);
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
                        // 彩色圆点
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
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 进度条
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: entry.value / total,
                              minHeight: 6,
                              backgroundColor: color.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 时长 + 百分比
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatMinutes(entry.value),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary,
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
    List<MapEntry<String, int>> entries,
    int total,
  ) {
    return List.generate(entries.length, (index) {
      final isTouched = _touchedIndex == index;
      final entry = entries[index];
      final color = _getSubjectColor(entry.key);

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '',
        radius: isTouched ? 38 : 32,
        borderSide: isTouched
            ? BorderSide(color: Colors.white, width: 2)
            : BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1),
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

  Color _getSubjectColor(String subject) {
    return _subjectColors[subject] ?? AppColors.study;
  }
}
