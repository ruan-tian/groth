import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/pet/models/pet_intent.dart';
import '../../features/pet/models/pet_runtime_state.dart';
import 'pet_orchestrator_provider.dart';

/// 宠物视图状态 —— 从 UnifiedState 投影到具体 Surface
class PetViewState {
  const PetViewState({
    this.imagePath,
    this.bubbleText,
    this.isBubbleVisible = false,
    this.mood = 'neutral',
    this.action = 'idle',
    this.module,
  });

  final String? imagePath;
  final String? bubbleText;
  final bool isBubbleVisible;
  final String mood;
  final String action;
  final String? module;
}

/// Dashboard 专用投影
final dashboardPetViewProvider = Provider<PetViewState?>((ref) {
  final state = ref.watch(petOrchestratorProvider);
  return _project(state, PetSurface.dashboard, null);
});

/// 模块页专用投影 family
final modulePetViewProvider = Provider.family<PetViewState?, String>((
  ref,
  module,
) {
  final state = ref.watch(petOrchestratorProvider);
  return _project(state, PetSurface.modulePage, module);
});

/// 宠物中心专用投影
final petCenterViewProvider = Provider<PetViewState?>((ref) {
  final state = ref.watch(petOrchestratorProvider);
  return _project(state, PetSurface.petCenter, null);
});

PetViewState? _project(
  PetRuntimeState state,
  PetSurface surface,
  String? module,
) {
  final intent = state.effectiveIntent;
  if (intent == null && state.baseIntent == null) return null;

  final active = intent;

  return PetViewState(
    imagePath: active?.imagePath ?? state.baseIntent?.imagePath,
    bubbleText: active?.displayMessage ?? state.baseIntent?.displayMessage,
    isBubbleVisible: (active?.fixedMessage ?? active?.displayMessage) != null,
    mood: 'neutral',
    action: _inferAction(active?.imagePath ?? state.baseIntent?.imagePath),
    module: module,
  );
}

String _inferAction(String? imagePath) {
  final path = imagePath?.toLowerCase();
  if (path == null) return 'idle';
  if (path.contains('thinking') ||
      path.contains('report') ||
      path.contains('ai')) {
    return 'think';
  }
  if (path.contains('happy') ||
      path.contains('done') ||
      path.contains('level') ||
      path.contains('goal') ||
      path.contains('task')) {
    return 'happy';
  }
  if (path.contains('sleep') || path.contains('yawn')) {
    return 'sleep';
  }
  if (path.contains('read') ||
      path.contains('study') ||
      path.contains('focus')) {
    return 'read';
  }
  if (path.contains('wave') || path.contains('greet')) {
    return 'wave';
  }
  return 'idle';
}
