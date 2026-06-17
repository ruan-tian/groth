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
  MusicImportService({Future<Directory> Function()? musicDirectoryProvider})
    : _musicDirectoryProvider = musicDirectoryProvider;

  static const supportedExtensions = <String>[
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
  ];

  final Future<Directory> Function()? _musicDirectoryProvider;

  Future<List<ImportedMusicFile>> pickAndCopyTracks() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
    );
    if (result == null) return const [];

    return copyTracksFromPaths(result.files.map((file) => file.path));
  }

  Future<List<ImportedMusicFile>> pickAndCopyDirectory() async {
    final directoryPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择音乐文件夹',
    );
    if (directoryPath == null) return const [];

    return scanAndCopyDirectory(directoryPath);
  }

  Future<List<ImportedMusicFile>> scanAndCopyDirectory(
    String directoryPath,
  ) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) return const [];

    final sourcePaths = <String>[];
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      if (!_isSupportedAudioPath(entity.path)) continue;
      sourcePaths.add(entity.path);
    }
    sourcePaths.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return copyTracksFromPaths(sourcePaths);
  }

  Future<List<ImportedMusicFile>> copyTracksFromPaths(
    Iterable<String?> sourcePaths,
  ) async {
    final targetDir = await _musicDirectory();
    final imported = <ImportedMusicFile>[];
    var index = 0;
    for (final sourcePath in sourcePaths) {
      if (sourcePath == null) continue;
      if (!_isSupportedAudioPath(sourcePath)) continue;

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
      await _copySidecarLyrics(sourcePath, targetPath);
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
    final customDirectory = await _musicDirectoryProvider?.call();
    if (customDirectory != null) {
      if (!await customDirectory.exists()) {
        await customDirectory.create(recursive: true);
      }
      return customDirectory;
    }

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

  bool _isSupportedAudioPath(String path) {
    final extension = p.extension(path).replaceFirst('.', '').toLowerCase();
    return supportedExtensions.contains(extension);
  }

  Future<String?> pickAndCopyLrcForTrack(String audioFilePath) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['lrc'],
    );
    if (result == null) return null;

    final sourcePath = result.files.first.path;
    if (sourcePath == null) return null;

    final source = File(sourcePath);
    if (!await source.exists()) return null;

    // 复制LRC文件到音频文件旁边
    final targetDir = p.dirname(audioFilePath);
    final targetName = '${p.basenameWithoutExtension(audioFilePath)}.lrc';
    final targetPath = p.join(targetDir, targetName);
    await source.copy(targetPath);
    return targetPath;
  }

  Future<void> _copySidecarLyrics(String sourcePath, String targetPath) async {
    final sourceLyrics = File(
      p.join(
        p.dirname(sourcePath),
        '${p.basenameWithoutExtension(sourcePath)}.lrc',
      ),
    );
    if (!await sourceLyrics.exists()) return;

    final targetLyrics = File(
      p.join(
        p.dirname(targetPath),
        '${p.basenameWithoutExtension(targetPath)}.lrc',
      ),
    );
    await sourceLyrics.copy(targetLyrics.path);
  }
}
