import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/pet/models/pet_ai_result.dart';
import 'dashboard_provider.dart';

/// Get the latest AI analysis result for a specific module
final latestPetAnalysisProvider =
    FutureProvider.family<PetAIResult?, String>((ref, sourceType) async {
  final db = ref.read(databaseProvider);

  final query = db.select(db.petMessages)
    ..where(
        (t) => t.type.equals('analysis') & t.sourceType.equals(sourceType))
    ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ..limit(1);

  final results = await query.get();
  if (results.isEmpty) return null;

  final record = results.first;
  return PetAIResult(
    title: record.title,
    summary: record.content,
    highlights: record.highlights?.split('|||') ?? [],
    risks: record.risks?.split('|||') ?? [],
    suggestions: record.suggestions?.split('|||') ?? [],
    petMessage: record.petMessage,
  );
});
