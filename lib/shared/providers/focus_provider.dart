import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    this.totalRounds = 4,
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

  /// 总轮次（默认 4 轮番茄）
  final int totalRounds;

  FocusSetupState copyWith({
    String? type,
    int? durationMinutes,
    String? title,
    Object? subject = _focusSetupUnset,
    Object? soundType = _focusSetupUnset,
    int? totalRounds,
  }) {
    return FocusSetupState(
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      title: title ?? this.title,
      subject: subject == _focusSetupUnset ? this.subject : subject as String?,
      soundType:
          soundType == _focusSetupUnset ? this.soundType : soundType as String?,
      totalRounds: totalRounds ?? this.totalRounds,
    );
  }
}

const Object _focusSetupUnset = Object();

/// 专注设置 StateProvider
final focusSetupProvider = StateProvider<FocusSetupState>((ref) {
  return const FocusSetupState();
});

// =============================================================================
// 专注循环状态机
// =============================================================================

/// 专注阶段
enum FocusPhase {
  focus,
  shortBreak,
  longBreak,
}

/// 专注循环状态
class FocusCycleState {
  const FocusCycleState({
    this.sessionGroupId,
    this.currentRound = 1,
    this.totalRounds = 4,
    this.phase = FocusPhase.focus,
    this.phaseStartAt,
    this.phaseEndAt,
    this.remainingSeconds = 0,
    this.isRunning = false,
    this.autoStartNextRound = true,
    this.focusSeconds = 25 * 60,
    this.shortBreakSeconds = 5 * 60,
    this.longBreakSeconds = 15 * 60,
    this.title = '',
    this.subject = '',
    this.soundType,
    this.type = 'pomodoro',
  });

  final String? sessionGroupId;
  final int currentRound;
  final int totalRounds;
  final FocusPhase phase;
  final DateTime? phaseStartAt;
  final DateTime? phaseEndAt;
  final int remainingSeconds;
  final bool isRunning;
  final bool autoStartNextRound;
  final int focusSeconds;
  final int shortBreakSeconds;
  final int longBreakSeconds;
  final String title;
  final String subject;
  final String? soundType;
  final String type;

  /// 是否处于休息阶段
  bool get isBreak =>
      phase == FocusPhase.shortBreak || phase == FocusPhase.longBreak;

  /// 是否是最后一轮
  bool get isLastRound => currentRound >= totalRounds;

  /// 进度 (0.0 ~ 1.0)
  double get progress {
    final total = phase == FocusPhase.focus
        ? focusSeconds
        : phase == FocusPhase.shortBreak
            ? shortBreakSeconds
            : longBreakSeconds;
    return total > 0 ? (remainingSeconds / total).clamp(0.0, 1.0) : 0.0;
  }

  FocusCycleState copyWith({
    String? sessionGroupId,
    int? currentRound,
    int? totalRounds,
    FocusPhase? phase,
    DateTime? phaseStartAt,
    DateTime? phaseEndAt,
    int? remainingSeconds,
    bool? isRunning,
    bool? autoStartNextRound,
    int? focusSeconds,
    int? shortBreakSeconds,
    int? longBreakSeconds,
    String? title,
    String? subject,
    String? soundType,
    String? type,
  }) {
    return FocusCycleState(
      sessionGroupId: sessionGroupId ?? this.sessionGroupId,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      phase: phase ?? this.phase,
      phaseStartAt: phaseStartAt ?? this.phaseStartAt,
      phaseEndAt: phaseEndAt ?? this.phaseEndAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      autoStartNextRound: autoStartNextRound ?? this.autoStartNextRound,
      focusSeconds: focusSeconds ?? this.focusSeconds,
      shortBreakSeconds: shortBreakSeconds ?? this.shortBreakSeconds,
      longBreakSeconds: longBreakSeconds ?? this.longBreakSeconds,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      soundType: soundType ?? this.soundType,
      type: type ?? this.type,
    );
  }

