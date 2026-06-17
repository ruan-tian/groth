import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/music_repository.dart';
import 'package:growth_os/features/music/utils/music_assets.dart';

MusicTracksCompanion _track({
  String title = 'Local Song',
  String filePath = 'C:/music/local.mp3',
  String originalPath = 'D:/source/local.mp3',
  int? createdAt,
}) {
  final now = createdAt ?? DateTime.now().millisecondsSinceEpoch;
  return MusicTracksCompanion.insert(
    title: title,
    filePath: filePath,
    originalPath: Value(originalPath),
    coverAsset: const Value(MusicAssets.coverDefault),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late MusicRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MusicRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('inserts and fetches local music tracks', () async {
    final id = await repo.insertTrack(_track(title: 'Morning Lofi'));

    final track = await repo.getTrackById(id);

    expect(track, isNotNull);
    expect(track!.title, 'Morning Lofi');
    expect(track.coverAsset, MusicAssets.coverDefault);
    expect(track.isFavorite, isFalse);
  });

  test('finds tracks by original path to avoid duplicate imports', () async {
    await repo.insertTrack(_track(originalPath: 'D:/source/song.mp3'));

    final existing = await repo.getTrackByOriginalPath('D:/source/song.mp3');

    expect(existing, isNotNull);
    expect(existing!.originalPath, 'D:/source/song.mp3');
  });

  test('updates favorite state and filters favorites', () async {
    final id = await repo.insertTrack(_track(title: 'Favorite Song'));

    await repo.updateFavorite(id, true);
    final favorites = await repo.getFavoriteTracks();

    expect(favorites, hasLength(1));
    expect(favorites.first.id, id);
    expect(favorites.first.isFavorite, isTrue);
  });

  test('updates duration and last played order', () async {
    final older = await repo.insertTrack(
      _track(title: 'Older', createdAt: 1000, filePath: 'C:/older.mp3'),
    );
    final newer = await repo.insertTrack(
      _track(title: 'Newer', createdAt: 2000, filePath: 'C:/newer.mp3'),
    );

    await repo.updateDuration(older, const Duration(seconds: 215));
    await repo.updateLastPlayed(older);
    final tracks = await repo.getTracks();
    final olderTrack = await repo.getTrackById(older);

    expect(olderTrack!.durationMs, 215000);
    expect(tracks.first.id, older);
    expect(tracks.map((track) => track.id), contains(newer));
  });

  test('creates playlists and stores track membership', () async {
    final trackId = await repo.insertTrack(_track(title: 'Playlist Song'));
    final playlistId = await repo.createPlaylist(
      name: 'Night Mix',
      coverAsset: MusicAssets.playlistCustom01,
    );

    await repo.addTrackToPlaylist(playlistId: playlistId, trackId: trackId);
    await repo.addTrackToPlaylist(playlistId: playlistId, trackId: trackId);

    final playlists = await repo.getPlaylists();
    final memberships = await repo.getPlaylistTracks();

    expect(playlists.single.name, 'Night Mix');
    expect(memberships, hasLength(1));
    expect(memberships.single.playlistId, playlistId);
    expect(memberships.single.trackId, trackId);
  });

  test('setTrackPlaylists replaces previous playlist membership', () async {
    final trackId = await repo.insertTrack(_track(title: 'Move Me'));
    final first = await repo.createPlaylist(
      name: 'First',
      coverAsset: MusicAssets.playlistCustom01,
    );
    final second = await repo.createPlaylist(
      name: 'Second',
      coverAsset: MusicAssets.playlistCustom02,
    );

    await repo.setTrackPlaylists(trackId: trackId, playlistIds: [first]);
    await repo.setTrackPlaylists(trackId: trackId, playlistIds: [second]);

    final memberships = await repo.getPlaylistTracks();

    expect(memberships, hasLength(1));
    expect(memberships.single.playlistId, second);
  });

  test('updates and clears manual scene override', () async {
    final trackId = await repo.insertTrack(_track(title: 'Manual Scene'));

    await repo.updateSceneOverride(trackId, 'sleep');
    final sleepTrack = await repo.getTrackById(trackId);

    expect(sleepTrack!.sceneOverride, 'sleep');

    await repo.updateSceneOverride(trackId, null);
    final clearedTrack = await repo.getTrackById(trackId);

    expect(clearedTrack!.sceneOverride, null);
  });
}
