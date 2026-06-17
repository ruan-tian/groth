import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/study_provider.dart';

// =============================================================================
// 科目调色板（按排序 index 分配颜色，最多 15 色）
// =============================================================================

List<Color> _subjectPalette(AppThemeColors c) => [
  c.danger, // 1 红
  c.fitness, // 2 橙
  c.diet, // 3 琥珀
  c.accent, // 4 金
  const Color(0xFF65A30D), // 5 黄绿
  const Color(0xFF059669), // 6 翠绿
  c.focus, // 7 青
  const Color(0xFF2563EB), // 8 钢蓝
  c.study, // 9 蓝
  c.sleep, // 10 紫
  const Color(0xFF7C3AED), // 11 紫罗兰
  const Color(0xFFDB2777), // 12 品红
  const Color(0xFFBE185D), // 13 玫红
  c.journal, // 14 玫粉
  c.primaryLight, // 15 浅靛
];

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
  List<MapEntry<String, int>> _entries = [];
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final subjectDist = ref.watch(
      subjectDistributionByRangeProvider(_selectedDays),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('科目分布', style: AppTextStyles.pageTitle),
        backgroundColor: colors.background,
      ),
      body: subjectDist.when(
        data: (dist) {
          if (dist.isEmpty) {
            return _buildEmptyState(colors);
          }
          return _buildContent(dist, colors);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: colors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('暂无科目数据', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Text('添加学习记录后，科目分布会显示在这里', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, int> dist, AppThemeColors colors) {
    final total = dist.values.fold<int>(0, (sum, v) => sum + v);
    _entries = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 范围选择器 ──
          _buildRangeSelector(colors),
          const SizedBox(height: AppSpacing.lg),

          // ── 饼图卡片 ──
          _buildPieChartCard(_entries, total, colors),
          const SizedBox(height: AppSpacing.xl),

          // ── 详细列表 ──
          Text('详细数据', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(_entries.length, (index) {
            final entry = _entries[index];
            return _buildSubjectTile(
              entry.key,
              entry.value,
              total,
              colors,
              index,
            );
          }),
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
      height: 36,
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: ranges.map((range) {
          final isSelected = _selectedDays == range['days'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDays = range['days'] as int),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? colors.study : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  range['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildPieChartCard(
    List<MapEntry<String, int>> entries,
    int total,
    AppThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 280,
            height: 280,
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
                    sectionsSpace: 3,
                    centerSpaceRadius: 70,
                    sections: _buildSections(entries, total, colors),
                  ),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.linear,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatHours(total),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
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
                  ],
                ),
              ],
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
      final color = _colorByIndex(colors, index);
      final percent = total > 0 ? (entry.value / total * 100).round() : 0;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: isTouched ? '$percent%' : '',
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: colors.textOnAccent,
        ),
        radius: isTouched ? 52 : 44,
        borderSide: isTouched
            ? BorderSide(color: colors.textOnAccent, width: 3)
            : BorderSide(
                color: colors.textOnAccent.withValues(alpha: 0.6),
                width: 1,
              ),
      );
    });
  }

  // ── 详细列表项 ──

  Widget _buildSubjectTile(
    String subject,
    int minutes,
    int total,
    AppThemeColors colors,
    int index,
  ) {
    final color = _colorByIndex(colors, index);
    final percent = (minutes / total * 100).toStringAsFixed(1);
    final isSelected = _touchedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _touchedIndex = _touchedIndex == index ? -1 : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : colors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.4) : colors.border,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 16 : 12,
                  height: isSelected ? 16 : 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: minutes / total,
                      minHeight: isSelected ? 10 : 8,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatMinutes(minutes),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? color : colors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 工具方法 ──

  String _formatHours(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '$h.${(m * 10 / 60).round()}h' : '${h}h';
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h${m}m' : '${h}h';
  }
}
