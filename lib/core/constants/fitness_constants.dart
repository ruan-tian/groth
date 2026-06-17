/// 健身相关常量
class FitnessConstants {
  FitnessConstants._();

  /// 每分钟消耗卡路里系数（基于 MET 估算）
  /// 来源：中等强度运动 MET ≈ 6，体重 75kg
  /// 卡路里 = MET × 体重(kg) × 时间(h) ≈ 6 × 75 × (1/60) ≈ 7.5 kcal/min
  static const double kcalPerMinute = 7.5;

  /// 估算卡路里消耗
  static int estimateCalories(int durationMinutes) {
    return (durationMinutes * kcalPerMinute).round();
  }
}
