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

/// Independent daily diary written by the pet, not the user's journal.
@DataClassName('PetDiary')
class PetDiaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get diaryDate => text().unique()(); // YYYY-MM-DD
  TextColumn get title => text()();
  TextColumn get contentMarkdown => text()();
  TextColumn get mood => text().withDefault(const Constant('cozy'))();
  TextColumn get comicPanelsJson => text().withDefault(const Constant('[]'))();
  TextColumn get dataSummaryJson => text().withDefault(const Constant('{}'))();
  TextColumn get generationStatus =>
      text().withDefault(const Constant('pending'))();
  TextColumn get generationMode =>
      text().withDefault(const Constant('manual'))();
  IntColumn get createdAt => integer()(); // timestamp ms
  IntColumn get updatedAt => integer()(); // timestamp ms
}
