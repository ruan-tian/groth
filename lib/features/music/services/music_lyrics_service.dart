import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/music_lyrics.dart';

class MusicLyricsService {
  static final RegExp _timestampPattern = RegExp(
    r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]',
  );

  Future<MusicLyricsView> loadForTrack(String audioPath) async {
    final lyricsPath = _lyricsPathForAudio(audioPath);
    final file = File(lyricsPath);
    if (!await file.exists()) {
      return const MusicLyricsView();
    }

    try {
      final content = await file.readAsString();
      final lines = parse(content);
      return MusicLyricsView(lines: lines, sourcePath: lyricsPath);
    } catch (error) {
      return MusicLyricsView(
        sourcePath: lyricsPath,
        errorMessage: '歌词读取失败：$error',
      );
    }
  }

  List<MusicLyricLine> parse(String content) {
    final parsed = <MusicLyricLine>[];
    for (final rawLine in content.split(RegExp(r'\r?\n'))) {
      final matches = _timestampPattern.allMatches(rawLine).toList();
      if (matches.isEmpty) continue;

      final text = rawLine.replaceAll(_timestampPattern, '').trim();
      if (text.isEmpty) continue;

      for (final match in matches) {
        parsed.add(MusicLyricLine(time: _durationFromMatch(match), text: text));
      }
    }
    parsed.sort((a, b) => a.time.compareTo(b.time));
    return parsed;
  }

  String _lyricsPathForAudio(String audioPath) {
    final dir = p.dirname(audioPath);
    final base = p.basenameWithoutExtension(audioPath);
    return p.join(dir, '$base.lrc');
  }

  Duration _durationFromMatch(RegExpMatch match) {
    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final fraction = match.group(3) ?? '0';
    final milliseconds = switch (fraction.length) {
      1 => int.parse(fraction) * 100,
      2 => int.parse(fraction) * 10,
      _ => int.parse(fraction.padRight(3, '0').substring(0, 3)),
    };
    return Duration(
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}
