import 'dart:async';

typedef SettingWrite = Future<void> Function(String key, String value);

class SettingsWriteQueue {
  SettingsWriteQueue({
    required SettingWrite write,
    Duration writeDelay = const Duration(milliseconds: 350),
  }) : _write = write,
       _writeDelay = writeDelay;

  final SettingWrite _write;
  final Duration _writeDelay;
  final Map<String, String> _pending = {};
  Future<void> _tail = Future.value();
  Timer? _timer;
  bool _disposed = false;

  void schedule(String key, String value) {
    if (_disposed) return;
    if (_pending[key] == value) return;
    _pending[key] = value;
    _timer?.cancel();
    _timer = Timer(_writeDelay, () {
      unawaited(flush());
    });
  }

  Future<void> writeNow(String key, String value) {
    schedule(key, value);
    return flush();
  }

  Future<void> flush() {
    if (_pending.isEmpty) return _tail;
    _timer?.cancel();
    _timer = null;
    final batch = Map<String, String>.from(_pending);
    _pending.clear();
    _tail = _tail.then((_) => _writeBatch(batch));
    return _tail;
  }

  Future<void> dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    return flush();
  }

  Future<void> _writeBatch(Map<String, String> batch) async {
    for (final entry in batch.entries) {
      await _write(entry.key, entry.value);
    }
  }
}
