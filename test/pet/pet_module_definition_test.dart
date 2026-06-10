import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/domain/pet/pet_scene_model.dart';

void main() {
  test('all pet module definitions expose display contract', () {
    expect(
      PetModuleDefinitions.byType.keys.toSet(),
      equals(PetModuleType.values.toSet()),
    );

    for (final module in PetModuleType.values) {
      final definition = module.definition;
      expect(definition.label, isNotEmpty, reason: module.name);
      expect(definition.softColorHex, startsWith('#'), reason: module.name);
      expect(definition.primaryColorHex, startsWith('#'), reason: module.name);
      expect(definition.defaultImagePath, isNotEmpty, reason: module.name);
      expect(definition.idleStates, isNotEmpty, reason: module.name);
      expect(definition.welcomeMessage, isNotEmpty, reason: module.name);
      expect(definition.encourageMessage, isNotEmpty, reason: module.name);
      expect(definition.doneMessage, isNotEmpty, reason: module.name);
      expect(definition.welcomeBubble, isNotEmpty, reason: module.name);
    }
  });

  test('reserved pet modules are wired to fallback assets', () {
    expect(PetModuleType.music.definition.defaultImagePath, isNotEmpty);
    expect(PetModuleType.accounting.definition.defaultImagePath, isNotEmpty);
    expect(PetSceneStateType.musicIdle.assetPath, isNotEmpty);
    expect(PetSceneStateType.accountingIdle.assetPath, isNotEmpty);
  });
}