  /// 序列化为 JSON（用于持久化恢复）
  Map<String, dynamic> toJson() => {
        'sessionGroupId': sessionGroupId,
        'currentRound': currentRound,
        'totalRounds': totalRounds,
        'phase': phase.index,
        'phaseStartAt': phaseStartAt?.millisecondsSinceEpoch,
        'phaseEndAt': phaseEndAt?.millisecondsSinceEpoch,
        'remainingSeconds': remainingSeconds,
        'isRunning': isRunning,
        'autoStartNextRound': autoStartNextRound,
        'focusSeconds': focusSeconds,
        'shortBreakSeconds': shortBreakSeconds,
        'longBreakSeconds': longBreakSeconds,
        'title': title,
        'subject': subject,
        'soundType': soundType,
        'type': type,
      };

  /// 从 JSON 反序列化
  factory FocusCycleState.fromJson(Map<String, dynamic> json) {
    return FocusCycleState(
      sessionGroupId: json['sessionGroupId'] as String?,
      currentRound: json['currentRound'] as int? ?? 1,
      totalRounds: json['totalRounds'] as int? ?? 4,
      phase: FocusPhase.values[json['phase'] as int? ?? 0],
      phaseStartAt: json['phaseStartAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['phaseStartAt'] as int)
          : null,
      phaseEndAt: json['phaseEndAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['phaseEndAt'] as int)
          : null,
      remainingSeconds: json['remainingSeconds'] as int? ?? 0,
      isRunning: json['isRunning'] as bool? ?? false,
      autoStartNextRound: json['autoStartNextRound'] as bool? ?? true,
      focusSeconds: json['focusSeconds'] as int? ?? 25 * 60,
      shortBreakSeconds: json['shortBreakSeconds'] as int? ?? 5 * 60,
      longBreakSeconds: json['longBreakSeconds'] as int? ?? 15 * 60,
      title: json['title'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      soundType: json['soundType'] as String?,
      type: json['type'] as String? ?? 'pomodoro',
    );
  }
}

// =============================================================================
// 专注循环 Notifier（状态机）
// =============================================================================

class FocusCycleNotifier extends StateNotifier<FocusCycleState> {
  FocusCycleNotifier() : super(const FocusCycleState());
  Timer? _tickTimer;
  static const _persistKey = 'focus_cycle_state';

  /// 开始新的专注循环
  void start({
    required int focusMinutes,
    required int totalRounds,
    required String type,
    String title = '',
    String subject = '',
    String? soundType,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
  }) {
    final now = DateTime.now();
    final focusSec = focusMinutes * 60;
    final groupId = '${now.millisecondsSinceEpoch}_${Random().nextInt(99999)}';

    state = FocusCycleState(
      sessionGroupId: groupId,
      currentRound: 1,
      totalRounds: totalRounds,
      phase: FocusPhase.focus,
      phaseStartAt: now,
      phaseEndAt: now.add(Duration(seconds: focusSec)),
      remainingSeconds: focusSec,
      isRunning: true,
      focusSeconds: focusSec,
      shortBreakSeconds: shortBreakMinutes * 60,
      longBreakSeconds: longBreakMinutes * 60,
      title: title,
      subject: subject,
      soundType: soundType,
      type: type,
    );

    _startTick();
    _persist();
  }

  /// 暂停
  void pause() {
    _tickTimer?.cancel();
    state = state.copyWith(isRunning: false);
    _persist();
  }

  /// 继续
  void resume() {
    final now = DateTime.now();
    final newEnd = now.add(Duration(seconds: state.remainingSeconds));
    state = state.copyWith(
      isRunning: true,
      phaseStartAt: now,
      phaseEndAt: newEnd,
    );
    _startTick();
    _persist();
  }

  /// 跳过当前休息阶段
  void skipBreak() {
    if (!state.isBreak) return;
    _tickTimer?.cancel();
    _advanceToNextPhase();
  }

  /// 取消整个循环
  void cancel() {
    _tickTimer?.cancel();
    state = const FocusCycleState();
    _clearPersist();
  }

  /// 核心状态机：推进到下一个阶段
  ///
  /// 返回 true 表示 cycle 完成（长休息结束）
  bool _advanceToNextPhase() {
    final s = state;

    if (s.phase == FocusPhase.focus) {
      if (s.isLastRound) {
        // 最后一轮 → 长休息
        final now = DateTime.now();
        state = s.copyWith(
          phase: FocusPhase.longBreak,
          phaseStartAt: now,
          phaseEndAt: now.add(Duration(seconds: s.longBreakSeconds)),
          remainingSeconds: s.longBreakSeconds,
          isRunning: true,
        );
        _startTick();
        _persist();
        return false;
      } else {
        // 非最后一轮 → 短休息
        final now = DateTime.now();
        state = s.copyWith(
          phase: FocusPhase.shortBreak,
          phaseStartAt: now,
          phaseEndAt: now.add(Duration(seconds: s.shortBreakSeconds)),
          remainingSeconds: s.shortBreakSeconds,
          isRunning: true,
        );
        _startTick();
        _persist();
        return false;
      }
    }

    if (s.phase == FocusPhase.shortBreak) {
      // 短休息结束 → 下一轮专注
      final now = DateTime.now();
      state = s.copyWith(
        currentRound: s.currentRound + 1,
        phase: FocusPhase.focus,
        phaseStartAt: now,
        phaseEndAt: now.add(Duration(seconds: s.focusSeconds)),
        remainingSeconds: s.focusSeconds,
        isRunning: true,
      );
      _startTick();
      _persist();
      return false;
    }

    if (s.phase == FocusPhase.longBreak) {
      // 长休息结束 → cycle 完成
      _tickTimer?.cancel();
      state = s.copyWith(isRunning: false);
      _clearPersist();
      return true;
    }

    return false;
  }

  /// 供外部调用的阶段推进（专注完成时调用）
  ///
  /// 返回 true 表示整个 cycle 完成
  bool advanceToNextPhase() {
    return _advanceToNextPhase();
  }

  /// 获取当前阶段的开始时间（用于保存记录）
  DateTime? getPhaseStartTime() => state.phaseStartAt;

  /// Tick：每秒更新 remainingSeconds
  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTick();
    });
  }

