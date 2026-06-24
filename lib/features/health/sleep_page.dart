import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../dashboard/providers/dashboard_provider.dart';
import '../../../shared/providers/settings_facade.dart';
import '../../../shared/providers/settings_provider.dart';
import 'providers/sleep_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import 'pages/add_sleep_record_sheet.dart';
import '../plan/utils/plan_module_assets.dart';
import '../plan/widgets/plan_module_visuals.dart';
import 'utils/sleep_display_formatters.dart';
import 'widgets/sleep_record_detail_sheet.dart';
import 'widgets/sleep_recent_records_card.dart';

/// 睡眠记录首页
class SleepPage extends ConsumerStatefulWidget {
  const SleepPage({super.key, this.isEmbedded = false, this.capsuleNav});

  final bool isEmbedded;
  final Widget? capsuleNav;

  @override
  ConsumerState<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends ConsumerState<SleepPage> {
  int _selectedRange = 7; // 7, 30, 365
  bool _showAllRecentRecords = false;

  // 薰衣草色系 (mapped to theme)
  Color get _lavender => context.growthColors.sleep;
  Color get _lavenderDark => HSLColor.fromColor(context.growthColors.sleep)
      .withLightness(
        (HSLColor.fromColor(context.growthColors.sleep).lightness - 0.12).clamp(
          0.0,
          1.0,
        ),
      )
      .toColor();
  Color get _lavenderLight => context.growthColors.softPurple;
  Color get _sleepPink => context.growthColors.journal;

  @override
  void initState() {
    super.initState();
    ref.read(sleepGoalInitProvider);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final sleepGoal = ref.watch(sleepGoalProvider);
    final lastNightRecord = ref.watch(lastNightSleepRecordProvider);
    final weeklyDuration = ref.watch(weeklyAvgSleepDurationProvider);
    final weeklyQuality = ref.watch(weeklyAvgSleepQualityProvider);

    // Range-based providers - only watch the selected range
    final durationList = _selectedRange == 7
        ? ref.watch(weeklySleepDurationProvider)
        : _selectedRange == 30
        ? ref.watch(monthlySleepDurationProvider)
        : ref.watch(yearlySleepDurationProvider);
    final qualityList = _selectedRange == 7
        ? ref.watch(weeklySleepQualityProvider)
        : _selectedRange == 30
        ? ref.watch(monthlySleepQualityProvider)
        : ref.watch(yearlySleepQualityProvider);

    final recentRecords = ref.watch(
      recentSleepRecordsProvider(_showAllRecentRecords ? 10 : 5),
    );

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text('睡眠', style: AppTextStyles.pageTitle),
              centerTitle: false,
              backgroundColor: colors.paper,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  tooltip: '设置睡眠目标',
                  onPressed: () => _showGoalEditSheet(context),
                  icon: const Icon(Icons.flag_outlined),
                ),
              ],
            ),
      body: ModulePageSurface(
        color: colors.sleep,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(lastNightSleepRecordProvider);
            ref.invalidate(recentSleepRecordsProvider(5));
            ref.invalidate(recentSleepRecordsProvider(10));
            if (_selectedRange == 7) {
              ref.invalidate(weeklySleepDurationProvider);
              ref.invalidate(weeklySleepQualityProvider);
            } else if (_selectedRange == 30) {
              ref.invalidate(monthlySleepDurationProvider);
              ref.invalidate(monthlySleepQualityProvider);
            } else {
              ref.invalidate(yearlySleepDurationProvider);
              ref.invalidate(yearlySleepQualityProvider);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.capsuleNav != null) widget.capsuleNav!,

                // [1] 宠物陪伴
                PlanModuleVisualHeader(
                  module: PlanModuleType.sleep,
                  color: colors.sleep,
                ),
                const SizedBox(height: 12),
                // [2] 昨晚睡眠 HeroCard
                _buildSleepOverview(
                  lastNightRecord,
                  weeklyDuration,
                  weeklyQuality,
                  sleepGoal,
                ),
                const SizedBox(height: 16),
                // [3] 记录睡眠入口
                _buildRecordSleepEntry(context),
                const SizedBox(height: 20),
                // [4] 睡眠趋势图表
                _buildTrendSection(
                  durationList,
                  qualityList,
                  weeklyDuration,
                  weeklyQuality,
                  sleepGoal,
                ),
                const SizedBox(height: 20),
                // [5] 睡眠建议 SoftCard
                _buildSleepSuggestions(lastNightRecord, sleepGoal),
                const SizedBox(height: 16),
                // [6] 最近记录
                _buildRecentRecords(recentRecords),
                const SizedBox(height: 96),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordSheet(context),
        backgroundColor: _lavender,
        child: Icon(Icons.add, color: colors.textOnAccent),
      ),
    );
  }

  // ─── 小猫提示条 ──────────────────────────────────────────────────────────

  // ─── 昨晚睡眠概况 ────────────────────────────────────────────────────────

  Widget _buildSleepOverview(
    AsyncValue<SleepRecord?> lastNightRecord,
    AsyncValue<double?> weeklyDuration,
    AsyncValue<double?> weeklyQuality,
    int sleepGoal,
  ) {
    final colors = context.growthColors;
    return lastNightRecord.when(
      data: (record) {
        if (record == null) {
          return _buildNoRecordCard();
        }
        final progress = (record.durationMinutes / (sleepGoal * 60)).clamp(
          0.0,
          1.0,
        );
        return ModuleHeroCard(
          icon: Icons.bedtime_rounded,
          title: '昨晚睡眠概况',
          primaryValue: formatSleepDuration(record.durationMinutes),
          primaryLabel: '昨晚睡眠时长',
          color: colors.sleep,
          progress: progress,
          targetLabel: '目标 $sleepGoal小时',
          metrics: [
            ModuleMetricChip(
              icon: Icons.nightlight_round,
              value: record.sleepTime,
              label: '入睡',
            ),
            ModuleMetricChip(
              icon: Icons.wb_sunny_rounded,
              value: record.wakeTime,
              label: '起床',
            ),
            ModuleMetricChip(
              icon: Icons.star_rounded,
              value: '${record.qualityLevel}/5',
              label: sleepQualityLabel(record.qualityLevel),
            ),
          ],
          onTargetTap: () => _showGoalEditSheet(context),
        );
      },
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const ErrorRetryWidget(),
    );
  }

  Widget _buildNoRecordCard() {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: colors.sleep.withValues(alpha: 0.12)),
        boxShadow: AppShadows.sm,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.nightlight_round,
              size: 48,
              color: _lavender.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              '昨晚暂无睡眠记录',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text('点击下方按钮记录睡眠', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  // ─── 记录睡眠入口 ────────────────────────────────────────────────────────

  Widget _buildRecordSleepEntry(BuildContext context) {
    return PlanModuleRecordEntryCard(
      color: _lavender,
      icon: Icons.edit_note_rounded,
      title: '记录睡眠',
      subtitle: '记录昨晚的睡眠数据',
      buttonLabel: '添加',
      onTap: () => _showAddRecordSheet(context),
    );
  }

  // ─── 趋势图表 ─────────────────────────────────────────────────────────────

  Widget _buildTrendSection(
    AsyncValue<List<Map>> durationList,
    AsyncValue<List<Map>> qualityList,
    AsyncValue<double?> weeklyDuration,
    AsyncValue<double?> weeklyQuality,
    int sleepGoal,
  ) {
    final colors = context.growthColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRangeSelector(),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          button: true,
          label: '睡眠趋势，查看详情',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _navigateToHistory(context),
            child: GrowthChartCard(
              title: '睡眠趋势',
              subtitle: '${_rangeSubtitle()} · 目标 $sleepGoal小时',
              icon: Icons.show_chart_rounded,
              color: colors.sleep,
              legend: [
                GrowthChartLegendItem(color: _lavender, label: '睡眠时长(h)'),
                GrowthChartLegendItem(color: _sleepPink, label: '睡眠质量(分)'),
              ],
              child: durationList.when(
                data: (dList) => qualityList.when(
                  data: (qList) => _buildSleepTrendChart(
                    dList,
                    qList,
                    weeklyDuration,
                    weeklyQuality,
                  ),
                  loading: () => _buildTrendLoading(),
                  error: (_, _) => _buildEmptyTrend(),
                ),
                loading: () => _buildTrendLoading(),
                error: (_, _) => _buildEmptyTrend(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeSelector() {
    return GrowthChartRangeSelector<int>(
      color: _lavender,
      selected: _selectedRange,
      options: const [
        GrowthChartRangeOption(value: 7, label: '周'),
        GrowthChartRangeOption(value: 30, label: '月'),
        GrowthChartRangeOption(value: 365, label: '年'),
      ],
      onChanged: (value) => setState(() => _selectedRange = value),
    );
  }

  Widget _buildAvgItem(String label, String value, Color color) {
    final colors = context.growthColors;
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepTrendChart(
    List<Map> durationData,
    List<Map> qualityData,
    AsyncValue<double?> weeklyDuration,
    AsyncValue<double?> weeklyQuality,
  ) {
    final data = _processSleepTrendData(durationData, qualityData);
    if (data.isEmpty) return _buildEmptyTrend();

    final durationPoints = <GrowthChartPoint>[];
    final qualityPoints = <GrowthChartPoint>[];
    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final label = _sleepTrendLabel(item, i);
      final subLabel = _sleepTrendSubLabel(item);
      final duration = (item['duration'] as num?)?.toDouble() ?? 0;
      final quality = (item['quality'] as num?)?.toDouble() ?? 0;

      durationPoints.add(
        GrowthChartPoint(
          label: label,
          subLabel: subLabel,
          value: duration / 60,
          rawLabel: _formatSleepTrendDuration(duration),
        ),
      );
      qualityPoints.add(
        GrowthChartPoint(
          label: label,
          subLabel: subLabel,
          value: quality,
          rawLabel: quality > 0 ? _formatSleepTrendQuality(quality) : '--',
        ),
      );
    }

    return Column(
      children: [
        GrowthMultiLineChart(
          key: ValueKey(
            'sleep_line_${_selectedRange}_${data.length}_${data.hashCode}',
          ),
          color: _lavender,
          height: 244,
          axisFormatter: (value) => '${_trimDouble(value)}h',
          series: [
            GrowthChartSeries(
              name: '睡眠时长',
              unit: 'h',
              color: _lavender,
              points: durationPoints,
              valueFormatter: (value) => '${_trimDouble(value)}h',
            ),
            GrowthChartSeries(
              name: '睡眠质量',
              unit: '分',
              color: _sleepPink,
              points: qualityPoints,
              valueFormatter: _formatSleepTrendQuality,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            weeklyDuration.when(
              data: (avg) => _buildAvgItem(
                '平均时长',
                avg != null ? formatSleepDuration(avg.toInt()) : '--',
                _lavender,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => _buildAvgItem('平均时长', '--', _lavender),
            ),
            weeklyQuality.when(
              data: (avg) => _buildAvgItem(
                '平均质量',
                avg != null ? '${avg.toStringAsFixed(1)} 分' : '--',
                _sleepPink,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => _buildAvgItem('平均质量', '--', _sleepPink),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToHistory(BuildContext context) {
    context.push('/plan/sleep/history');
  }

  Widget _buildEmptyTrend() {
    return SizedBox(
      height: 244,
      child: GrowthChartEmpty(color: _lavender, label: '记录后显示睡眠趋势'),
    );
  }

  Widget _buildTrendLoading() {
    return SizedBox(
      height: 244,
      child: Center(child: CircularProgressIndicator(color: _lavender)),
    );
  }

  String _rangeSubtitle() {
    return switch (_selectedRange) {
      7 => '近 7 天',
      30 => '近 30 天',
      _ => '本年',
    };
  }

  List<Map<String, dynamic>> _processSleepTrendData(
    List<Map> durationData,
    List<Map> qualityData,
  ) {
    final merged = _mergeSleepTrendData(durationData, qualityData);
    if (_selectedRange == 30) return _aggregateSleepTrendByWeek(merged);
    if (_selectedRange == 365) return _aggregateSleepTrendByMonth(merged);
    return merged;
  }

  List<Map<String, dynamic>> _mergeSleepTrendData(
    List<Map> durationData,
    List<Map> qualityData,
  ) {
    final map = <String, Map<String, dynamic>>{};
    for (final item in durationData) {
      final date = _normalizeDate(item['date'] as String? ?? '');
      if (date.isEmpty) continue;
      map[date] = {'date': date, 'duration': item['duration'], 'quality': null};
    }
    for (final item in qualityData) {
      final date = _normalizeDate(item['date'] as String? ?? '');
      if (date.isEmpty) continue;
      map.putIfAbsent(
        date,
        () => {'date': date, 'duration': null, 'quality': null},
      );
      map[date]!['quality'] = item['quality'];
    }
    return map.values.toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  /// Normalize date string to yyyy-MM-dd format
  String _normalizeDate(String date) {
    if (date.isEmpty) return '';
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _aggregateSleepTrendByWeek(
    List<Map<String, dynamic>> daily,
  ) {
    if (daily.isEmpty) return [];
    final weeks = <Map<String, dynamic>>[];
    for (var i = 0; i < daily.length; i += 7) {
      final chunk = daily.sublist(i, (i + 7).clamp(0, daily.length));
      final durationValues = chunk
          .map((item) => (item['duration'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      final qualityValues = chunk
          .map((item) => (item['quality'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      weeks.add({
        'date': chunk.first['date'],
        'endDate': chunk.last['date'],
        'duration': _averageDouble(durationValues),
        'quality': qualityValues.isEmpty ? null : _averageDouble(qualityValues),
      });
    }
    return weeks;
  }

  List<Map<String, dynamic>> _aggregateSleepTrendByMonth(
    List<Map<String, dynamic>> daily,
  ) {
    final now = DateTime.now();
    final year = now.year;
    final monthMap = <String, List<Map<String, dynamic>>>{};
    for (final item in daily) {
      final date = item['date'] as String? ?? '';
      final parsed = DateTime.tryParse(date);
      if (parsed == null || parsed.year != year) continue;
      monthMap.putIfAbsent(date.substring(0, 7), () => []).add(item);
    }
    return List.generate(12, (index) {
      final month = index + 1;
      final key = '$year-${month.toString().padLeft(2, '0')}';
      final chunk = monthMap[key] ?? const <Map<String, dynamic>>[];
      final durationValues = chunk
          .map((item) => (item['duration'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      final qualityValues = chunk
          .map((item) => (item['quality'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      return {
        'date': key,
        'duration': _averageDouble(durationValues),
        'quality': qualityValues.isEmpty ? null : _averageDouble(qualityValues),
      };
    }).toList();
  }

  String _sleepTrendLabel(Map<String, dynamic> item, int index) {
    if (_selectedRange == 30) return '第${index + 1}周';
    final date = item['date'] as String? ?? '';
    if (_selectedRange == 365) {
      final month = date.length >= 7
          ? int.tryParse(date.substring(5, 7))
          : null;
      return month == null ? date : '$month月';
    }
    // Week view: show weekday name
    final parsed = DateTime.tryParse(date);
    if (parsed != null) {
      const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return names[parsed.weekday - 1];
    }
    return date;
  }

  String _sleepTrendSubLabel(Map<String, dynamic> item) {
    if (_selectedRange == 365) return '';
    final date = item['date'] as String? ?? '';
    if (_selectedRange == 30) {
      final start = _dateShort(item['date'] as String? ?? '');
      final end = _dateShort(item['endDate'] as String? ?? '');
      if (start.isEmpty || end.isEmpty) return '';
      return '$start-$end';
    }
    // Week view: show M/d
    return _dateShort(date);
  }

  String _formatSleepTrendDuration(double minutes) {
    if (minutes <= 0) return '0m';
    if (minutes < 60) return '${minutes.round()}m';
    return '${_trimDouble(minutes / 60)}h';
  }

  String _formatSleepTrendQuality(double quality) {
    if (quality <= 0) return '--';
    return '${quality.toStringAsFixed(1)}分';
  }

  static String _dateShort(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '';
    return '${parsed.month}/${parsed.day}';
  }

  static double _averageDouble(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static String _trimDouble(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
  }

  // ─── 睡眠建议 ────────────────────────────────────────────────────────────

  Widget _buildSleepSuggestions(
    AsyncValue<SleepRecord?> lastNightRecord,
    int sleepGoal,
  ) {
    final colors = context.growthColors;
    return lastNightRecord.when(
      data: (record) {
        final suggestions = _getSuggestions(record, sleepGoal);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _lavenderLight,
            borderRadius: BorderRadius.circular(AppRadius.mlg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_rounded, size: 20, color: _lavender),
                  const SizedBox(width: 8),
                  Text(
                    '睡眠建议',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _lavenderDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...suggestions.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: _lavender.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const ErrorRetryWidget(),
    );
  }

  List<String> _getSuggestions(SleepRecord? record, int sleepGoal) {
    if (record == null) {
      return ['开始记录睡眠，获取个性化建议', '保持规律的作息时间', '睡前 1 小时远离电子屏幕'];
    }

    final suggestions = <String>[];

    if (record.durationMinutes < sleepGoal * 60) {
      suggestions.add('昨晚睡眠不足，建议今天适当提前入睡');
    }
    if (record.fallAsleepMinutes > 30) {
      suggestions.add('入睡时间较长，可以尝试睡前冥想或深呼吸');
    }
    if (record.wakeCount > 2) {
      suggestions.add('夜间频繁醒来，建议检查睡眠环境是否安静');
    }
    if (record.qualityLevel <= 2) {
      suggestions.add('睡眠质量较低，建议保持规律作息和适量运动');
    }
    if (record.qualityLevel >= 4) {
      suggestions.add('昨晚睡眠质量很好，继续保持当前的作息习惯！');
    }

    suggestions.add('睡前 1 小时远离电子屏幕，帮助提升睡眠质量');

    return suggestions;
  }

  // ─── 最近记录 ────────────────────────────────────────────────────────────

  Widget _buildRecentRecords(AsyncValue<List<SleepRecord>> recentRecords) {
    return SleepRecentRecordsCard(
      recentRecords: recentRecords,
      isExpanded: _showAllRecentRecords,
      onToggleExpand: () =>
          setState(() => _showAllRecentRecords = !_showAllRecentRecords),
      onViewAll: () => _navigateToHistory(context),
      onDeleteRecord: (record) => _deleteRecord(context, ref, record),
      onRecordTap: (record) => showSleepRecordDetailSheet(
        context,
        record,
        accentColor: _lavender,
        dreamBackgroundColor: _lavenderLight,
      ),
      emptyIconColor: _lavender,
    );
  }

  // ─── 目标编辑弹窗 ────────────────────────────────────────────────────────

  void _showGoalEditSheet(BuildContext context) {
    GoalEditSheet.show(
      context: context,
      title: '设置睡眠目标',
      currentValue: ref.read(sleepGoalProvider),
      unit: '小时/天',
      min: 4,
      max: 12,
      step: 1,
      suggestion: '建议每天睡眠 7~9 小时',
      color: _lavender,
      onSave: (value) async {
        await ref.read(settingsFacadeProvider).setSleepGoalHours(value);
      },
    );
  }

  // ─── 添加记录弹窗 ────────────────────────────────────────────────────────

  void _showAddRecordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSleepRecordSheet(
        onSave: () {
          ref.invalidate(lastNightSleepRecordProvider);
          ref.invalidate(recentSleepRecordsProvider(5));
          ref.invalidate(recentSleepRecordsProvider(10));
          // Only invalidate the selected range
          if (_selectedRange == 7) {
            ref.invalidate(weeklySleepDurationProvider);
            ref.invalidate(weeklySleepQualityProvider);
          } else if (_selectedRange == 30) {
            ref.invalidate(monthlySleepDurationProvider);
            ref.invalidate(monthlySleepQualityProvider);
          } else {
            ref.invalidate(yearlySleepDurationProvider);
            ref.invalidate(yearlySleepQualityProvider);
          }
        },
      ),
    );
  }

  // ─── 删除记录 ────────────────────────────────────────────────────────────

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    SleepRecord record,
  ) async {
    final colors = context.growthColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除确认'),
        content: const Text('确定要删除这条睡眠记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: colors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || !context.mounted) return;

    try {
      final repo = ref.read(sleepRepositoryProvider);
      await repo.deleteSleepRecord(record.id);
      if (!mounted || !context.mounted) return;

      ref.invalidate(lastNightSleepRecordProvider);
      ref.invalidate(recentSleepRecordsProvider(5));
      ref.invalidate(recentSleepRecordsProvider(10));
      ref.invalidate(dashboardProvider);
      // Only invalidate the selected range
      if (_selectedRange == 7) {
        ref.invalidate(weeklySleepDurationProvider);
        ref.invalidate(weeklySleepQualityProvider);
      } else if (_selectedRange == 30) {
        ref.invalidate(monthlySleepDurationProvider);
        ref.invalidate(monthlySleepQualityProvider);
      } else {
        ref.invalidate(yearlySleepDurationProvider);
        ref.invalidate(yearlySleepQualityProvider);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已删除')));
    } catch (e) {
      if (!mounted || !context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败，请重试')));
    }
  }
}
