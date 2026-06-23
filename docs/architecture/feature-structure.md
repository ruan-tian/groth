# Feature Structure

## Feature Directory Layout

```
features/xxx/
  pages/           # Page widgets (UI screens)
  widgets/         # Feature-specific widgets
  providers/       # Riverpod providers (state management)
  repositories/    # Data access layer (Drift CRUD)
  models/          # Data models
  services/        # Business logic
  constants/       # Feature-specific constants
  utils/           # Feature-specific utilities
```

## Naming Conventions

| Item | Convention | Example |
|------|------------|---------|
| Feature directory | snake_case | `fitness/`, `knowledge/` |
| Page file | `*_page.dart` | `fitness_page.dart` |
| Provider file | `*_provider.dart` | `fitness_provider.dart` |
| Repository file | `*_repository.dart` | `fitness_repository.dart` |
| Service file | `*_service.dart` | `pet_ai_service.dart` |
| Widget file | descriptive name | `dashboard_pet_widget.dart` |

## Provider Placement

- Business providers: `features/xxx/providers/`
- Global providers: `shared/providers/` (database, settings, theme, lifecycle)
- Repository providers: co-located with repository or in feature's providers/

## Repository Placement

- Business repositories: `features/xxx/repositories/`
- Global repositories: `core/repositories/` (only `setting_repository.dart`)

## Current Feature List

| Feature | Purpose |
|---------|---------|
| dashboard | Home page, overview |
| study | Study records, timer |
| knowledge | Knowledge cards, AI generation |
| fitness | Fitness records, training timer |
| journal | Daily journal, tags |
| health | Diet, sleep, weather |
| focus | Pomodoro timer, white noise |
| statistics | Charts, analytics |
| pet | Pet center, AI analysis |
| music | Music player, playlist |
| plan | Task management |
| ai | AI analysis pages |
| settings | App settings |
