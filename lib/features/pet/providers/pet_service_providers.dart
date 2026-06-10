import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/database_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/service_providers.dart';
import '../services/pet_diary_service.dart';

/// Pet diary generation service Provider.
final petDiaryServiceProvider = Provider<PetDiaryService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PetDiaryService(
    db: db,
    diaryRepository: ref.watch(petDiaryRepositoryProvider),
    aiConfigRepository: ref.watch(aiConfigRepositoryProvider),
    settingRepository: ref.watch(settingRepositoryProvider),
    aiService: ref.watch(aiServiceProvider),
  );
});
