import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

// =============================================================================
// 设置 Provider
// =============================================================================

/// 全部设置 (`Map<String, String>`)
final settingsProvider = FutureProvider<Map<String, String>>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final settings = await repo.getAllSettings();
  return {for (final s in settings) s.key: s.value};
});

/// 按 key 获取单条设置值
///
/// 用法：`ref.watch(settingProvider('theme_mode'))`
final settingProvider = FutureProvider.family<String?, String>((
  ref,
  key,
) async {
  final repo = ref.watch(settingRepositoryProvider);
  return repo.getSetting(key);
});

/// 主题模式 StateProvider
///
/// 默认跟随系统，可通过 `ref.read(themeModeProvider.notifier).state = ...` 切换。
/// 持久化需在 UI 层调用 SettingRepository.setSetting 同步写入。
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

/// 从数据库初始化主题模式的 Provider
///
/// 在 app 启动时 watch 此 provider 以从数据库加载已保存的主题设置。
final themeInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('theme_mode');
  if (value != null) {
    ref.read(themeModeProvider.notifier).state = _parseThemeMode(value);
  }
});

/// 将字符串解析为 ThemeMode
ThemeMode _parseThemeMode(String value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

// =============================================================================
// 记录模式 Provider
// =============================================================================

/// 默认记录模式 StateProvider
///
/// 'simple' = 简单模式，'professional' = 专业模式
final defaultRecordModeProvider = StateProvider<String>((ref) {
  return 'simple';
});

/// 从数据库初始化记录模式的 Provider
final recordModeInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('default_record_mode');
  if (value != null) {
    ref.read(defaultRecordModeProvider.notifier).state = value;
  }
});

// =============================================================================
// 今日目标 Provider
// =============================================================================

/// 单个每日目标
class DailyGoal {
  const DailyGoal({required this.name, required this.target, this.unit = '分钟'});

  /// 任务名称（如 "学习"）
  final String name;

  /// 目标值（如 120）
  final int target;

  /// 单位（如 "分钟"、"篇"）
  final String unit;

  Map<String, dynamic> toJson() => {
    'name': name,
    'target': target,
    'unit': unit,
  };

  factory DailyGoal.fromJson(Map<String, dynamic> json) => DailyGoal(
    name: json['name'] as String,
    target: json['target'] as int,
    unit: json['unit'] as String? ?? '分钟',
  );
}

/// 默认每日目标
const defaultDailyGoals = [
  DailyGoal(name: '学习', target: 120, unit: '分钟'),
  DailyGoal(name: '健身', target: 45, unit: '分钟'),
  DailyGoal(name: '写日记', target: 1, unit: '篇'),
];

/// 今日目标 StateProvider（内存中的当前值）
final dailyGoalsProvider = StateProvider<List<DailyGoal>>((ref) {
  return defaultDailyGoals;
});

/// 从数据库初始化今日目标的 Provider
final dailyGoalsInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('daily_goals');
  if (value != null) {
    try {
      final list = jsonDecode(value) as List<dynamic>;
      final goals = list
          .map((e) => DailyGoal.fromJson(e as Map<String, dynamic>))
          .toList();
      if (goals.isNotEmpty) {
        ref.read(dailyGoalsProvider.notifier).state = goals;
      }
    } catch (_) {
      // 解析失败则使用默认值
    }
  }
});

// =============================================================================
// 饮食目标 Provider
// =============================================================================

/// 每日卡路里目标（kcal）
final dailyCalorieGoalProvider = StateProvider<int>((ref) => 2000);

/// 从数据库初始化每日卡路里目标
final dailyCalorieGoalInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('daily_calorie_goal');
  if (value != null) {
    final goal = int.tryParse(value);
    if (goal != null && goal > 0) {
      ref.read(dailyCalorieGoalProvider.notifier).state = goal;
    }
  }
});

/// 每日饮水量目标（ml）
final dailyWaterGoalProvider = StateProvider<int>((ref) => 2000);

/// 从数据库初始化每日饮水量目标
final dailyWaterGoalInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('daily_water_goal');
  if (value != null) {
    final goal = int.tryParse(value);
    if (goal != null && goal > 0) {
      ref.read(dailyWaterGoalProvider.notifier).state = goal;
    }
  }
});

