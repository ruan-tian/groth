import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalErrorLogService {
  LocalErrorLogService._();

  static const _fileName = 'growth_os_errors.log';
  static const _archiveFileName = 'growth_os_errors.old.log';
  static const _maxBytes = 512 * 1024;

  static Future<void> recordFlutterError(FlutterErrorDetails details) {
    return record(
      details.exception,
      details.stack ?? StackTrace.current,
      source:
          details.context?.toStringDeep(minLevel: DiagnosticLevel.info) ??
          'flutter',
    );
  }

  static Future<void> record(
    Object error,
    StackTrace stack, {
    String source = 'zone',
  }) async {
    try {
      final file = await _logFile();
      await _rotateIfNeeded(file);
      final entry = [
        '--- ${DateTime.now().toIso8601String()} [$source] ---',
        error.toString(),
        stack.toString(),
        '',
      ].join('\n');
      await file.writeAsString(entry, mode: FileMode.append, flush: true);
    } catch (e) {
      // Error logging must never become the reason the app crashes.
      debugPrint('写入错误日志失败: $e');
    }
  }

  static Future<List<String>> readRecentLines({int limit = 200}) async {
    try {
      final file = await _logFile();
      if (!await file.exists()) return const [];
      final lines = await file.readAsLines();
      if (lines.length <= limit) return lines;
      return lines.sublist(lines.length - limit);
    } catch (e) {
      debugPrint('读取错误日志失败: $e');
      return const [];
    }
  }

  static Future<void> clear() async {
    try {
      final file = await _logFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('清除错误日志失败: $e');
    }
  }

  static Future<File> _logFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final logDir = Directory('${supportDir.path}${Platform.pathSeparator}logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    return File('${logDir.path}${Platform.pathSeparator}$_fileName');
  }

  static Future<void> _rotateIfNeeded(File file) async {
    if (!await file.exists()) return;
    final length = await file.length();
    if (length < _maxBytes) return;

    final archive = File(
      '${file.parent.path}${Platform.pathSeparator}$_archiveFileName',
    );
    if (await archive.exists()) {
      await archive.delete();
    }
    await file.rename(archive.path);
  }
}
