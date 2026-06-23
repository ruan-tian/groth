import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/pet/pet_ai_result.dart';
import 'pet_message_provider.dart';

/// Get the latest AI analysis result for a specific module
final latestPetAnalysisProvider = FutureProvider.family<PetAIResult?, String>((
  ref,
  sourceType,
) async {
  final repo = ref.watch(petMessageRepositoryProvider);
  return repo.getLatestAnalysis(sourceType);
});

/// Get the latest AI analysis result across ALL modules
///
/// Used by dashboard and pet center to show the most recent AI insight
/// regardless of which module generated it.
final latestPetAnalysisOverallProvider = FutureProvider<PetAIResult?>((
  ref,
) async {
  final repo = ref.watch(petMessageRepositoryProvider);
  return repo.getLatestAnalysisOverall();
});
