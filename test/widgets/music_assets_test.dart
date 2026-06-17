import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/music/utils/music_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MusicAssets are bundled and loadable', (tester) async {
    expect(MusicAssets.all, hasLength(93));

    for (final asset in MusicAssets.all) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
  });

  testWidgets('MusicAssets are PNG or WebP images', (tester) async {
    for (final asset in MusicAssets.all) {
      final data = await rootBundle.load(asset);
      final isWebP = _isWebP(data);
      final isPng = _isPng(data);
      expect(isWebP || isPng, isTrue, reason: '$asset should be WebP or PNG');
    }
  });

  test('coverForTitle maps local song names to themed default covers', () {
    expect(MusicAssets.coverForTitle('Morning Lofi'), MusicAssets.coverLofi);
    expect(MusicAssets.coverForTitle('晚安小夜曲'), MusicAssets.coverSleep);
    expect(MusicAssets.coverForTitle('专注学习曲'), MusicAssets.coverStudy);
    expect(
      MusicAssets.coverForTitle('Fitness Beats'),
      MusicAssets.coverFitness,
    );
    expect(
      MusicAssets.coverForTitle('rain white noise'),
      MusicAssets.coverRain,
    );
    expect(MusicAssets.coverForTitle('晨间唤醒'), MusicAssets.coverMorning);
    expect(MusicAssets.coverForTitle('cafe relax'), MusicAssets.coverRelax);
    expect(MusicAssets.coverForTitle('unknown song'), MusicAssets.coverDefault);
  });
}

bool _isWebP(ByteData data) {
  if (data.lengthInBytes < 12) return false;
  return data.getUint8(0) == 0x52 &&
      data.getUint8(1) == 0x49 &&
      data.getUint8(2) == 0x46 &&
      data.getUint8(3) == 0x46 &&
      data.getUint8(8) == 0x57 &&
      data.getUint8(9) == 0x45 &&
      data.getUint8(10) == 0x42 &&
      data.getUint8(11) == 0x50;
}

bool _isPng(ByteData data) {
  const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (data.lengthInBytes < pngSignature.length) return false;
  for (var i = 0; i < pngSignature.length; i++) {
    if (data.getUint8(i) != pngSignature[i]) return false;
  }
  return true;
}
