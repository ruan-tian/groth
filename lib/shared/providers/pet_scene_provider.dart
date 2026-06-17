import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/pet/pet_scene_model.dart';
import '../../core/utils/pet_scene_resolver.dart';

// =============================================================================
// 宠物场景状态 Provider
// =============================================================================

/// 宠物场景状态
class PetSceneState {
  const PetSceneState({
    required this.config,
    this.showBubble = false,
    this.bubbleText,
    this.reportTitle,
    this.reportHighlights = const [],
    this.reportSuggestions = const [],
    this.showReport = false,
  });

  final PetSceneConfig config;
  final bool showBubble;
  final String? bubbleText;
  final String? reportTitle;
  final List<String> reportHighlights;
  final List<String> reportSuggestions;
  final bool showReport;

  PetSceneState copyWith({
    PetSceneConfig? config,
    bool? showBubble,
    String? bubbleText,
    String? reportTitle,
    List<String>? reportHighlights,
    List<String>? reportSuggestions,
    bool? showReport,
  }) {
    return PetSceneState(
      config: config ?? this.config,
      showBubble: showBubble ?? this.showBubble,
      bubbleText: bubbleText ?? this.bubbleText,
      reportTitle: reportTitle ?? this.reportTitle,
      reportHighlights: reportHighlights ?? this.reportHighlights,
      reportSuggestions: reportSuggestions ?? this.reportSuggestions,
      showReport: showReport ?? this.showReport,
    );
  }
}

/// 宠物场景状态管理
///
/// 每个模块独立拥有一个实例，互不干扰。
class PetSceneNotifier extends StateNotifier<PetSceneState> {
  PetSceneNotifier(PetModuleType module)
    : _module = module,
      super(
        PetSceneState(
          config: PetSceneConfig(
            state: module.idleStates.first,
            message: PetSceneResolver.getWelcomeBubble(module),
            decoration: getDecorationForState(module.idleStates.first),
          ),
        ),
      );

  final PetModuleType _module;
  Timer? _idleTimer;
  Timer? _bubbleTimer;

  /// 初始化场景（页面进入时调用）
  ///
  /// 如果当前已有报告状态，则保留报告，不重置。
  void initScene({required bool hasRecords}) {
    // 如果已有报告状态，保留报告不重置
    if (state.showReport) return;

    _idleTimer?.cancel();
    _bubbleTimer?.cancel();

    final config = PetSceneResolver.resolve(
      module: _module,
      hasRecords: hasRecords,
    );

    state = PetSceneState(
      config: config,
      showBubble: true,
      bubbleText: PetSceneResolver.getWelcomeBubble(_module),
    );

    // 3 秒后隐藏欢迎气泡
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      state = state.copyWith(showBubble: false, bubbleText: null);
    });

    // 启动待机切换定时器
    _startIdleTimer();
  }

  /// 更新数据状态（数据变化时调用）
  void updateDataState({required bool hasRecords, bool justCompleted = false}) {
    _idleTimer?.cancel();
    _bubbleTimer?.cancel();

    final config = PetSceneResolver.resolve(
      module: _module,
      hasRecords: hasRecords,
      justCompleted: justCompleted,
    );

    String? bubble;
    bool showBubble = false;

    if (justCompleted) {
      bubble = config.message;
      showBubble = true;
      _bubbleTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        state = state.copyWith(showBubble: false, bubbleText: null);
      });
    }

    state = PetSceneState(
      config: config,
      showBubble: showBubble,
      bubbleText: bubble,
    );

    _startIdleTimer();
  }

  /// 显示自定义气泡
  void showBubble(
    String text, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _bubbleTimer?.cancel();
    state = state.copyWith(showBubble: true, bubbleText: text);
    _bubbleTimer = Timer(duration, () {
      if (!mounted) return;
      state = state.copyWith(showBubble: false, bubbleText: null);
    });
  }

  /// 切换到 AI 思考状态
  void setThinking() {
    _idleTimer?.cancel();
    _bubbleTimer?.cancel();
    state = PetSceneState(
      config: PetSceneConfig(
        state: PetSceneStateType.thinking,
        message: '甜甜正在认真分析中～',
        decoration: const PetDecoration(primary: '🤔', secondary: '💭'),
      ),
      showBubble: true,
      bubbleText: '甜甜正在认真分析中～',
    );
  }

  /// 切换到 AI 完成状态（带完整报告数据）
  void setReport(
    String petMessage, {
    String? title,
    List<String> highlights = const [],
    List<String> suggestions = const [],
  }) {
    _idleTimer?.cancel();
    _bubbleTimer?.cancel();
    state = PetSceneState(
      config: PetSceneConfig(
        state: PetSceneStateType.report,
        message: petMessage,
        decoration: const PetDecoration(primary: '📊', secondary: '✨'),
      ),
      showBubble: true,
      bubbleText: petMessage,
      reportTitle: title,
      reportHighlights: highlights,
      reportSuggestions: suggestions,
      showReport: true,
    );
  }

  /// 隐藏报告标签行
  void hideReport() {
    state = state.copyWith(showReport: false);
  }

  /// 切换到 AI 错误状态
  void setError(String errorMsg) {
    _idleTimer?.cancel();
    _bubbleTimer?.cancel();
    state = PetSceneState(
      config: PetSceneConfig(
        state: PetSceneStateType.error,
        message: errorMsg,
        decoration: const PetDecoration(primary: '😿', secondary: '💔'),
      ),
      showBubble: true,
      bubbleText: '这次分析失败啦，稍后再试试吧！',
    );
  }

  /// 启动待机切换定时器
  void _startIdleTimer() {
    _idleTimer?.cancel();
    // 20~40 秒随机切换一次
    final seconds = 20 + (DateTime.now().millisecondsSinceEpoch % 21);
    _idleTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      final newState = PetSceneResolver.randomIdleState(_module);
      final decoration = getDecorationForState(newState);
      state = PetSceneState(
        config: PetSceneConfig(
          state: newState,
          message: state.config.message,
          decoration: decoration,
        ),
        showBubble: state.showBubble,
        bubbleText: state.bubbleText,
      );
      _startIdleTimer(); // 递归启动下一个
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _bubbleTimer?.cancel();
    super.dispose();
  }
}

/// 宠物场景 Provider（按模块分组，每个模块独立状态）
final petSceneProvider =
    StateNotifierProvider.family<
      PetSceneNotifier,
      PetSceneState,
      PetModuleType
    >((ref, module) {
      return PetSceneNotifier(module);
    });
