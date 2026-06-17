import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

/// 通知权限被拒绝后，引导用户到系统设置开启。
///
/// 返回 true 表示用户点击了"去设置"（已跳转到系统设置页）。
/// 返回 false 表示用户点击了"取消"。
Future<bool> showNotificationPermissionGuide(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final colors = ctx.growthColors;
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: colors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '需要通知权限',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '开启通知后，才能在指定时间提醒你喝水、睡觉、专注等。\n\n'
          '请在系统设置中找到"通知"并开启。',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消', style: TextStyle(color: colors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('去设置'),
          ),
        ],
      );
    },
  );
  if (result == true) {
    AppSettings.openAppSettings(type: AppSettingsType.notification);
    return true;
  }
  return false;
}
