import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/chart_scale_utils.dart';
import '../../../shared/providers/database_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/study_provider.dart';

/// 学习记录详情页
///
/// 展示单条学习记录的完整信息，支持删除操作。
class StudyRecordDetailPage extends ConsumerWidget {
  const StudyRecordDetailPage({super.key, required this.recordId});

  final int recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(_studyRecordByIdProvider(recordId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: recordAsync.when(
        data: (record) => _DetailBody(record: record),
        loading: () => Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.study,
            ),
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: AppColors.danger.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('加载失败', style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$e',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 根据 ID 查询单条记录的 Provider
// =============================================================================

final _studyRecordByIdProvider =
    FutureProvider.family<StudyRecord, int>((ref, id) async {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.studyRecords)
    ..where((t) => t.id.equals(id));
  return query.getSingle();
});

// =============================================================================
// 详情内容
// =============================================================================

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.record});

  final StudyRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProfessional = record.mode == 'professional';
    final startDt = DateTime.fromMillisecondsSinceEpoch(record.startTime);
    final endDt = DateTime.fromMillisecondsSinceEpoch(record.endTime);
    final createdDt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── 渐变 Header ──
        SliverToBoxAdapter(child: _buildHeader(context, ref)),

        // ── 正文内容 ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 信息网格 (2x2) ──
                _buildInfoGrid(context),
                const SizedBox(height: AppSpacing.lg),

