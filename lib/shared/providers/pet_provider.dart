import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../features/pet/utils/pet_assets.dart';
import 'dashboard_provider.dart';

enum PetStateType { idle, peek, happy, sleepy }

class PetRepository {
  PetRepository(this._db);

  final AppDatabase _db;

  Future<PetProfile?> getProfile() async {
    final profiles = await (_db.select(_db.petProfiles)..limit(1)).get();
    return profiles.isNotEmpty ? profiles.first : null;
  }

  Future<void> initProfile() async {
    final existing = await getProfile();
    if (existing == null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db
          .into(_db.petProfiles)
          .insert(
            PetProfilesCompanion(
              name: const Value('甜甜'),
              level: const Value(1),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }
  }

  Future<void> updateName(String name) async {
    final profile = await getProfile();
    final cleanName = normalizePetName(name);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (profile == null) {
      await _db
          .into(_db.petProfiles)
          .insert(
            PetProfilesCompanion(
              name: Value(cleanName),
              level: const Value(1),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      return;
    }

    await (_db.update(
      _db.petProfiles,
    )..where((t) => t.id.equals(profile.id))).write(
      PetProfilesCompanion(name: Value(cleanName), updatedAt: Value(now)),
    );
  }

  Future<void> updateLevel(int level) async {
    final profile = await getProfile();
    if (profile != null) {
      await (_db.update(
        _db.petProfiles,
      )..where((t) => t.id.equals(profile.id))).write(
        PetProfilesCompanion(
          level: Value(level),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
  }

  Future<PetState?> getState() async {
    final states = await (_db.select(_db.petStates)..limit(1)).get();
    return states.isNotEmpty ? states.first : null;
  }

  Future<void> initState() async {
    final existing = await getState();
    if (existing == null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db
          .into(_db.petStates)
          .insert(
            PetStatesCompanion(
              currentState: const Value('idle'),
              lastInteractionTime: Value(now),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }
  }

  Future<void> updateState(String state) async {
    final existing = await getState();
    if (existing != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await (_db.update(
        _db.petStates,
      )..where((t) => t.id.equals(existing.id))).write(
        PetStatesCompanion(
          currentState: Value(state),
          lastInteractionTime: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }

  Future<void> recordHappyTime() async {
    final existing = await getState();
    if (existing != null) {
      await (_db.update(
        _db.petStates,
      )..where((t) => t.id.equals(existing.id))).write(
        PetStatesCompanion(
          lastHappyTime: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
  }

  Future<bool> shouldShowSleepy() async {
    final state = await getState();
    if (state == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursSinceInteraction =
        (now - state.lastInteractionTime) / (1000 * 60 * 60);

    return hoursSinceInteraction >= 48;
  }
}

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
  final dashboard = await ref.watch(dashboardProvider.future);
  return dashboard.currentLevel;
});

final petNameProvider = FutureProvider<String>((ref) async {
  final profile = await ref.watch(petProfileProvider.future);
  return normalizePetName(profile?.name);
});

String normalizePetName(String? name) {
  final clean = name?.trim();
  if (clean == null || clean.isEmpty) return '甜甜';
  if (clean.contains('鐢滅敎')) return '甜甜';
  return clean;
}

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
  final dashboard = ref.watch(dashboardProvider);
  return dashboard.when(
    data: (data) => petTitleForLevel(data.currentLevel),
    loading: () => '萌芽',
    error: (_, _) => '萌芽',
  );
});

final petAppearanceProvider = Provider<String>((ref) {
  final dashboard = ref.watch(dashboardProvider);
  return dashboard.when(
    data: (data) => petAppearanceForLevel(data.currentLevel),
    loading: () => '普通甜甜',
    error: (_, _) => '普通甜甜',
  );
});
