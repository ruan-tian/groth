import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/knowledge_v3_schema.dart';

class KnowledgeV3Repository {
  KnowledgeV3Repository(this._db);

  static const _defaultSpaceName = '\u9ed8\u8ba4\u77e5\u8bc6\u7a7a\u95f4';
  static const _defaultSpaceNote =
      '\u4ece\u8fd9\u91cc\u5f00\u59cb\u5bfc\u5165\u8d44\u6599\uff0c'
      '\u8ba9\u751c\u751c\u5e2e\u4f60\u751f\u6210\u77e5\u8bc6\u5361\u3002';

  final AppDatabase _db;
  bool _tablesEnsured = false;

  Future<KnowledgeSpaceV3> ensureDefaultSpace() async {
    await _ensureTables();
    final existing = await _db
        .customSelect(
          'SELECT * FROM knowledge_spaces_v3 WHERE name = ? LIMIT 1',
          variables: [const Variable<String>(_defaultSpaceName)],
        )
        .getSingleOrNull();
    if (existing != null) return KnowledgeSpaceV3.fromRow(existing);

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.customInsert(
      '''
      INSERT INTO knowledge_spaces_v3
        (name, type, note, sort_order, is_archived, created_at, updated_at)
      VALUES (?, 'custom', ?, 0, 0, ?, ?)
      ''',
      variables: [
        const Variable<String>(_defaultSpaceName),
        const Variable<String>(_defaultSpaceNote),
        Variable<int>(now),
        Variable<int>(now),
      ],
    );
    return (await getSpace(id))!;
  }

  Future<List<KnowledgeSpaceV3>> getSpaces({
    bool includeArchived = false,
  }) async {
    await _ensureTables();
    final rows = await _db.customSelect('''
          SELECT * FROM knowledge_spaces_v3
          ${includeArchived ? '' : 'WHERE is_archived = 0'}
          ORDER BY updated_at DESC, sort_order ASC
          ''', readsFrom: const {}).get();
    if (rows.isEmpty && !includeArchived) {
      return [await ensureDefaultSpace()];
    }
    return rows.map(KnowledgeSpaceV3.fromRow).toList(growable: false);
  }

  Future<KnowledgeSpaceV3?> getSpace(int id) async {
    await _ensureTables();
    final rows = await _db
        .customSelect(
          'SELECT * FROM knowledge_spaces_v3 WHERE id = ? LIMIT 1',
          variables: [Variable<int>(id)],
        )
        .get();
    if (rows.isEmpty) return null;
    return KnowledgeSpaceV3.fromRow(rows.first);
  }

  Future<int> createSpace({
    required String name,
    String type = 'custom',
    String? note,
  }) async {
    await _ensureTables();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', '空间名称不能为空');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final sortOrder = await _nextSpaceSortOrder();
    return _db.customInsert(
      '''
      INSERT INTO knowledge_spaces_v3
        (name, type, note, sort_order, is_archived, created_at, updated_at)
      VALUES (?, ?, ?, ?, 0, ?, ?)
      ''',
      variables: [
        Variable<String>(trimmed),
        Variable<String>(type),
        Variable<String>(_nullable(note)),
        Variable<int>(sortOrder),
        Variable<int>(now),
        Variable<int>(now),
      ],
    );
  }

