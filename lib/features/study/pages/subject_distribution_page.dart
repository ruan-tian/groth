import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../study/providers/study_provider.dart';

// =============================================================================
// 科目调色板 — 蓝色同色系（按排序 index 分配，最多 15 色）
// =============================================================================

List<Color> _subjectPalette(AppThemeColors c) => [
  const Color(0xFF3F5FEA), // 主蓝
  const Color(0xFF5B7CFA), // 柔和蓝紫
  const Color(0xFF7EA6FF), // 浅蓝
  const Color(0xFF8FB7FF), // 更浅蓝
  const Color(0xFF4A6CF7), // 深蓝紫
  const Color(0xFF6B8CFF), // 中蓝紫
  const Color(0xFF9DBBFF), // 雾蓝
  const Color(0xFF5C7DF9), // 靛蓝
  const Color(0xFFA8C4FF), // 淡蓝
  const Color(0xFF7494FF), // 天蓝
  const Color(0xFFB8D0FF), // 极淡蓝
  const Color(0xFF6E8EFF), // 中等蓝
  const Color(0xFFC4D6FF), // 薄雾蓝
  const Color(0xFF8AA2FF), // 灰蓝
  const Color(0xFFD0DAFF), // 最淡蓝
];

Color _uncategorizedColor() => const Color(0xFFBFCBEE); // 雾蓝灰

Color _colorByIndex(AppThemeColors colors, int index) {
  final palette = _subjectPalette(colors);
  return palette[index % palette.length];
}

// =============================================================================
// 科目分布详情页
// =============================================================================

class SubjectDistributionPage extends ConsumerStatefulWidget {
  const SubjectDistributionPage({super.key});

  @override
  ConsumerState<SubjectDistributionPage> createState() =>
      _SubjectDistributionPageState();
}

class _SubjectDistributionPageState
    extends ConsumerState<SubjectDistributionPage> {
  int _touchedIndex = -1;
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final overview = ref.watch(studyOverviewByRangeProvider(_selectedDays));

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: overview.when(
          data: (data) {
            if (data.distribution.isEmpty) {
              return _buildEmptyState(colors);
            }
            return _buildContent(data, colors);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败: $e')),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeColors colors) {
    return Column(
      children: [
        _buildHeader(colors),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 64,
                  color: colors.textTertiary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('暂无科目数据', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '添加学习记录后，科目分布会显示在这里',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(StudyOverview data, AppThemeColors colors) {
    final entries = data.distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = data.totalMinutes;
    final uncategorized = data.distribution['未分类'] ?? 0;
    final showTip = total > 0 && (uncategorized / total) > 0.8;

    return Column(
      children: [
        // ── 自定义头部 ──
        _buildHeader(colors),
        // ── 范围选择器 ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildRangeSelector(colors),
        ),
        const SizedBox(height: 16),
        // ── 内容区域 ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 概览卡片 ──
                _buildOverviewCard(data, colors),
                const SizedBox(height: 16),
                // ── 科目占比卡片 ──
                _buildDistributionCard(entries, total, colors),
                // ── 分类建议 ──
                if (showTip) ...[
                  const SizedBox(height: 12),
                  _buildTip(colors),
                ],
                const SizedBox(height: 24),
                // ── 详细数据 ──
                Text(
                  '详细数据',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(entries.length, (index) {
                  final entry = entries[index];
                  return _buildRankCard(
                    index + 1,
                    entry.key,
                    entry.value,
                    total,
                    colors,
                    index,
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: colors.textPrimary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '科目分布',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '查看不同时间范围内的学习科目占比',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(AppThemeColors colors) {
    const ranges = [
      {'label': '日', 'days': 1},
      {'label': '周', 'days': 7},
      {'label': '月', 'days': 30},
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: ranges.map((range) {
          final isSelected = _selectedDays == range['days'];
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedDays = range['days'] as int),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? colors.study : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  range['label'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colors.textOnAccent
                        : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCard(StudyOverview data, AppThemeColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEF1F8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F5FEA).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedDays == 1
                ? '今日学习概览'
                : _selectedDays == 7
                    ? '本周学习概览'
                    : '本月学习概览',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatMinutes(data.totalMinutes),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '总学习时长',
            style: TextStyle(
              fontSize: 13,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.calendar_today_rounded,
                label: '已记录 ${data.activeDays} 天',
                colors: colors,
              ),
              const SizedBox(width: 16),
              _buildStatChip(
                icon: Icons.trending_up_rounded,
                label: '日均 ${_formatMinutes(data.dailyAverage)}',
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required AppThemeColors colors,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.textTertiary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionCard(
    List<MapEntry<String, int>> entries,
    int total,
    AppThemeColors colors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEF1F8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F5FEA).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '科目占比',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左侧：环形图
              _buildDonutChart(entries, total, colors),
              const SizedBox(width: 28),
              // 右侧：图例
              Expanded(
                child: _buildLegend(entries, total, colors),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(
    List<MapEntry<String, int>> entries,
    int total,
    AppThemeColors colors,
  ) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
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
              centerSpaceRadius: 44,
              sections: _buildSections(entries, total, colors),
            ),
            duration: const Duration(milliseconds: 150),
            curve: Curves.linear,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatMinutes(total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '总学习',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(
    List<MapEntry<String, int>> entries,
    int total,
    AppThemeColors colors,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final isUncategorized = entry.key == '未分类';
        final color = isUncategorized
            ? _uncategorizedColor()
            : _colorByIndex(colors, index);
        final percent =
            total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTip(AppThemeColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: colors.study,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '大部分记录暂未分类，建议补充科目标签',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.study,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(
    int rank,
    String subject,
    int minutes,
    int total,
    AppThemeColors colors,
    int index,
  ) {
    final isUncategorized = subject == '未分类';
    final color = isUncategorized
        ? _uncategorizedColor()
        : _colorByIndex(colors, index);
    final percent =
        total > 0 ? (minutes / total * 100).toStringAsFixed(1) : '0';
    final subtitle = isUncategorized ? '暂未设置科目标签' : '已分类学习记录';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEF1F8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F5FEA).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 序号
              Text(
                rank.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA5AEC2),
                ),
              ),
              const SizedBox(width: 14),
              // 科目名 + 说明
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8A93A8),
                      ),
                    ),
                  ],
                ),
              ),
              // 时长 + 百分比
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatMinutes(minutes),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A93A8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 胶囊进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total > 0 ? minutes / total : 0,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<MapEntry<String, int>> entries,
    int total,
    AppThemeColors colors,
  ) {
    return List.generate(entries.length, (index) {
      final isTouched = _touchedIndex == index;
      final entry = entries[index];
      final isUncategorized = entry.key == '未分类';
      final color = isUncategorized
          ? _uncategorizedColor()
          : _colorByIndex(colors, index);

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '',
        radius: isTouched ? 28 : 24,
        borderSide: BorderSide(
          color: colors.card.withValues(alpha: 0.8),
          width: 1.5,
        ),
      );
    });
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h${m}m' : '${h}h';
  }
}
