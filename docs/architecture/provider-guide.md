# Provider Guide

## Provider Types

| Type | Use Case | Example |
|------|----------|---------|
| `Provider` | Singleton services, repositories | `fitnessRepositoryProvider` |
| `FutureProvider` | Async data fetching | `journalsProvider` |
| `FutureProvider.family` | Parameterized async data | `journalsByDateProvider(date)` |
| `StateProvider` | Simple mutable state | `selectedTabProvider` |
| `StateNotifierProvider` | Complex state logic | `PetAINotifier` |
| `StreamProvider` | Reactive data streams | `databaseReadyProvider` |

## Provider Placement Rules

### Global Providers (shared/providers/)

Only these types belong in shared/providers/:
- Database provider (`databaseProvider`)
- Settings provider (`settingsProvider`)
- Theme provider (`themeModeProvider`)
- App lifecycle provider (`appLifecycleProvider`)
- Repository providers for global services

### Business Providers (features/xxx/providers/)

All business logic providers belong in their feature:
- Feature-specific state providers
- Feature-specific repository providers
- Feature-specific service providers

## Provider Naming

| Pattern | Example |
|---------|---------|
| Data provider | `journalsProvider`, `todayTasksProvider` |
| Repository provider | `fitnessRepositoryProvider` |
| Service provider | `aiServiceProvider` |
| State provider | `selectedTabProvider` |
| Family provider | `journalsByDateProvider(date)` |

## Anti-Patterns

### Don't: Direct DB access in providers

```dart
// BAD
final allTasksProvider = FutureProvider<List<DailyTask>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.select(db.dailyTasks).get();
});
```

### Do: Use repository

```dart
// GOOD
final allTasksProvider = FutureProvider<List<DailyTask>>((ref) async {
  final repo = ref.watch(dailyTaskRepositoryProvider);
  return repo.getAllTasks();
});
```

### Don't: Business providers in shared/

```dart
// BAD - shared/providers/study_provider.dart
final studyProvider = StateNotifierProvider<...>(...);
```

### Do: Business providers in features/

```dart
// GOOD - features/study/providers/study_provider.dart
final studyProvider = StateNotifierProvider<...>(...);
```
