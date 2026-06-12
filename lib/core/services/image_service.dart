import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageImportException implements Exception {
  const ImageImportException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null ? message : '$message: $cause';
}

class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const double targetLongEdge = 1600;
  static const int imageQuality = 85;

  Future<String?> pickAndSaveImage() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: targetLongEdge,
      maxHeight: targetLongEdge,
      imageQuality: imageQuality,
      requestFullMetadata: false,
    );
    if (xFile == null) return null;

    return _copyToAppDir(xFile.path);
  }

  Future<List<String>> pickAndSaveMultipleImages({int maxImages = 9}) async {
    final xFiles = await _picker.pickMultiImage(
      limit: maxImages,
      maxWidth: targetLongEdge,
      maxHeight: targetLongEdge,
      imageQuality: imageQuality,
      requestFullMetadata: false,
    );
    if (xFiles.isEmpty) return [];

    final paths = <String>[];
    for (final xFile in xFiles) {
      paths.add(await _copyToAppDir(xFile.path));
    }
    return paths;
  }

  Future<String> _copyToAppDir(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'journal_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final ts = DateTime.now().microsecondsSinceEpoch;
      final sourceExt = p.extension(sourcePath);
      final ext = sourceExt.isEmpty ? '.jpg' : sourceExt;
      final fileName = 'img_$ts$ext';
      final destPath = p.join(imagesDir.path, fileName);

      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (error) {
      throw ImageImportException('图片导入失败', error);
    }
  }
}
