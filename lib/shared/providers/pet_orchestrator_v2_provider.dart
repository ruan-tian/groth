import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/pet/models/pet_display_intent.dart';
import '../../features/pet/models/pet_priority.dart';
import '../../features/pet/models/pet_runtime_state.dart';
import '../../features/pet/services/life_session_manager.dart';
import '../../features/pet/services/pet_orchestrator_v2.dart';

/// 宠物 Orchestrator V2 Provider（自动初始化）
final petOrchestratorV2Provider =
    StateNotifierProvider<PetOrchestratorV2, PetRuntimeState>((ref) {
  final orchestrator = PetOrchestratorV2(ref);
  orchestrator.init();
  ref.onDispose(() => orchestrator.dispose());
  return orchestrator;
});

/// 当前应显示的 Intent Provider
final currentPetIntentProvider = Provider<PetDisplayIntent?>((ref) {
  final state = ref.watch(petOrchestratorV2Provider);
  return state.effectiveIntent;
});

/// Dashboard LifeSession Intent Provider
final dashboardPetIntentProvider = FutureProvider<PetDisplayIntent>((ref) async {
  final manager = ref.read(lifeSessionManagerProvider);
  final session = await manager.getCurrent();

  final intent = PetDisplayIntent(
    id: 'life_${session.id}',
    type: 'life_session',
    priority: PetPriority.life,
    imagePath: session.imagePath,
    messages: session.messages,
    fixedMessage: session.aiMessage,
    startedAt: session.startedAt,
    expiresAt: session.expiresAt,
    fromAI: session.aiUsed,
  );

  // 设置为 baseIntent
  ref.read(petOrchestratorV2Provider.notifier).setBaseIntent(intent);

  return intent;
});