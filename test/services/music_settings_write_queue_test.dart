import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/music/services/music_settings_write_queue.dart';

void main() {
  test('flush writes only the latest value for each key', () async {
    final writes = <String, String>{};
    final queue = MusicSettingsWriteQueue(
      writeDelay: const Duration(days: 1),
      write: (key, value) async {
        writes[key] = value;
      },
    );

    queue.schedule('volume', '0.2');
    queue.schedule('volume', '0.8');
    queue.schedule('float_x', '0.4');
    await queue.flush();

    expect(writes, {'volume': '0.8', 'float_x': '0.4'});
  });

  test('serializes overlapping flushes', () async {
    final order = <String>[];
    final queue = MusicSettingsWriteQueue(
      writeDelay: const Duration(days: 1),
      write: (key, value) async {
        order.add('$key:$value:start');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        order.add('$key:$value:end');
      },
    );

    queue.schedule('a', '1');
    final firstFlush = queue.flush();
    queue.schedule('b', '2');
    final secondFlush = queue.flush();
    await Future.wait([firstFlush, secondFlush]);

    expect(order, ['a:1:start', 'a:1:end', 'b:2:start', 'b:2:end']);
  });

  test('dispose flushes pending writes and ignores later schedules', () async {
    final writes = <String, String>{};
    final queue = MusicSettingsWriteQueue(
      writeDelay: const Duration(days: 1),
      write: (key, value) async {
        writes[key] = value;
      },
    );

    queue.schedule('position', '1200');
    await queue.dispose();
    queue.schedule('position', '2400');
    await queue.flush();

    expect(writes, {'position': '1200'});
  });
}
