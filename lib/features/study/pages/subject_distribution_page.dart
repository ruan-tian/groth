import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/study_provider.dart';

// =============================================================================
// 科目颜色映射（与 study_page 保持一致）
// =============================================================================

const _subjectColors = <String, Color>{
  '数学': Color(0xFF6366F1),      // 靛蓝色
  '英语': Color(0xFF10B981),      // 翠绿色
  '物理': Color(0xFF3B82F6),      // 蓝色
  '化学': Color(0xFFF59E0B),      // 琥珀色
  '编程': Color(0xFF8B5CF6),      // 紫色
  '语文': Color(0xFFEC4899),      // 粉色
  '历史': Color(0xFF14B8A6),      // 青色
  '地理': Color(0xFFEF4444),      // 红色
  '生物': Color(0xFF06B6D4),      // 天蓝色
  '其他': Color(0xFF9CA3AF),      // 浅灰色
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
  List<MapEntry<String, int>> _entries = [];

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
    _entries = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 饼图卡片 ──
          _buildPieChartCard(_entries, total),
          const SizedBox(height: AppSpacing.xl),

          // ── 详细列表 ──
          Text('详细数据', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          ..._entries.map((entry) =>
              _buildSubjectTile(entry.key, entry.value, total)),
        ],
      ),
    );
  }

  // ── 饼图卡片 ──

  Widget _buildPieChartCard(
      List<MapEntry<String, int>> entries, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
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
                    sectionsSpace: 3,
                    centerSpaceRadius: 70,
                    sections: _buildSections(entries, total),
                  ),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.linear,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatHours(total),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '总学习时长',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
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
  ) {
    return List.generate(entries.length, (index) {
      final isTouched = _touchedIndex == index;
      final entry = entries[index];
      final color = _getSubjectColor(entry.key);
      final percent = total > 0 ? (entry.value / total * 100).round() : 0;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: isTouched ? '$percent%' : '',
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        radius: isTouched ? 52 : 44,
        borderSide: isTouched
            ? const BorderSide(color: Colors.white, width: 3)
            : BorderSide(
                color: Colors.white.withValues(alpha: 0.6), width: 1),
      );
    });
  }

  // ── 详细列表项 ──

  Widget _buildSubjectTile(String subject, int minutes, int total) {
    final color = _getSubjectColor(subject);
    final percent = (minutes / total * 100).toStringAsFixed(1);
    final index = _entries.indexWhere((e) => e.key == subject);
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
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : AppColors.border,
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
                  Text(
                    subject,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: AppColors.textPrimary,
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
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: isSelected
                        ? color
                        : AppColors.textTertiary,
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
