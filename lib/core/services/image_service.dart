import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 图片选取与本地存储服务
///
/// 从系统图库选取图片，复制到应用私有目录，返回本地路径。
class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// 选取单张图片并复制到应用目录，返回本地文件路径。
  ///
  /// 用户取消时返回 `null`。
  Future<String?> pickAndSaveImage() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return null;

    final savedPath = await _copyToAppDir(xFile.path);
    return savedPath;
  }

  /// 选取多张图片（最多 [maxImages] 张），返回本地文件路径列表。
  ///
  /// 用户取消时返回空列表。
  Future<List<String>> pickAndSaveMultipleImages({
    int maxImages = 9,
  }) async {
    final xFiles = await _picker.pickMultiImage(limit: maxImages);
    if (xFiles.isEmpty) return [];

    final paths = <String>[];
    for (final xFile in xFiles) {
      final savedPath = await _copyToAppDir(xFile.path);
      if (savedPath != null) {
        paths.add(savedPath);
      }
    }
    return paths;
  }

  /// 将 [sourcePath] 复制到 `journal_images/` 子目录，返回目标路径。
  Future<String?> _copyToAppDir(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'journal_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = p.extension(sourcePath); // e.g. ".jpg"
      final fileName = 'img_$ts$ext';
      final destPath = p.join(imagesDir.path, fileName);

      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (_) {
      return null;
    }
  }
}
