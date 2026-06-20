import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/study/utils/knowledge_source_chunker.dart';
import '../../features/study/utils/knowledge_tfidf_index.dart';
import '../../features/study/utils/knowledge_synonyms.dart';
import '../database/app_database.dart';

class KnowledgeSourceRepository {
  KnowledgeSourceRepository(this._db, {KnowledgeSourceChunker? chunker})
    : _chunker = chunker ?? const KnowledgeSourceChunker();

  static const _duplicateResolutionSettingKey =
      'knowledge_source_duplicate_resolutions';
  static const _keepBothDuplicateResolution = 'keep_both';

  final AppDatabase _db;
  final KnowledgeSourceChunker _chunker;

  Future<int> importTextSource({
    required String title,
    required String content,
    String type = 'text',
    String? sourcePath,
    String goalKey = 'custom',
    String? goalName,
    String moduleKey = 'custom',
    String? moduleName,
    String? tags,
  }) async {
    final chunks = _chunker.split(content);
    final now = DateTime.now().millisecondsSinceEpoch;

    return _db.transaction(() async {
      final sourceId = await _db
          .into(_db.knowledgeSources)
          .insert(
            KnowledgeSourcesCompanion.insert(
              title: title.trim(),
              type: Value(type),
              sourcePath: Value(_nullable(sourcePath)),
              goalKey: Value(goalKey),
              goalName: Value(_nullable(goalName)),
              moduleKey: Value(moduleKey),
              moduleName: Value(_nullable(moduleName)),
              tags: Value(_nullable(tags)),
              createdAt: now,
              updatedAt: now,
            ),
          );

      if (chunks.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.knowledgeChunks,
            chunks.map(
              (chunk) => KnowledgeChunksCompanion.insert(
                sourceId: sourceId,
                chunkIndex: chunk.index,
                heading: Value(_nullable(chunk.heading)),
                content: chunk.content,
                tokenEstimate: Value(chunk.tokenEstimate),
                createdAt: now,
              ),
            ),
          );
        });
      }