  void _onTick() {
    if (!state.isRunning || state.phaseEndAt == null) return;

    final remaining =
        state.phaseEndAt!.difference(DateTime.now()).inSeconds;

    if (remaining <= 0) {
      // 阶段结束
      state = state.copyWith(remainingSeconds: 0);
      // 不在这里自动推进，由 focus_session_page 控制
      // （需要先保存记录、发宠物事件等）
    } else {
      state = state.copyWith(remainingSeconds: remaining);
    }
  }

  /// App 从后台恢复时调用，重算 remainingSeconds
  void recalculate() {
    if (state.phaseEndAt == null) return;
    final remaining =
        state.phaseEndAt!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      state = state.copyWith(remainingSeconds: 0);
    } else {
      state = state.copyWith(remainingSeconds: remaining);
    }
  }

  /// 持久化当前状态到 SharedPreferences
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_persistKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  /// 清除持久化状态
  Future<void> _clearPersist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_persistKey);
    } catch (_) {}
  }

  /// 从持久化恢复状态（App 启动时调用）
  Future<bool> restoreFromPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_persistKey);
      if (json == null || json.isEmpty) return false;

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final restored = FocusCycleState.fromJson(decoded);

      // 如果已经不运行了，清除
      if (!restored.isRunning) {
        await _clearPersist();
        return false;
      }

      // 恢复并重算 remaining
      state = restored;
      recalculate();

      // 如果恢复后发现已经超时，清除
      if (state.remainingSeconds <= 0) {
        await _clearPersist();
        state = const FocusCycleState();
        return false;
      }

      // 恢复 tick
      _startTick();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}

/// 专注循环 Provider
final focusCycleProvider =
    StateNotifierProvider<FocusCycleNotifier, FocusCycleState>((ref) {
  return FocusCycleNotifier();
});
