import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../models/health_data.dart';
import '../../health/providers/sleep_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';

enum SleepSortOption { newest, oldest, highestQuality }

class SleepHistoryPage extends ConsumerStatefulWidget {
  const SleepHistoryPage({super.key});

  @override
  ConsumerState<SleepHistoryPage> createState() => _SleepHistoryPageState();
}

class _SleepHistoryPageState extends ConsumerState<SleepHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedPeriod = 'week';
  SleepSortOption _sortOption = SleepSortOption.newest;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedPeriod = switch (_tabController.index) {
            0 => 'week',
            1 => 'month',
            _ => 'all',
          };
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final records = ref.watch(recentSleepRecordsProvider(30));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          '睡眠历史',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<SleepSortOption>(
            icon: Icon(Icons.sort_rounded, color: colors.textSecondary),
            color: colors.card,
            surfaceTintColor: colors.card,
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder: (context) => [
              _buildSortItem(context, SleepSortOption.newest, '最新优先'),
              _buildSortItem(context, SleepSortOption.oldest, '最早优先'),
              _buildSortItem(context, SleepSortOption.highestQuality, '质量最高'),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.sleep,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.sleep,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: '最近7天'),
            Tab(text: '最近30天'),
            Tab(text: '全部'),
          ],
        ),
      ),
      body: records.when(
        data: (allRecords) {
          final filteredRecords = _filterRecords(allRecords);
          if (filteredRecords.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildRecordList(context, filteredRecords);
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.sleep)),
        error: (e, _) => Center(
          child: Text('加载失败：$e', style: TextStyle(color: colors.textSecondary)),
        ),
      ),
    );
  }

  PopupMenuItem<SleepSortOption> _buildSortItem(
    BuildContext context,
    SleepSortOption option,
    String text,
  ) {
    final colors = context.growthColors;
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Text(text, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
          if (_sortOption == option) ...[
            const Spacer(),
            Icon(Icons.check_rounded, size: 16, color: colors.sleep),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context, List<SleepRecord> records) {
    final colors = context.growthColors;
    final count = records.length;
    final avgDuration = count > 0
        ? records.map((r) => r.durationMinutes).reduce((a, b) => a + b) / count
        : 0.0;
    final avgQuality = count > 0
        ? records.map((r) => r.qualityLevel).reduce((a, b) => a + b) / count
        : 0.0;

    final hours = (avgDuration ~/ 60).toStringAsFixed(0);
    final mins = (avgDuration % 60).round().toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.sleep, colors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.nightlight_round,
            label: '平均时长',
            value: '${hours}h${mins}m',
          ),
          _StatItem(
            icon: Icons.star_rounded,
            label: '平均质量',
            value: avgQuality.toStringAsFixed(1),
          ),
          _StatItem(
            icon: Icons.calendar_today_rounded,
            label: '总记录',
            value: '$count',
          ),
        ],
      ),
    );
  }

  Widget _buildRecordList(BuildContext context, List<SleepRecord> records) {
    final sorted = _sortRecords(records);
    final groups = groupRecordsByDate(
      sorted,
      (record) => DateTime.parse(record.sleepDate),
    );

    final items = <_ListItem>[];
    for (final entry in groups.entries) {
      items.add(_ListItem.header(entry.key));
      for (final record in entry.value) {
        items.add(_ListItem.record(record));
      }
    }

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        _buildStatsSummary(context, records),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item.isHeader) {
                return DateGroupHeader(label: item.headerLabel!);
              }
              final record = item.record!;
              return _SleepRecordCard(
                record: record,
                onTap: () => _showRecordDetail(context, record),
              );
            },
          ),
        ),
      ],
    );
  }

  List<SleepRecord> _filterRecords(List<SleepRecord> records) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return records.where((record) {
          final date = DateTime.parse(record.sleepDate);
          return date.isAfter(weekAgo);
        }).toList();
      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        return records.where((record) {
          final date = DateTime.parse(record.sleepDate);
          return date.isAfter(monthAgo);
        }).toList();
      default:
        return records;
    }
  }

  List<SleepRecord> _sortRecords(List<SleepRecord> records) {
    final sorted = List<SleepRecord>.from(records);
    switch (_sortOption) {
      case SleepSortOption.newest:
        sorted.sort((a, b) => b.sleepDate.compareTo(a.sleepDate));
      case SleepSortOption.oldest:
        sorted.sort((a, b) => a.sleepDate.compareTo(b.sleepDate));
      case SleepSortOption.highestQuality:
        sorted.sort((a, b) => b.qualityLevel.compareTo(a.qualityLevel));
    }
    return sorted;
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.growthColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: EmptyStateWidget(
          icon: Icons.nightlight_round,
          title: '暂无睡眠记录',
          subtitle: '记录你的睡眠数据，\n追踪每日睡眠质量',
          accentColor: colors.sleep,
        ),
      ),
    );
  }

  void _showRecordDetail(BuildContext context, SleepRecord record) {
    final colors = context.growthColors;
    final date = DateTime.parse(record.sleepDate);
    final weekday = _weekdayLabel(date);
    final dateStr = '${date.year}年${date.month}月${date.day}日 $weekday';
    final hours = record.durationMinutes ~/ 60;
    final mins = record.durationMinutes % 60;

    RecordDetailSheet.show(
      context: context,
      title: dateStr,
      accentColor: colors.sleep,
      accentColorLight: colors.softPurple,
      primaryMetricLabel: '睡眠时长',
      primaryMetricValue: '${hours}h ${mins}m',
      primaryMetricIcon: Icons.nightlight_round,
      detailItems: [
        DetailItem(
          label: '入睡时间',
          value: record.sleepTime,
          icon: Icons.nightlight_round,
        ),
        DetailItem(
          label: '起床时间',
          value: record.wakeTime,
          icon: Icons.wb_sunny_rounded,
        ),
        DetailItem(
          label: '入睡用时',
          value: '${record.fallAsleepMinutes}分钟',
          icon: Icons.timer_outlined,
        ),
        DetailItem(
          label: '夜间醒来',
          value: '${record.wakeCount}次',
          icon: Icons.notifications_none_rounded,
        ),
      ],
      extraCards: Column(
        children: [
          _buildQualityCard(context, record),
          const SizedBox(height: AppSpacing.md),
          _buildEnergyCard(context, record),
          if (record.dreamNote?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            _buildDreamCard(context, record),
          ],
          if (record.note?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            _buildNoteCard(context, record),
          ],
        ],
      ),
    );
  }

  Widget _buildQualityCard(BuildContext context, SleepRecord record) {
    final colors = context.growthColors;
    final qualityColor = _qualityColor(colors, record.qualityLevel);
    return _DetailInfoCard(
      backgroundColor: colors.softGold,
      icon: Icons.star_rounded,
      iconColor: qualityColor,
      label: '睡眠质量',
      value: '${record.qualityLevel}/5',
      trailing: _qualityLabel(record.qualityLevel),
      trailingColor: qualityColor,
    );
  }

  Widget _buildEnergyCard(BuildContext context, SleepRecord record) {
    final colors = context.growthColors;
    return _DetailInfoCard(
      backgroundColor: colors.softGreen,
      icon: Icons.battery_charging_full_rounded,
      iconColor: colors.success,
      label: '醒后精力',
      value: '${record.energyLevel}/5',
    );
  }

  Widget _buildDreamCard(BuildContext context, SleepRecord record) {
    final colors = context.growthColors;
    return _TextDetailCard(
      backgroundColor: colors.softPurple,
      icon: Icons.auto_awesome_rounded,
      iconColor: colors.sleep,
      label: '梦境',
      value: record.dreamNote!,
    );
  }

  Widget _buildNoteCard(BuildContext context, SleepRecord record) {
    final colors = context.growthColors;
    return _TextDetailCard(
      backgroundColor: colors.surfaceVariant,
      icon: Icons.note_outlined,
      iconColor: colors.textSecondary,
      label: '备注',
      value: record.note!,
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trailing,
    this.trailingColor,
  });

  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? trailing;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        trailing!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: trailingColor ?? iconColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextDetailCard extends StatelessWidget {
  const _TextDetailCard({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: colors.textOnAccent.withValues(alpha: 0.86),
          size: 22,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: colors.textOnAccent,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textOnAccent.withValues(alpha: 0.76),
          ),
        ),
      ],
    );
  }
}

