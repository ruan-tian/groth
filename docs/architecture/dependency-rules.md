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

| Source | Target | Allowed Paths | Reason |
|--------|--------|---------------|--------|
| ai | knowledge | services, providers | AI analysis uses knowledge context |
| focus | music | models, providers, utils | White noise in focus timer |
| dashboard | fitness, health | utils, pages, providers | Dashboard aggregation + refresh |
| settings | fitness | utils | Avatar assets |
| fitness | dashboard | providers | Refresh dashboard after adding record |

## Legacy Exceptions

| File | Exception | TODO |
|------|-----------|------|
| features/ai/pages/ai_analysis_page.dart | Imports 5 module providers | Refactor to AiAnalysisInputFacade (facade created) |

## Legacy Re-exports

`core/repositories/` and `shared/providers/` contain re-export files for backward compatibility. These are marked with `// Legacy compatibility only.` comments. New code should import directly from `features/*/repositories/` and `features/*/providers/`.

Current counts:
- core/repositories/ legacy re-exports: 19
- shared/providers/ legacy re-exports: 19

## Verification

Run `dart scripts/check_architecture.dart` to verify compliance.