  Future<void> renameSpace({
    required int id,
    required String name,
    String? note,
    String? type,
  }) async {
    await _ensureTables();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customUpdate(
      '''
      UPDATE knowledge_spaces_v3
      SET name = ?, note = ?, type = COALESCE(?, type), updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable<String>(name.trim()),
        Variable<String>(_nullable(note)),
        Variable<String>(type),
        Variable<int>(now),
        Variable<int>(id),
      ],
    );
  }

  Future<void> archiveSpace(int id) async {
    await _ensureTables();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customUpdate(
      'UPDATE knowledge_spaces_v3 SET is_archived = 1, updated_at = ? WHERE id = ?',
      variables: [Variable<int>(now), Variable<int>(id)],
    );
  }

  Future<void> rememberSpace(int id) async {
    await _ensureTables();
    await _touchSpace(id, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<KnowledgeMaterial>> getMaterials(int spaceId) async {
    await _ensureTables();
    final rows = await _db
        .customSelect(
          '''
          SELECT * FROM knowledge_materials
          WHERE space_id = ? AND is_archived = 0
          ORDER BY order_index ASC, updated_at DESC
          ''',
          variables: [Variable<int>(spaceId)],
        )
        .get();
    return rows.map(KnowledgeMaterial.fromRow).toList(growable: false);
  }

  Future<KnowledgeMaterial?> getMaterial(int id) async {
    await _ensureTables();
    final rows = await _db
        .customSelect(
          'SELECT * FROM knowledge_materials WHERE id = ? LIMIT 1',
          variables: [Variable<int>(id)],
        )
        .get();
    if (rows.isEmpty) return null;
    return KnowledgeMaterial.fromRow(rows.first);
  }

  Future<int> importMaterial({
    required int spaceId,
    required String title,
    required String content,
    String sourceType = 'text',
    String? sourcePath,
    String? url,
  }) async {
    await _ensureTables();
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw ArgumentError.value(content, 'content', '资料内容不能为空');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.customInsert(
      '''
      INSERT INTO knowledge_materials
        (space_id, title, content, source_type, source_path, url, order_index,
         status, is_archived, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'ready', 0, ?, ?)
      ''',
      variables: [
        Variable<int>(spaceId),
        Variable<String>(
          title.trim().isEmpty ? _deriveTitle(trimmedContent) : title.trim(),
        ),
        Variable<String>(trimmedContent),
        Variable<String>(sourceType),
        Variable<String>(_nullable(sourcePath)),
        Variable<String>(_nullable(url)),
        Variable<int>(await _nextMaterialOrder(spaceId)),
        Variable<int>(now),
        Variable<int>(now),
      ],
    );
    await _touchSpace(spaceId, now);
    return id;
  }

  Future<void> updateMaterial({
    required int id,
    required String title,
    required String content,
  }) async {
    await _ensureTables();
    final material = await getMaterial(id);
    if (material == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customUpdate(
      '''
      UPDATE knowledge_materials
      SET title = ?, content = ?, updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable<String>(title.trim().isEmpty ? material.title : title.trim()),
        Variable<String>(content.trim()),
        Variable<int>(now),
        Variable<int>(id),
      ],
    );
    await _touchSpace(material.spaceId, now);
  }

  Future<void> archiveMaterial(int id) async {
    await _ensureTables();
    final material = await getMaterial(id);
    if (material == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customUpdate(
      'UPDATE knowledge_materials SET is_archived = 1, updated_at = ? WHERE id = ?',
      variables: [Variable<int>(now), Variable<int>(id)],
    );
    await _touchSpace(material.spaceId, now);
  }

  Future<void> reorderMaterial({
    required int id,
    required int direction,
  }) async {
    await _ensureTables();
    final material = await getMaterial(id);
    if (material == null) return;
    final materials = await getMaterials(material.spaceId);
    final index = materials.indexWhere((item) => item.id == id);
    final target = (index + direction).clamp(0, materials.length - 1);
    if (index < 0 || target == index) return;
    final reordered = [...materials];
    final item = reordered.removeAt(index);
    reordered.insert(target, item);
    for (var i = 0; i < reordered.length; i++) {
      await _db.customUpdate(
        'UPDATE knowledge_materials SET order_index = ? WHERE id = ?',
        variables: [Variable<int>(i), Variable<int>(reordered[i].id)],
      );
    }
  }

  Future<List<KnowledgeCardV3>> getCards(int spaceId) async {
    await _ensureTables();
    final rows = await _db
        .customSelect(
          '''
          SELECT * FROM knowledge_cards_v3
          WHERE space_id = ? AND is_archived = 0
          ORDER BY order_index ASC, due_at ASC, importance DESC, updated_at DESC
          ''',
          variables: [Variable<int>(spaceId)],
        )
        .get();
    return rows.map(KnowledgeCardV3.fromRow).toList(growable: false);
  }

  Future<KnowledgeCardV3?> getCard(int id) async {
    await _ensureTables();
    final rows = await _db
        .customSelect(
          'SELECT * FROM knowledge_cards_v3 WHERE id = ? LIMIT 1',
          variables: [Variable<int>(id)],
        )
        .get();
    if (rows.isEmpty) return null;
    return KnowledgeCardV3.fromRow(rows.first);
  }

  Future<int> createCard({
    required int spaceId,
    int? materialId,
    required String question,
    required String answer,
    String? explanation,
    String cardType = 'recall',
    int importance = 3,
    int difficulty = 3,
    String? sourceTitle,
    String? sourceExcerpt,
    String? memoryHint,
    String? sourceChunkId,
    String? sourceLocatorJson,
    String? concept,
    String? knowledgePoint,
    String? examScene,
    String? commonMistake,
    bool grounded = true,
    String status = 'auto_approved',
    List<String> relatedConcepts = const [],
    List<String> tags = const [],
  }) async {
    await _ensureTables();
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.customInsert(
      '''
      INSERT INTO knowledge_cards_v3
        (space_id, material_id, question, answer, explanation, card_type,
         importance, difficulty, source_title, source_excerpt, memory_hint,
         source_chunk_id, source_locator_json, concept, knowledge_point,
         exam_scene, common_mistake, grounded, status,
         related_concepts_json, tags_json,
         mastery_level, review_count, correct_streak, due_at, order_index,
         is_archived, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
              0, 0, 0, ?, ?, 0, ?, ?)
      ''',
      variables: [
        Variable<int>(spaceId),
        Variable<int>(materialId),
        Variable<String>(question.trim()),
        Variable<String>(answer.trim()),
        Variable<String>(_nullable(explanation)),
        Variable<String>(cardType),
        Variable<int>(importance.clamp(1, 5)),
        Variable<int>(difficulty.clamp(1, 5)),
        Variable<String>(_nullable(sourceTitle)),
        Variable<String>(_nullable(sourceExcerpt)),
        Variable<String>(_nullable(memoryHint)),
        Variable<String>(_nullable(sourceChunkId)),
        Variable<String>(_nullable(sourceLocatorJson)),
        Variable<String>(_nullable(concept)),
        Variable<String>(_nullable(knowledgePoint)),
        Variable<String>(_nullable(examScene)),
        Variable<String>(_nullable(commonMistake)),
        Variable<int>(grounded ? 1 : 0),
        Variable<String>(_normalizeCardStatus(status)),
        Variable<String>(
          relatedConcepts.isEmpty ? null : jsonEncode(relatedConcepts),
        ),
        Variable<String>(tags.isEmpty ? null : jsonEncode(tags)),
        Variable<int>(now),
        Variable<int>(await _nextCardOrder(spaceId)),
        Variable<int>(now),
        Variable<int>(now),
      ],
    );
    await _touchSpace(spaceId, now);
    return id;
  }

  Future<void> updateCard({
    required int id,
    required String question,
    required String answer,
    String? explanation,
  }) async {
    await _ensureTables();
    final card = await getCard(id);
    if (card == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customUpdate(
      '''
      UPDATE knowledge_cards_v3
      SET question = ?, answer = ?, explanation = ?, updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable<String>(question.trim()),
        Variable<String>(answer.trim()),
        Variable<String>(_nullable(explanation)),
        Variable<int>(now),
        Variable<int>(id),
      ],
    );
    await _touchSpace(card.spaceId, now);
  }

  Future<void> archiveCard(int id) async {
    await _ensureTables();
    final card = await getCard(id);
    if (card == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customUpdate(
      'UPDATE knowledge_cards_v3 SET is_archived = 1, updated_at = ? WHERE id = ?',
      variables: [Variable<int>(now), Variable<int>(id)],
    );
    await _touchSpace(card.spaceId, now);
  }

  Future<void> reorderCard({required int id, required int direction}) async {
    await _ensureTables();
    final card = await getCard(id);
    if (card == null) return;
    final cards = await getCards(card.spaceId);
    final index = cards.indexWhere((item) => item.id == id);
    final target = (index + direction).clamp(0, cards.length - 1);
    if (index < 0 || target == index) return;
    final reordered = [...cards];
    final item = reordered.removeAt(index);
    reordered.insert(target, item);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < reordered.length; i++) {
      await _db.customUpdate(
        'UPDATE knowledge_cards_v3 SET order_index = ?, updated_at = ? WHERE id = ?',
        variables: [
          Variable<int>(i),
          Variable<int>(now),
          Variable<int>(reordered[i].id),
        ],
      );
    }
    await _touchSpace(card.spaceId, now);
  }

  Future<List<KnowledgeCardV3>> getReviewQueue(
    int spaceId, {
    KnowledgeReviewModeV3 mode = KnowledgeReviewModeV3.smart,
    int limit = 80,
  }) async {
    await _ensureTables();
    final cards = await getCards(spaceId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final filtered = switch (mode) {
      KnowledgeReviewModeV3.due => cards.where((card) => card.dueAt <= now),
      KnowledgeReviewModeV3.weak => cards.where(isWeakCard),
      KnowledgeReviewModeV3.all => cards,
      KnowledgeReviewModeV3.smart => cards,
    }.toList(growable: false);
    filtered.sort((a, b) {
      final weakCompare = _boolRank(
        isWeakCard(b),
      ).compareTo(_boolRank(isWeakCard(a)));
      if (weakCompare != 0) return weakCompare;
      final dueCompare = _boolRank(
        b.dueAt <= now,
      ).compareTo(_boolRank(a.dueAt <= now));
      if (dueCompare != 0) return dueCompare;
      final streakCompare = a.correctStreak.compareTo(b.correctStreak);
      if (streakCompare != 0) return streakCompare;
      return a.dueAt.compareTo(b.dueAt);
    });
    return filtered.take(limit).toList(growable: false);
  }

  Future<void> reviewCard({
    required KnowledgeCardV3 card,
    required int rating,
    int durationMs = 0,
  }) async {
    await _ensureTables();
    final bounded = rating.clamp(0, 3);
    final now = DateTime.now();
    final previousMastery = card.masteryLevel;
    final nextMastery = _nextMastery(previousMastery, bounded);
    final nextStreak = bounded >= 2 ? card.correctStreak + 1 : 0;
    final nextDueAt = now.add(
      _nextReviewDelay(
        rating: bounded,
        nextMastery: nextMastery,
        nextStreak: nextStreak,
      ),
    );
    await _db.transaction(() async {
      await _db.customUpdate(
        '''
        UPDATE knowledge_cards_v3
        SET mastery_level = ?, review_count = ?, correct_streak = ?,
            last_reviewed_at = ?, due_at = ?, updated_at = ?
        WHERE id = ?
        ''',
        variables: [
          Variable<int>(nextMastery),
          Variable<int>(card.reviewCount + 1),
          Variable<int>(nextStreak),
          Variable<int>(now.millisecondsSinceEpoch),
          Variable<int>(nextDueAt.millisecondsSinceEpoch),
          Variable<int>(now.millisecondsSinceEpoch),
          Variable<int>(card.id),
        ],
      );
      await _db.customInsert(
        '''
        INSERT INTO knowledge_review_logs_v3
          (card_id, space_id, rating, previous_mastery, next_mastery,
           duration_ms, reviewed_at, next_due_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable<int>(card.id),
          Variable<int>(card.spaceId),
          Variable<int>(bounded),
          Variable<int>(previousMastery),
          Variable<int>(nextMastery),
          Variable<int>(durationMs),
          Variable<int>(now.millisecondsSinceEpoch),
          Variable<int>(nextDueAt.millisecondsSinceEpoch),
        ],
      );
    });
    await _touchSpace(card.spaceId, now.millisecondsSinceEpoch);
  }

  Future<List<KnowledgeMaterial>> searchMaterials({
    required int spaceId,
    required String query,
    int limit = 8,
  }) async {
    await _ensureTables();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final materials = await getMaterials(spaceId);
    final ranked =
        materials
            .where(
              (item) =>
                  item.title.toLowerCase().contains(q) ||
                  item.content.toLowerCase().contains(q),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final aTitle = a.title.toLowerCase().contains(q) ? 0 : 1;
            final bTitle = b.title.toLowerCase().contains(q) ? 0 : 1;
            if (aTitle != bTitle) return aTitle.compareTo(bTitle);
            return b.updatedAt.compareTo(a.updatedAt);
          });
    return ranked.take(limit).toList(growable: false);
  }

  Future<List<KnowledgeCardV3>> searchCards({
    required int spaceId,
    required String query,
    int limit = 8,
  }) async {
    await _ensureTables();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final cards = await getCards(spaceId);
    final ranked =
        cards
            .where(
              (card) =>
                  card.question.toLowerCase().contains(q) ||
                  card.answer.toLowerCase().contains(q) ||
                  (card.explanation ?? '').toLowerCase().contains(q),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final aQuestion = a.question.toLowerCase().contains(q) ? 0 : 1;
            final bQuestion = b.question.toLowerCase().contains(q) ? 0 : 1;
            if (aQuestion != bQuestion) return aQuestion.compareTo(bQuestion);
            final importance = b.importance.compareTo(a.importance);
            if (importance != 0) return importance;
            return b.updatedAt.compareTo(a.updatedAt);
          });
    return ranked.take(limit).toList(growable: false);
  }

  Future<List<TiantianQaSearchHit>> searchQa({
    required int spaceId,
    required String query,
    int limit = 8,
  }) async {
    await _ensureTables();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final rows = await _db
        .customSelect(
          '''
          SELECT
            s.id AS session_id,
            s.space_id AS space_id,
            s.title AS title,
            s.updated_at AS updated_at,
            m.id AS message_id,
            m.role AS role,
            m.content AS content,
            m.created_at AS message_created_at
          FROM tiantian_qa_sessions s
          JOIN tiantian_qa_messages m ON m.session_id = s.id
          WHERE s.space_id = ?
          ORDER BY s.updated_at DESC, m.created_at ASC
          ''',
          variables: [Variable<int>(spaceId)],
        )
        .get();
    final hits = <TiantianQaSearchHit>[];
    final seenSessions = <int>{};
    for (final row in rows) {
      final title = row.read<String>('title');
      final content = row.read<String>('content');
      if (!title.toLowerCase().contains(q) &&
          !content.toLowerCase().contains(q)) {
        continue;
      }
      final sessionId = row.read<int>('session_id');
      if (!seenSessions.add(sessionId)) continue;
      hits.add(
        TiantianQaSearchHit(
          sessionId: sessionId,
          spaceId: row.read<int>('space_id'),
          title: title,
          role: row.read<String>('role'),
          excerpt: _excerpt(content),
          updatedAt: row.read<int>('updated_at'),
        ),
      );
      if (hits.length >= limit) break;
    }
    return hits;
  }

  Future<int> createQaSession({
    required int spaceId,
    required String title,
    List<int> referencedMaterialIds = const [],
  }) async {
    await _ensureTables();
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.customInsert(
      '''
      INSERT INTO tiantian_qa_sessions
        (space_id, title, referenced_material_ids_json, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable<int>(spaceId),
        Variable<String>(title.trim().isEmpty ? '甜甜问答' : title.trim()),
        Variable<String>(
          referencedMaterialIds.isEmpty
              ? null
              : jsonEncode(referencedMaterialIds),
        ),
        Variable<int>(now),
        Variable<int>(now),
      ],
    );
  }

  Future<List<TiantianQaSession>> getQaSessions(int spaceId) async {
    await _ensureTables();
    final rows = await _db
        .customSelect(
          '''
          SELECT * FROM tiantian_qa_sessions
          WHERE space_id = ?
          ORDER BY updated_at DESC
          LIMIT 20
          ''',
          variables: [Variable<int>(spaceId)],
        )
        .get();
    return rows.map(TiantianQaSession.fromRow).toList(growable: false);
  }

  /// 获取空间的最新会话，若无则自动创建一个
  Future<TiantianQaSession> getOrCreateSpaceSession(int spaceId) async {
    final sessions = await getQaSessions(spaceId);
    if (sessions.isNotEmpty) return sessions.first;
    final id = await createQaSession(spaceId: spaceId, title: '甜甜问答');
    final created = await getQaSession(id);
    return created!;
  }

  /// 获取单个会话
  Future<TiantianQaSession?> getQaSession(int sessionId) async {
    await _ensureTables();
    final rows = await _db
        .customSelect(
          'SELECT * FROM tiantian_qa_sessions WHERE id = ?',
          variables: [Variable<int>(sessionId)],
        )
        .get();
    if (rows.isEmpty) return null;
    return TiantianQaSession.fromRow(rows.first);
  }

  /// 更新会话的关联资料
  Future<void> updateSessionMaterials(
    int sessionId,
    List<int> materialIds,
  ) async {
    await _ensureTables();
    await _db.customUpdate(
      'UPDATE tiantian_qa_sessions SET referenced_material_ids_json = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable<String>(materialIds.isEmpty ? null : jsonEncode(materialIds)),
        Variable<int>(DateTime.now().millisecondsSinceEpoch),
        Variable<int>(sessionId),
      ],
    );
  }

  /// 更新会话标题
  Future<void> updateSessionTitle(int sessionId, String title) async {
    await _ensureTables();
    await _db.customUpdate(
      'UPDATE tiantian_qa_sessions SET title = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable<String>(title),
        Variable<int>(DateTime.now().millisecondsSinceEpoch),
        Variable<int>(sessionId),
      ],
    );
  }

  Future<List<TiantianQaMessage>> getQaMessages(int sessionId) async {
    await _ensureTables();
    final rows = await _db
        .customSelect(
          '''
          SELECT * FROM tiantian_qa_messages
          WHERE session_id = ?
          ORDER BY created_at ASC
          ''',
          variables: [Variable<int>(sessionId)],
        )
        .get();
    return rows.map(TiantianQaMessage.fromRow).toList(growable: false);
  }

  Future<int> addQaMessage({
    required int sessionId,
    required String role,
    required String content,
    List<KnowledgeMaterial> sources = const [],
    String? answerMode,
    bool? grounded,
  }) async {
    await _ensureTables();
    final now = DateTime.now().millisecondsSinceEpoch;
    final sourcesJson = _qaSourcesJson(
      sources: sources,
      answerMode: answerMode,
      grounded: grounded,
    );
    return _db.customInsert(
      '''
      INSERT INTO tiantian_qa_messages
        (session_id, role, content, sources_json, saved_as_card, created_at)
      VALUES (?, ?, ?, ?, 0, ?)
      ''',
      variables: [
        Variable<int>(sessionId),
        Variable<String>(role),
        Variable<String>(content),
        Variable<String>(sourcesJson),
        Variable<int>(now),
      ],
    );
  }

  String? _qaSourcesJson({
    required List<KnowledgeMaterial> sources,
    String? answerMode,
    bool? grounded,
  }) {
    final hasMetadata = answerMode != null || grounded != null;
    if (sources.isEmpty && !hasMetadata) return null;
    final sourceItems = sources
        .map(
          (item) => {
            'id': item.id,
            'title': item.title,
            'excerpt': _excerpt(item.content),
          },
        )
        .toList(growable: false);
    if (!hasMetadata) return jsonEncode(sourceItems);
    return jsonEncode({
      'answerMode': answerMode,
      'grounded': grounded,
      'usedMaterialIds': sources.map((item) => item.id).toList(growable: false),
      'sources': sourceItems,
    });
  }

  Future<void> markLatestAssistantMessageSavedAsCard(int sessionId) async {
    await _ensureTables();
    await _db.customUpdate(
      '''
      UPDATE tiantian_qa_messages
      SET saved_as_card = 1
      WHERE id = (
        SELECT id FROM tiantian_qa_messages
        WHERE session_id = ? AND role = 'assistant'
        ORDER BY created_at DESC, id DESC
        LIMIT 1
      )
      ''',
      variables: [Variable<int>(sessionId)],
    );
  }

  Future<KnowledgeSpaceStatsV3> getSpaceStats(int spaceId) async {
    final materials = await getMaterials(spaceId);
    final cards = await getCards(spaceId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final masterySum = cards.fold<int>(
      0,
      (sum, card) => sum + card.masteryLevel,
    );
    return KnowledgeSpaceStatsV3(
      materialCount: materials.length,
      cardCount: cards.length,
      dueCount: cards.where((card) => card.dueAt <= now).length,
      weakCount: cards.where(isWeakCard).length,
      masteredCount: cards
          .where((card) => card.masteryLevel >= 4 && card.correctStreak > 0)
          .length,
      reviewedCount: cards.where((card) => card.reviewCount > 0).length,
      masteryPercent: cards.isEmpty
          ? 0
          : ((masterySum / (cards.length * 5)) * 100).round().clamp(0, 100),
    );
  }

  bool isWeakCard(KnowledgeCardV3 card) {
    return card.masteryLevel <= 2 ||
        (card.reviewCount > 0 && card.correctStreak == 0);
  }

  Future<void> _ensureTables() async {
    if (_tablesEnsured) return;
    await KnowledgeV3SchemaService.ensureSchema(_db);
    _tablesEnsured = true;
  }

  Future<int> _nextSpaceSortOrder() async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS count FROM knowledge_spaces_v3')
        .getSingle();
    return row.read<int>('count');
  }

  Future<int> _nextMaterialOrder(int spaceId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS count FROM knowledge_materials WHERE space_id = ?',
          variables: [Variable<int>(spaceId)],
        )
        .getSingle();
    return row.read<int>('count');
  }

  Future<int> _nextCardOrder(int spaceId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS count FROM knowledge_cards_v3 WHERE space_id = ?',
          variables: [Variable<int>(spaceId)],
        )
        .getSingle();
    return row.read<int>('count');
  }

  Future<void> _touchSpace(int spaceId, int now) {
    return _db.customUpdate(
      'UPDATE knowledge_spaces_v3 SET updated_at = ? WHERE id = ?',
      variables: [Variable<int>(now), Variable<int>(spaceId)],
    );
  }

  int _nextMastery(int current, int rating) {
    final delta = switch (rating) {
      0 => -2,
      1 => -1,
      2 => 1,
      _ => 2,
    };
    return (current + delta).clamp(0, 5);
  }

  Duration _nextReviewDelay({
    required int rating,
    required int nextMastery,
    required int nextStreak,
  }) {
    if (rating == 0) return const Duration(minutes: 10);
    if (rating == 1) return const Duration(days: 1);
    final baseDays = rating == 2
        ? const [2, 2, 3, 4, 6, 8]
        : const [5, 6, 8, 10, 14, 21];
    final index = nextMastery.clamp(0, baseDays.length - 1).toInt();
    final streakBonus = nextStreak > 2
        ? (nextStreak - 2) * (rating == 2 ? 1 : 2)
        : 0;
    return Duration(days: baseDays[index] + streakBonus);
  }

  int _boolRank(bool value) => value ? 1 : 0;

  String _deriveTitle(String content) {
    final firstLine = content
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '未命名资料');
    return firstLine.length <= 24
        ? firstLine
        : '${firstLine.substring(0, 24)}...';
  }

  String _excerpt(String content) {
    final text = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    return text.length <= 160 ? text : '${text.substring(0, 160)}...';
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _normalizeCardStatus(String value) {
    const allowed = {
      'draft',
      'approved',
      'rejected',
      'needs_review',
      'auto_approved',
    };
    final normalized = value.trim().toLowerCase();
    return allowed.contains(normalized) ? normalized : 'draft';
  }
}

class KnowledgeSpaceV3 {
  const KnowledgeSpaceV3({
    required this.id,
    required this.name,
    required this.type,
    this.note,
    this.iconAssetKey,
    this.colorSeed,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KnowledgeSpaceV3.fromRow(QueryRow row) {
    return KnowledgeSpaceV3(
      id: row.read<int>('id'),
      name: row.read<String>('name'),
      type: row.read<String>('type'),
      note: row.readNullable<String>('note'),
      iconAssetKey: row.readNullable<String>('icon_asset_key'),
      colorSeed: row.readNullable<String>('color_seed'),
      sortOrder: row.read<int>('sort_order'),
      isArchived: row.read<int>('is_archived') == 1,
      createdAt: row.read<int>('created_at'),
      updatedAt: row.read<int>('updated_at'),
    );
  }

  final int id;
  final String name;
  final String type;
  final String? note;
  final String? iconAssetKey;
  final String? colorSeed;
  final int sortOrder;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;
}

class KnowledgeMaterial {
  const KnowledgeMaterial({
    required this.id,
    required this.spaceId,
    required this.title,
    required this.content,
    required this.sourceType,
    this.sourcePath,
    this.url,
    required this.orderIndex,
    required this.status,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KnowledgeMaterial.fromRow(QueryRow row) {
    return KnowledgeMaterial(
      id: row.read<int>('id'),
      spaceId: row.read<int>('space_id'),
      title: row.read<String>('title'),
      content: row.read<String>('content'),
      sourceType: row.read<String>('source_type'),
      sourcePath: row.readNullable<String>('source_path'),
      url: row.readNullable<String>('url'),
      orderIndex: row.read<int>('order_index'),
      status: row.read<String>('status'),
      isArchived: row.read<int>('is_archived') == 1,
      createdAt: row.read<int>('created_at'),
      updatedAt: row.read<int>('updated_at'),
    );
  }

  final int id;
  final int spaceId;
  final String title;
  final String content;
  final String sourceType;
  final String? sourcePath;
  final String? url;
  final int orderIndex;
  final String status;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;
}

class KnowledgeCardV3 {
  const KnowledgeCardV3({
    required this.id,
    required this.spaceId,
    this.materialId,
    required this.question,
    required this.answer,
    this.explanation,
    required this.cardType,
    required this.importance,
    required this.difficulty,
    this.sourceTitle,
    this.sourceExcerpt,
    this.memoryHint,
    this.sourceChunkId,
    this.sourceLocatorJson,
    this.concept,
    this.knowledgePoint,
    this.examScene,
    this.commonMistake,
    this.grounded = true,
    this.status = 'auto_approved',
    this.relatedConceptsJson,
    this.tagsJson,
    required this.orderIndex,
    required this.masteryLevel,
    required this.reviewCount,
    required this.correctStreak,
    required this.dueAt,
    this.lastReviewedAt,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KnowledgeCardV3.fromRow(QueryRow row) {
    return KnowledgeCardV3(
      id: row.read<int>('id'),
      spaceId: row.read<int>('space_id'),
      materialId: row.readNullable<int>('material_id'),
      question: row.read<String>('question'),
      answer: row.read<String>('answer'),
      explanation: row.readNullable<String>('explanation'),
      cardType: row.read<String>('card_type'),
      importance: row.read<int>('importance'),
      difficulty: row.read<int>('difficulty'),
      sourceTitle: row.readNullable<String>('source_title'),
      sourceExcerpt: row.readNullable<String>('source_excerpt'),
      memoryHint: row.readNullable<String>('memory_hint'),
      sourceChunkId: row.readNullable<String>('source_chunk_id'),
      sourceLocatorJson: row.readNullable<String>('source_locator_json'),
      concept: row.readNullable<String>('concept'),
      knowledgePoint: row.readNullable<String>('knowledge_point'),
      examScene: row.readNullable<String>('exam_scene'),
      commonMistake: row.readNullable<String>('common_mistake'),
      grounded: (row.readNullable<int>('grounded') ?? 1) == 1,
      status: row.readNullable<String>('status') ?? 'auto_approved',
      relatedConceptsJson: row.readNullable<String>('related_concepts_json'),
      tagsJson: row.readNullable<String>('tags_json'),
      orderIndex: row.readNullable<int>('order_index') ?? 0,
      masteryLevel: row.read<int>('mastery_level'),
      reviewCount: row.read<int>('review_count'),
      correctStreak: row.read<int>('correct_streak'),
      dueAt: row.read<int>('due_at'),
      lastReviewedAt: row.readNullable<int>('last_reviewed_at'),
      isArchived: row.read<int>('is_archived') == 1,
      createdAt: row.read<int>('created_at'),
      updatedAt: row.read<int>('updated_at'),
    );
  }

  final int id;
  final int spaceId;
  final int? materialId;
  final String question;
  final String answer;
  final String? explanation;
  final String cardType;
  final int importance;
  final int difficulty;
  final String? sourceTitle;
  final String? sourceExcerpt;
  final String? memoryHint;
  final String? sourceChunkId;
  final String? sourceLocatorJson;
  final String? concept;
  final String? knowledgePoint;
  final String? examScene;
  final String? commonMistake;
  final bool grounded;
  final String status;
  final String? relatedConceptsJson;
  final String? tagsJson;
  final int orderIndex;
  final int masteryLevel;
  final int reviewCount;
  final int correctStreak;
  final int dueAt;
  final int? lastReviewedAt;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;
}

class TiantianQaSession {
  const TiantianQaSession({
    required this.id,
    required this.spaceId,
    required this.title,
    this.referencedMaterialIdsJson,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TiantianQaSession.fromRow(QueryRow row) {
    return TiantianQaSession(
      id: row.read<int>('id'),
      spaceId: row.read<int>('space_id'),
      title: row.read<String>('title'),
      referencedMaterialIdsJson: row.readNullable<String>(
        'referenced_material_ids_json',
      ),
      createdAt: row.read<int>('created_at'),
      updatedAt: row.read<int>('updated_at'),
    );
  }

  final int id;
  final int spaceId;
  final String title;
  final String? referencedMaterialIdsJson;
  final int createdAt;
  final int updatedAt;
}

class TiantianQaMessage {
  const TiantianQaMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.sourcesJson,
    required this.savedAsCard,
    required this.createdAt,
  });

  factory TiantianQaMessage.fromRow(QueryRow row) {
    return TiantianQaMessage(
      id: row.read<int>('id'),
      sessionId: row.read<int>('session_id'),
      role: row.read<String>('role'),
      content: row.read<String>('content'),
      sourcesJson: row.readNullable<String>('sources_json'),
      savedAsCard: row.read<int>('saved_as_card') == 1,
      createdAt: row.read<int>('created_at'),
    );
  }

  final int id;
  final int sessionId;
  final String role;
  final String content;
  final String? sourcesJson;
  final bool savedAsCard;
  final int createdAt;
}

class TiantianQaSearchHit {
  const TiantianQaSearchHit({
    required this.sessionId,
    required this.spaceId,
    required this.title,
    required this.role,
    required this.excerpt,
    required this.updatedAt,
  });

  final int sessionId;
  final int spaceId;
  final String title;
  final String role;
  final String excerpt;
  final int updatedAt;
}

enum KnowledgeReviewModeV3 { smart, due, weak, all }

class KnowledgeSpaceStatsV3 {
  const KnowledgeSpaceStatsV3({
    required this.materialCount,
    required this.cardCount,
    required this.dueCount,
    required this.weakCount,
    required this.masteredCount,
    required this.reviewedCount,
    required this.masteryPercent,
  });

  final int materialCount;
  final int cardCount;
  final int dueCount;
  final int weakCount;
  final int masteredCount;
  final int reviewedCount;
  final int masteryPercent;
}
