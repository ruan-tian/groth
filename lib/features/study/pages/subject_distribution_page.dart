import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/study_provider.dart';

/// 科目颜色映射
const _subjectColors = <String, Color>{
  '数学': Color(0xFF5B7CFF),
  '英语': Color(0xFF32C785),
  '物理': Color(0xFFFF9F43),
  '化学': Color(0xFFFF7BAA),
  '编程': Color(0xFF7C6BFF),
  '语文': Color(0xFF00BCD4),
  '历史': Color(0xFFE91E63),
  '地理': Color(0xFF4CAF50),
  '生物': Color(0xFFFF5722),
  '其他': Color(0xFF9E9E9E),
};

Color _getSubjectColor(String subject) {
  return _subjectColors[subject] ?? AppColors.primary;
}

/// 科目分布详情页
class SubjectDistributionPage extends ConsumerWidget {
  const SubjectDistributionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Icon(Icons.pie_chart_outline, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('暂无科目数据', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Text('添加学习记录后，科目分布会显示在这里', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, int> dist) {
    final total = dist.values.fold<int>(0, (sum, v) => sum + v);
    final entries = dist.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 环形图
          _buildDonutChart(entries, total),
          const SizedBox(height: AppSpacing.xl),

          // 科目列表
          Text('详细数据', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          ...entries.map((entry) => _buildSubjectTile(entry.key, entry.value, total)),
        ],
      ),
    );
  }

  Widget _buildDonutChart(List<MapEntry<String, int>> entries, int total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _DonutPainter(entries: entries, total: total),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(total / 60).toStringAsFixed(1)}h',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text('总学习时长', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 图例
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: entries.map((entry) {
              final color = _getSubjectColor(entry.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(entry.key, style: AppTextStyles.caption),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTile(String subject, int minutes, int total) {
    final color = _getSubjectColor(subject);
    final percent = (minutes / total * 100).toStringAsFixed(1);
    final hours = (minutes / 60).toStringAsFixed(1);

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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
                  backgroundColor: color.withOpacity(0.12),
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
              Text('${hours}h', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text('$percent%', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.entries, required this.total});

  final List<MapEntry<String, int>> entries;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;

    var startAngle = -pi / 2;

    for (var i = 0; i < entries.length; i++) {
      final minutes = entries[i].value;
      final sweepAngle = (minutes / total) * 2 * pi;
      final color = _getSubjectColor(entries[i].key);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
