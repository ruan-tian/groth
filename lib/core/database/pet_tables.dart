import 'package:drift/drift.dart';

/// 宠物档案表
@DataClassName('PetProfile')
class PetProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant('甜甜'))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer()(); // timestamp ms
  IntColumn get updatedAt => integer()(); // timestamp ms
}

/// 宠物状态表
@DataClassName('PetState')
class PetStates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get currentState => text().withDefault(const Constant('idle'))();
  IntColumn get lastInteractionTime => integer()(); // timestamp ms
  IntColumn get lastHappyTime => integer().nullable()();
  IntColumn get createdAt => integer()(); // timestamp ms
  IntColumn get updatedAt => integer()(); // timestamp ms
}
