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
final modulePetViewProvider = Provider.family<PetViewState?, String>((ref, module) {
  final state = ref.watch(petOrchestratorProvider);
  return _project(state, PetSurface.modulePage, module);
});

/// 宠物中心专用投影
final petCenterViewProvider = Provider<PetViewState?>((ref) {
  final state = ref.watch(petOrchestratorProvider);
  return _project(state, PetSurface.petCenter, null);
});

PetViewState? _project(PetRuntimeState state, PetSurface surface, String? module) {
  final intent = state.effectiveIntent;
  if (intent == null && state.baseIntent == null) return null;

  final active = intent;

  return PetViewState(
    imagePath: active?.imagePath ?? state.baseIntent?.imagePath,
    bubbleText: active?.displayMessage ?? state.baseIntent?.displayMessage,
    isBubbleVisible: (active?.fixedMessage ?? active?.displayMessage) != null,
    mood: 'neutral',
    action: 'idle',
    module: module,
  );
}
