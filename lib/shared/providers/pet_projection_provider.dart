import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/pet/pet_display_intent.dart';
import '../../core/domain/pet/pet_intent.dart';
import '../../core/domain/pet/pet_runtime_state.dart';
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
  final active = _visibleActiveIntent(state, surface, module);
  final fallback = switch (surface) {
    PetSurface.modulePage => module != null ? state.moduleIntents[module] : null,
    PetSurface.dashboard => state.lifeIntent,
    PetSurface.petCenter => state.lifeIntent,
  };
  final intent = active ?? fallback;

  if (intent == null) return null;

  return PetViewState(
    imagePath: intent.imagePath,
    bubbleText: intent.displayMessage,
    isBubbleVisible:
        intent.fixedMessage != null || intent.messages.isNotEmpty,
    mood: 'neutral',
    action: _inferAction(intent.imagePath),
    module: intent.module ?? module,
  );
}

PetDisplayIntent? _visibleActiveIntent(
  PetRuntimeState state,
  PetSurface surface,
  String? module,
) {
  final active = state.activeIntent;
  if (active == null || active.isExpired) return null;
  final activeModule = active.module;

  switch (surface) {
    case PetSurface.dashboard:
      return activeModule == null ? active : null;
    case PetSurface.petCenter:
      return active;
    case PetSurface.modulePage:
      if (activeModule == null || activeModule == module) {
        return active;
      }
      return null;
  }
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
