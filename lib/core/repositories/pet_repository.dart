import 'package:drift/drift.dart';

import '../database/app_database.dart';

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

String normalizePetName(String? name) {
  final clean = name?.trim();
  if (clean == null || clean.isEmpty) return '甜甜';
  if (clean.contains('鐢滅敎')) return '甜甜';
  return clean;
}
