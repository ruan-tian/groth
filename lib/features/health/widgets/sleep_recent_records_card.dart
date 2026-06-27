import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/constants/record_icon_assets.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../../shared/widgets/swipe_delete_tile.dart';
import '../utils/sleep_display_formatters.dart';

class SleepRecentRecordsCard extends StatelessWidget {
  const SleepRecentRecordsCard({
    super.key,
    required this.recentRecords,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onViewAll,
    required this.onDeleteRecord,
    required this.onRecordTap,
    required this.emptyIconColor,
  });

  final AsyncValue<List<SleepRecord>> recentRecords;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onViewAll;
  final ValueChanged<SleepRecord> onDeleteRecord;
  final ValueChanged<SleepRecord> onRecordTap;
  final Color emptyIconColor;

  @override
  Widget build(BuildContext context) {
    return recentRecords.when(
      data: (records) {
        if (records.isEmpty) {
          return _EmptySleepRecords(iconColor: emptyIconColor);
        }

        final displayRecords = isExpanded ? records : records.take(5).toList();
        return ModuleRecordsCard(
          title: '最近记录',
          action: '查看全部',
          onActionTap: onViewAll,
          color: context.growthColors.sleep,
          recordCount: records.length,
          maxVisible: 5,
          isExpanded: isExpanded,
          onToggleExpand: onToggleExpand,
          children: displayRecords
              .map(
                (r) => SwipeDeleteTile(
                  key: ValueKey('sleep_${r.id}'),
                  onConfirmDelete: () async {
                    onDeleteRecord(r);
                    return false;
                  },
                  onDismissed: () {},
                  child: RecentRecordTile(
                    icon: Icons.nightlight_round,
                    iconColor: context.growthColors.textOnAccent,
                    iconBackgroundColor: context.growthColors.sleep,
                    imageAsset: RecordIconAssets.sleep,
                    title: '${r.sleepDate} 睡眠记录',
                    subtitle:
                        '${r.sleepTime} - ${r.wakeTime} · ${formatSleepDuration(r.durationMinutes)}',
                    primaryBadge: sleepQualityLabel(r.qualityLevel),
                    primaryBadgeColor: context.growthColors.sleep,
                    secondaryBadge:
                        '${r.durationMinutes ~/ 60}h${r.durationMinutes % 60}m',
                    secondaryBadgeColor: context.growthColors.textSecondary,
                    onTap: () => onRecordTap(r),
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

class _EmptySleepRecords extends StatelessWidget {
  const _EmptySleepRecords({required this.iconColor});

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.growthColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.nightlight_round,
              size: 48,
              color: iconColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '还没有睡眠记录',
              style: AppTextStyles.cardTitle.copyWith(
                color: context.growthColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('点击 + 记录昨晚的睡眠', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
