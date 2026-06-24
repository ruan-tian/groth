# Dependency Rules

## Core Rules

```
app -> features, core, shared
features -> core, shared
shared -> must not import features
core -> must not import features
```

## Forbidden Dependencies

| Rule | Source | Target | Status |
|------|--------|--------|--------|
| R1 | core | features | Forbidden |
| R2 | shared | features | Forbidden (re-exports allowed) |
| R3 | pages | core/database | Forbidden |
| R4 | feature A | feature B internals | Forbidden (whitelist excepted) |

## Cross-Feature Whitelist

Short-term exceptions documented in `scripts/check_architecture.dart`:

| Source | Target | Allowed Paths | Reason | Status |
|--------|--------|---------------|--------|--------|
| ai | knowledge | services, providers | AI analysis uses knowledge context | ✅ Facade integrated |
| focus | music | models, providers, utils | White noise in focus timer | ⏳ FocusMusicFacade created, to be integrated |
| dashboard | fitness, health | utils, pages, providers | Dashboard aggregation + refresh | ✅ DashboardQuickActions created |
| settings | fitness | utils | Avatar assets | ✅ Acceptable |
| fitness | dashboard | providers | Refresh dashboard after adding record | ✅ FitnessDashboardFacade created |

## Legacy Exceptions

| File | Exception | TODO |
|------|-----------|------|
| features/ai/pages/ai_analysis_page.dart | Imports 5 module providers | ✅ Refactored to use AiAnalysisInputFacade |

## Facade Files

| Facade | File | Purpose |
|--------|------|---------|
| AiAnalysisInputFacade | `lib/features/ai/providers/ai_analysis_input_facade.dart` | Aggregates study/fitness/diet/sleep/dashboard data for AI analysis |
| FocusMusicFacade | `lib/features/focus/providers/focus_music_facade.dart` | Abstracts music player for focus module |
| DashboardQuickActions | `lib/features/dashboard/providers/dashboard_quick_actions.dart` | Abstracts health quick actions for dashboard |
| FitnessDashboardFacade | `lib/features/fitness/providers/fitness_dashboard_facade.dart` | Abstracts dashboard refresh for fitness module |
| PetDiaryDataCollector | `lib/features/pet/services/pet_diary_data_collector.dart` | Encapsulates DB queries for pet diary service |

## Legacy Re-exports

`core/repositories/` and `shared/providers/` contain re-export files for backward compatibility. These are marked with `// Legacy compatibility only.` comments. New code should import directly from `features/*/repositories/` and `features/*/providers/`.

Current counts:
- core/repositories/ legacy re-exports: 19
- shared/providers/ legacy re-exports: 19

## Verification

Run `dart scripts/check_architecture.dart` to verify compliance.
