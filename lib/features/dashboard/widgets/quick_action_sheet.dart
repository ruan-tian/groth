import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import '../../../shared/widgets/common/common_widgets.dart';

class QuickActionSheet extends StatelessWidget {
  const QuickActionSheet({
    super.key,
    required this.onStudy,
    required this.onFitness,
    required this.onJournal,
  });

  final VoidCallback onStudy;
  final VoidCallback onFitness;
  final VoidCallback onJournal;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onStudy,
    required VoidCallback onFitness,
    required VoidCallback onJournal,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionSheet(
        onStudy: onStudy,
        onFitness: onFitness,
        onJournal: onJournal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      title: '快速记录',
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionTile(
            icon: Icons.menu_book_rounded,
            color: AppColors.study,
            title: '添加学习',
            subtitle: '记录时长、难度和收获',
            onTap: () => _closeThen(context, onStudy),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.fitness_center_rounded,
            color: AppColors.fitness,
            title: '添加健身',
            subtitle: '记录训练、强度和感受',
            onTap: () => _closeThen(context, onFitness),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.edit_note_rounded,
            color: AppColors.journal,
            title: '写复盘',
            subtitle: '整理今天的完成和改进',
            onTap: () => _closeThen(context, onJournal),
          ),
        ],
      ),
    );
  }

  void _closeThen(BuildContext context, VoidCallback callback) {
    Navigator.of(context).pop();
    callback();
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GrowthCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
