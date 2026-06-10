import 'package:drift/drift.dart';

import '../database/app_database.dart';

class MusicRepository {
  MusicRepository(this._db);

  final AppDatabase _db;

  Stream<List<MusicTrack>> watchTracks() {
    return (_db.select(_db.musicTracks)..orderBy([
          (t) => OrderingTerm.desc(t.lastPlayedAt),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
        .watch();
  }

  Future<List<MusicTrack>> getTracks() {
    return (_db.select(_db.musicTracks)..orderBy([
          (t) => OrderingTerm.desc(t.lastPlayedAt),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
        .get();
  }

  Future<List<MusicTrack>> getFavoriteTracks() {
    return (_db.select(_db.musicTracks)
          ..where((t) => t.isFavorite.equals(true))
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .get();
  }

  Future<MusicTrack?> getTrackById(int id) {
    return (_db.select(
      _db.musicTracks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<MusicTrack?> getTrackByOriginalPath(String originalPath) {
    return (_db.select(
      _db.musicTracks,
    )..where((t) => t.originalPath.equals(originalPath))).getSingleOrNull();
  }

  Future<int> insertTrack(MusicTracksCompanion track) {
    return _db.into(_db.musicTracks).insert(track);
  }

  Future<void> updateFavorite(int id, bool isFavorite) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.musicTracks)..where((t) => t.id.equals(id))).write(
      MusicTracksCompanion(
        isFavorite: Value(isFavorite),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updateLastPlayed(int id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.musicTracks)..where((t) => t.id.equals(id))).write(
      MusicTracksCompanion(lastPlayedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<void> updateDuration(int id, Duration duration) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.musicTracks)..where((t) => t.id.equals(id))).write(
      MusicTracksCompanion(
        durationMs: Value(duration.inMilliseconds),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteTrack(int id) {
    return (_db.delete(_db.musicTracks)..where((t) => t.id.equals(id))).go();
  }
}
