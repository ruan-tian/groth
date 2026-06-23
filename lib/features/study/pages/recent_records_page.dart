import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../study/providers/study_provider.dart';
import '../../../shared/widgets/common/date_group_header.dart';

/// 学习记录排序方式
enum StudySortOption { newest, oldest, highestExp }

/// 最近学习记录详情页
///
/// 支持排序、日期分组，使用高级卡片样式。
class RecentRecordsPage extends ConsumerStatefulWidget {
  const RecentRecordsPage({super.key});

  @override
  ConsumerState<RecentRecordsPage> createState() => _RecentRecordsPageState();
}

class _RecentRecordsPageState extends ConsumerState<RecentRecordsPage> {
  StudySortOption _sortOption = StudySortOption.newest;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final recentRecords = ref.watch(sortedRecentStudyRecordsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('学习记录', style: AppTextStyles.pageTitle),
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        actions: [
          PopupMenuButton<StudySortOption>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.study.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.sort_rounded, color: colors.study, size: 20),
            ),
            onSelected: (option) => setState(() => _sortOption = option),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            elevation: 4,
            itemBuilder: (context) => [
              _buildSortItem(
                StudySortOption.newest,
                '最新优先',
                Icons.access_time_rounded,
              ),
              _buildSortItem(
                StudySortOption.oldest,
                '最早优先',
                Icons.history_rounded,
              ),
              _buildSortItem(
                StudySortOption.highestExp,
                '经验值最高',
                Icons.star_rounded,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: recentRecords.when(
        data: (records) {
          if (records.isEmpty) {
            return _buildEmptyState();
          }
          return _buildRecordList(records);
        },
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colors.study,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('加载中...', style: AppTextStyles.caption),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('加载失败: $e', style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.lg),
              TextButton.icon(
                onPressed: () =>
                    ref.invalidate(sortedRecentStudyRecordsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<StudySortOption> _buildSortItem(
    StudySortOption option,
    String text,
    IconData icon,
  ) {
    final colors = context.growthColors;
    final isSelected = _sortOption == option;
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? colors.study : colors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colors.study : colors.textPrimary,
              ),
            ),
          ),
          if (isSelected)
            Icon(Icons.check_rounded, size: 18, color: colors.study),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 记录列表（按日期分组）
  // ---------------------------------------------------------------------------

  Widget _buildRecordList(List<StudyRecord> records) {
    final colors = context.growthColors;
    final sorted = _sortRecords(records);

    // 统计汇总
    final totalCount = sorted.length;
    final totalMinutes = sorted.fold<int>(
      0,
      (sum, r) => sum + r.durationMinutes,
    );
    final totalExp = sorted.fold<int>(0, (sum, r) => sum + r.expGained);

    // 按日期分组
    final groups = groupRecordsByDate(
      sorted,
      (r) => DateTime.fromMillisecondsSinceEpoch(r.startTime),
    );

    final items = <_ListItem>[];
    for (final entry in groups.entries) {
      items.add(_ListItem.header(entry.key));
      for (final record in entry.value) {
        items.add(_ListItem.record(record));
      }
    }

    return RefreshIndicator(
      color: colors.study,
      backgroundColor: colors.card,
      onRefresh: () async {
        ref.invalidate(sortedRecentStudyRecordsProvider);
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        itemCount: items.length + 1, // +1 for stats header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildStatsHeader(totalCount, totalMinutes, totalExp);
          }
          final item = items[index - 1];
          if (item.isHeader) {
            return _DateGroupLabel(label: item.headerLabel!);
          }
          final record = item.record!;
          return _RecordCard(
            record: record,
            onTap: () => context.push('/plan/study/detail/${record.id}'),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 顶部统计卡片
  // ---------------------------------------------------------------------------

  Widget _buildStatsHeader(int count, int minutes, int exp) {
    final colors = context.growthColors;
    final hours = (minutes / 60).toStringAsFixed(1);
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.study, colors.study.withValues(alpha: 0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: colors.study.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.article_outlined,
            label: '总记录',
            value: '$count',
          ),
          _StatDivider(),
          _StatItem(
            icon: Icons.timer_outlined,
            label: '总时长',
            value: '${hours}h',
          ),
          _StatDivider(),
          _StatItem(
            icon: Icons.star_outline_rounded,
            label: '总经验',
            value: '$exp',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 空状态
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    final colors = context.growthColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.study.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 40,
                color: colors.study.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('暂无学习记录', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '开始你的第一次学习\n记录会显示在这里',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 排序
  // ---------------------------------------------------------------------------

  List<StudyRecord> _sortRecords(List<StudyRecord> records) {
    final sorted = List<StudyRecord>.from(records);
    switch (_sortOption) {
      case StudySortOption.newest:
        sorted.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case StudySortOption.oldest:
        sorted.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
      case StudySortOption.highestExp:
        sorted.sort((a, b) => b.expGained.compareTo(a.expGained));
        break;
    }
    return sorted;
  }
}

// =============================================================================
// 统计项
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
    final colors = context.growthColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: colors.textOnAccent.withValues(alpha: 0.85),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textOnAccent,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: colors.textOnAccent.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: 1,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.textOnAccent.withValues(alpha: 0.0),
            colors.textOnAccent.withValues(alpha: 0.25),
            colors.textOnAccent.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

// =============================================================================
// 日期分组标签
// =============================================================================

class _DateGroupLabel extends StatelessWidget {
  const _DateGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// =============================================================================
// 高级记录卡片
// =============================================================================

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, this.onTap});

  final StudyRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final dt = DateTime.fromMillisecondsSinceEpoch(record.startTime);
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final isProfessional = record.mode == 'professional';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: colors.study.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.study.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── 左侧图标 ──
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.study.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: colors.study,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),

            // ── 中间内容 ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (record.subject != null &&
                          record.subject!.isNotEmpty) ...[
                        Text(
                          record.subject!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          '  ·  ',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textHint,
                          ),
                        ),
                      ],
                      Text(
                        '${record.durationMinutes}分钟',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                      Text(
                        '  ·  ',
                        style: TextStyle(fontSize: 13, color: colors.textHint),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── 右侧徽章 ──
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Badge(
                  text: '+${record.expGained}',
                  color: colors.study,
                  icon: Icons.star_rounded,
                ),
                const SizedBox(height: 5),
                _Badge(
                  text: isProfessional ? '专业' : '简单',
                  color: colors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 徽章组件
// =============================================================================

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 列表项模型（分组头或记录）
// =============================================================================

class _ListItem {
  _ListItem.header(this.headerLabel) : record = null, isHeader = true;
  _ListItem.record(this.record) : headerLabel = null, isHeader = false;

  final String? headerLabel;
  final StudyRecord? record;
  final bool isHeader;
}
