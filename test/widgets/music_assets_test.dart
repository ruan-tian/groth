import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/music/utils/music_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MusicAssets are bundled and loadable', (tester) async {
    expect(MusicAssets.all, hasLength(46));

    for (final asset in MusicAssets.all) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
  });

  testWidgets('MusicAssets have alpha or are WebP', (tester) async {
    for (final asset in MusicAssets.all) {
      final data = await rootBundle.load(asset);
      final isWebP = _isWebP(data);
      final isAlphaPng = _pngHasAlphaChannel(data);
      expect(isWebP || isAlphaPng, isTrue,
          reason: '$asset should be WebP or alpha PNG');
    }
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

bool _pngHasAlphaChannel(ByteData data) {
  const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (data.lengthInBytes < 26) return false;
  for (var i = 0; i < pngSignature.length; i++) {
    if (data.getUint8(i) != pngSignature[i]) return false;
  }
  final colorType = data.getUint8(25);
  return colorType == 4 || colorType == 6;
}
