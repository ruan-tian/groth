import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../features/health/pages/add_sleep_record_sheet.dart';

/// 快速开始菜单
///
/// 从底部弹出，提供 5 个快捷入口：
/// - 开始学习（番茄钟）
/// - 开始运动（健身页面）
/// - 喝水打卡（喝水页面）
/// - 记录睡眠（睡眠页面）
/// - 开始日记（写日记页面）
class QuickActionSheet extends StatelessWidget {
  const QuickActionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: context.growthColors.shadow.withValues(alpha: 0.28),
      isScrollControlled: true,
      builder: (context) => const QuickActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽条
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '快速开始',
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      '5 个入口',
                      style: AppTextStyles.label.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // 列表项
            _QuickActionTile(
              assetPath: 'assets/images/quick_actions/ic_quick_study.webp',
              title: '开始学习',
              subtitle: '番茄钟计时，专注学习',
              accentColor: colors.study,
              softColor: colors.softBlue,
              onTap: () {
                Navigator.pop(context);
                context.push('/focus');
              },
            ),
            _QuickActionTile(
              assetPath: 'assets/images/quick_actions/ic_quick_fitness.webp',
              title: '开始运动',
              subtitle: '记录训练，强身健体',
              accentColor: colors.fitness,
              softColor: colors.softGreen,
              onTap: () {
                Navigator.pop(context);
                context.push('/plan/fitness/add');
              },
            ),
            _QuickActionTile(
              assetPath: 'assets/images/quick_actions/ic_quick_water.webp',
              title: '喝水打卡',
              subtitle: '保持水分，健康生活',
              accentColor: colors.diet,
              softColor: colors.softBlue,
              onTap: () {
                Navigator.pop(context);
                context.push('/plan/diet/water-reminder');
              },
            ),
            _QuickActionTile(
              assetPath: 'assets/images/quick_actions/ic_quick_sleep.webp',
              title: '记录睡眠',
              subtitle: '好好休息，恢复精力',
              accentColor: colors.sleep,
              softColor: colors.softPurple,
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => AddSleepRecordSheet(
                    onSave: () {
                      // 保存后的回调，可以刷新数据
                    },
                  ),
                );
              },
            ),
            _QuickActionTile(
              assetPath: 'assets/images/quick_actions/ic_quick_journal.webp',
              title: '开始日记',
              subtitle: '记录心情，反思成长',
              accentColor: colors.journal,
              softColor: colors.softPink,
              onTap: () {
                Navigator.pop(context);
                context.push('/plan/journal/write');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// 快速操作列表项
class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.softColor,
    required this.onTap,
  });

  final String assetPath;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color softColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          softColor,
                          accentColor.withValues(alpha: 0.16),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.16),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.card.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            assetPath,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.auto_awesome_rounded,
                              color: accentColor,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // 文字
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 箭头
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
