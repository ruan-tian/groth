import '../../../shared/services/settings_write_queue.dart';

typedef MusicSettingWrite = SettingWrite;

class MusicSettingsWriteQueue extends SettingsWriteQueue {
  MusicSettingsWriteQueue({required super.write, super.writeDelay});
}
