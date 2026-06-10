import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/plan/utils/plan_module_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PlanModuleAssets are bundled and loadable', (tester) async {
    expect(PlanModuleAssets.all, hasLength(45));
    expect(PlanModuleAssets.premiumV2Fallbacks, hasLength(10));
    expect(PlanModuleAssets.premiumFallbacks, hasLength(10));

    for (final asset in PlanModuleAssets.all) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}
