import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../core/repositories/pet_repository.dart';
import '../../core/constants/pet_assets.dart';
import '../../../shared/providers/database_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/service_providers.dart';

export '../../core/repositories/pet_repository.dart'
    show PetRepository, normalizePetName;

enum PetStateType { idle, peek, happy, sleepy }

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository(ref.watch(databaseProvider));
});

final petProfileProvider = FutureProvider<PetProfile?>((ref) async {
  final repo = ref.watch(petRepositoryProvider);
  return repo.getProfile();
});

final petStateProvider = FutureProvider<PetState?>((ref) async {
  final repo = ref.watch(petRepositoryProvider);
  return repo.getState();
});

final petStateTypeProvider = StateProvider<PetStateType>((ref) {
  return PetStateType.idle;
});

final petLevelProvider = FutureProvider<int>((ref) async {
  final expRepo = ref.watch(expRepositoryProvider);
  final expService = ref.watch(expServiceProvider);
  final totalExp = await expRepo.getTotalExp();
  return expService.calculateLevelProgress(totalExp).level;
});

final petNameProvider = FutureProvider<String>((ref) async {
  final profile = await ref.watch(petProfileProvider.future);
  return normalizePetName(profile?.name);
});

String petTitleForLevel(int level) {
  if (level <= 5) return '萌芽';
  if (level <= 10) return '成长';
  if (level <= 20) return '进阶';
  if (level <= 35) return '高手';
  if (level <= 50) return '大师';
  return '传说';
}

String petAppearanceForLevel(int level) {
  if (level <= 9) return '普通甜甜';
  if (level <= 19) return '书包甜甜';
  if (level <= 49) return '眼镜甜甜';
  return '围巾甜甜';
}

String getPetLevelName(int level) => petAppearanceForLevel(level);

String getPetImagePath(PetStateType state) {
  switch (state) {
    case PetStateType.idle:
      return PetAssets.petIdle;
    case PetStateType.peek:
      return PetAssets.petPeek;
    case PetStateType.happy:
      return PetAssets.petHappy;
    case PetStateType.sleepy:
      return PetAssets.petSleepy;
  }
}

String getPetMessage(PetStateType state) {
  switch (state) {
    case PetStateType.idle:
      return '今天也要加油哦';
    case PetStateType.peek:
      return '好久没记录了，来写点什么吧';
    case PetStateType.happy:
      return '太棒了，目标完成啦';
    case PetStateType.sleepy:
      return '有点困了，我们慢慢收尾';
  }
}

final petBubbleProvider = StateProvider<String?>((ref) {
  return null;
});

final petBubbleVisibleProvider = StateProvider<bool>((ref) {
  return false;
});

final petAgeDaysProvider = Provider<int>((ref) {
  final profile = ref.watch(petProfileProvider);
  return profile.when(
    data: (p) {
      if (p == null) return 0;
      final created = DateTime.fromMillisecondsSinceEpoch(p.createdAt);
      return DateTime.now().difference(created).inDays;
    },
    loading: () => 0,
    error: (_, _) => 0,
  );
});

final petTitleProvider = Provider<String>((ref) {
  final level = ref.watch(petLevelProvider);
  return level.when(
    data: petTitleForLevel,
    loading: () => '萌芽',
    error: (_, _) => '萌芽',
  );
});

final petAppearanceProvider = Provider<String>((ref) {
  final level = ref.watch(petLevelProvider);
  return level.when(
    data: petAppearanceForLevel,
    loading: () => '普通甜甜',
    error: (_, _) => '普通甜甜',
  );
});