// =============================================================================
// 每日饮水量记录 Provider
// =============================================================================

/// 每日饮水量记录 (Map<日期字符串, 饮水量ml>)
final dailyWaterIntakeProvider = StateProvider<Map<String, int>>((ref) => {});

/// 从数据库初始化今日饮水量
final todayWaterIntakeInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('daily_water_intake');
  if (value != null) {
    try {
      final map = (jsonDecode(value) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      );
      ref.read(dailyWaterIntakeProvider.notifier).state = map;
    } catch (_) {
      // 解析失败则使用空值
    }
  }
});

/// 获取今日饮水量
int getTodayWaterIntake(Map<String, int> waterMap) {
  final today = DateTime.now();
  final key =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  return waterMap[key] ?? 0;
}

/// 保存饮水量到数据库
Future<void> saveWaterIntake(WidgetRef ref, int amount) async {
  final waterMap = Map<String, int>.from(ref.read(dailyWaterIntakeProvider));
  final today = DateTime.now();
  final key =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  waterMap[key] = (waterMap[key] ?? 0) + amount;
  ref.read(dailyWaterIntakeProvider.notifier).state = waterMap;

  final repo = ref.read(settingRepositoryProvider);
  await repo.setSetting('daily_water_intake', jsonEncode(waterMap));
}

// =============================================================================
// 周目标 Provider
// =============================================================================

/// 每周健身目标（次数）
final weeklyFitnessGoalProvider = StateProvider<int>((ref) => 5);

/// 从数据库初始化周健身目标
final weeklyFitnessGoalInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('weekly_fitness_goal');
  if (value != null) {
    final goal = int.tryParse(value);
    if (goal != null && goal > 0) {
      ref.read(weeklyFitnessGoalProvider.notifier).state = goal;
    }
  }
});

// =============================================================================
// 首页卡片配置 Provider
// =============================================================================

/// 首页概览卡片配置
class DashboardCardConfig {
  const DashboardCardConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.unit,
    required this.defaultTarget,
  });

  /// 唯一标识
  final String id;

  /// 显示名称
  final String name;

  /// 图标
  final IconData icon;

  /// 主色
  final Color color;

  /// 柔和背景色
  final Color softColor;

  /// 单位
  final String unit;

  /// 默认目标值
  final int defaultTarget;
}

/// 所有可用的卡片类型
const availableDashboardCards = <DashboardCardConfig>[
  DashboardCardConfig(
    id: 'study',
    name: '学习',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF5D68F2),
    softColor: Color(0xFFEAF0FF),
    unit: '分钟',
    defaultTarget: 120,
  ),
  DashboardCardConfig(
    id: 'fitness',
    name: '健身',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFF35C976),
    softColor: Color(0xFFE8F8EE),
    unit: '分钟',
    defaultTarget: 45,
  ),
  DashboardCardConfig(
    id: 'diet',
    name: '饮食',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFFF8A3D),
    softColor: Color(0xFFFFF0E5),
    unit: '次',
    defaultTarget: 3,
  ),
  DashboardCardConfig(
    id: 'sleep',
    name: '睡眠',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF7058F5),
    softColor: Color(0xFFF0EDFF),
    unit: '分钟',
    defaultTarget: 480,
  ),
  DashboardCardConfig(
    id: 'journal',
    name: '日记',
    icon: Icons.edit_note_rounded,
    color: Color(0xFFFF7EAA),
    softColor: Color(0xFFFFEDF3),
    unit: '篇',
    defaultTarget: 1,
  ),
  DashboardCardConfig(
    id: 'water',
    name: '饮水',
    icon: Icons.water_drop_rounded,
    color: Color(0xFF4A90D9),
    softColor: Color(0xFFE8F2FC),
    unit: 'ml',
    defaultTarget: 2000,
  ),
  DashboardCardConfig(
    id: 'focus',
    name: '专注',
    icon: Icons.timer_rounded,
    color: Color(0xFFFF9F43),
    softColor: Color(0xFFFFF4E8),
    unit: '分钟',
    defaultTarget: 60,
  ),
  DashboardCardConfig(
    id: 'weight',
    name: '体重',
    icon: Icons.monitor_weight_rounded,
    color: Color(0xFF6B7280),
    softColor: Color(0xFFF3F4F6),
    unit: 'kg',
    defaultTarget: 0,
  ),
];

