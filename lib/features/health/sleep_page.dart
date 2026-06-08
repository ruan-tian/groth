import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart'
    hide settingRepositoryProvider;
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/sleep_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../../shared/widgets/swipe_delete_tile.dart';
import 'pages/add_sleep_record_sheet.dart';
import 'package:go_router/go_router.dart';
import '../pet/models/pet_scene_model.dart';
import '../pet/widgets/pet_scene_banner.dart';

/// 睡眠记录首页
class SleepPage extends ConsumerStatefulWidget {
  const SleepPage({super.key, this.isEmbedded = false, this.capsuleNav});

  final bool isEmbedded;
  final Widget? capsuleNav;

  @override
  ConsumerState<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends ConsumerState<SleepPage> {
  int _sleepGoalHours = 8;
  int _selectedRange = 7; // 7, 30, 365
  bool _showAllRecentRecords = false;

  // 薰衣草色系
  static const _lavender = Color(0xFF9B8FE8);
  static const _lavenderDark = Color(0xFF7B6FD6);
  static const _lavenderLight = Color(0xFFF0EDFF);
  static const _sleepPink = Color(0xFFFFB8C6);
  static const _warmWhite = Color(0xFFFFF8F0);

  @override
  void initState() {
    super.initState();
    _loadSleepGoal();
  }

  Future<void> _loadSleepGoal() async {
    final repo = ref.read(settingRepositoryProvider);
    final value = await repo.getSetting('sleep_goal_hours');
    if (value != null && mounted) {
      setState(() {
        _sleepGoalHours = int.tryParse(value) ?? 8;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastNightRecord = ref.watch(lastNightSleepRecordProvider);
    final weeklyDuration = ref.watch(weeklyAvgSleepDurationProvider);
    final weeklyQuality = ref.watch(weeklyAvgSleepQualityProvider);

    // Range-based providers
    final weeklyDurationList = ref.watch(weeklySleepDurationProvider);
    final weeklyQualityList = ref.watch(weeklySleepQualityProvider);
    final monthlyDurationList = ref.watch(monthlySleepDurationProvider);
    final monthlyQualityList = ref.watch(monthlySleepQualityProvider);
    final yearlyDurationList = ref.watch(yearlySleepDurationProvider);
    final yearlyQualityList = ref.watch(yearlySleepQualityProvider);

    // Select data based on range
    final durationList = _selectedRange == 7
        ? weeklyDurationList
        : _selectedRange == 30
            ? monthlyDurationList
            : yearlyDurationList;
    final qualityList = _selectedRange == 7
        ? weeklyQualityList
        : _selectedRange == 30
            ? monthlyQualityList
            : yearlyQualityList;

    final recentRecords = ref.watch(
      recentSleepRecordsProvider(_showAllRecentRecords ? 10 : 5),
    );

    return Scaffold(
      backgroundColor: AppColors.softLavender,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text('睡眠', style: AppTextStyles.pageTitle),
              centerTitle: false,
              backgroundColor: AppColors.softLavender,
              actions: [
                IconButton(
                  tooltip: '设置睡眠目标',
                  onPressed: () => _showGoalEditSheet(context),
                  icon: const Icon(Icons.flag_outlined),
                ),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(lastNightSleepRecordProvider);
          ref.invalidate(weeklyAvgSleepDurationProvider);
          ref.invalidate(weeklyAvgSleepQualityProvider);
          ref.invalidate(weeklySleepDurationProvider);
          ref.invalidate(weeklySleepQualityProvider);
          ref.invalidate(monthlySleepDurationProvider);
          ref.invalidate(monthlySleepQualityProvider);
          ref.invalidate(yearlySleepDurationProvider);
          ref.invalidate(yearlySleepQualityProvider);
          ref.invalidate(recentSleepRecordsProvider(5));
          ref.invalidate(recentSleepRecordsProvider(10));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.capsuleNav != null) widget.capsuleNav!,

              // ── 1. 小猫提示条 ──
              _buildPetBanner(lastNightRecord),
              const SizedBox(height: AppSpacing.lg),

              // ── 2. 昨晚睡眠概况 ──
              _buildSleepOverview(lastNightRecord, weeklyDuration, weeklyQuality),
              const SizedBox(height: AppSpacing.lg),

              // ── 3. 记录睡眠入口 ──
              _buildRecordSleepEntry(context),
              const SizedBox(height: AppSpacing.lg),

              // ── 4. 趋势图表 ──
              _buildTrendSection(durationList, qualityList, weeklyDuration, weeklyQuality),
              const SizedBox(height: AppSpacing.lg),

              // ── 5. 睡眠建议 ──
              _buildSleepSuggestions(lastNightRecord),
              const SizedBox(height: AppSpacing.lg),

              // ── 6. 最近记录 ──
              _buildRecentRecords(recentRecords),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordSheet(context),
        backgroundColor: _lavender,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ─── 小猫提示条 ──────────────────────────────────────────────────────────

  Widget _buildPetBanner(AsyncValue<SleepRecord?> lastNightRecord) {
    final hasRecords = lastNightRecord.valueOrNull != null;
    return PetSceneBanner(
      module: PetModuleType.sleep,
      hasRecords: hasRecords,
      onTap: () => context.push('/pet-center'),
    );
  }

  // ─── 昨晚睡眠概况 ────────────────────────────────────────────────────────

  Widget _buildSleepOverview(
    AsyncValue<SleepRecord?> lastNightRecord,
    AsyncValue<double?> weeklyDuration,
    AsyncValue<double?> weeklyQuality,
  ) {
    return lastNightRecord.when(
      data: (record) {
        if (record == null) {
          return _buildNoRecordCard();
        }

        // 计算前一晚数据用于对比
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '昨晚睡眠概况',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            // 2x2 网格
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.bedtime_rounded,
                    label: '睡眠时长',
                    value: _formatDuration(record.durationMinutes),
                    subtitle: '目标 ${_sleepGoalHours}小时',
                    progress: record.durationMinutes / (_sleepGoalHours * 60),
                    color: _lavender,
                    backgroundColor: _lavenderLight,
                    onTap: () => _showGoalEditSheet(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.nightlight_round,
                    label: '入睡时间',
                    value: record.sleepTime,
                    subtitle: _getSleepTimeChange(record),
                    color: const Color(0xFF7B6FD6),
                    backgroundColor: _lavenderLight.withValues(alpha: 0.6),
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.wb_sunny_rounded,
                    label: '起床时间',
                    value: record.wakeTime,
                    subtitle: _getWakeTimeChange(record),
                    color: const Color(0xFFFFB347),
                    backgroundColor: _warmWhite,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.star_rounded,
                    label: '睡眠评分',
                    value: '${record.qualityLevel}/5',
                    subtitle: _getQualityLabel(record.qualityLevel),
                    color: _getQualityColor(record.qualityLevel),
                    backgroundColor: _getQualityColor(record.qualityLevel).withValues(alpha: 0.1),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildNoRecordCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lavender.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.nightlight_round, size: 48, color: _lavender.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              '昨晚暂无睡眠记录',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text('点击下方按钮记录睡眠', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  String _getSleepTimeChange(SleepRecord record) {
    // 简化：显示入睡用时
    if (record.fallAsleepMinutes > 0) {
      return '入睡用时 ${record.fallAsleepMinutes}分钟';
    }
    return '入睡用时 --';
  }

  String _getWakeTimeChange(SleepRecord record) {
    if (record.wakeCount > 0) {
      return '夜间醒来 ${record.wakeCount}次';
    }
    return '整夜安睡';
  }

  // ─── 记录睡眠入口 ────────────────────────────────────────────────────────

  Widget _buildRecordSleepEntry(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddRecordSheet(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _lavender.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: _lavender.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _lavenderLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_note_rounded, color: _lavender, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '记录睡眠',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('记录昨晚的睡眠数据', style: AppTextStyles.caption),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _lavender,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    '添加',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 趋势图表 ─────────────────────────────────────────────────────────────

  Widget _buildTrendSection(
    AsyncValue<List<Map>> durationList,
    AsyncValue<List<Map>> qualityList,
    AsyncValue<double?> weeklyDuration,
    AsyncValue<double?> weeklyQuality,
  ) {
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
            GestureDetector(
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
                return GestureDetector(
                  onTap: () => _navigateToHistory(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _lavender.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题行
                        Row(
                          children: [
                            Icon(Icons.bar_chart_rounded, size: 18, color: _lavender),
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
                          child: _SleepCombinedChart(
                            durationData: dList,
                            qualityData: qList,
                            durationColor: _lavender,
                            qualityColor: _sleepPink,
                            goalHours: _sleepGoalHours,
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
                                avg != null ? _formatDuration(avg.toInt()) : '--',
                                _lavender,
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                            weeklyQuality.when(
                              data: (avg) => _buildAvgItem(
                                '平均质量',
                                avg != null ? '${avg.toStringAsFixed(1)} 分' : '--',
                                _sleepPink,
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
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
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _lavenderLight,
        borderRadius: BorderRadius.circular(10),
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
    return Expanded(
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
            color: isSelected ? Colors.white : Colors.transparent,
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
                color: isSelected ? _lavender : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF86909C),
          ),
        ),
      ],
    );
  }

  Widget _buildAvgItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF86909C),
          ),
        ),
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
            Icon(Icons.show_chart, size: 40, color: _lavender.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text('暂无数据', style: TextStyle(color: _lavender)),
          ],
        ),
      ),
    );
  }

  // ─── 睡眠建议 ────────────────────────────────────────────────────────────

  Widget _buildSleepSuggestions(AsyncValue<SleepRecord?> lastNightRecord) {
    return lastNightRecord.when(
      data: (record) {
        final suggestions = _getSuggestions(record);
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
              ...suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 6, color: _lavender.withValues(alpha: 0.6)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  List<String> _getSuggestions(SleepRecord? record) {
    if (record == null) {
      return [
        '开始记录睡眠，获取个性化建议',
        '保持规律的作息时间',
        '睡前 1 小时远离电子屏幕',
      ];
    }

    final suggestions = <String>[];

    if (record.durationMinutes < _sleepGoalHours * 60) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '最近记录',
          action: '查看全部',
          onActionTap: () => _navigateToHistory(context),
        ),
        recentRecords.when(
          data: (records) {
            if (records.isEmpty) {
              return _buildEmptyState();
            }
            final displayRecords = _showAllRecentRecords
                ? records
                : records.take(5).toList();
            return Column(
              children: [
                ...displayRecords.map((r) => SwipeDeleteTile(
                  key: ValueKey('sleep_${r.id}'),
                  onConfirmDelete: () async {
                    _deleteRecord(context, ref, r);
                    return false;
                  },
                  onDismissed: () {},
                  child: RecentRecordTile(
                    icon: Icons.nightlight_round,
                    iconColor: Colors.white,
                    iconBackgroundColor: const Color(0xFF9B8FE8),
                    title: '${r.sleepDate} 睡眠记录',
                    subtitle:
                        '${r.sleepTime} - ${r.wakeTime} · ${_formatDuration(r.durationMinutes)}',
                    primaryBadge: _getQualityLabel(r.qualityLevel),
                    primaryBadgeColor: const Color(0xFF9B8FE8),
                    secondaryBadge:
                        '${r.durationMinutes ~/ 60}h${r.durationMinutes % 60}m',
                    secondaryBadgeColor: AppColors.textSecondary,
                    onTap: () => _showRecordDetail(context, r),
                  ),
                )),
                if (records.length > 5 && !_showAllRecentRecords)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showAllRecentRecords = true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '查看更多',
                            style: TextStyle(
                              fontSize: 13,
                              color: _lavender,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(Icons.expand_more, size: 18, color: _lavender),
                        ],
                      ),
                    ),
                  ),
                if (_showAllRecentRecords && records.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showAllRecentRecords = false),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '收起',
                            style: TextStyle(
                              fontSize: 13,
                              color: _lavender,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(Icons.expand_less, size: 18, color: _lavender),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败: $e')),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.nightlight_round, size: 48, color: _lavender.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text(
              '还没有睡眠记录',
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('点击 + 记录昨晚的睡眠', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  // ─── 目标编辑弹窗 ────────────────────────────────────────────────────────

  void _showGoalEditSheet(BuildContext context) {
    GoalEditSheet.show(
      context: context,
      title: '设置睡眠目标',
      currentValue: _sleepGoalHours,
      unit: '小时/天',
      min: 4,
      max: 12,
      step: 1,
      suggestion: '建议每天睡眠 7~9 小时',
      color: _lavender,
      onSave: (value) async {
        final repo = ref.read(settingRepositoryProvider);
        await repo.setSetting('sleep_goal_hours', value.toString());
        setState(() => _sleepGoalHours = value);
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
          ref.invalidate(weeklyAvgSleepDurationProvider);
          ref.invalidate(weeklyAvgSleepQualityProvider);
          ref.invalidate(weeklySleepDurationProvider);
          ref.invalidate(weeklySleepQualityProvider);
          ref.invalidate(monthlySleepDurationProvider);
          ref.invalidate(monthlySleepQualityProvider);
          ref.invalidate(yearlySleepDurationProvider);
          ref.invalidate(yearlySleepQualityProvider);
          ref.invalidate(recentSleepRecordsProvider(5));
          ref.invalidate(recentSleepRecordsProvider(10));
        },
      ),
    );
  }

  // ─── 记录详情弹窗 ────────────────────────────────────────────────────────

  void _showRecordDetail(BuildContext context, SleepRecord record) {
    final date = DateTime.parse(record.sleepDate);
    final weekday = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];
    final dateStr = '${date.year}年${date.month}月${date.day}日 $weekday';

    final hours = record.durationMinutes ~/ 60;
    final mins = record.durationMinutes % 60;
    final durationStr = '${hours}h ${mins}m';

    final detailItems = [
      DetailItem(label: '入睡时间', value: record.sleepTime, icon: Icons.nightlight_round),
      DetailItem(label: '起床时间', value: record.wakeTime, icon: Icons.wb_sunny_rounded),
      DetailItem(label: '入睡用时', value: '${record.fallAsleepMinutes}分钟', icon: Icons.timer_outlined),
      DetailItem(label: '夜间醒来', value: '${record.wakeCount}次', icon: Icons.notifications_none_rounded),
    ];

    // Build extra cards: quality, energy, dream, note
    final extraCards = <Widget>[
      // 睡眠质量
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFB347), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('睡眠质量', style: TextStyle(fontSize: 13, color: Color(0xFF86909C))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${record.qualityLevel}/5',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2329)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getQualityLabel(record.qualityLevel),
                        style: TextStyle(fontSize: 13, color: _getQualityColor(record.qualityLevel)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // 醒后精力
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE6FFF0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.battery_charging_full_rounded, color: Color(0xFF52C41A), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('醒后精力', style: TextStyle(fontSize: 13, color: Color(0xFF86909C))),
                  const SizedBox(height: 4),
                  Text(
                    '${record.energyLevel}/5',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2329)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    // 梦境备注
    if (record.dreamNote != null && record.dreamNote!.isNotEmpty) {
      extraCards.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _lavenderLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, color: _lavender, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('梦境', style: TextStyle(fontSize: 13, color: Color(0xFF86909C))),
                    const SizedBox(height: 4),
                    Text(
                      record.dreamNote!,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2329)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 备注
    if (record.note != null && record.note!.isNotEmpty) {
      extraCards.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.note_outlined, color: Color(0xFF86909C), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('备注', style: TextStyle(fontSize: 13, color: Color(0xFF86909C))),
                    const SizedBox(height: 4),
                    Text(
                      record.note!,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2329)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => RecordDetailSheet(
        title: dateStr,
        accentColor: _lavender,
        primaryMetricLabel: '睡眠时长',
        primaryMetricValue: durationStr,
        detailItems: detailItems,
        extraCard: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < extraCards.length; i++) ...[
              extraCards[i],
              if (i < extraCards.length - 1) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  // ─── 删除记录 ────────────────────────────────────────────────────────────

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    SleepRecord record,
  ) async {
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
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(sleepRepositoryProvider);
        await repo.deleteSleepRecord(record.id);
        ref.invalidate(lastNightSleepRecordProvider);
        ref.invalidate(recentSleepRecordsProvider(5));
        ref.invalidate(recentSleepRecordsProvider(10));
        ref.invalidate(weeklyAvgSleepDurationProvider);
        ref.invalidate(weeklyAvgSleepQualityProvider);
        ref.invalidate(weeklySleepDurationProvider);
        ref.invalidate(weeklySleepQualityProvider);
        ref.invalidate(monthlySleepDurationProvider);
        ref.invalidate(monthlySleepQualityProvider);
        ref.invalidate(yearlySleepDurationProvider);
        ref.invalidate(yearlySleepQualityProvider);
        ref.invalidate(dashboardProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已删除')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  // ─── 工具方法 ────────────────────────────────────────────────────────────

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '$hours小时$mins分';
    if (hours > 0) return '$hours小时';
    return '$mins分钟';
  }

  String _getQualityLabel(int quality) {
    switch (quality) {
      case 1: return '很差';
      case 2: return '较差';
      case 3: return '一般';
      case 4: return '良好';
      case 5: return '优秀';
      default: return '一般';
    }
  }

  Color _getQualityColor(int quality) {
    if (quality >= 4) return AppColors.success;
    if (quality >= 3) return const Color(0xFFFFB347);
    return AppColors.danger;
  }

}

// ─── 指标卡片 ──────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
    this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const Spacer(),
                if (onTap != () {})
                  Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 10),
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 睡眠组合图表（fl_chart 柱状图+折线图）──────────────────────────────────

class _SleepCombinedChart extends StatefulWidget {
  const _SleepCombinedChart({
    required this.durationData,
    required this.qualityData,
    required this.durationColor,
    required this.qualityColor,
    required this.goalHours,
    required this.selectedRange,
  });

  final List<Map> durationData;
  final List<Map> qualityData;
  final Color durationColor;
  final Color qualityColor;
  final int goalHours;
  final int selectedRange;

  @override
  State<_SleepCombinedChart> createState() => _SleepCombinedChartState();
}

class _SleepCombinedChartState extends State<_SleepCombinedChart> {
  int? _touchedBarIndex;
  int? _touchedLineIndex;

  // ── Unit formatting helpers ──

  /// Format duration minutes: <60min → "30m", ≥60min → "7.5h"
  String _formatDurationValue(double minutes) {
    if (minutes < 60) return '${minutes.round()}m';
    final h = minutes / 60;
    return '${h.toStringAsFixed(h == h.roundToDouble() ? 0 : 1)}h';
  }

  /// Format quality: "3.5分"
  String _formatQualityValue(double quality) {
    return '${quality.toStringAsFixed(1)}分';
  }

  // ── Data aggregation ─-

  /// Merge duration and quality data by date
  List<Map<String, dynamic>> _mergeData() {
    final map = <String, Map<String, dynamic>>{};
    for (final d in widget.durationData) {
      final date = d['date'] as String? ?? '';
      map[date] = {'date': date, 'duration': d['duration'], 'quality': null};
    }
    for (final q in widget.qualityData) {
      final date = q['date'] as String? ?? '';
      if (map.containsKey(date)) {
        map[date]!['quality'] = q['quality'];
      } else {
        map[date] = {'date': date, 'duration': null, 'quality': q['quality']};
      }
    }
    return map.values.toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  /// Aggregate daily data into weekly groups (for month view: 4 bars)
  List<Map<String, dynamic>> _aggregateByWeek(List<Map<String, dynamic>> daily) {
    if (daily.isEmpty) return [];
    final weeks = <Map<String, dynamic>>[];
    for (var i = 0; i < daily.length; i += 7) {
      final chunk = daily.sublist(i, (i + 7).clamp(0, daily.length));
      final durValues = chunk
          .map((e) => (e['duration'] as num?)?.toDouble())
          .where((v) => v != null)
          .cast<double>()
          .toList();
      final qualValues = chunk
          .map((e) => (e['quality'] as num?)?.toDouble())
          .where((v) => v != null)
          .cast<double>()
          .toList();
      final startDate = chunk.first['date'] as String;
      final endDate = chunk.last['date'] as String;
      weeks.add({
        'date': startDate,
        'endDate': endDate,
        'duration': durValues.isNotEmpty
            ? durValues.reduce((a, b) => a + b) / durValues.length
            : 0.0,
        'quality': qualValues.isNotEmpty
            ? qualValues.reduce((a, b) => a + b) / qualValues.length
            : null,
      });
    }
    return weeks;
  }

  /// Aggregate daily data into monthly groups (for year view: 12 bars)
  List<Map<String, dynamic>> _aggregateByMonth(List<Map<String, dynamic>> daily) {
    if (daily.isEmpty) return [];
    final monthMap = <String, List<Map<String, dynamic>>>{};
    for (final d in daily) {
      final date = d['date'] as String? ?? '';
      if (date.length >= 7) {
        final key = date.substring(0, 7); // "YYYY-MM"
        monthMap.putIfAbsent(key, () => []).add(d);
      }
    }
    final sortedKeys = monthMap.keys.toList()..sort();
    return sortedKeys.map((key) {
      final chunk = monthMap[key]!;
      final durValues = chunk
          .map((e) => (e['duration'] as num?)?.toDouble())
          .where((v) => v != null)
          .cast<double>()
          .toList();
      final qualValues = chunk
          .map((e) => (e['quality'] as num?)?.toDouble())
          .where((v) => v != null)
          .cast<double>()
          .toList();
      return {
        'date': key,
        'duration': durValues.isNotEmpty
            ? durValues.reduce((a, b) => a + b) / durValues.length
            : 0.0,
        'quality': qualValues.isNotEmpty
            ? qualValues.reduce((a, b) => a + b) / qualValues.length
            : null,
      };
    }).toList();
  }

  /// Get the processed data list based on selected range
  List<Map<String, dynamic>> get _processedData {
    final merged = _mergeData();
    if (widget.selectedRange == 30) return _aggregateByWeek(merged);
    if (widget.selectedRange == 365) return _aggregateByMonth(merged);
    return merged; // week: daily data
  }

  // ── X-axis label builders ──

  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  /// Week view: "周一\n6/2"
  String _weekMainLabel(Map<String, dynamic> d) {
    final date = d['date'] as String? ?? '';
    if (date.length < 10) return '';
    final dt = DateTime.tryParse(date);
    if (dt == null) return date.substring(8, 10);
    return _weekdays[dt.weekday - 1];
  }

  String _weekSubLabel(Map<String, dynamic> d) {
    final date = d['date'] as String? ?? '';
    if (date.length < 10) return date;
    final dt = DateTime.tryParse(date);
    if (dt == null) return date.substring(8, 10);
    return '${dt.month}/${dt.day}';
  }

  /// Month view: "第一周\n6/1-6/7"
  String _monthMainLabel(int index) {
    const labels = ['第一周', '第二周', '第三周', '第四周', '第五周'];
    return index < labels.length ? labels[index] : '第${index + 1}周';
  }

  String _monthSubLabel(Map<String, dynamic> d) {
    final start = d['date'] as String? ?? '';
    final end = d['endDate'] as String? ?? '';
    String fmt(String s) {
      if (s.length < 10) return s;
      final dt = DateTime.tryParse(s);
      if (dt == null) return s.substring(5, 10);
      return '${dt.month}/${dt.day}';
    }
    return '${fmt(start)}-${fmt(end)}';
  }

  /// Year view: "1月"
  String _yearMainLabel(Map<String, dynamic> d) {
    final date = d['date'] as String? ?? '';
    if (date.length < 7) return date;
    final month = int.tryParse(date.substring(5, 7)) ?? 0;
    return '$month月';
  }

  @override
  Widget build(BuildContext context) {
    final data = _processedData;
    if (data.isEmpty) return const SizedBox.shrink();

    final maxY = (widget.goalHours).toDouble() + 1;
    final n = data.length;

    return Row(
      children: [
        // Left Y-axis (duration hours) - lavender
        SizedBox(
          width: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (i) {
              final value = maxY - (maxY / 4) * i;
              return Text(
                value == value.roundToDouble()
                    ? '${value.toInt()}h'
                    : '${value.toStringAsFixed(1)}h',
                style: TextStyle(fontSize: 9, color: widget.durationColor),
              );
            }),
          ),
        ),
        const SizedBox(width: 6),
        // Chart area with label overlay
        Expanded(
          child: ClipRect(
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  // Bar chart (duration)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 0),
                    child: BarChart(
                      BarChartData(
                        maxY: maxY,
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        enabled: true,
                        longPressDuration: const Duration(milliseconds: 100),
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => widget.durationColor,
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final d = data[group.x];
                            final dur = (d['duration'] as num?)?.toDouble() ?? 0;
                            final qual = (d['quality'] as num?)?.toDouble();
                            final lines = <String>[_formatDurationValue(dur)];
                            if (qual != null) lines.add(_formatQualityValue(qual));
                            return BarTooltipItem(
                              lines.join('\n'),
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                        touchCallback: (event, response) {
                          setState(() {
                            if (response != null && response.spot != null &&
                                event is FlLongPressEnd) {
                              _touchedBarIndex = null;
                            } else if (response != null && response.spot != null) {
                              _touchedBarIndex = response.spot!.touchedBarGroupIndex;
                            }
                          });
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= n) return const SizedBox.shrink();
                              final d = data[idx];
                              String main;
                              String sub;
                              if (widget.selectedRange == 7) {
                                main = _weekMainLabel(d);
                                sub = _weekSubLabel(d);
                              } else if (widget.selectedRange == 30) {
                                main = _monthMainLabel(idx);
                                sub = _monthSubLabel(d);
                              } else {
                                main = _yearMainLabel(d);
                                sub = '';
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(main, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
                                    if (sub.isNotEmpty)
                                      Text(sub, style: const TextStyle(fontSize: 8, color: Color(0xFF999999))),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFFE8E8E8),
                          strokeWidth: 0.5,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(n, (i) {
                        final dur = (data[i]['duration'] as num?)?.toDouble() ?? 0;
                        final hours = dur / 60;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: hours,
                              color: widget.durationColor.withValues(
                                alpha: _touchedBarIndex == i ? 1.0 : 0.75,
                              ),
                              width: n > 14 ? 8 : (n > 7 ? 12 : 20),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: widget.durationColor.withValues(alpha: 0.06),
                              ),
                            ),
                          ],
                          showingTooltipIndicators:
                              _touchedBarIndex == i ? [0] : [],
                        );
                      }),
                    ),
                  ),
                ),
                // Line chart (quality)
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 0),
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 5.5,
                      clipData: FlClipData.all(),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        longPressDuration: const Duration(milliseconds: 100),
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => widget.qualityColor,
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final d = spot.x.toInt() < data.length
                                  ? data[spot.x.toInt()]
                                  : null;
                              final dur = d != null
                                  ? _formatDurationValue(
                                      (d['duration'] as num?)?.toDouble() ?? 0)
                                  : '';
                              return LineTooltipItem(
                                '${_formatQualityValue(spot.y)}${dur.isNotEmpty ? '\n$dur' : ''}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        touchCallback: (event, response) {
                          setState(() {
                            if (event is FlLongPressEnd) {
                              _touchedLineIndex = null;
                            } else if (response != null &&
                                response.lineBarSpots != null &&
                                response.lineBarSpots!.isNotEmpty) {
                              _touchedLineIndex =
                                  response.lineBarSpots!.first.spotIndex;
                            }
                          });
                        },
                      ),
                      titlesData: FlTitlesData(show: false),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(n, (i) {
                            final quality =
                                (data[i]['quality'] as num?)?.toDouble();
                            return FlSpot(i.toDouble(), quality ?? 0);
                          }),
                          isCurved: true,
                          preventCurveOverShooting: true,
                          curveSmoothness: 0.3,
                          color: widget.qualityColor,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              final isTouched = _touchedLineIndex == index;
                              return FlDotCirclePainter(
                                radius: isTouched ? 5 : 3.5,
                                color: Colors.white,
                                strokeWidth: isTouched ? 3 : 2,
                                strokeColor: widget.qualityColor,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 250),
                  ),
                ),
                // Value label overlay
                CustomPaint(
                  size: Size.infinite,
                  painter: _ChartLabelPainter(
                    data: data,
                    maxY: maxY,
                    barColor: widget.durationColor,
                    lineColor: widget.qualityColor,
                    touchedBarIndex: _touchedBarIndex,
                    touchedLineIndex: _touchedLineIndex,
                    formatDuration: _formatDurationValue,
                    formatQuality: _formatQualityValue,
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
        const SizedBox(width: 6),
        // Right Y-axis (quality 1-5) - pink
        SizedBox(
          width: 24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(6, (i) {
              return Text(
                '${5 - i}',
                style: TextStyle(fontSize: 9, color: widget.qualityColor),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ChartLabelPainter extends CustomPainter {
  _ChartLabelPainter({
    required this.data,
    required this.maxY,
    required this.barColor,
    required this.lineColor,
    required this.touchedBarIndex,
    required this.touchedLineIndex,
    required this.formatDuration,
    required this.formatQuality,
  });

  final List<Map<String, dynamic>> data;
  final double maxY;
  final Color barColor;
  final Color lineColor;
  final int? touchedBarIndex;
  final int? touchedLineIndex;
  final String Function(double) formatDuration;
  final String Function(double) formatQuality;

  @override
  void paint(Canvas canvas, Size size) {
    final n = data.length;
    if (n == 0) return;

    // Chart padding must match the Padding widget around the charts
    const chartPadLeft = 4.0;
    const chartPadRight = 4.0;
    const chartPadTop = 8.0;
    const chartPadBottom = 0.0;

    final chartW = size.width - chartPadLeft - chartPadRight;
    final chartH = size.height - chartPadTop - chartPadBottom;

    // Bar width matches the chart
    final barWidth = n > 14 ? 8.0 : (n > 7 ? 12.0 : 20.0);

    // Bar x-position formula (matches fl_chart spaceAround)
    final extraSpace = (chartW - n * barWidth) / n;
    final eachSpace = barWidth + extraSpace;

    // Y-axis mapping: value 0..maxY → chart bottom..top
    double valueToY(double value) {
      final ratio = (value / maxY).clamp(0.0, 1.0);
      return chartPadTop + chartH * (1 - ratio);
    }

    for (var i = 0; i < n; i++) {
      final centerX = chartPadLeft + eachSpace * 0.5 + i * eachSpace;
      final dur = (data[i]['duration'] as num?)?.toDouble() ?? 0;
      final qual = (data[i]['quality'] as num?)?.toDouble();
      final hours = dur / 60;
      final isBarTouched = touchedBarIndex == i;
      final isLineTouched = touchedLineIndex == i;

      // Duration label on top of bar
      final barTopY = valueToY(hours);
      if (isBarTouched) {
        _drawLabel(canvas, centerX, barTopY - 14, formatDuration(dur), barColor, bold: true);
      } else {
        _drawLabel(canvas, centerX, barTopY - 12, formatDuration(dur), barColor);
      }

      // Quality label near line point
      if (qual != null) {
        final pointY = valueToY(qual * maxY / 5.5);
        final labelY = pointY - (isLineTouched ? 16 : 14);
        if (isLineTouched) {
          _drawLabel(canvas, centerX, labelY, formatQuality(qual), lineColor, bold: true);
        } else {
          _drawLabel(canvas, centerX, labelY, formatQuality(qual), lineColor);
        }
      }
    }
  }

  void _drawLabel(Canvas canvas, double cx, double cy, String text, Color color,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: bold ? 10 : 9,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = cx - tp.width / 2;
    final dy = cy - tp.height / 2;
    // Background pill
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dx - 3, dy - 1, tp.width + 6, tp.height + 2),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _ChartLabelPainter old) =>
      touchedBarIndex != old.touchedBarIndex ||
      touchedLineIndex != old.touchedLineIndex ||
      data != old.data;
}


