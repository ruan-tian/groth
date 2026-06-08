import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/study_provider.dart';

// =============================================================================
// 科目颜色映射（与 study_page 保持一致）
// =============================================================================

const _subjectColors = <String, Color>{
  '数学': AppColors.study,
  '英语': AppColors.success,
  '物理': Color(0xFF3B82F6),
  '化学': Color(0xFF06B6D4),
  '编程': AppColors.primaryDark,
  '语文': Color(0xFF4ADE80),
  '历史': Color(0xFF6366F1),
  '地理': Color(0xFF14B8A6),
  '生物': Color(0xFF0EA5E9),
  '其他': AppColors.textTertiary,
};

Color _getSubjectColor(String subject) {
  return _subjectColors[subject] ?? AppColors.study;
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

  @override
  Widget build(BuildContext context) {
    final subjectDist = ref.watch(subjectDistributionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('科目分布', style: AppTextStyles.pageTitle),
        backgroundColor: AppColors.background,
      ),
      body: subjectDist.when(
        data: (dist) {
          if (dist.isEmpty) {
            return _buildEmptyState();
          }
          return _buildContent(dist);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('暂无科目数据', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Text('添加学习记录后，科目分布会显示在这里',
              style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, int> dist) {
    final total = dist.values.fold<int>(0, (sum, v) => sum + v);
    final entries = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 主卡片：左饼图 + 右图例 ──
          _buildPieChartCard(entries, total),
          const SizedBox(height: AppSpacing.xl),

          // ── 详细列表 ──
          Text('详细数据', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          ...entries.map((entry) =>
              _buildSubjectTile(entry.key, entry.value, total)),
        ],
      ),
    );
  }

  // ── 饼图卡片 ──

  Widget _buildPieChartCard(
      List<MapEntry<String, int>> entries, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 左侧：饼图 ──
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback:
                          (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 56,
                    sections: _buildSections(entries, total),
                  ),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.linear,
                ),
                // 中心总时长
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatHours(total),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '总学习时长',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // ── 右侧：图例列表 ──
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(entries.length, (index) {
                final entry = entries[index];
                final color = _getSubjectColor(entry.key);
                final percent = total > 0
                    ? (entry.value / total * 100).round()
                    : 0;
                final isSelected = _touchedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _touchedIndex =
                          _touchedIndex == index ? -1 : index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        // 彩色圆点
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 12 : 10,
                          height: isSelected ? 12 : 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 科目名
                        SizedBox(
                          width: 40,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 进度条
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: entry.value / total,
                              minHeight: 8,
                              backgroundColor:
                                  color.withValues(alpha: 0.1),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 时长 + 百分比
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatMinutes(entry.value),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<MapEntry<String, int>> entries,
    int total,
  ) {
    return List.generate(entries.length, (index) {
      final isTouched = _touchedIndex == index;
      final entry = entries[index];
      final color = _getSubjectColor(entry.key);

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '',
        radius: isTouched ? 44 : 38,
        borderSide: isTouched
            ? const BorderSide(color: Colors.white, width: 2.5)
            : BorderSide(
                color: Colors.white.withValues(alpha: 0.6), width: 1),
      );
    });
  }

  // ── 详细列表项 ──

  Widget _buildSubjectTile(String subject, int minutes, int total) {
    final color = _getSubjectColor(subject);
    final percent = (minutes / total * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: minutes / total,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(4),
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
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text('$percent%', style: AppTextStyles.caption),
            ],
          ),
        ],
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
