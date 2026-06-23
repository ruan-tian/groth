# AI Module Boundary

## Module Responsibilities

| Module | Responsibility | Files |
|--------|---------------|-------|
| `core/ai` | AI infrastructure: API client, config, error handling | `ai_client.dart`, `ai_config.dart`, `ai_error.dart` |
| `features/ai` | AI analysis pages, AI chat UI | `ai_analysis_page.dart`, `ai_chat_page.dart` |
| `features/knowledge` | Knowledge context, card generation, review | `knowledge_context_service.dart`, `knowledge_card_ai_service.dart` |

## Data Flow

```
User Action -> features/ai/pages -> features/ai/services -> core/ai/client -> API
                                    features/knowledge/services -> features/knowledge/repositories -> DB
```

## Cross-Module Dependencies

### features/ai -> features/knowledge (Allowed)

- `ai_analysis_card_service.dart` imports `knowledge_card_ai_service.dart`
- `ai_analysis_page.dart` imports `knowledge_context_service.dart`

Reason: AI analysis uses knowledge context for enhanced insights.

### features/ai -> other features (Legacy Exception)

`ai_analysis_page.dart` currently imports providers from:
- dashboard
- study
- fitness
- health (diet, sleep)

TODO: Refactor to `AiAnalysisInputFacade` that aggregates data from module repositories.

## Pet AI Analysis

Pet AI analysis is in `features/pet/services/pet_ai_service.dart`:
- Collects data from study, fitness, diet, sleep modules
- Calls AI API via `core/ai`
- Saves results to `petMessages` table via `PetMessageRepository`

## Future Refactoring

### AiAnalysisInputFacade

```dart
// Target architecture
class AiAnalysisInputFacade {
  AiAnalysisInputFacade({
    required StudyRepository studyRepo,
    required FitnessRepository fitnessRepo,
    required DietRepository dietRepo,
    required SleepRepository sleepRepo,
  });

  Future<Map<String, dynamic>> collectAnalysisData({
    required String module,
    required DateRange range,
  });
}
```

This would:
- Remove direct provider imports from ai_analysis_page
- Centralize data collection logic
- Enable testing with mock repositories
