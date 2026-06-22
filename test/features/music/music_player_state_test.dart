import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/music/models/music_player_state.dart';

MusicTrack _track({
  required int id,
  required String title,
  bool isFavorite = false,
  int? lastPlayedAt,
  String filePath = 'C:/music/song.mp3',
}) {
  return MusicTrack(
    id: id,
    title: title,
    filePath: filePath,
    originalPath: filePath,
    coverAsset: null,
    sceneOverride: null,
    durationMs: null,
    isFavorite: isFavorite,
    lastPlayedAt: lastPlayedAt,
    createdAt: 1000,
    updatedAt: 1000,
  );
}

void main() {
  group('MusicPlayerState', () {
    test('currentTrack returns null when no tracks', () {
      const state = MusicPlayerState();
      expect(state.currentTrack, isNull);
    });

    test('currentTrack returns first track when currentTrackId is null', () {
      final track = _track(id: 1, title: 'Song 1');
      final state = MusicPlayerState(tracks: [track]);
      expect(state.currentTrack?.id, 1);
    });

    test('currentTrack returns matching track by id', () {
      final track1 = _track(id: 1, title: 'Song 1');
      final track2 = _track(id: 2, title: 'Song 2');
      final state = MusicPlayerState(
        tracks: [track1, track2],
        currentTrackId: 2,
      );
      expect(state.currentTrack?.id, 2);
    });

    test('favoriteTracks filters by isFavorite', () {
      final track1 = _track(id: 1, title: 'Song 1', isFavorite: true);
      final track2 = _track(id: 2, title: 'Song 2', isFavorite: false);
      final track3 = _track(id: 3, title: 'Song 3', isFavorite: true);
      final state = MusicPlayerState(tracks: [track1, track2, track3]);

      expect(state.favoriteTracks, hasLength(2));
      expect(state.favoriteTracks.map((t) => t.id), [1, 3]);
    });

    test('recentTracks sorts by lastPlayedAt descending', () {
      final track1 = _track(id: 1, title: 'Old', lastPlayedAt: 1000);
      final track2 = _track(id: 2, title: 'New', lastPlayedAt: 2000);
      final track3 = _track(id: 3, title: 'NoHistory', lastPlayedAt: 500);
      final state = MusicPlayerState(tracks: [track1, track2, track3]);

      // recentTracks filters by lastPlayedAt != null and sorts descending
      expect(state.recentTracks.map((t) => t.id), [2, 1, 3]);
    });

    test('recentTracks returns all tracks when none have lastPlayedAt', () {
      final track1 = _track(id: 1, title: 'Song 1');
      final track2 = _track(id: 2, title: 'Song 2');
      final state = MusicPlayerState(tracks: [track1, track2]);

      // When no tracks have lastPlayedAt, returns all tracks
      expect(state.recentTracks, hasLength(2));
    });

    test('selectedTracks returns all tracks when no playlist selected', () {
      final track1 = _track(id: 1, title: 'Song 1');
      final track2 = _track(id: 2, title: 'Song 2');
      final state = MusicPlayerState(tracks: [track1, track2]);

      expect(state.selectedTracks, hasLength(2));
    });

    test('selectedTracks filters by selectedPlaylistId', () {
      final track1 = _track(id: 1, title: 'Song 1');
      final track2 = _track(id: 2, title: 'Song 2');
      final playlist = MusicPlaylist(
        id: 10,
        name: 'My Playlist',
        coverAsset: 'test',
        sortOrder: 0,
        createdAt: 1000,
        updatedAt: 1000,
      );
      final playlistTrack = MusicPlaylistTrack(
        playlistId: 10,
        trackId: 1,
        createdAt: 1000,
      );
      final state = MusicPlayerState(
        tracks: [track1, track2],
        playlists: [playlist],
        playlistTracks: [playlistTrack],
        selectedPlaylistId: 10,
      );

      expect(state.selectedTracks, hasLength(1));
      expect(state.selectedTracks.first.id, 1);
    });

    test('playQueueIds are preserved in state', () {
      final state = MusicPlayerState(playQueueIds: [3, 1, 2]);
      expect(state.playQueueIds, [3, 1, 2]);
    });

    test('copyWith creates new state with updated values', () {
      const state = MusicPlayerState(
        isPlaying: false,
        volume: 0.5,
      );

      final newState = state.copyWith(
        isPlaying: true,
        volume: 0.8,
      );

      expect(newState.isPlaying, isTrue);
      expect(newState.volume, 0.8);
      expect(state.isPlaying, isFalse);
      expect(state.volume, 0.5);
    });
  });
}
