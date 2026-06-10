import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

String formatSleepDuration(int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours > 0 && mins > 0) return '$hours小时$mins分';
  if (hours > 0) return '$hours小时';
  return '$mins分钟';
}

String sleepQualityLabel(int quality) {
  switch (quality) {
    case 1:
      return '很差';
    case 2:
      return '较差';
    case 3:
      return '一般';
    case 4:
      return '良好';
    case 5:
      return '优秀';
    default:
      return '一般';
  }
}

Color sleepQualityColor(int quality) {
  if (quality >= 4) return AppColors.success;
  if (quality >= 3) return const Color(0xFFFFB347);
  return AppColors.danger;
}
