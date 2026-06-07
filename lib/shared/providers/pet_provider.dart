import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import 'dashboard_provider.dart';

// =============================================================================
// Pet 状态枚举
// =============================================================================

/// 宠物状态
enum PetStateType {
  idle, // 默认状态
  peek, // 探头状态
  happy, // 开心状态
  sleepy, // 困倦状态
}

// =============================================================================
// Pet Repository
// =============================================================================

/// 宠物仓库
class PetRepository {
  PetRepository(this._db);

  final AppDatabase _db;

  /// 获取宠物档案
  Future<PetProfile?> getProfile() async {
    final profiles = await (_db.select(_db.petProfiles)..limit(1)).get();
    return profiles.isNotEmpty ? profiles.first : null;
  }

  /// 初始化宠物档案
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

  /// 更新宠物等级
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

  /// 获取宠物状态
  Future<PetState?> getState() async {
    final states = await (_db.select(_db.petStates)..limit(1)).get();
    return states.isNotEmpty ? states.first : null;
  }

  /// 初始化宠物状态
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

  /// 更新宠物状态
  Future<void> updateState(String state) async {
    final existing = await getState();
    if (existing != null) {
      await (_db.update(
        _db.petStates,
      )..where((t) => t.id.equals(existing.id))).write(
        PetStatesCompanion(
          currentState: Value(state),
          lastInteractionTime: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
  }

  /// 记录开心时间
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

  /// 检查是否需要显示 sleepy 状态（48小时未记录）
  Future<bool> shouldShowSleepy() async {
    final state = await getState();
    if (state == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursSinceInteraction =
        (now - state.lastInteractionTime) / (1000 * 60 * 60);

    return hoursSinceInteraction >= 48;
  }
}

// =============================================================================
// Pet Providers
// =============================================================================

/// 宠物仓库 Provider
final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository(ref.watch(databaseProvider));
});

/// 宠物档案 Provider
final petProfileProvider = FutureProvider<PetProfile?>((ref) async {
  final repo = ref.watch(petRepositoryProvider);
  return repo.getProfile();
});

/// 宠物状态 Provider
final petStateProvider = FutureProvider<PetState?>((ref) async {
  final repo = ref.watch(petRepositoryProvider);
  return repo.getState();
});

/// 当前宠物状态类型 Provider
final petStateTypeProvider = StateProvider<PetStateType>((ref) {
  return PetStateType.idle;
});

/// 宠物等级 Provider
final petLevelProvider = FutureProvider<int>((ref) async {
  final profile = await ref.watch(petProfileProvider.future);
  return profile?.level ?? 1;
});

/// 宠物名称 Provider
final petNameProvider = FutureProvider<String>((ref) async {
  final profile = await ref.watch(petProfileProvider.future);
  return profile?.name ?? '甜甜';
});

/// 宠物等级名称
String getPetLevelName(int level) {
  if (level >= 50) return '围巾甜甜';
  if (level >= 20) return '眼镜甜甜';
  if (level >= 10) return '书包甜甜';
  return '普通甜甜';
}

/// 宠物状态图片路径
String getPetImagePath(PetStateType state) {
  switch (state) {
    case PetStateType.idle:
      return 'assets/pet/pet_idle.png';
    case PetStateType.peek:
      return 'assets/pet/pet_peek.png';
    case PetStateType.happy:
      return 'assets/pet/pet_happy.png';
    case PetStateType.sleepy:
      return 'assets/pet/pet_sleepy.png';
  }
}

/// 宠物提示文案
String getPetMessage(PetStateType state) {
  switch (state) {
    case PetStateType.idle:
      return '今天也要加油哦～';
    case PetStateType.peek:
      return '好久没记录了，来写点什么吧？';
    case PetStateType.happy:
      return '太棒了！目标完成啦～';
    case PetStateType.sleepy:
      return '好困...好久没见到你了...';
  }
}

/// 宠物提示气泡 Provider
final petBubbleProvider = StateProvider<String?>((ref) {
  return null;
});

/// 宠物提示气泡显示状态
final petBubbleVisibleProvider = StateProvider<bool>((ref) {
  return false;
});

/// 陪伴天数 Provider
final petAgeDaysProvider = Provider<int>((ref) {
  final profile = ref.watch(petProfileProvider);
  return profile.when(
    data: (p) {
      if (p == null) return 0;
      final created = DateTime.fromMillisecondsSinceEpoch(p.createdAt);
      return DateTime.now().difference(created).inDays;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// 宠物称号 Provider
final petTitleProvider = Provider<String>((ref) {
  final profile = ref.watch(petProfileProvider);
  return profile.when(
    data: (p) {
      final level = p?.level ?? 1;
      if (level <= 5) return '萌芽';
      if (level <= 10) return '成长';
      if (level <= 20) return '进阶';
      if (level <= 35) return '高手';
      if (level <= 50) return '大师';
      return '传说';
    },
    loading: () => '萌芽',
    error: (_, __) => '萌芽',
  );
});

/// 宠物外观名称 Provider
final petAppearanceProvider = Provider<String>((ref) {
  final profile = ref.watch(petProfileProvider);
  return profile.when(
    data: (p) {
      final level = p?.level ?? 1;
      if (level <= 9) return '普通甜甜';
      if (level <= 19) return '书包甜甜';
      if (level <= 49) return '眼镜甜甜';
      return '围巾甜甜';
    },
    loading: () => '普通甜甜',
    error: (_, __) => '普通甜甜',
  );
});