                // ── 时间信息 ──
                _buildSection(
                  icon: Icons.schedule_rounded,
                  title: '时间信息',
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.play_circle_outline_rounded,
                        label: '开始',
                        value: _formatDateTime(startDt),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.stop_circle_outlined,
                        label: '结束',
                        value: _formatDateTime(endDt),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.access_time_rounded,
                        label: '时长',
                        value: '${record.durationMinutes} 分钟',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: '记录于',
                        value: _formatDateTime(createdDt),
                      ),
                    ],
                  ),
                ),

                // ── 专业模式信息 ──
                if (isProfessional) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildProfessionalSection(context),
                ],

                // ── 收获 ──
                if (record.gain != null && record.gain!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildSection(
                    icon: Icons.lightbulb_outline_rounded,
                    title: '收获',
                    child: Text(
                      record.gain!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                // ── 遗留问题 ──
                if (record.problem != null && record.problem!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildSection(
                    icon: Icons.help_outline_rounded,
                    title: '遗留问题',
                    child: Text(
                      record.problem!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                // ── 备注 ──
                if (record.note != null && record.note!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildSection(
                    icon: Icons.notes_rounded,
                    title: '备注',
                    child: Text(
                      record.note!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                // ── 学习趋势 ──
                const SizedBox(height: AppSpacing.xl),
                _buildSectionTitle('学习趋势'),
                const SizedBox(height: AppSpacing.md),
                _StudyTrendChart(record: record),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 渐变 Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isProfessional = record.mode == 'professional';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl, 56, AppSpacing.xxl, AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.study,
            AppColors.study.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // ── 顶部操作栏 ──
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _confirmDelete(context, ref),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 图标 ──
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          // ── 标题 ──
          Text(
            record.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // ── 标签行 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeaderBadge(
                icon: Icons.star_rounded,
                text: '+${record.expGained} EXP',
              ),
              const SizedBox(width: 10),
              _HeaderBadge(
                icon: isProfessional ? Icons.school_rounded : Icons.menu_book_rounded,
                text: isProfessional ? '专业模式' : '简单模式',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 信息网格 (2x2)
  // ---------------------------------------------------------------------------

  Widget _buildInfoGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.timer_outlined,
                label: '时长',
                value: '${record.durationMinutes}分钟',
                color: AppColors.study,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.book_outlined,
                label: '科目',
                value: record.subject ?? '--',
                color: AppColors.study,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.speed_rounded,
                label: '难度',
                value: record.difficultyLevel != null
                    ? '${record.difficultyLevel}/5'
                    : '--',
                color: AppColors.study,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.check_circle_outline_rounded,
                label: '掌握度',
                value: record.masteryLevel != null
                    ? '${record.masteryLevel}/5'
                    : '--',
                color: AppColors.study,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 专业模式信息
  // ---------------------------------------------------------------------------

  Widget _buildProfessionalSection(BuildContext context) {
    return _buildSection(
      icon: Icons.school_rounded,
      title: '专业信息',
      child: Column(
        children: [
          if (record.chapter != null && record.chapter!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.bookmark_outline_rounded,
              label: '章节',
              value: record.chapter!,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (record.focusLevel != null) ...[
            _InfoRow(
              icon: Icons.center_focus_strong_rounded,
              label: '专注度',
              value: '${record.focusLevel}/5',
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 通用区块
  // ---------------------------------------------------------------------------

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.study.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.study.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.study.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: AppColors.study),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 区块标题（无卡片容器）
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.study,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 工具方法
  // ---------------------------------------------------------------------------

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('删除确认'),
          ],
        ),
        content: Text(
          '确定要删除学习记录「${record.title}」吗？\n此操作不可撤销。',
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(studyRepositoryProvider);
        await repo.deleteStudyRecord(record.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('已删除'),
              backgroundColor: AppColors.textPrimary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: $e'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          );
        }
      }
    }
  }
}

// =============================================================================
// Header 徽章
// =============================================================================

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 信息瓦片 (2x2 网格中的一块)
// =============================================================================

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 信息行
// =============================================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 学习趋势图
// =============================================================================

class _StudyTrendChart extends ConsumerStatefulWidget {
  const _StudyTrendChart({required this.record});

  final StudyRecord record;

  @override
  ConsumerState<_StudyTrendChart> createState() => _StudyTrendChartState();
}

class _StudyTrendChartState extends ConsumerState<_StudyTrendChart> {
  String _selectedRange = 'week';

  static const _barColor = AppColors.study;
  final _barColorLight = AppColors.study.withValues(alpha: 0.3);
  static const _tooltipBg = Color(0xFF1E293B);

  // ── 周/月/年中文名 ──
  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const _months = [
    '1月', '2月', '3月', '4月', '5月', '6月',
    '7月', '8月', '9月', '10月', '11月', '12月',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.study.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.study.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRangeSelector(),
          const SizedBox(height: AppSpacing.lg),
          _buildChart(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 范围选择器
  // ---------------------------------------------------------------------------

  Widget _buildRangeSelector() {
    const options = [
      ('week', '本周'),
      ('month', '本月'),
      ('year', '本年'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: options.map((opt) {
          final selected = _selectedRange == opt.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRange = opt.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _barColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                ),
                child: Text(
                  opt.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 图表主体
  // ---------------------------------------------------------------------------

  Widget _buildChart() {
    switch (_selectedRange) {
      case 'week':
        return _buildWeekChart();
      case 'month':
        return _buildMonthChart();
      case 'year':
        return _buildYearChart();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── 本周图表 ──
  Widget _buildWeekChart() {
    final async = ref.watch(weeklyDailyStudyProvider);
    return async.when(
      data: (stats) {
        final now = DateTime.now();
        // 构建 7 天数据（周一到周日）
        final weekday = now.weekday; // 1=Mon
        final monday = now.subtract(Duration(days: weekday - 1));
        final days = List.generate(7, (i) => monday.add(Duration(days: i)));

        final barData = days.map((day) {
          final match = stats.where((s) =>
              s.date.year == day.year &&
              s.date.month == day.month &&
              s.date.day == day.day);
          return _TrendBarData(
            label: _weekdays[day.weekday - 1],
            subLabel: '${day.month}/${day.day}',
            value: match.isNotEmpty ? match.first.studyMinutes : 0,
            date: day,
          );
        }).toList();

        return _buildBarChart(
          barData: barData,
          range: 'week',
          emptyHint: '本周暂无学习数据',
        );
      },
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _barColor)),
      ),
      error: (e, _) => SizedBox(
        height: 240,
        child: Center(child: Text('加载失败: $e', style: AppTextStyles.caption)),
      ),
    );
  }

  // ── 本月图表 ──
  Widget _buildMonthChart() {
    final async = ref.watch(monthlyDailyStudyProvider);
    return async.when(
      data: (stats) {
        // 聚合为 4 周
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final weeks = <_TrendBarData>[];

        for (int w = 0; w < 4; w++) {
          final weekStart = monthStart.add(Duration(days: w * 7));
          final weekEnd = weekStart.add(const Duration(days: 6));
          final weekStats = stats.where((s) =>
              !s.date.isBefore(weekStart) && !s.date.isAfter(weekEnd));
          final total = weekStats.fold<int>(0, (sum, s) => sum + s.studyMinutes);

          final startStr = '${weekStart.month}/${weekStart.day}';
          final endStr = '${weekEnd.month}/${weekEnd.day}';
          weeks.add(_TrendBarData(
            label: '第${w + 1}周',
            subLabel: '$startStr-$endStr',
            value: total,
          ));
        }

        return _buildBarChart(
          barData: weeks,
          range: 'month',
          emptyHint: '本月暂无学习数据',
        );
      },
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _barColor)),
      ),
      error: (e, _) => SizedBox(
        height: 240,
        child: Center(child: Text('加载失败: $e', style: AppTextStyles.caption)),
      ),
    );
  }

  // ── 本年图表 ──
  Widget _buildYearChart() {
    final async = ref.watch(yearlyMonthlyStudyProvider);
    return async.when(
      data: (stats) {
        final barData = stats.map((s) {
          // month 格式: YYYY-MM
          final parts = s.month.split('-');
          final monthIndex = int.tryParse(parts.last) ?? 1;
          return _TrendBarData(
            label: _months[monthIndex - 1],
            value: s.studyMinutes,
          );
        }).toList();

        return _buildBarChart(
          barData: barData,
          range: 'year',
          emptyHint: '本年暂无学习数据',
        );
      },
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _barColor)),
      ),
      error: (e, _) => SizedBox(
        height: 240,
        child: Center(child: Text('加载失败: $e', style: AppTextStyles.caption)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 通用柱状图
  // ---------------------------------------------------------------------------

  Widget _buildBarChart({
    required List<_TrendBarData> barData,
    required String range,
    required String emptyHint,
  }) {
    if (barData.isEmpty || barData.every((d) => d.value == 0)) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Text(emptyHint, style: AppTextStyles.caption),
        ),
      );
    }

    final minutesList = barData.map((d) => d.value).toList();
    final scale = buildDurationChartScale(minutesList);
    final yMax = scale.maxY;

    return ClipRect(
      child: SizedBox(
        height: 240,
        child: BarChart(
          BarChartData(
            maxY: yMax * 1.25,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: _buildTouchData(barData, scale),
            titlesData: _buildTitles(barData, scale, yMax, range),
            gridData: _buildGrid(scale),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(barData.length, (i) {
              return _buildBarGroup(i, barData, yMax, range);
            }),
          ),
        ),
      ),
    );
  }

  // ── 触摸交互 ──
  BarTouchData _buildTouchData(List<_TrendBarData> barData, DurationChartScale scale) {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => _tooltipBg,
        tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final bar = barData[group.x];
          final title = bar.subLabel ?? bar.label;
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
            ],
          );
        },
      ),
    );
  }

  // ── 坐标轴标题 ──
  FlTitlesData _buildTitles(
    List<_TrendBarData> barData,
    DurationChartScale scale,
    double yMax,
    String range,
  ) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: range == 'week' ? 44 : 36,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= barData.length) {
              return const SizedBox.shrink();
            }
            return _buildBottomLabel(index, barData, range);
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
      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= barData.length) {
              return const SizedBox.shrink();
            }
            final bar = barData[index];
            if (bar.value == 0) return const SizedBox.shrink();
            // 当数据点过多时，只显示首尾和最大值
            if (barData.length > 10) {
              if (index != 0 && index != barData.length - 1) {
                final maxValue = barData.map((b) => b.value).reduce((a, b) => a > b ? a : b);
                if (bar.value != maxValue) return const SizedBox.shrink();
              }
            }
            return _TrendValueBubble(value: _formatMinutesCompact(bar.value));
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
  BarChartGroupData _buildBarGroup(
    int index,
    List<_TrendBarData> barData,
    double yMax,
    String range,
  ) {
    final bar = barData[index];
    final highlighted = _isHighlighted(index, barData, range);
    final barWidth = range == 'week' ? 20.0 : range == 'month' ? 28.0 : 16.0;

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: bar.value.toDouble(),
          color: highlighted ? _barColor : _barColorLight,
          width: barWidth,
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
    );
  }

  // ── 底部标签 ──
  Widget _buildBottomLabel(int index, List<_TrendBarData> barData, String range) {
    final bar = barData[index];
    final highlighted = _isHighlighted(index, barData, range);

    final mainStyle = TextStyle(
      fontSize: range == 'month' ? 10 : 11,
      fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
      color: highlighted ? _barColor : AppColors.textPrimary,
    );
    final subStyle = TextStyle(
      fontSize: 10,
      color: highlighted ? _barColor : AppColors.textTertiary,
    );

    if (range == 'week') {
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

    if (range == 'month') {
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

  // ── 辅助方法 ──
  bool _isHighlighted(int index, List<_TrendBarData> barData, String range) {
    if (range == 'week' && barData[index].date != null) {
      final now = DateTime.now();
      final d = barData[index].date!;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }
    return false;
  }

  String _formatMinutesCompact(int minutes) {
    if (minutes <= 0) return '0';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '$h.${(m * 10 / 60).round()}h';
  }
}

// =============================================================================
// 趋势图柱状数据
// =============================================================================

class _TrendBarData {
  const _TrendBarData({
    required this.label,
    required this.value,
    this.subLabel,
    this.date,
  });

  final String label;
  final int value;
  final String? subLabel;
  final DateTime? date;
}

// =============================================================================
// 趋势图柱顶数值气泡
// =============================================================================

class _TrendValueBubble extends StatelessWidget {
  const _TrendValueBubble({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.study,
        ),
      ),
    );
  }
}
