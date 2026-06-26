class RecordIconAssets {
  RecordIconAssets._();

  static const _root = 'assets/images/record_icons';

  /// 学习模块记录图标
  static const study = '$_root/学习.webp';

  /// 健身模块记录图标
  static const fitness = '$_root/健身.webp';

  /// 日记模块记录图标
  static const journal = '$_root/日记.webp';

  /// 饮食模块 - 默认图标
  static const diet = '$_root/饮食.webp';

  /// 饮食模块 - 早餐图标
  static const breakfast = '$_root/早餐.webp';

  /// 饮食模块 - 午餐图标
  static const lunch = '$_root/午餐.webp';

  /// 饮食模块 - 晚餐图标
  static const dinner = '$_root/晚餐.webp';

  /// 饮食模块 - 加餐图标
  static const snack = '$_root/加餐.webp';

  /// 睡眠模块记录图标
  static const sleep = '$_root/睡眠.webp';

  /// 默认记录图标（兜底）
  static const fallback = '$_root/默认.webp';

  /// 根据餐次类型返回对应图标路径
  static String dietByMealType(String mealType) {
    return switch (mealType) {
      'breakfast' => breakfast,
      'lunch' => lunch,
      'dinner' => dinner,
      'snack' => snack,
      _ => diet,
    };
  }
}
