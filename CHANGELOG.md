# Changelog

## 2026-06-18

### Performance Optimizations

- **StatisticsService**: Parallelized 9 sequential DB queries using `Future.wait()` - reduces weekly/monthly stats load from ~9 sequential queries to 1 parallel batch
- **knowledgeBaseOverviewProvider**: Batch chunk fetch - 1 query instead of N (where N = number of sources)
- **knowledge_source_repository**: Added batch methods `getChunksForSources()` and `getCardReferencesForSources()` for bulk operations
- **Composite Indexes**: Added 3 missing indexes for knowledge_cards:
  - `idx_knowledge_cards_mastery` on (archived, mastery_level) - speeds up weak card queries
  - `idx_knowledge_cards_streak` on (archived, correct_streak) - speeds up high-error card queries  
  - `idx_knowledge_cards_due_mastery` on (archived, due_at, mastery_level) - speeds up review queue queries

### Cleanup

- **Removed dead provider**: `dueKnowledgeCardsCountProvider` was never watched (only invalidated) - removed definition + 14 invalidation calls across 11 files

### Files Changed

- `lib/core/services/statistics_service.dart` - Parallel queries
- `lib/core/repositories/knowledge_source_repository.dart` - Batch methods
- `lib/shared/providers/knowledge_source_provider.dart` - Use batch fetch
- `lib/shared/providers/knowledge_card_provider.dart` - Remove dead provider
- `lib/core/database/app_database.dart` - Add composite indexes
- 11 feature files - Remove dead provider invalidation calls
