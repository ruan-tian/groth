import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/music/services/music_lyrics_service.dart';

void main() {
  group('MusicLyricsService', () {
    test('parses standard lrc timestamps', () {
      final service = MusicLyricsService();

      final lines = service.parse('''
[00:01.20]第一句
[00:05.05]第二句
''');

      expect(lines, hasLength(2));
      expect(lines[0].time, const Duration(seconds: 1, milliseconds: 200));
      expect(lines[0].text, '第一句');
      expect(lines[1].time, const Duration(seconds: 5, milliseconds: 50));
      expect(lines[1].text, '第二句');
    });

    test('expands multiple timestamps on one line', () {
      final service = MusicLyricsService();

      final lines = service.parse('[00:02.00][00:04.00]重复歌词');

      expect(lines, hasLength(2));
      expect(lines[0].time, const Duration(seconds: 2));
      expect(lines[1].time, const Duration(seconds: 4));
      expect(lines[0].text, '重复歌词');
      expect(lines[1].text, '重复歌词');
    });

    test('ignores empty and invalid lines', () {
      final service = MusicLyricsService();

      final lines = service.parse('''
普通文本
[ar:artist]
[00:03.00]
[00:04.00]有效歌词
''');

      expect(lines, hasLength(1));
      expect(lines.single.time, const Duration(seconds: 4));
      expect(lines.single.text, '有效歌词');
    });
  });
}
