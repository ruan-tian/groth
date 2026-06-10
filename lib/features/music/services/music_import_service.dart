import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImportedMusicFile {
  const ImportedMusicFile({
    required this.title,
    required this.filePath,
    required this.originalPath,
  });

  final String title;
  final String filePath;
  final String originalPath;
}

class MusicImportService {
  static const supportedExtensions = <String>[
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
  ];

  Future<List<ImportedMusicFile>> pickAndCopyTracks() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
    );
    if (result == null) return const [];

    final targetDir = await _musicDirectory();
    final imported = <ImportedMusicFile>[];
    var index = 0;
    for (final file in result.files) {
      final sourcePath = file.path;
      if (sourcePath == null) continue;

      final source = File(sourcePath);
      if (!await source.exists()) continue;

      final title = _titleFromPath(sourcePath);
      final extension = p.extension(sourcePath).toLowerCase();
      final safeBase = _safeFileName(p.basenameWithoutExtension(sourcePath));
      final targetPath = p.join(
        targetDir.path,
        '${DateTime.now().millisecondsSinceEpoch}_${index++}_$safeBase$extension',
      );
      await source.copy(targetPath);
      imported.add(
        ImportedMusicFile(
          title: title,
          filePath: targetPath,
          originalPath: sourcePath,
        ),
      );
    }
    return imported;
  }

  Future<Directory> _musicDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'music'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _titleFromPath(String path) {
    final raw = p.basenameWithoutExtension(path).replaceAll('_', ' ').trim();
    return raw.isEmpty ? '本地音乐' : raw;
  }

  String _safeFileName(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    return cleaned.isEmpty ? 'track' : cleaned;
  }
}
