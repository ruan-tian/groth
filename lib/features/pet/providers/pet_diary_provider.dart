import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/repository_providers.dart';
import '../services/pet_diary_service.dart';
import 'pet_service_providers.dart';

final todayPetDiaryProvider = FutureProvider<PetDiary?>((ref) async {
  final service = ref.watch(petDiaryServiceProvider);
  return service.ensureTodayDiary();
});

final recentPetDiariesProvider = FutureProvider<List<PetDiary>>((ref) async {
  final repo = ref.watch(petDiaryRepositoryProvider);
  return repo.getRecentDiaries();
});

final petDiaryByIdProvider = FutureProvider.family<PetDiary?, int>((ref, id) {
  final repo = ref.watch(petDiaryRepositoryProvider);
  return repo.getDiaryById(id);
});

final petDiarySummaryPreviewProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.watch(petDiaryServiceProvider);
  return service.buildTodaySummary();
});

final petDiaryAutoEnabledProvider = StateProvider<bool>((ref) => false);

final petDiaryAutoEnabledInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(petDiaryServiceProvider);
  ref.read(petDiaryAutoEnabledProvider.notifier).state = await service
      .isAutoEnabled();
});

Future<void> savePetDiaryAutoEnabled(WidgetRef ref, bool enabled) async {
  ref.read(petDiaryAutoEnabledProvider.notifier).state = enabled;
  await ref.read(petDiaryServiceProvider).setAutoEnabled(enabled);
}

String formatPetDiaryDate(DateTime date) => PetDiaryService.formatDate(date);
