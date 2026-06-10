import '../../../core/database/app_database.dart';

class MusicPlayerState {
  const MusicPlayerState({
    this.tracks = const [],
    this.currentTrackId,
    this.isPlaying = false,
    this.isExpanded = false,
    this.isLoading = false,
    this.isImporting = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 0.65,
    this.errorMessage,
  });

  final List<MusicTrack> tracks;
  final int? currentTrackId;
  final bool isPlaying;
  final bool isExpanded;
  final bool isLoading;
  final bool isImporting;
  final Duration position;
  final Duration duration;
  final double volume;
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

  bool get hasTracks => tracks.isNotEmpty;

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

  MusicPlayerState copyWith({
    List<MusicTrack>? tracks,
    Object? currentTrackId = _sentinel,
    bool? isPlaying,
    bool? isExpanded,
    bool? isLoading,
    bool? isImporting,
    Duration? position,
    Duration? duration,
    double? volume,
    Object? errorMessage = _sentinel,
  }) {
    return MusicPlayerState(
      tracks: tracks ?? this.tracks,
      currentTrackId: currentTrackId == _sentinel
          ? this.currentTrackId
          : currentTrackId as int?,
      isPlaying: isPlaying ?? this.isPlaying,
      isExpanded: isExpanded ?? this.isExpanded,
      isLoading: isLoading ?? this.isLoading,
      isImporting: isImporting ?? this.isImporting,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
