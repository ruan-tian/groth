import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/constants/pet_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PetCenterAssets are bundled and loadable', (tester) async {
    final assets = [
      ...PetCenterAssets.all,
      PetAssets.eventExpGain,
      PetAssets.eventLevelUp,
      PetAssets.eventTaskDone,
      PetAssets.eventWeeklyRpt,
      PetAssets.eventMonthlyRpt,
      PetAssets.aiThinking,
      PetAssets.aiPrivacy,
      PetAssets.aiReport,
      PetAssets.commonEmpty,
      PetCenterAssets.bubbleTail,
      'assets/pet/empty/empty_task.webp',
      'assets/pet/concerts/参加ChrisJames演唱会.webp',
    ];

    for (final asset in assets) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}
