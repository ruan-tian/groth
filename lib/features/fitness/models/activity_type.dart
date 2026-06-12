import 'package:flutter/material.dart';

/// 运动类型枚举
///
/// 用于健身记录的运动分类，每种类型有不同的专属字段。
enum ActivityType {
  strength('力量训练', '🏋️', Icons.fitness_center_rounded),
  running('跑步', '🏃', Icons.directions_run_rounded),
  ballSports('球类', '⚽', Icons.sports_baseball_rounded),
  yoga('瑜伽', '🧘', Icons.self_improvement_rounded),
  swimming('游泳', '🏊', Icons.pool_rounded),
  cycling('骑行', '🚴', Icons.directions_bike_rounded),
  outdoor('户外', '🥾', Icons.terrain_rounded),
  other('其他', '🏅', Icons.star_rounded);

  const ActivityType(this.label, this.emoji, this.icon);

  /// 显示名称
  final String label;

  /// Emoji 图标
  final String emoji;

  /// Material 图标
  final IconData icon;

  /// 从字符串反序列化（兼容旧数据）
  static ActivityType fromString(String? value) {
    if (value == null) return ActivityType.strength;
    for (final type in ActivityType.values) {
      if (type.name == value) return type;
    }
    return ActivityType.strength;
  }
}

/// 球类子类型
enum BallType {
  basketball('篮球', '🏀'),
  football('足球', '⚽'),
  tennis('网球', '🎾'),
  badminton('羽毛球', '🏸'),
  tableTennis('乒乓球', '🏓'),
  volleyball('排球', '🏐'),
  other('其他', '🎯');

  const BallType(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// 瑜伽流派
enum YogaStyle {
  hatha('哈他', '🧘'),
  vinyasa('流瑜伽', '🌊'),
  yin('阴瑜伽', '🌙'),
  power('力量瑜伽', '💪'),
  meditation('冥想', '🧠'),
  other('其他', '✨');

  const YogaStyle(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// 泳姿
enum SwimStroke {
  freestyle('自由泳', '🏊'),
  breaststroke('蛙泳', '🐸'),
  backstroke('仰泳', '🔄'),
  butterfly('蝶泳', '🦋'),
  medley('混合', '🔀');

  const SwimStroke(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// 户外活动类型
enum OutdoorActivity {
  hiking('徒步', '🥾'),
  climbing('登山', '⛰️'),
  rockClimbing('攀岩', '🧗'),
  camping('露营', '⛺'),
  other('其他', '🌿');

  const OutdoorActivity(this.label, this.emoji);
  final String label;
  final String emoji;
}
