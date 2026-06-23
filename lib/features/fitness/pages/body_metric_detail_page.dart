import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../fitness/providers/fitness_provider.dart';
import '../../../shared/providers/repository_providers.dart';

/// 身体数据详情页面
///
/// 展示身体数据趋势图和历史记录列表。
class BodyMetricDetailPage extends ConsumerStatefulWidget {
  const BodyMetricDetailPage({super.key});

  @override
  ConsumerState<BodyMetricDetailPage> createState() =>
      _BodyMetricDetailPageState();
}

class _BodyMetricDetailPageState extends ConsumerState<BodyMetricDetailPage> {
  int _selectedDays = 30;
  String _selectedMetric = 'weight';

  String get _selectedRange {
    if (_selectedDays <= 7) return 'week';
    if (_selectedDays <= 30) return 'month';
    return 'year';
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(bodyMetricsTrendProvider(_selectedDays));
    final colors = context.growthColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('身体数据趋势', style: AppTextStyles.pageTitle),
        centerTitle: false,
        backgroundColor: colors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/plan/fitness/body-metric/add'),
          ),
        ],
      ),
      body: metricsAsync.when(
        data: (metrics) {
          if (metrics.isEmpty) {
            return _buildEmptyState();
          }
          return _buildContent(metrics);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.growthColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monitor_weight_outlined, size: 64, color: colors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text(
            '还没有身体数据记录',
            style: AppTextStyles.cardTitle.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '点击右上角 + 开始记录',
            style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => context.push('/plan/fitness/body-metric/add'),
            icon: const Icon(Icons.add),
            label: const Text('记录身体数据'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.fitness,
              foregroundColor: colors.textOnAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<BodyMetric> metrics) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildTimeRangeSelector(),
        const SizedBox(height: AppSpacing.md),
        _buildMetricSelector(),
        const SizedBox(height: AppSpacing.lg),
        _buildTrendChart(metrics),
        const SizedBox(height: AppSpacing.lg),
        _buildLatestSummary(metrics),
        const SizedBox(height: AppSpacing.lg),
        _buildHistoryList(metrics),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    final colors = context.growthColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildRangeChip('week', '周', 7),
          _buildRangeChip('month', '月', 30),
          _buildRangeChip('year', '年', 365),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String range, String label, int days) {
    final isSelected = _selectedRange == range;
    final colors = context.growthColors;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedDays = days;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colors.fitness : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricSelector() {
    final colors = context.growthColors;
    final metrics = [
      ('weight', '体重', Icons.monitor_weight_outlined),
      ('bodyFat', '体脂率', Icons.water_drop_outlined),
      ('chest', '胸围', Icons.straighten),
      ('waist', '腰围', Icons.straighten),
      ('hip', '臀围', Icons.straighten),
      ('arm', '臂围', Icons.straighten),
      ('thigh', '大腿围', Icons.straighten),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: metrics.map((m) {
          final isSelected = _selectedMetric == m.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedMetric = m.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.fitness.withValues(alpha: 0.12)
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? colors.fitness : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      m.$3,
                      size: 16,
                      color: isSelected ? colors.fitness : colors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      m.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? colors.fitness
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendChart(List<BodyMetric> metrics) {
    final filteredMetrics = metrics.where((m) {
      switch (_selectedMetric) {
        case 'weight':
          return m.weight != null;
        case 'bodyFat':
          return m.bodyFat != null;
        case 'chest':
          return m.chest != null;
        case 'waist':
          return m.waist != null;
        case 'hip':
          return m.hip != null;
        case 'arm':
          return m.arm != null;
        case 'thigh':
          return m.thigh != null;
        default:
          return false;
      }
    }).toList();

    if (filteredMetrics.isEmpty) {
      final colors = context.growthColors;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Center(
          child: Text('暂无${_getMetricLabel()}数据', style: AppTextStyles.caption),
        ),
      );
    }

    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_getMetricLabel()}趋势', style: AppTextStyles.cardTitle),
              const Spacer(),
              Text(
                _getMetricUnit(),
                style: AppTextStyles.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRect(
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(filteredMetrics),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: colors.divider.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: AppTextStyles.caption,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          // X 值是距首日的天数差，转换回日期
                          if (filteredMetrics.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final firstDate = DateTime.parse(
                            filteredMetrics.first.recordDate,
                          );
                          final date = firstDate.add(
                            Duration(days: value.toInt()),
                          );
                          // 只在有数据的日期附近显示标签
                          final hasData = filteredMetrics.any((m) {
                            final mDate = DateTime.parse(m.recordDate);
                            return mDate.year == date.year &&
                                mDate.month == date.month &&
                                mDate.day == date.day;
                          });
                          if (!hasData && filteredMetrics.length > 7) {
                            return const SizedBox.shrink();
                          }
                          String mainLabel;
                          String subLabel = '';

                          if (_selectedRange == 'week') {
                            const dayNames = [
                              '周一',
                              '周二',
                              '周三',
                              '周四',
                              '周五',
                              '周六',
                              '周日',
                            ];
                            mainLabel = dayNames[date.weekday - 1];
                            subLabel = '${date.month}/${date.day}';
                          } else if (_selectedRange == 'month') {
                            final weekNum = ((date.day - 1) / 7).floor() + 1;
                            mainLabel = '第${_weekCn(weekNum)}周';
                            final weekStart = date.subtract(
                              Duration(days: date.weekday - 1),
                            );
                            final weekEnd = weekStart.add(
                              const Duration(days: 6),
                            );
                            subLabel =
                                '${weekStart.month}/${weekStart.day}-${weekEnd.month}/${weekEnd.day}';
                          } else {
                            mainLabel = '${date.month}月';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mainLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                if (subLabel.isNotEmpty)
                                  Text(
                                    subLabel,
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
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildSpots(filteredMetrics),
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: colors.fitness,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: colors.fitness,
                            strokeWidth: 2,
                            strokeColor: colors.card,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.fitness.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index >= 0 && index < filteredMetrics.length) {
                            final metric = filteredMetrics[index];
                            final value = _getMetricValue(metric);
                            return LineTooltipItem(
                              '${metric.recordDate}\n',
                              AppTextStyles.caption.copyWith(
                                color: colors.textOnAccent,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${value?.toStringAsFixed(1) ?? '--'} ${_getMetricUnit()}',
                                  style: TextStyle(
                                    color: colors.textOnAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildSpots(List<BodyMetric> metrics) {
    if (metrics.isEmpty) return [];
    final firstDate = DateTime.parse(metrics.first.recordDate);
    return List.generate(metrics.length, (index) {
      final value = _getMetricValue(metrics[index]);
      final date = DateTime.parse(metrics[index].recordDate);
      final dayDiff = date
          .difference(DateTime(firstDate.year, firstDate.month, firstDate.day))
          .inDays
          .toDouble();
      return FlSpot(dayDiff, value ?? 0);
    });
  }

  double? _getMetricValue(BodyMetric metric) {
    switch (_selectedMetric) {
      case 'weight':
        return metric.weight;
      case 'bodyFat':
        return metric.bodyFat;
      case 'chest':
        return metric.chest;
      case 'waist':
        return metric.waist;
      case 'hip':
        return metric.hip;
      case 'arm':
        return metric.arm;
      case 'thigh':
        return metric.thigh;
      default:
        return null;
    }
  }

  String _getMetricLabel() {
    switch (_selectedMetric) {
      case 'weight':
        return '体重';
      case 'bodyFat':
        return '体脂率';
      case 'chest':
        return '胸围';
      case 'waist':
        return '腰围';
      case 'hip':
        return '臀围';
      case 'arm':
        return '臂围';
      case 'thigh':
        return '大腿围';
      default:
        return '';
    }
  }

  String _getMetricUnit() {
    switch (_selectedMetric) {
      case 'weight':
        return 'kg';
      case 'bodyFat':
        return '%';
      case 'chest':
      case 'waist':
      case 'hip':
      case 'arm':
      case 'thigh':
        return 'cm';
      default:
        return '';
    }
  }

  double _calculateInterval(List<BodyMetric> metrics) {
    final values = metrics.map((m) => _getMetricValue(m)).whereType<double>();
    if (values.isEmpty) return 1;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    return range > 0 ? range / 4 : 1;
  }

  String _weekCn(int week) {
    const names = ['一', '二', '三', '四'];
    return week >= 1 && week <= 4 ? names[week - 1] : '$week';
  }

  Widget _buildLatestSummary(List<BodyMetric> metrics) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    final colors = context.growthColors;

    final latest = metrics.last;
    final previous = metrics.length > 1 ? metrics[metrics.length - 2] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('最新数据', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.md),
          _SummaryRow(
            label: '体重',
            value: latest.weight,
            unit: 'kg',
            previousValue: previous?.weight,
          ),
          _SummaryRow(
            label: '体脂率',
            value: latest.bodyFat,
            unit: '%',
            previousValue: previous?.bodyFat,
          ),
          _SummaryRow(
            label: '胸围',
            value: latest.chest,
            unit: 'cm',
            previousValue: previous?.chest,
          ),
          _SummaryRow(
            label: '腰围',
            value: latest.waist,
            unit: 'cm',
            previousValue: previous?.waist,
          ),
          _SummaryRow(
            label: '臀围',
            value: latest.hip,
            unit: 'cm',
            previousValue: previous?.hip,
          ),
          _SummaryRow(
            label: '臂围',
            value: latest.arm,
            unit: 'cm',
            previousValue: previous?.arm,
          ),
          _SummaryRow(
            label: '大腿围',
            value: latest.thigh,
            unit: 'cm',
            previousValue: previous?.thigh,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<BodyMetric> metrics) {
    final reversed = metrics.reversed.toList();
    final colors = context.growthColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('历史记录', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.md),
          ...reversed.map(
            (metric) => _HistoryTile(
              metric: metric,
              onDelete: () => _confirmDelete(metric),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BodyMetric metric) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除 ${metric.recordDate} 的身体数据吗？\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: context.growthColors.danger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(fitnessRepositoryProvider);
        await repo.deleteBodyMetric(metric.id);
        ref.invalidate(allBodyMetricsProvider);
        ref.invalidate(recentBodyMetricsProvider);
        ref.invalidate(latestBodyMetricProvider);
        ref.invalidate(bodyMetricsTrendProvider);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已删除')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('删除失败，请重试')));
        }
      }
    }
  }
}

// =============================================================================
// 摘要行
// =============================================================================

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.unit,
    this.previousValue,
  });

  final String label;
  final double? value;
  final String unit;
  final double? previousValue;

  @override
  Widget build(BuildContext context) {
    final change = value != null && previousValue != null
        ? value! - previousValue!
        : null;
    final colors = context.growthColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value != null ? '${value!.toStringAsFixed(1)} $unit' : '--',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.growthColors.textPrimary,
              ),
            ),
          ),
          if (change != null) _ChangeIndicator(change: change, unit: unit),
        ],
      ),
    );
  }
}

class _ChangeIndicator extends StatelessWidget {
  const _ChangeIndicator({required this.change, required this.unit});

  final double change;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final isPositive = change > 0;
    final colors = context.growthColors;
    final color = isPositive ? colors.danger : colors.success;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          '${change.abs().toStringAsFixed(1)} $unit',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 历史记录磁贴
// =============================================================================

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.metric, required this.onDelete});

  final BodyMetric metric;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.fitness.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.monitor_weight_outlined,
              color: colors.fitness,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.recordDate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(_buildSubtitle(), style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colors.danger, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (metric.weight != null) {
      parts.add('体重: ${metric.weight!.toStringAsFixed(1)}kg');
    }
    if (metric.bodyFat != null) {
      parts.add('体脂: ${metric.bodyFat!.toStringAsFixed(1)}%');
    }
    if (metric.waist != null) {
      parts.add('腰围: ${metric.waist!.toStringAsFixed(1)}cm');
    }
    return parts.isEmpty ? '无数据' : parts.join(' · ');
  }
}
