import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import 'repository_providers.dart';

// =============================================================================
// 专注记录数据 Provider
// =============================================================================

/// 今日专注总时长（分钟）
final todayFocusMinutesProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(focusRepositoryProvider);
  return repo.getTotalFocusMinutesByDate(DateTime.now());
});

/// 今日专注记录
final todayFocusSessionsProvider = FutureProvider<List<FocusSession>>((ref) {
  final repo = ref.watch(focusRepositoryProvider);
  return repo.getFocusSessionsByDate(DateTime.now());
});

/// 最近 10 条专注记录（按创建时间倒序）
final recentFocusSessionsProvider = FutureProvider<List<FocusSession>>((ref) {
  final repo = ref.watch(focusRepositoryProvider);
  return repo.getRecentFocusSessions(limit: 10);
});

// =============================================================================
// 专注设置状态
// =============================================================================

/// 专注页面设置状态
class FocusSetupState {
  const FocusSetupState({
    this.type = 'pomodoro',
    this.durationMinutes = 25,
    this.title = '',
    this.subject,
    this.soundType,
  });

  /// 专注类型: pomodoro / deep / ultra / custom
  final String type;

  /// 专注时长（分钟）
  final int durationMinutes;

  /// 专注标题
  final String title;

  /// 学习科目
  final String? subject;

  /// 白噪音类型
  final String? soundType;

  FocusSetupState copyWith({
    String? type,
    int? durationMinutes,
    String? title,
    String? subject,
    String? soundType,
  }) {
    return FocusSetupState(
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      soundType: soundType ?? this.soundType,
    );
  }
}

/// 专注设置 StateProvider
final focusSetupProvider = StateProvider<FocusSetupState>((ref) {
  return const FocusSetupState();
});
