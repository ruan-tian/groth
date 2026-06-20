import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../features/music/utils/default_music_seed.dart';

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

  Future<List<MusicPlaylist>> getPlaylists() {
    return (_db.select(_db.musicPlaylists)..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
        .get();
  }

  Future<List<MusicPlaylistTrack>> getPlaylistTracks() {
    return _db.select(_db.musicPlaylistTracks).get();
  }

  Future<int> ensureDefaultStudyPlaylist() async {
    final existingPlaylist =
        await (_db.select(_db.musicPlaylists)
              ..where((t) => t.name.equals(DefaultMusicSeeds.playlistName))
              ..limit(1))
            .getSingleOrNull();
    final playlistId =
        existingPlaylist?.id ??
        await createPlaylist(
          name: DefaultMusicSeeds.playlistName,
          coverAsset: DefaultMusicSeeds.playlistCover,
        );

    for (final seed in DefaultMusicSeeds.seeds) {
      final trackId = await _ensureSeedTrack(seed);
      await addTrackToPlaylist(playlistId: playlistId, trackId: trackId);
    }

    return playlistId;
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

  Future<int> _ensureSeedTrack(DefaultMusicSeed seed) async {
    final existing = await getTrackByOriginalPath(seed.originalPath);
    if (existing != null) return existing.id;

    final now = DateTime.now().millisecondsSinceEpoch;
    return insertTrack(
      MusicTracksCompanion.insert(
        title: seed.title,
        filePath: seed.filePath,
        originalPath: Value(seed.originalPath),
        coverAsset: Value(seed.coverAsset),
        sceneOverride: Value(seed.sceneOverride),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<int> insertTrack(MusicTracksCompanion track) {
    return _db.into(_db.musicTracks).insert(track);
  }

  Future<int> createPlaylist({
    required String name,
    required String coverAsset,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxSort =
        await (_db.selectOnly(_db.musicPlaylists)
              ..addColumns([_db.musicPlaylists.sortOrder.max()]))
            .map((row) => row.read(_db.musicPlaylists.sortOrder.max()) ?? -1)
            .getSingle();
    return _db
        .into(_db.musicPlaylists)
        .insert(
          MusicPlaylistsCompanion.insert(
            name: name,
            coverAsset: Value(coverAsset),
            sortOrder: Value(maxSort + 1),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> deletePlaylist(int id) {
    return (_db.delete(_db.musicPlaylists)..where((t) => t.id.equals(id))).go();
  }

  Future<void> addTrackToPlaylist({
    required int playlistId,
    required int trackId,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db
        .into(_db.musicPlaylistTracks)
        .insert(
          MusicPlaylistTracksCompanion.insert(
            playlistId: playlistId,
            trackId: trackId,
            createdAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> removeTrackFromPlaylist({
    required int playlistId,
    required int trackId,
  }) {
    return (_db.delete(_db.musicPlaylistTracks)..where(
          (t) => t.playlistId.equals(playlistId) & t.trackId.equals(trackId),
        ))
        .go();
  }

  Future<void> setTrackPlaylists({
    required int trackId,
    required Iterable<int> playlistIds,
  }) async {
    final uniqueIds = playlistIds.toSet();
    await _db.transaction(() async {
      await (_db.delete(
        _db.musicPlaylistTracks,
      )..where((t) => t.trackId.equals(trackId))).go();
      for (final playlistId in uniqueIds) {
        await addTrackToPlaylist(playlistId: playlistId, trackId: trackId);
      }
    });
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

  Future<void> updateCoverAsset(int id, String coverAsset) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.musicTracks)..where((t) => t.id.equals(id))).write(
      MusicTracksCompanion(
        coverAsset: Value(coverAsset),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updatePlaylistCoverAsset(int id, String coverAsset) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(
      _db.musicPlaylists,
    )..where((t) => t.id.equals(id))).write(
      MusicPlaylistsCompanion(
        coverAsset: Value(coverAsset),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updateSceneOverride(int id, String? sceneOverride) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.musicTracks)..where((t) => t.id.equals(id))).write(
      MusicTracksCompanion(
        sceneOverride: Value(sceneOverride),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteTrack(int id) {
    return (_db.delete(_db.musicTracks)..where((t) => t.id.equals(id))).go();
  }
}
