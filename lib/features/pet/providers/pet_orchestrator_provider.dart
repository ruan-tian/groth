import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/pet/pet_display_intent.dart';
import '../../../core/domain/pet/pet_priority.dart';
import '../../../core/domain/pet/pet_runtime_state.dart';
import '../../../shared/providers/pet_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../services/life_session_manager.dart';
import '../services/pet_orchestrator.dart';

/// 宠物 Orchestrator Provider（自动初始化）
final petOrchestratorProvider =
    StateNotifierProvider<PetOrchestrator, PetRuntimeState>((ref) {
      final orchestrator = PetOrchestrator(
        expRepository: ref.read(expRepositoryProvider),
        petRepository: ref.read(petRepositoryProvider),
      );
      orchestrator.init();
      ref.onDispose(orchestrator.dispose);
      return orchestrator;
    });

/// 当前应显示的 Intent Provider
final currentPetIntentProvider = Provider<PetDisplayIntent?>((ref) {
  final state = ref.watch(petOrchestratorProvider);
  return state.effectiveIntent;
});

/// Dashboard LifeSession Intent Provider
final dashboardPetIntentProvider = FutureProvider<PetDisplayIntent>((
  ref,
) async {
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

  // 设置为 Dashboard LifeSession，不覆盖模块页待机状态。
  ref.read(petOrchestratorProvider.notifier).setLifeIntent(intent);

  return intent;
});
