# Repository Guide

## Repository Purpose

Repositories encapsulate data access logic. They:
- Own the database instance (`AppDatabase`)
- Provide typed CRUD operations
- Handle transactions for multi-table operations
- Abstract Drift-specific details from providers/pages

## Repository Placement

| Location | Purpose | Example |
|----------|---------|---------|
| `features/xxx/repositories/` | Business repositories | `FitnessRepository`, `JournalRepository` |
| `core/repositories/` | Global repositories only | `SettingRepository` |

## Repository Naming

| Pattern | Example |
|---------|---------|
| Entity repository | `FitnessRepository`, `PetRepository` |
| Composite entity | `PetMessageRepository`, `KnowledgeCardRepository` |

## Repository Methods

### Standard CRUD

```dart
class FitnessRepository {
  FitnessRepository(this._db);
  final AppDatabase _db;

  Future<int> insertRecord(FitnessRecordsCompanion record);
  Future<void> updateRecord(FitnessRecordsCompanion record);
  Future<void> deleteRecord(int id);
  Future<FitnessRecord?> getRecordById(int id);
  Future<List<FitnessRecord>> getAllRecords();
}
```

### Transaction Pattern

```dart
Future<int> saveRecordWithExp({
  required FitnessRecordsCompanion record,
  required Iterable<FitnessExercisesCompanion> exercises,
  required int exp,
  required String reason,
  required int createdAt,
}) {
  return _db.transaction(() async {
    final recordId = await insertRecord(record);
    await insertExercises(exercises.map(
      (e) => e.copyWith(recordId: Value(recordId)),
    ));
    await updateRecordExp(recordId, exp);
    await ExpRepository(_db).insertExpLog(...);
    return recordId;
  });
}
```

## Anti-Patterns

### Don't: Direct DB access in providers/pages

```dart
// BAD
final db = ref.read(databaseProvider);
await db.into(db.petMessages).insert(...);
```

### Do: Use repository

```dart
// GOOD
final repo = ref.read(petMessageRepositoryProvider);
await repo.insertAnalysisResult(...);
```

### Don't: Business repositories in core/

```dart
// BAD - core/repositories/study_repository.dart
class StudyRepository { ... }
```

### Do: Business repositories in features/

```dart
// GOOD - features/study/repositories/study_repository.dart
class StudyRepository { ... }
```

## Legacy Re-exports

`core/repositories/` contains re-export files for backward compatibility. These are marked with `// Legacy compatibility only.` New code should import directly from `features/*/repositories/`.

Current legacy re-exports: 0 files (all deleted)

## Data Aggregation Services

Some services need to query data from multiple modules for aggregation purposes. These services should:

1. Be placed in the feature that owns the aggregation logic
2. Accept repositories as constructor dependencies
3. Use repository methods when available
4. Fall back to direct DB access only when repository methods don't exist

### PetDiaryDataCollector

`PetDiaryDataCollector` aggregates data from study, fitness, diet, sleep, task, exp, and weather modules for pet diary generation. It now uses repository methods:

- `StudyRepository.getStudyRecordsByRange(DateTime, DateTime)`
- `FitnessRepository.getFitnessRecordsByRange(DateTime, DateTime)`
- `DietRepository.getDietRecordsByDate(DateTime)`
- `SleepRepository.getSleepRecordByDate(DateTime)`
- `ExpRepository.getExpLogsByRange(DateTime, DateTime)`
- `DailyTaskRepository.getTasksByDate(String)`
- `WeatherRepository.getWeatherByDate(String)`

**Status**: Fully integrated with repository pattern.
