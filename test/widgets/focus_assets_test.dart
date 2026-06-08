import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/focus/utils/focus_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FocusAssets are bundled and loadable', (tester) async {
    for (final asset in FocusAssets.all) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}