class _SleepRecordCard extends StatelessWidget {
  const _SleepRecordCard({required this.record, required this.onTap});

  final SleepRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final date = DateTime.parse(record.sleepDate);
    final dateStr = '${date.month}月${date.day}日 ${_weekdayLabel(date)}';
    final hours = record.durationMinutes ~/ 60;
    final mins = record.durationMinutes % 60;
    final durationText = hours > 0
        ? '${hours}h${mins > 0 ? '${mins}m' : ''}'
        : '${mins}m';
    final qualityColor = _qualityColor(colors, record.qualityLevel);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.softPurple.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.nightlight_round,
                color: colors.sleep,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${record.sleepTime} - ${record.wakeTime}',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    durationText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.sleep,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: qualityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: qualityColor),
                      const SizedBox(width: 2),
                      Text(
                        '${record.qualityLevel}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: qualityColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _qualityLabel(record.qualityLevel),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: qualityColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListItem {
  _ListItem.header(this.headerLabel) : record = null, isHeader = true;
  _ListItem.record(this.record) : headerLabel = null, isHeader = false;

  final String? headerLabel;
  final SleepRecord? record;
  final bool isHeader;
}

String _weekdayLabel(DateTime date) {
  return const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];
}

String _qualityLabel(int quality) {
  return switch (quality) {
    1 => '很差',
    2 => '较差',
    3 => '一般',
    4 => '良好',
    5 => '优秀',
    _ => '一般',
  };
}

Color _qualityColor(AppThemeColors colors, int quality) {
  if (quality >= 4) return colors.success;
  if (quality >= 3) return colors.warning;
  return colors.danger;
}
