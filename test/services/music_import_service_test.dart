import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/music/services/music_import_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('MusicImportService', () {
    late Directory sourceDir;
    late Directory targetDir;
    late MusicImportService service;

    setUp(() async {
      sourceDir = await Directory.systemTemp.createTemp('music_source_');
      targetDir = await Directory.systemTemp.createTemp('music_target_');
      service = MusicImportService(
        musicDirectoryProvider: () async => targetDir,
      );
    });

    tearDown(() async {
      if (await sourceDir.exists()) {
        await sourceDir.delete(recursive: true);
      }
      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }
    });

    test(
      'copyTracksFromPaths copies supported audio and sidecar lyrics',
      () async {
        final audio = File(p.join(sourceDir.path, 'Rain_Sound.mp3'));
        final lyrics = File(p.join(sourceDir.path, 'Rain_Sound.lrc'));
        final note = File(p.join(sourceDir.path, 'notes.txt'));
        await audio.writeAsBytes([1, 2, 3]);
        await lyrics.writeAsString('[00:00.00]Rain');
        await note.writeAsString('not audio');

        final imported = await service.copyTracksFromPaths([
          audio.path,
          note.path,
          null,
        ]);

        expect(imported, hasLength(1));
        expect(imported.single.title, 'Rain Sound');
        expect(imported.single.originalPath, audio.path);
        expect(await File(imported.single.filePath).exists(), isTrue);

        final copiedLyrics = File(
          p.join(
            p.dirname(imported.single.filePath),
            '${p.basenameWithoutExtension(imported.single.filePath)}.lrc',
          ),
        );
        expect(await copiedLyrics.readAsString(), '[00:00.00]Rain');
      },
    );

    test(
      'scanAndCopyDirectory recursively imports supported audio only',
      () async {
        final nested = Directory(p.join(sourceDir.path, 'nested'));
        await nested.create();
        final first = File(p.join(nested.path, 'a_focus.wav'));
        final second = File(p.join(sourceDir.path, 'b_sleep.ogg'));
        final unsupported = File(p.join(sourceDir.path, 'cover.png'));
        await first.writeAsBytes([1]);
        await second.writeAsBytes([2]);
        await unsupported.writeAsBytes([3]);

        final imported = await service.scanAndCopyDirectory(sourceDir.path);

        expect(imported.map((file) => file.title), ['b sleep', 'a focus']);
        expect(imported.map((file) => p.extension(file.filePath)), [
          '.ogg',
          '.wav',
        ]);
        for (final file in imported) {
          expect(await File(file.filePath).exists(), isTrue);
        }
      },
    );
  });
}
