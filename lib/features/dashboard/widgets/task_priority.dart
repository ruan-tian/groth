import 'package:flutter/material.dart';

// =============================================================================
// TaskPriority - 优先级枚举
// =============================================================================

enum TaskPriority {
  none(0, '无', Color(0xFFD0D5DD)),
  low(1, '低', Color(0xFF5D68F2)),
  medium(2, '中', Color(0xFFFF8A3D)),
  high(3, '高', Color(0xFFFF4D4F));

  const TaskPriority(this.value, this.label, this.color);
  final int value;
  final String label;
  final Color color;

  static TaskPriority fromValue(int v) =>
      TaskPriority.values.firstWhere((p) => p.value == v, orElse: () => none);
}
