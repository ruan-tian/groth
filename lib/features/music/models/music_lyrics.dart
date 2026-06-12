class MusicLyricLine {
  const MusicLyricLine({
    required this.time,
    required this.text,
  });

  final Duration time;
  final String text;
}

class MusicLyricsView {
  const MusicLyricsView({
    this.lines = const [],
    this.sourcePath,
    this.errorMessage,
  });

  final List<MusicLyricLine> lines;
  final String? sourcePath;
  final String? errorMessage;

  bool get hasLyrics => lines.isNotEmpty;

  int activeIndex(Duration position) {
    if (lines.isEmpty) return -1;
    var index = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].time <= position) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }

  MusicLyricLine? lineAt(int index) {
    if (index < 0 || index >= lines.length) return null;
    return lines[index];
  }
}
