part of '../fitness_page.dart';

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.softOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colors.fitness),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FitnessTrendChart extends StatelessWidget {
  const _FitnessTrendChart({required this.data, required this.range});

  final List<FitnessChartData> data;
  final int range; // 7, 30, or 365

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final weightPoints = data
        .where((item) => item.weight != null)
        .map(
          (item) => GrowthChartPoint(
            label: _dateLabel(item.date),
            subLabel: _subLabel(item.date),
            date: item.date,
            value: item.weight!,
            rawLabel: '${item.weight!.toStringAsFixed(1)}kg',
          ),
        )
        .toList(growable: false);
    return GrowthMultiLineChart(
      key: ValueKey('fitness_${range}_${data.length}_${data.hashCode}'),
      color: colors.fitness,
      height: 224,
      series: [
        GrowthChartSeries(
          name: '锻炼',
          unit: 'min',
          color: colors.fitness,
          points: data
              .map(
                (item) => GrowthChartPoint(
                  label: _dateLabel(item.date),
                  subLabel: _subLabel(item.date),
                  date: item.date,
                  value: item.minutes.toDouble(),
                  rawLabel: _formatMinutes(item.minutes.toDouble()),
                ),
              )
              .toList(growable: false),
          valueFormatter: _formatMinutes,
        ),
        GrowthChartSeries(
          name: '消耗',
          unit: 'kcal',
          color: colors.warning,
          points: data
              .map(
                (item) => GrowthChartPoint(
                  label: _dateLabel(item.date),
                  subLabel: _subLabel(item.date),
                  date: item.date,
                  value: item.calories.toDouble(),
                  rawLabel: '${item.calories}kcal',
                ),
              )
              .toList(growable: false),
          valueFormatter: (value) => '${value.round()}kcal',
        ),
        if (weightPoints.isNotEmpty)
          GrowthChartSeries(
            name: '体重',
            unit: 'kg',
            color: colors.textTertiary,
            points: weightPoints,
            valueFormatter: (value) => '${value.toStringAsFixed(1)}kg',
          ),
      ],
    );
  }

  /// Format main label based on range
  String _dateLabel(DateTime date) {
    if (range == 7) {
      // Week view: show weekday name
      return _weekdayName(date.weekday);
    } else if (range == 30) {
      // Month view: show M/d
      return '${date.month}/${date.day}';
    } else {
      // Year view: show month
      return '${date.month}月';
    }
  }

  /// Format sub-label based on range
  String _subLabel(DateTime date) {
    if (range == 7) {
      // Week view: show M/d
      return '${date.month}/${date.day}';
    } else if (range == 30) {
      // Month view: show weekday name
      return _weekdayName(date.weekday);
    } else {
      // Year view: no sub-label
      return '';
    }
  }

  static String _weekdayName(int weekday) {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[weekday - 1];
  }

  static String _formatMinutes(double value) {
    if (value < 60) return '${value.round()}min';
    final hours = value / 60;
    final text = hours == hours.roundToDouble()
        ? hours.round().toString()
        : hours.toStringAsFixed(1);
    return '${text}h';
  }
}

class _FitnessEntryCard extends StatelessWidget {
  const _FitnessEntryCard({
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
                style: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
