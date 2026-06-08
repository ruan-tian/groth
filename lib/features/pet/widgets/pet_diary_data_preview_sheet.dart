import 'package:flutter/material.dart';

class PetDiaryDataPreviewSheet extends StatelessWidget {
  const PetDiaryDataPreviewSheet({
    super.key,
    required this.summary,
    required this.onConfirm,
    this.isLoading = false,
  });

  final Map<String, dynamic> summary;
  final VoidCallback onConfirm;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final study = summary['study'] as Map<String, dynamic>? ?? {};
    final fitness = summary['fitness'] as Map<String, dynamic>? ?? {};
    final sleep = summary['sleep'] as Map<String, dynamic>? ?? {};
    final diet = summary['diet'] as Map<String, dynamic>? ?? {};
    final growth = summary['growth'] as Map<String, dynamic>? ?? {};
    final tasks = summary['tasks'] as Map<String, dynamic>? ?? {};

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF7FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8A8C7).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '让甜甜写今天的日记',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6E4A58),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '生成前只会发送昨天的统计摘要，不发送你的完整日记正文。',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF8E6D78),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  icon: Icons.menu_book_rounded,
                  label: '学习 ${study['minutes'] ?? 0} 分钟',
                ),
                _SummaryChip(
                  icon: Icons.fitness_center_rounded,
                  label: '健身 ${fitness['minutes'] ?? 0} 分钟',
                ),
                _SummaryChip(
                  icon: Icons.bedtime_rounded,
                  label: '睡眠 ${sleep['minutes'] ?? 0} 分钟',
                ),
                _SummaryChip(
                  icon: Icons.restaurant_rounded,
                  label: '饮食 ${diet['recordCount'] ?? 0} 条',
                ),
                _SummaryChip(
                  icon: Icons.task_alt_rounded,
                  label: '任务 ${tasks['completed'] ?? 0}/${tasks['total'] ?? 0}',
                ),
                _SummaryChip(
                  icon: Icons.auto_awesome_rounded,
                  label: '经验 +${growth['expGained'] ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF0C7D8)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: Color(0xFFD8709B),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '隐私边界：摘要里不包含用户日记正文，也不会加入成长经验统计。',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF8E6D78),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8E6D78),
                      side: const BorderSide(color: Color(0xFFE8A8C7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('先不写'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isLoading ? null : onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE889B5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('确认生成'),
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF2D2E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFFD8709B)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A5661),
            ),
          ),
        ],
      ),
    );
  }
}