      return sourceId;
    });
  }

  Future<List<KnowledgeSource>> getSources({bool includeArchived = false}) {
    final query = _db.select(_db.knowledgeSources);
    if (!includeArchived) {
      query.where((t) => t.archived.equals(false));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.get();
  }

  Future<KnowledgeSource?> getSourceById(int id) {
    return (_db.select(
      _db.knowledgeSources,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateSourceMetadata({
    required int id,
    required String title,
    required String type,
    required String goalKey,
    required String moduleKey,
    String? sourcePath,
    String? goalName,
    String? moduleName,
    String? tags,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Source title cannot be empty.',
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(
      _db.knowledgeSources,
    )..where((t) => t.id.equals(id))).write(
      KnowledgeSourcesCompanion(
        title: Value(trimmedTitle),
        type: Value(type.trim().isEmpty ? 'text' : type.trim()),
        sourcePath: Value(_nullable(sourcePath)),
        goalKey: Value(goalKey),
        goalName: Value(_nullable(goalName)),
        moduleKey: Value(moduleKey),
        moduleName: Value(_nullable(moduleName)),
        tags: Value(_nullable(tags)),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> renameCustomGoal({
    required String oldGoalName,
    required String newGoalName,
  }) {
    final oldName = oldGoalName.trim();
    final newName = newGoalName.trim();
    if (oldName.isEmpty || newName.isEmpty || oldName == newName) {
      return Future.value();
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.knowledgeSources)..where(
          (t) =>
              t.archived.equals(false) &
              t.goalKey.equals('custom') &
              t.goalName.equals(oldName),
        ))
        .write(
          KnowledgeSourcesCompanion(
            goalName: Value(newName),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> replaceSourceContent({
    required int id,
    required String content,
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw ArgumentError.value(
        content,
        'content',
        'Source content cannot be empty.',
      );
    }

    final hasLinkedCards =
        await ((_db.selectOnly(_db.knowledgeCardSourceLinks)
              ..addColumns([_db.knowledgeCardSourceLinks.id.count()])
              ..where(_db.knowledgeCardSourceLinks.sourceId.equals(id)))
            .map(
              (row) =>
                  row.read(_db.knowledgeCardSourceLinks.id.count()) != null &&
                  row.read(_db.knowledgeCardSourceLinks.id.count())! > 0,
            )
            .getSingle());
    if (hasLinkedCards) {
      throw StateError(
        'Cannot rebuild source chunks after cards have linked citations.',
      );
    }

    final chunks = _chunker.split(trimmedContent);
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await (_db.delete(
        _db.knowledgeChunks,
      )..where((t) => t.sourceId.equals(id))).go();

      if (chunks.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.knowledgeChunks,
            chunks.map(
              (chunk) => KnowledgeChunksCompanion.insert(
                sourceId: id,
                chunkIndex: chunk.index,
                heading: Value(_nullable(chunk.heading)),
                content: chunk.content,
                tokenEstimate: Value(chunk.tokenEstimate),
                createdAt: now,
              ),
            ),
          );
        });
      }

      await (_db.update(_db.knowledgeSources)..where((t) => t.id.equals(id)))
          .write(KnowledgeSourcesCompanion(updatedAt: Value(now)));
    });
  }

  Future<List<KnowledgeSourceImportDuplicateCandidate>>
  findImportDuplicateCandidates({
    required String title,
    required String content,
    String? sourcePath,
    int limit = 3,
  }) {
    return _findDuplicateCandidates(
      title: title,
      content: content,
      sourcePath: sourcePath,
      limit: limit,
    );
  }

  Future<List<KnowledgeSourceImportDuplicateCandidate>>
  findRelatedDuplicateSources({required int sourceId, int limit = 3}) async {
    final source = await getSourceById(sourceId);
    if (source == null) return const [];

    final chunks = await getChunksForSource(sourceId);
    final content = _rebuildSourceContent(chunks);
    final candidates = await _findDuplicateCandidates(
      title: source.title,
      content: content,
      sourcePath: source.sourcePath,
      limit: limit,
      excludeSourceId: sourceId,
    );
    final resolutions = await _loadDuplicateResolutions();
    return candidates
        .where(
          (candidate) => !_isDuplicatePairKept(
            resolutions: resolutions,
            sourceId: sourceId,
            candidateSourceId: candidate.source.id,
          ),
        )
        .toList(growable: false);
  }

  Future<void> markDuplicatePairKept({
    required int sourceId,
    required int candidateSourceId,
  }) async {
    if (sourceId == candidateSourceId) {
      throw ArgumentError.value(
        candidateSourceId,
        'candidateSourceId',
        'Duplicate pair requires two different sources.',
      );
    }

    final source = await getSourceById(sourceId);
    final candidate = await getSourceById(candidateSourceId);
    if (source == null || candidate == null) {
      throw StateError('Cannot resolve duplicates for missing sources.');
    }

    final resolutions = await _loadDuplicateResolutions();
    resolutions[_duplicatePairKey(sourceId, candidateSourceId)] =
        _keepBothDuplicateResolution;
    await _saveDuplicateResolutions(resolutions);
  }

  Future<List<KnowledgeSourceImportDuplicateCandidate>>
  _findDuplicateCandidates({
    required String title,
    required String content,
    String? sourcePath,
    required int limit,
    int? excludeSourceId,
  }) async {
    final normalizedTitle = _normalizeDuplicateText(title);
    final normalizedSourcePath = _normalizeDuplicateText(sourcePath ?? '');
    final normalizedContent = _normalizeDuplicateText(content);
    if (normalizedContent.isEmpty) return const [];

    final sources = await getSources(includeArchived: true);
    final candidates = <KnowledgeSourceImportDuplicateCandidate>[];

    for (final source in sources) {
      if (excludeSourceId != null && source.id == excludeSourceId) {
        continue;
      }
      final chunks = await getChunksForSource(source.id);
      final references = await getCardReferencesForSource(source.id);
      final rebuiltContent = _rebuildSourceContent(chunks);
      final sourceNormalizedContent = _normalizeDuplicateText(rebuiltContent);
      if (sourceNormalizedContent.isEmpty) continue;

      final sameTitle =
          normalizedTitle.isNotEmpty &&
          _normalizeDuplicateText(source.title) == normalizedTitle;
      final sameSourcePath =
          normalizedSourcePath.isNotEmpty &&
          _normalizeDuplicateText(source.sourcePath ?? '') ==
              normalizedSourcePath;
      final exactContentMatch = sourceNormalizedContent == normalizedContent;
      final similarContentMatch =
          !exactContentMatch &&
          _hasSubstantialContentOverlap(
            normalizedContent,
            sourceNormalizedContent,
          );

      var score = 0;
      if (exactContentMatch) score += 100;
      if (similarContentMatch) score += 40;
      if (sameTitle) score += 25;
      if (sameSourcePath) score += 20;

      if (!exactContentMatch &&
          !similarContentMatch &&
          !(sameTitle && sameSourcePath)) {
        continue;
      }

      candidates.add(
        KnowledgeSourceImportDuplicateCandidate(
          source: source,
          score: score,
          chunkCount: chunks.length,
          linkedCardCount: references
              .map((item) => item.card.id)
              .toSet()
              .length,
          exactContentMatch: exactContentMatch,
          similarContentMatch: similarContentMatch,
          sameTitle: sameTitle,
          sameSourcePath: sameSourcePath,
        ),
      );
    }

    candidates.sort((left, right) {
      final scoreCompare = right.score.compareTo(left.score);
      if (scoreCompare != 0) return scoreCompare;
      return right.source.updatedAt.compareTo(left.source.updatedAt);
    });
    return candidates.take(limit).toList(growable: false);
  }

  Future<List<KnowledgeChunk>> getChunksForSource(int sourceId) {
    return (_db.select(_db.knowledgeChunks)
          ..where((t) => t.sourceId.equals(sourceId))
          ..orderBy([(t) => OrderingTerm.asc(t.chunkIndex)]))
        .get();
  }

  /// Get chunks for multiple sources in a single query (batch optimization).
  /// Returns a map of sourceId -> list of chunks.
  Future<Map<int, List<KnowledgeChunk>>> getChunksForSources(
    List<int> sourceIds,
  ) async {
    if (sourceIds.isEmpty) return {};
    final chunks =
        await (_db.select(_db.knowledgeChunks)
              ..where((t) => t.sourceId.isIn(sourceIds))
              ..orderBy([(t) => OrderingTerm.asc(t.chunkIndex)]))
            .get();
    final result = <int, List<KnowledgeChunk>>{};
    for (final chunk in chunks) {
      result.putIfAbsent(chunk.sourceId, () => []).add(chunk);
    }
    return result;
  }

  /// Get card references for multiple sources in a single query (batch optimization).
  /// Returns a map of sourceId -> list of references.
  Future<Map<int, List<KnowledgeCardSourceLink>>> getCardReferencesForSources(
    List<int> sourceIds,
  ) async {
    if (sourceIds.isEmpty) return {};
    final links = await (_db.select(
      _db.knowledgeCardSourceLinks,
    )..where((t) => t.sourceId.isIn(sourceIds))).get();
    final result = <int, List<KnowledgeCardSourceLink>>{};
    for (final link in links) {
      result.putIfAbsent(link.sourceId, () => []).add(link);
    }
    return result;
  }

  Future<List<KnowledgeCardSourceLink>> getAllCardSourceLinks() {
    return _db.select(_db.knowledgeCardSourceLinks).get();
  }

  Future<List<KnowledgeCardSourceReference>> getReferencesForCard(
    int cardId,
  ) async {
    final rows =
        await (_db.select(_db.knowledgeCardSourceLinks).join([
                innerJoin(
                  _db.knowledgeSources,
                  _db.knowledgeSources.id.equalsExp(
                    _db.knowledgeCardSourceLinks.sourceId,
                  ),
                ),
                innerJoin(
                  _db.knowledgeChunks,
                  _db.knowledgeChunks.id.equalsExp(
                    _db.knowledgeCardSourceLinks.chunkId,
                  ),
                ),
              ])
              ..where(_db.knowledgeCardSourceLinks.cardId.equals(cardId))
              ..orderBy([
                OrderingTerm.desc(_db.knowledgeCardSourceLinks.createdAt),
              ]))
            .get();

    return rows
        .map(
          (row) => KnowledgeCardSourceReference(
            link: row.readTable(_db.knowledgeCardSourceLinks),
            source: row.readTable(_db.knowledgeSources),
            chunk: row.readTable(_db.knowledgeChunks),
          ),
        )
        .toList(growable: false);
  }

  Future<List<KnowledgeSourceCardReference>> getCardReferencesForSource(
    int sourceId,
  ) async {
    final rows =
        await (_db.select(_db.knowledgeCardSourceLinks).join([
                innerJoin(
                  _db.knowledgeCards,
                  _db.knowledgeCards.id.equalsExp(
                    _db.knowledgeCardSourceLinks.cardId,
                  ),
                ),
                innerJoin(
                  _db.knowledgeChunks,
                  _db.knowledgeChunks.id.equalsExp(
                    _db.knowledgeCardSourceLinks.chunkId,
                  ),
                ),
              ])
              ..where(_db.knowledgeCardSourceLinks.sourceId.equals(sourceId))
              ..orderBy([
                OrderingTerm.desc(_db.knowledgeCardSourceLinks.createdAt),
              ]))
            .get();

    return rows
        .map(
          (row) => KnowledgeSourceCardReference(
            link: row.readTable(_db.knowledgeCardSourceLinks),
            card: row.readTable(_db.knowledgeCards),
            chunk: row.readTable(_db.knowledgeChunks),
          ),
        )
        .toList(growable: false);
  }

  Future<List<KnowledgeChunkSearchResult>> searchChunks({
    required String query,
    String? goalKey,
    String? goalName,
    String? moduleKey,
    String? moduleName,
    int limit = 8,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const [];

    final terms = normalizedQuery
        .toLowerCase()
        .split(RegExp(r'[\s,，、]+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);

    final rows = await (_db.select(_db.knowledgeChunks).join([
      innerJoin(
        _db.knowledgeSources,
        _db.knowledgeSources.id.equalsExp(_db.knowledgeChunks.sourceId),
      ),
    ])..where(_db.knowledgeSources.archived.equals(false))).get();

    // Collect scope-filtered chunks for TF-IDF index
    final scopedSources = <int, KnowledgeSource>{};
    final scopedChunks = <KnowledgeChunk>[];
    for (final row in rows) {
      final source = row.readTable(_db.knowledgeSources);
      if (!_matchesScope(
        source,
        goalKey: goalKey,
        goalName: goalName,
        moduleKey: moduleKey,
        moduleName: moduleName,
      )) {
        continue;
      }
      final chunk = row.readTable(_db.knowledgeChunks);
      scopedSources[chunk.id] = source;
      scopedChunks.add(chunk);
    }

    if (scopedChunks.isEmpty) return const [];

    // Build TF-IDF index from scoped chunks
    final tfidfIndex = TfidfIndex();
    tfidfIndex.build(
      scopedChunks
          .map((chunk) => (id: chunk.id, text: chunk.content))
          .toList(growable: false),
    );

    // Expand query with synonyms for better recall
    final expandedTerms = KnowledgeSynonyms.expandQuery(normalizedQuery);
    final expandedQuery = expandedTerms.join(' ');
    final tfidfResults = tfidfIndex.search(expandedQuery, limit: limit * 3);
    final tfidfScores = <int, double>{
      for (final r in tfidfResults) r.id: r.score,
    };

    // Compute blended scores: 55% TF-IDF + 35% keyword + 10% recency
    final results = <KnowledgeChunkSearchResult>[];
    for (final chunk in scopedChunks) {
      final source = scopedSources[chunk.id]!;
      final keywordScore = terms.isEmpty
          ? 0
          : _scoreChunk(source, chunk, terms);
      final tfidfScore = tfidfScores[chunk.id] ?? 0.0;
      final recencyBoost = _recencyBoost(source.updatedAt);

      // Only score chunks that match on at least one signal
      if (keywordScore <= 0 && tfidfScore <= 0) continue;

      // Normalize scores for blending
      final normalizedKeyword = keywordScore.toDouble().clamp(0, 100);
      final normalizedTfidf = tfidfScore > 0
          ? (tfidfScore * 10).clamp(0, 100)
          : 0.0;

      final blendedScore =
          (normalizedTfidf * 0.55 +
                  normalizedKeyword * 0.35 +
                  recencyBoost * 2.0)
              .round()
              .clamp(1, 9999);

      results.add(
        KnowledgeChunkSearchResult(
          source: source,
          chunk: chunk,
          score: blendedScore,
        ),
      );
    }

    results.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      final sourceCompare = b.source.updatedAt.compareTo(a.source.updatedAt);
      if (sourceCompare != 0) return sourceCompare;
      return a.chunk.chunkIndex.compareTo(b.chunk.chunkIndex);
    });
    return results.take(limit).toList(growable: false);
  }

  Future<void> archiveSource(int id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(
      _db.knowledgeSources,
    )..where((t) => t.id.equals(id))).write(
      KnowledgeSourcesCompanion(
        archived: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteSource(int id) async {
    await (_db.delete(
      _db.knowledgeSources,
    )..where((t) => t.id.equals(id))).go();
    await _removeDuplicateResolutionsForSource(id);
  }

  Future<void> linkCardToChunk({
    required int cardId,
    required int sourceId,
    required int chunkId,
    String? quote,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db
        .into(_db.knowledgeCardSourceLinks)
        .insert(
          KnowledgeCardSourceLinksCompanion.insert(
            cardId: cardId,
            sourceId: sourceId,
            chunkId: chunkId,
            quote: Value(_nullable(quote)),
            createdAt: now,
          ),
        );
  }

  bool _matchesScope(
    KnowledgeSource source, {
    String? goalKey,
    String? goalName,
    String? moduleKey,
    String? moduleName,
  }) {
    if (goalKey != null && goalKey.isNotEmpty && source.goalKey != goalKey) {
      return false;
    }
    if (moduleKey != null &&
        moduleKey.isNotEmpty &&
        source.moduleKey != moduleKey) {
      return false;
    }
    if (goalName != null &&
        goalName.trim().isNotEmpty &&
        source.goalName != goalName.trim()) {
      return false;
    }
    if (moduleName != null &&
        moduleName.trim().isNotEmpty &&
        source.moduleName != moduleName.trim()) {
      return false;
    }
    return true;
  }

  int _scoreChunk(
    KnowledgeSource source,
    KnowledgeChunk chunk,
    List<String> terms,
  ) {
    final title = source.title.toLowerCase();
    final heading = (chunk.heading ?? '').toLowerCase();
    final content = chunk.content.toLowerCase();
    var score = 0;
    for (final term in terms) {
      if (title == term) {
        score += 18;
      } else if (title.contains(term)) {
        score += 12;
      }
      if (heading == term) {
        score += 16;
      } else if (heading.contains(term)) {
        score += 10;
      }
      final occurrences = _countOccurrences(content, term);
      score += occurrences.clamp(0, 6) * 2;
    }
    if (score > 0) score += _recencyBoost(source.updatedAt);
    return score;
  }

  int _recencyBoost(int updatedAt) {
    final age = DateTime.now().millisecondsSinceEpoch - updatedAt;
    if (age <= const Duration(days: 7).inMilliseconds) return 3;
    if (age <= const Duration(days: 30).inMilliseconds) return 2;
    if (age <= const Duration(days: 90).inMilliseconds) return 1;
    return 0;
  }

  int _countOccurrences(String text, String term) {
    var count = 0;
    var start = 0;
    while (true) {
      final index = text.indexOf(term, start);
      if (index == -1) return count;
      count++;
      start = index + term.length;
    }
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _duplicatePairKey(int leftId, int rightId) {
    final first = leftId < rightId ? leftId : rightId;
    final second = leftId < rightId ? rightId : leftId;
    return '$first:$second';
  }

  bool _isDuplicatePairKept({
    required Map<String, String> resolutions,
    required int sourceId,
    required int candidateSourceId,
  }) {
    return resolutions[_duplicatePairKey(sourceId, candidateSourceId)] ==
        _keepBothDuplicateResolution;
  }

  Future<Map<String, String>> _loadDuplicateResolutions() async {
    final row =
        await (_db.select(_db.appSettings)
              ..where((t) => t.key.equals(_duplicateResolutionSettingKey)))
            .getSingleOrNull();
    final rawValue = row?.value.trim();
    if (rawValue == null || rawValue.isEmpty) {
      return <String, String>{};
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map) {
        return <String, String>{};
      }
      return decoded.map<String, String>(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> _saveDuplicateResolutions(
    Map<String, String> resolutions,
  ) async {
    if (resolutions.isEmpty) {
      await (_db.delete(
        _db.appSettings,
      )..where((t) => t.key.equals(_duplicateResolutionSettingKey))).go();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion(
            key: const Value(_duplicateResolutionSettingKey),
            value: Value(jsonEncode(resolutions)),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> _removeDuplicateResolutionsForSource(int sourceId) async {
    final resolutions = await _loadDuplicateResolutions();
    final prefix = '$sourceId:';
    final suffix = ':$sourceId';
    final originalLength = resolutions.length;
    resolutions.removeWhere(
      (pairKey, _) => pairKey.startsWith(prefix) || pairKey.endsWith(suffix),
    );
    if (resolutions.length == originalLength) {
      return;
    }
    await _saveDuplicateResolutions(resolutions);
  }

  String _normalizeDuplicateText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  String _rebuildSourceContent(List<KnowledgeChunk> chunks) {
    return chunks
        .map((chunk) => chunk.content.trim())
        .where((item) => item.isNotEmpty)
        .join('\n\n');
  }

  bool _hasSubstantialContentOverlap(String left, String right) {
    if (left.isEmpty || right.isEmpty) return false;
    if (left == right) return true;

    final shorter = left.length <= right.length ? left : right;
    final longer = left.length <= right.length ? right : left;
    if (shorter.length >= 120 && longer.contains(shorter)) {
      return true;
    }

    final prefixLength = left.length < right.length
        ? left.length
        : right.length;
    final comparableLength = prefixLength > 160 ? 160 : prefixLength;
    if (comparableLength < 80) return false;
    return left.substring(0, comparableLength) ==
        right.substring(0, comparableLength);
  }

  /// Check knowledge base data integrity.
  ///
  /// Returns a list of human-readable issues found. Empty list = healthy.
  Future<List<String>> checkHealth() async {
    final issues = <String>[];

    // Check for sources without chunks
    final sources = await getSources(includeArchived: true);
    for (final source in sources) {
      final chunks = await getChunksForSource(source.id);
      if (chunks.isEmpty) {
        issues.add('资料「${source.title}」(id: ${source.id}) 没有任何切片');
      }
    }

    // Check for broken source links
    final allLinks = await getAllCardSourceLinks();
    final sourceIds = sources.map((s) => s.id).toSet();
    for (final link in allLinks) {
      if (!sourceIds.contains(link.sourceId)) {
        issues.add(
          '来源引用 (id: ${link.id}) 指向不存在的资料 (sourceId: ${link.sourceId})',
        );
      }
    }

    // Check for duplicate source titles
    final titleCounts = <String, int>{};
    for (final src in sources) {
      final key = src.title.trim().toLowerCase();
      titleCounts[key] = (titleCounts[key] ?? 0) + 1;
    }
    for (final entry in titleCounts.entries) {
      if (entry.value > 1) {
        issues.add('发现 ${entry.value} 份同名资料：「${entry.key}」');
      }
    }

    return issues;
  }
}

class KnowledgeChunkSearchResult {
  const KnowledgeChunkSearchResult({
    required this.source,
    required this.chunk,
    required this.score,
  });

  final KnowledgeSource source;
  final KnowledgeChunk chunk;
  final int score;
}

class KnowledgeCardSourceReference {
  const KnowledgeCardSourceReference({
    required this.link,
    required this.source,
    required this.chunk,
  });

  final KnowledgeCardSourceLink link;
  final KnowledgeSource source;
  final KnowledgeChunk chunk;
}

class KnowledgeSourceCardReference {
  const KnowledgeSourceCardReference({
    required this.link,
    required this.card,
    required this.chunk,
  });

  final KnowledgeCardSourceLink link;
  final KnowledgeCard card;
  final KnowledgeChunk chunk;
}

class KnowledgeSourceImportDuplicateCandidate {
  const KnowledgeSourceImportDuplicateCandidate({
    required this.source,
    required this.score,
    required this.chunkCount,
    required this.linkedCardCount,
    required this.exactContentMatch,
    required this.similarContentMatch,
    required this.sameTitle,
    required this.sameSourcePath,
  });

  final KnowledgeSource source;
  final int score;
  final int chunkCount;
  final int linkedCardCount;
  final bool exactContentMatch;
  final bool similarContentMatch;
  final bool sameTitle;
  final bool sameSourcePath;

  List<String> get reasons {
    final labels = <String>[];
    if (exactContentMatch) {
      labels.add('正文完全一致');
    } else if (similarContentMatch) {
      labels.add('正文高度相似');
    }
    if (sameTitle) {
      labels.add('标题一致');
    }
    if (sameSourcePath) {
      labels.add('来源说明一致');
    }
    return labels;
  }

  String get reasonSummary => reasons.join(' · ');
}
