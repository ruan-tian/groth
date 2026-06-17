import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/sleep_display_formatters.dart';

void showSleepRecordDetailSheet(
  BuildContext context,
  SleepRecord record, {
  required Color accentColor,
  required Color dreamBackgroundColor,
}) {
  final date = DateTime.parse(record.sleepDate);
  final weekday = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];
  final dateStr = '${date.year}年${date.month}月${date.day}日 $weekday';

  final hours = record.durationMinutes ~/ 60;
  final mins = record.durationMinutes % 60;
  final durationStr = '${hours}h ${mins}m';

  final detailItems = [
    DetailItem(
      label: '入睡时间',
      value: record.sleepTime,
      icon: Icons.nightlight_round,
    ),
    DetailItem(
      label: '起床时间',
      value: record.wakeTime,
      icon: Icons.wb_sunny_rounded,
    ),
    DetailItem(
      label: '入睡用时',
      value: '${record.fallAsleepMinutes}分钟',
      icon: Icons.timer_outlined,
    ),
    DetailItem(
      label: '夜间醒来',
      value: '${record.wakeCount}次',
      icon: Icons.notifications_none_rounded,
    ),
  ];

  final extraCards = <Widget>[
    _DetailInfoCard(
      backgroundColor: const Color(0xFFFFF8F0),
      icon: Icons.star_rounded,
      iconColor: const Color(0xFFFFB347),
      label: '睡眠质量',
      child: Row(
        children: [
          Text(
            '${record.qualityLevel}/5',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.growthColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            sleepQualityLabel(record.qualityLevel),
            style: TextStyle(
              fontSize: 13,
              color: sleepQualityColor(record.qualityLevel),
            ),
          ),
        ],
      ),
    ),
    _DetailInfoCard(
      backgroundColor: const Color(0xFFE6FFF0),
      icon: Icons.battery_charging_full_rounded,
      iconColor: const Color(0xFF52C41A),
      label: '醒后精力',
      child: Text(
        '${record.energyLevel}/5',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: context.growthColors.textPrimary,
        ),
      ),
    ),
  ];

  if (record.dreamNote != null && record.dreamNote!.isNotEmpty) {
    extraCards.add(
      _DetailInfoCard(
        backgroundColor: dreamBackgroundColor,
        icon: Icons.auto_awesome,
        iconColor: accentColor,
        label: '梦境',
        child: Text(
          record.dreamNote!,
          style: TextStyle(
            fontSize: 14,
            color: context.growthColors.textPrimary,
          ),
        ),
      ),
    );
  }

  if (record.note != null && record.note!.isNotEmpty) {
    extraCards.add(
      _DetailInfoCard(
        backgroundColor: const Color(0xFFF5F5F5),
        icon: Icons.note_outlined,
        iconColor: context.growthColors.textTertiary,
        label: '备注',
        child: Text(
          record.note!,
          style: TextStyle(
            fontSize: 14,
            color: context.growthColors.textPrimary,
          ),
        ),
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => RecordDetailSheet(
      title: dateStr,
      accentColor: accentColor,
      primaryMetricLabel: '睡眠时长',
      primaryMetricValue: durationStr,
      detailItems: detailItems,
      extraCards: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < extraCards.length; i++) ...[
            extraCards[i],
            if (i < extraCards.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    ),
  );
}

class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
  });

  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.growthColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
