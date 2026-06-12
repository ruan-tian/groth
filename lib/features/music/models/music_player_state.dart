import '../../../core/database/app_database.dart';
import 'music_lyrics.dart';

enum PlayMode {
  sequential,  // 顺序播放
  loopAll,     // 列表循环
  loopSingle,  // 单曲循环
  shuffle,     // 随机播放
}

enum MusicCollection {
  all,
  favorites,
  recent;

  String get label {
    return switch (this) {
      MusicCollection.all => '全部',
      MusicCollection.favorites => '收藏',
      MusicCollection.recent => '最近',
    };
  }
}

class MusicPlayerState {
  const MusicPlayerState({
    this.tracks = const [],
    this.currentTrackId,
    this.selectedCollection = MusicCollection.all,
    this.playMode = PlayMode.loopAll,
    this.isPlaying = false,
    this.isExpanded = false,
    this.isLoading = false,
    this.isImporting = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 0.65,
    this.lyrics = const MusicLyricsView(),
    this.sleepTimerEndAtMs,
    this.sleepTimerEndOfTrack = false,
    this.sleepTimerRemainingSeconds = 0,
    this.floatX = 0.0,
    this.floatY = 0.72,
    this.errorMessage,
  });

  final List<MusicTrack> tracks;
  final int? currentTrackId;
  final MusicCollection selectedCollection;
  final PlayMode playMode;
  final bool isPlaying;
  final bool isExpanded;
  final bool isLoading;
  final bool isImporting;
  final Duration position;
  final Duration duration;
  final double volume;
  final MusicLyricsView lyrics;
  final int? sleepTimerEndAtMs;
  final bool sleepTimerEndOfTrack;
  final int sleepTimerRemainingSeconds;
  final double floatX;
  final double floatY;
  final String? errorMessage;

  MusicTrack? get currentTrack {
    for (final track in tracks) {
      if (track.id == currentTrackId) return track;
    }
    return tracks.isEmpty ? null : tracks.first;
  }

  List<MusicTrack> get favoriteTracks {
    return tracks.where((track) => track.isFavorite).toList();
  }

  List<MusicTrack> get recentTracks {
    final recent = tracks.where((track) => track.lastPlayedAt != null).toList();
    if (recent.isEmpty) return tracks;
    recent.sort((a, b) => (b.lastPlayedAt ?? 0).compareTo(a.lastPlayedAt ?? 0));
    return recent;
  }

  List<MusicTrack> get selectedTracks {
    return tracksForCollection(selectedCollection);
  }

  List<MusicTrack> tracksForCollection(MusicCollection collection) {
    return switch (collection) {
      MusicCollection.all => tracks,
      MusicCollection.favorites => favoriteTracks,
      MusicCollection.recent => recentTracks,
    };
  }

  bool get hasTracks => tracks.isNotEmpty;

  String get playModeLabel {
    return switch (playMode) {
      PlayMode.sequential => '顺序',
      PlayMode.loopAll => '列表循环',
      PlayMode.loopSingle => '单曲循环',
      PlayMode.shuffle => '随机',
    };
  }

  bool get hasActiveSleepTimer {
    return sleepTimerEndOfTrack || sleepTimerEndAtMs != null;
  }

  String get sleepTimerLabel {
    if (sleepTimerEndOfTrack) return '播完停止';
    final seconds = sleepTimerRemainingSeconds;
    if (seconds <= 0) return '定时';
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }

  Duration get effectiveDuration {
    if (duration > Duration.zero) return duration;
    final ms = currentTrack?.durationMs;
    if (ms == null || ms <= 0) return Duration.zero;
    return Duration(milliseconds: ms);
  }

  double get progress {
    final total = effectiveDuration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  int get activeLyricIndex => lyrics.activeIndex(position);

  MusicLyricLine? get previousLyric => lyrics.lineAt(activeLyricIndex - 1);

  MusicLyricLine? get currentLyric => lyrics.lineAt(activeLyricIndex);

  MusicLyricLine? get nextLyric => lyrics.lineAt(activeLyricIndex + 1);

  MusicPlayerState copyWith({
    List<MusicTrack>? tracks,
    Object? currentTrackId = _sentinel,
    MusicCollection? selectedCollection,
    PlayMode? playMode,
    bool? isPlaying,
    bool? isExpanded,
    bool? isLoading,
    bool? isImporting,
    Duration? position,
    Duration? duration,
    double? volume,
    MusicLyricsView? lyrics,
    Object? sleepTimerEndAtMs = _sentinel,
    bool? sleepTimerEndOfTrack,
    int? sleepTimerRemainingSeconds,
    double? floatX,
    double? floatY,
    Object? errorMessage = _sentinel,
  }) {
    return MusicPlayerState(
      tracks: tracks ?? this.tracks,
      currentTrackId: currentTrackId == _sentinel
          ? this.currentTrackId
          : currentTrackId as int?,
      selectedCollection: selectedCollection ?? this.selectedCollection,
      playMode: playMode ?? this.playMode,
      isPlaying: isPlaying ?? this.isPlaying,
      isExpanded: isExpanded ?? this.isExpanded,
      isLoading: isLoading ?? this.isLoading,
      isImporting: isImporting ?? this.isImporting,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      lyrics: lyrics ?? this.lyrics,
      sleepTimerEndAtMs: sleepTimerEndAtMs == _sentinel
          ? this.sleepTimerEndAtMs
          : sleepTimerEndAtMs as int?,
      sleepTimerEndOfTrack: sleepTimerEndOfTrack ?? this.sleepTimerEndOfTrack,
      sleepTimerRemainingSeconds:
          sleepTimerRemainingSeconds ?? this.sleepTimerRemainingSeconds,
      floatX: floatX ?? this.floatX,
      floatY: floatY ?? this.floatY,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
