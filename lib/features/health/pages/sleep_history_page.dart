import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/sleep_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';

/// 睡眠记录排序方式
enum SleepSortOption { newest, oldest, highestQuality }

/// 睡眠历史记录页面
///
/// Premium lavender-themed page with gradient stats summary,
/// grouped records with consistent card styling, and a shared RecordDetailSheet.
class SleepHistoryPage extends ConsumerStatefulWidget {
  const SleepHistoryPage({super.key});

  @override
  ConsumerState<SleepHistoryPage> createState() => _SleepHistoryPageState();
}

class _SleepHistoryPageState extends ConsumerState<SleepHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'week';
  SleepSortOption _sortOption = SleepSortOption.newest;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedPeriod = 'week';
            break;
          case 1:
            _selectedPeriod = 'month';
            break;
          case 2:
            _selectedPeriod = 'all';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(recentSleepRecordsProvider(30));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '睡眠历史',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<SleepSortOption>(
            icon: const Icon(Icons.sort, color: AppColors.textSecondary),
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder: (context) => [
              _buildSortItem(SleepSortOption.newest, '最新优先'),
              _buildSortItem(SleepSortOption.oldest, '最早优先'),
              _buildSortItem(SleepSortOption.highestQuality, '质量最高'),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.lavender,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.lavender,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
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
            return _buildEmptyState();
          }

          return _buildRecordList(filteredRecords);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.lavender),
        ),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sort menu
  // ---------------------------------------------------------------------------

  PopupMenuItem<SleepSortOption> _buildSortItem(
    SleepSortOption option,
    String text,
  ) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Text(text, style: const TextStyle(fontSize: 14)),
          if (_sortOption == option) ...[
            const Spacer(),
            Icon(Icons.check, size: 16, color: AppColors.lavender),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats summary card (gradient lavender)
  // ---------------------------------------------------------------------------

  Widget _buildStatsSummary(List<SleepRecord> records) {
    final count = records.length;
    final avgDuration = count > 0
        ? records.map((r) => r.durationMinutes).reduce((a, b) => a + b) / count
        : 0.0;
    final avgQuality = count > 0
        ? records.map((r) => r.qualityLevel).reduce((a, b) => a + b) / count
        : 0.0;

    final hours = (avgDuration ~/ 60).toStringAsFixed(0);
    final mins = (avgDuration % 60).round().toString().padLeft(2, '0');
    final qualityStr = avgQuality.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.lavender, AppColors.lavenderDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender.withValues(alpha: 0.3),
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
            value: '$qualityStr',
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

  // ---------------------------------------------------------------------------
  // Record list (grouped by date)
  // ---------------------------------------------------------------------------

  Widget _buildRecordList(List<SleepRecord> records) {
    final sorted = _sortRecords(records);

    final groups = groupRecordsByDate(
      sorted,
      (r) => DateTime.parse(r.sleepDate),
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
        // ── Stats summary ──
        const SizedBox(height: AppSpacing.lg),
        _buildStatsSummary(records),

        // ── Record list ──
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

  // ---------------------------------------------------------------------------
  // Filtering & sorting
  // ---------------------------------------------------------------------------

  List<SleepRecord> _filterRecords(List<SleepRecord> records) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return records.where((r) {
          final date = DateTime.parse(r.sleepDate);
          return date.isAfter(weekAgo);
        }).toList();
      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        return records.where((r) {
          final date = DateTime.parse(r.sleepDate);
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
        break;
      case SleepSortOption.oldest:
        sorted.sort((a, b) => a.sleepDate.compareTo(b.sleepDate));
        break;
      case SleepSortOption.highestQuality:
        sorted.sort((a, b) => b.qualityLevel.compareTo(a.qualityLevel));
        break;
    }
    return sorted;
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: EmptyStateWidget(
          icon: Icons.nightlight_round,
          title: '暂无睡眠记录',
          subtitle: '记录你的睡眠数据，\n追踪每日睡眠质量',
          accentColor: AppColors.lavender,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Detail bottom sheet (uses shared RecordDetailSheet)
  // ---------------------------------------------------------------------------

  void _showRecordDetail(BuildContext context, SleepRecord record) {
    final date = DateTime.parse(record.sleepDate);
    final weekday =
        ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];
    final dateStr = '${date.year}年${date.month}月${date.day}日 $weekday';

    final hours = record.durationMinutes ~/ 60;
    final mins = record.durationMinutes % 60;

    RecordDetailSheet.show(
      context: context,
      title: dateStr,
      accentColor: AppColors.lavender,
      accentColorLight: AppColors.softLavender,
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
          _buildQualityCard(record),
          const SizedBox(height: AppSpacing.md),
          _buildEnergyCard(record),
          if (record.dreamNote?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            _buildDreamCard(record),
          ],
          if (record.note?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            _buildNoteCard(record),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Detail extra cards (shown inside RecordDetailSheet)
  // ---------------------------------------------------------------------------

  Widget _buildQualityCard(SleepRecord record) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFB347), size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '睡眠质量',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      '${record.qualityLevel}/5',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _qualityLabel(record.qualityLevel),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _qualityColor(record.qualityLevel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyCard(SleepRecord record) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.battery_charging_full_rounded,
            color: AppColors.success,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '醒后精力',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${record.energyLevel}/5',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDreamCard(SleepRecord record) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.softLavender,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.lavender, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '梦境',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  record.dreamNote!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(SleepRecord record) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.note_outlined, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '备注',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  record.note!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _qualityLabel(int quality) {
    switch (quality) {
      case 1:
        return '很差';
      case 2:
        return '较差';
      case 3:
        return '一般';
      case 4:
        return '良好';
      case 5:
        return '优秀';
      default:
        return '一般';
    }
  }

  Color _qualityColor(int quality) {
    if (quality >= 4) return AppColors.success;
    if (quality >= 3) return AppColors.warning;
    return AppColors.danger;
  }
}

// =============================================================================
// Stat item widget (used in the gradient stats summary)
// =============================================================================

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 22),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Sleep record card (premium lavender styling)
// =============================================================================

class _SleepRecordCard extends StatelessWidget {
  const _SleepRecordCard({
    required this.record,
    required this.onTap,
  });

  final SleepRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(record.sleepDate);
    final weekday =
        ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];
    final dateStr = '${date.month}月${date.day}日 $weekday';

    final hours = record.durationMinutes ~/ 60;
    final mins = record.durationMinutes % 60;
    final durationText =
        hours > 0 ? '${hours}h${mins > 0 ? '${mins}m' : ''}' : '${mins}m';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.lavender.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            // ── Leading icon ──
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.lavender.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.nightlight_round,
                color: AppColors.lavender,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // ── Center content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${record.sleepTime} - ${record.wakeTime}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    durationText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lavender,
                    ),
                  ),
                ],
              ),
            ),

            // ── Quality badge ──
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _qualityColor(record.qualityLevel).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: _qualityColor(record.qualityLevel),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${record.qualityLevel}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _qualityColor(record.qualityLevel),
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
                    color: _qualityColor(record.qualityLevel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _qualityLabel(int quality) {
    switch (quality) {
      case 1:
        return '很差';
      case 2:
        return '较差';
      case 3:
        return '一般';
      case 4:
        return '良好';
      case 5:
        return '优秀';
      default:
        return '一般';
    }
  }

  Color _qualityColor(int quality) {
    if (quality >= 4) return AppColors.success;
    if (quality >= 3) return AppColors.warning;
    return AppColors.danger;
  }
}

// =============================================================================
// List item model (header or record)
// =============================================================================

class _ListItem {
  _ListItem.header(this.headerLabel)
      : record = null,
        isHeader = true;
  _ListItem.record(this.record)
      : headerLabel = null,
        isHeader = false;

  final String? headerLabel;
  final SleepRecord? record;
  final bool isHeader;
}
