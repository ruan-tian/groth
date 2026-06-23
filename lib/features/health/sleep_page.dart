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
import 'widgets/sleep_combined_chart.dart';
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
  Color get _lavenderDark => context.growthColors.primaryDark;
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.capsuleNav != null) widget.capsuleNav!,

                // ── 1. 小猫提示条 ──
                PlanModuleVisualHeader(
                  module: PlanModuleType.sleep,
                  color: colors.sleep,
                ),
                const SizedBox(height: AppSpacing.md),
                PlanModuleActionImageCard(
                  module: PlanModuleType.sleep,
                  color: colors.sleep,
                  onTap: () => context.push('/plan/sleep/reminder'),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── 2. 昨晚睡眠概况 ──
                _buildSleepOverview(
                  lastNightRecord,
                  weeklyDuration,
                  weeklyQuality,
                  sleepGoal,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── 3. 记录睡眠入口 ──
                _buildRecordSleepEntry(context),
                const SizedBox(height: AppSpacing.lg),

                // ── 4. 趋势图表 ──
                _buildTrendSection(
                  durationList,
                  qualityList,
                  weeklyDuration,
                  weeklyQuality,
                  sleepGoal,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── 5. 睡眠建议 ──
                _buildSleepSuggestions(lastNightRecord, sleepGoal),
                const SizedBox(height: AppSpacing.lg),

                // ── 6. 最近记录 ──
                _buildRecentRecords(recentRecords),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.card, colors.sleep.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: colors.sleep.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
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
    final rangeLabel = _selectedRange == 7
        ? '近7天趋势'
        : _selectedRange == 30
        ? '近30天趋势'
        : '近1年趋势';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(rangeLabel, style: AppTextStyles.sectionTitle),
            const Spacer(),
            Semantics(
              button: true,
              label: '查看详情',
              child: GestureDetector(
                onTap: () => _navigateToHistory(context),
                child: Row(
                  children: [
                    Text(
                      '查看详情',
                      style: TextStyle(fontSize: 12, color: _lavender),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: _lavender),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // 时间范围选择器
        _buildRangeSelector(),
        const SizedBox(height: AppSpacing.md),
        // 组合图表
        durationList.when(
          data: (dList) {
            if (dList.isEmpty) return _buildEmptyTrend();
            return qualityList.when(
              data: (qList) {
                return Semantics(
                  button: true,
                  label: '睡眠趋势，查看详情',
                  child: GestureDetector(
                    onTap: () => _navigateToHistory(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.card,
                            colors.sleep.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xxxl),
                        border: Border.all(
                          color: colors.sleep.withValues(alpha: 0.14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题行
                          Row(
                            children: [
                              Icon(
                                Icons.bar_chart_rounded,
                                size: 18,
                                color: _lavender,
                              ),
                              const SizedBox(width: 8),
                              Text('睡眠趋势', style: AppTextStyles.cardTitle),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 图例
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegend(_lavender, '睡眠时长'),
                              const SizedBox(width: 24),
                              _buildLegend(_sleepPink, '睡眠质量'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // fl_chart 组合图表
                          SizedBox(
                            height: 260,
                            child: SleepCombinedChart(
                              durationData: dList,
                              qualityData: qList,
                              durationColor: _lavender,
                              qualityColor: _sleepPink,
                              goalHours: sleepGoal,
                              selectedRange: _selectedRange,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 平均值
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              weeklyDuration.when(
                                data: (avg) => _buildAvgItem(
                                  '平均时长',
                                  avg != null
                                      ? formatSleepDuration(avg.toInt())
                                      : '--',
                                  _lavender,
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, _) => const ErrorRetryWidget(),
                              ),
                              weeklyQuality.when(
                                data: (avg) => _buildAvgItem(
                                  '平均质量',
                                  avg != null
                                      ? '${avg.toStringAsFixed(1)} 分'
                                      : '--',
                                  _sleepPink,
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, _) => const ErrorRetryWidget(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => _buildEmptyTrend(),
              error: (_, _) => _buildEmptyTrend(),
            );
          },
          loading: () => _buildEmptyTrend(),
          error: (_, _) => _buildEmptyTrend(),
        ),
      ],
    );
  }

  Widget _buildRangeSelector() {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: _lavender.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          _buildRangeChip('7天', 7),
          _buildRangeChip('30天', 30),
          _buildRangeChip('1年', 365),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, int days) {
    final isSelected = _selectedRange == days;
    final colors = context.growthColors;
    return Expanded(
      child: Semantics(
        button: true,
        label: '显示$label数据',
        selected: isSelected,
        child: GestureDetector(
          onTap: () {
            if (_selectedRange != days) {
              setState(() => _selectedRange = days);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? colors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _lavender.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
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
                  color: isSelected ? _lavender : colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    final colors = context.growthColors;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
      ],
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

  void _navigateToHistory(BuildContext context) {
    context.push('/plan/sleep/history');
  }

  Widget _buildEmptyTrend() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: _lavenderLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 40,
              color: _lavender.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text('暂无数据', style: TextStyle(color: _lavender)),
          ],
        ),
      ),
    );
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
            borderRadius: BorderRadius.circular(16),
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