/// 根据 ID 获取卡片配置
DashboardCardConfig? getCardConfigById(String id) {
  try {
    return availableDashboardCards.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}

/// 默认首页卡片 ID 列表
const defaultDashboardCardIds = ['study', 'fitness', 'diet', 'sleep'];

/// 首页卡片 ID 列表 StateProvider
final dashboardCardIdsProvider = StateProvider<List<String>>((ref) {
  return defaultDashboardCardIds;
});

/// 从数据库初始化首页卡片配置的 Provider
final dashboardCardIdsInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('dashboard_cards');
  if (value != null) {
    try {
      final list = (jsonDecode(value) as List<dynamic>).cast<String>();
      if (list.isNotEmpty) {
        ref.read(dashboardCardIdsProvider.notifier).state = list;
      }
    } catch (_) {
      // 解析失败则使用默认值
    }
  }
});

/// 保存首页卡片配置到数据库
Future<void> saveDashboardCardIds(WidgetRef ref, List<String> ids) async {
  ref.read(dashboardCardIdsProvider.notifier).state = ids;
  final repo = ref.read(settingRepositoryProvider);
  await repo.setSetting('dashboard_cards', jsonEncode(ids));
}

// =============================================================================
// 用户资料 Provider
// =============================================================================

/// 用户昵称 StateProvider
final userNicknameProvider = StateProvider<String>((ref) {
  return '甜甜';
});

/// 用户头像路径 StateProvider
final userAvatarPathProvider = StateProvider<String?>((ref) {
  return null;
});

/// 从数据库初始化用户昵称的 Provider
final userNicknameInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('nickname');
  if (value != null && value.isNotEmpty) {
    ref.read(userNicknameProvider.notifier).state = value;
  }
});

/// 从数据库初始化用户头像的 Provider
final userAvatarInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('avatar_path');
  if (value != null && value.isNotEmpty) {
    ref.read(userAvatarPathProvider.notifier).state = value;
  }
});

/// 用户身高 StateProvider (cm)
final userHeightProvider = StateProvider<double?>((ref) {
  return null;
});

/// 从数据库初始化用户身高的 Provider
final userHeightInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('height');
  if (value != null && value.isNotEmpty) {
    final height = double.tryParse(value);
    if (height != null && height > 0) {
      ref.read(userHeightProvider.notifier).state = height;
    }
  }
});

/// 计算 BMI
/// 公式: BMI = 体重(kg) / (身高(m))^2
double? calculateBMI(double? weight, double? heightCm) {
  if (weight == null || heightCm == null || heightCm <= 0) {
    return null;
  }
  final heightM = heightCm / 100;
  return weight / (heightM * heightM);
}

/// 获取 BMI 分类
String getBMICategory(double bmi) {
  if (bmi < 18.5) return '偏瘦';
  if (bmi < 24) return '正常';
  if (bmi < 28) return '偏胖';
  return '肥胖';
}

/// 获取 BMI 分类颜色
Color getBMICategoryColor(double bmi) {
  if (bmi < 18.5) return const Color(0xFF4A90D9); // 蓝色
  if (bmi < 24) return const Color(0xFF35C976); // 绿色
  if (bmi < 28) return const Color(0xFFFFB13D); // 橙色
  return const Color(0xFFFF5A66); // 红色
}

// =============================================================================
// AI 自动分析 Provider
// =============================================================================

/// AI 自动分析开关
final autoAiAnalysisProvider = StateProvider<bool>((ref) => false);

/// 从数据库初始化 AI 自动分析开关
final autoAiAnalysisInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('auto_ai_analysis');
  if (value != null) {
    ref.read(autoAiAnalysisProvider.notifier).state = value == 'true';
  }
});

/// 日记上传分析开关
final journalUploadProvider = StateProvider<bool>((ref) => false);

/// 从数据库初始化日记上传开关
final journalUploadInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('journal_upload');
  if (value != null) {
    ref.read(journalUploadProvider.notifier).state = value == 'true';
  }
});
