import 'package:drift/drift.dart';

import '../database/app_database.dart';

class KnowledgeCardRepository {
  KnowledgeCardRepository(this._db);

  final AppDatabase _db;

  Future<int> insertCard(KnowledgeCardsCompanion card) {
    return _db.into(_db.knowledgeCards).insert(card);
  }

  Future<void> insertCards(List<KnowledgeCardsCompanion> cards) async {
    if (cards.isEmpty) return;
    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAll(_db.knowledgeCards, cards);
      });
    });
  }

  Future<List<KnowledgeCustomTemplateBundle>>
  getCustomTemplatesWithModules() async {
    final templates =
        await (_db.select(_db.knowledgeCustomTemplates)
              ..where((t) => t.archived.equals(false))
              ..orderBy([
                (t) => OrderingTerm.asc(t.sortOrder),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();

    if (templates.isEmpty) return const [];

    final templateIds = templates.map((item) => item.id).toList();
    final modules =
        await (_db.select(_db.knowledgeCustomTemplateModules)
              ..where(
                (t) =>
                    t.archived.equals(false) & t.templateId.isIn(templateIds),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.sortOrder),
                (t) => OrderingTerm.asc(t.createdAt),
              ]))
            .get();

    final modulesByTemplate = <int, List<KnowledgeCustomTemplateModule>>{};
    for (final module in modules) {
      modulesByTemplate
          .putIfAbsent(
            module.templateId,
            () => <KnowledgeCustomTemplateModule>[],
          )
          .add(module);
    }

    return templates
        .map(
          (template) => KnowledgeCustomTemplateBundle(
            template: template,
            modules: modulesByTemplate[template.id] ?? const [],
          ),
        )
        .toList(growable: false);
  }

  Future<int> createCustomTemplate({
    required String name,
    String? description,
    String? coverAsset,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final sortOrder = await _nextTemplateSortOrder();
    return _db
        .into(_db.knowledgeCustomTemplates)
        .insert(
          KnowledgeCustomTemplatesCompanion.insert(
            name: name,
            description: Value(description),
            coverAsset: Value(coverAsset),
            sortOrder: Value(sortOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateCustomTemplate({
    required int id,
    required String name,
    String? description,
    String? coverAsset,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(
      _db.knowledgeCustomTemplates,
    )..where((t) => t.id.equals(id))).write(
      KnowledgeCustomTemplatesCompanion(
        name: Value(name),
        description: Value(description),
        coverAsset: Value(coverAsset),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> archiveCustomTemplate(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await (_db.update(
        _db.knowledgeCustomTemplates,
      )..where((t) => t.id.equals(id))).write(
        KnowledgeCustomTemplatesCompanion(
          archived: const Value(true),
          updatedAt: Value(now),
        ),
      );

      await (_db.update(
        _db.knowledgeCustomTemplateModules,
      )..where((t) => t.templateId.equals(id))).write(
        KnowledgeCustomTemplateModulesCompanion(
          archived: const Value(true),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Future<int> createCustomTemplateModule({
    required int templateId,
    required String name,
    required String deckKey,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final sortOrder = await _nextModuleSortOrder(templateId);
    return _db
        .into(_db.knowledgeCustomTemplateModules)
        .insert(
          KnowledgeCustomTemplateModulesCompanion.insert(
            templateId: templateId,
            name: name,
            deckKey: Value(deckKey),
            sortOrder: Value(sortOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateCustomTemplateModule({
    required int id,
    required String name,
    required String deckKey,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(
      _db.knowledgeCustomTemplateModules,
    )..where((t) => t.id.equals(id))).write(
      KnowledgeCustomTemplateModulesCompanion(
        name: Value(name),
        deckKey: Value(deckKey),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> archiveCustomTemplateModule(int id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(
      _db.knowledgeCustomTemplateModules,
    )..where((t) => t.id.equals(id))).write(
      KnowledgeCustomTemplateModulesCompanion(
        archived: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updateCard(KnowledgeCardsCompanion card) {
    return _db.update(_db.knowledgeCards).replace(card);
  }

  Future<void> updateCardContent({
    required int id,
    required String deckKey,
    required String goalKey,
    required String moduleKey,
    required String title,
    required String question,
    required String answer,
    String? goalName,
    String? moduleName,
    String? subject,
    String? explanation,
    String? tags,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(
      _db.knowledgeCards,
    )..where((t) => t.id.equals(id))).write(
      KnowledgeCardsCompanion(
        deckKey: Value(deckKey),
        goalKey: Value(goalKey),
        goalName: Value(goalName),
        moduleKey: Value(moduleKey),
        moduleName: Value(moduleName),
        subject: Value(subject),
        title: Value(title),
        question: Value(question),
        answer: Value(answer),
        explanation: Value(explanation),
        tags: Value(tags),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> archiveCard(int id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(
      _db.knowledgeCards,
    )..where((t) => t.id.equals(id))).write(
      KnowledgeCardsCompanion(
        archived: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> archiveCards(List<int> ids) async {
    if (ids.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await (_db.update(
        _db.knowledgeCards,
      )..where((t) => t.id.isIn(ids))).write(
        KnowledgeCardsCompanion(
          archived: const Value(true),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Future<void> updateCardsSubject(List<int> ids, String? subject) async {
    if (ids.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await (_db.update(
        _db.knowledgeCards,
      )..where((t) => t.id.isIn(ids))).write(
        KnowledgeCardsCompanion(subject: Value(subject), updatedAt: Value(now)),
      );
    });
  }

  Future<void> moveCardsToModule(
    List<int> ids, {
    required String deckKey,
    required String goalKey,
    String? goalName,
    required String moduleKey,
    String? moduleName,
  }) async {
    if (ids.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await (_db.update(
        _db.knowledgeCards,
      )..where((t) => t.id.isIn(ids))).write(
        KnowledgeCardsCompanion(
          deckKey: Value(deckKey),
          goalKey: Value(goalKey),
          goalName: Value(goalName),
          moduleKey: Value(moduleKey),
          moduleName: Value(moduleName),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Future<void> restoreCard(int id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(
      _db.knowledgeCards,
    )..where((t) => t.id.equals(id))).write(
      KnowledgeCardsCompanion(
        archived: const Value(false),
        updatedAt: Value(now),
      ),
    );
  }

  Future<KnowledgeCard?> getCardById(int id) {
    return (_db.select(
      _db.knowledgeCards,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<KnowledgeCard>> getAllCards() {
    return (_db.select(_db.knowledgeCards)
          ..where((t) => t.archived.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<List<KnowledgeCard>> getArchivedCards() {
    return (_db.select(_db.knowledgeCards)
          ..where((t) => t.archived.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<List<KnowledgeCard>> getCardsByDeck(String deckKey) {
    return (_db.select(_db.knowledgeCards)
          ..where((t) => t.archived.equals(false) & t.deckKey.equals(deckKey))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<List<KnowledgeCard>> getCardsByGoal(String goalKey) {
    return (_db.select(_db.knowledgeCards)
          ..where((t) => t.archived.equals(false) & t.goalKey.equals(goalKey))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<List<KnowledgeCard>> getCardsForImportScope({
    required String deckKey,
    required String goalKey,
    String? goalName,
    required String moduleKey,
    String? moduleName,
  }) {
    final query = _db.select(_db.knowledgeCards)
      ..where(
        (t) =>
            t.archived.equals(false) &
            t.deckKey.equals(deckKey) &
            t.goalKey.equals(goalKey) &
            t.moduleKey.equals(moduleKey),
      );

    if (goalName != null && goalName.isNotEmpty) {
      query.where((t) => t.goalName.equals(goalName));
    }
    if (moduleName != null && moduleName.isNotEmpty) {
      query.where((t) => t.moduleName.equals(moduleName));
    }

    return query.get();
  }

  Future<List<KnowledgeCard>> getReviewQueue({
    String? deckKey,
    String? goalKey,
    String? goalName,
    String? moduleKey,
    String? moduleName,
    bool dueOnly = true,
    int limit = 30,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final query = _db.select(_db.knowledgeCards)
      ..where((t) => t.archived.equals(false));

    if (deckKey != null && deckKey.isNotEmpty) {
      query.where((t) => t.deckKey.equals(deckKey));
    }
    if (goalKey != null && goalKey.isNotEmpty) {
      query.where((t) => t.goalKey.equals(goalKey));
    }
    if (goalName != null && goalName.isNotEmpty) {
      query.where((t) => t.goalName.equals(goalName));
    }
    if (moduleKey != null && moduleKey.isNotEmpty) {
      query.where((t) => t.moduleKey.equals(moduleKey));
    }
    if (moduleName != null && moduleName.isNotEmpty) {
      query.where((t) => t.moduleName.equals(moduleName));
    }
    if (dueOnly) {
      query.where((t) => t.dueAt.isSmallerOrEqualValue(now));
    }

    query
      ..orderBy([
        (t) => OrderingTerm.asc(t.dueAt),
        (t) => OrderingTerm.asc(t.masteryLevel),
        (t) => OrderingTerm.asc(t.lastReviewedAt),
      ])
      ..limit(limit);

    return query.get();
  }

  Future<List<KnowledgeCard>> getWeakCards({
    String? deckKey,
    String? goalKey,
    String? goalName,
    String? moduleKey,
    String? moduleName,
    int limit = 30,
  }) {
    final query = _db.select(_db.knowledgeCards)
      ..where(
        (t) =>
            t.archived.equals(false) &
            (t.masteryLevel.isSmallerOrEqualValue(2) |
                (t.reviewCount.isBiggerThanValue(0) &
                    t.correctStreak.equals(0))),
      );

    if (deckKey != null && deckKey.isNotEmpty) {
      query.where((t) => t.deckKey.equals(deckKey));
    }
    if (goalKey != null && goalKey.isNotEmpty) {
      query.where((t) => t.goalKey.equals(goalKey));
    }
    if (goalName != null && goalName.isNotEmpty) {
      query.where((t) => t.goalName.equals(goalName));
    }
    if (moduleKey != null && moduleKey.isNotEmpty) {
      query.where((t) => t.moduleKey.equals(moduleKey));
    }
    if (moduleName != null && moduleName.isNotEmpty) {
      query.where((t) => t.moduleName.equals(moduleName));
    }

    query
      ..orderBy([
        (t) => OrderingTerm.asc(t.masteryLevel),
        (t) => OrderingTerm.asc(t.correctStreak),
        (t) => OrderingTerm.asc(t.dueAt),
        (t) => OrderingTerm.desc(t.reviewCount),
      ])
      ..limit(limit);

    return query.get();
  }

  Future<int> getTotalCount() async {
    final countExp = _db.knowledgeCards.id.count();
    final row =
        await (_db.selectOnly(_db.knowledgeCards)
              ..addColumns([countExp])
              ..where(_db.knowledgeCards.archived.equals(false)))
            .getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<int> getDueCount({
    String? deckKey,
    String? goalKey,
    String? goalName,
    String? moduleKey,
    String? moduleName,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final countExp = _db.knowledgeCards.id.count();
    final query = _db.selectOnly(_db.knowledgeCards)
      ..addColumns([countExp])
      ..where(
        _db.knowledgeCards.archived.equals(false) &
            _db.knowledgeCards.dueAt.isSmallerOrEqualValue(now),
      );

    if (deckKey != null && deckKey.isNotEmpty) {
      query.where(_db.knowledgeCards.deckKey.equals(deckKey));
    }
    if (goalKey != null && goalKey.isNotEmpty) {
      query.where(_db.knowledgeCards.goalKey.equals(goalKey));
    }
    if (goalName != null && goalName.isNotEmpty) {
      query.where(_db.knowledgeCards.goalName.equals(goalName));
    }
    if (moduleKey != null && moduleKey.isNotEmpty) {
      query.where(_db.knowledgeCards.moduleKey.equals(moduleKey));
    }
    if (moduleName != null && moduleName.isNotEmpty) {
      query.where(_db.knowledgeCards.moduleName.equals(moduleName));
    }

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<void> reviewCard({
    required KnowledgeCard card,
    required int quality,
  }) async {
    final boundedQuality = quality.clamp(0, 3);
    final now = DateTime.now();
    final previousMastery = card.masteryLevel;
    final nextMastery = _nextMastery(previousMastery, boundedQuality);
    final nextStreak = boundedQuality >= 2 ? card.correctStreak + 1 : 0;
    final nextDueAt = now.add(
      _nextReviewDelay(
        quality: boundedQuality,
        nextMastery: nextMastery,
        nextStreak: nextStreak,
      ),
    );

    await _db.transaction(() async {
      await (_db.update(
        _db.knowledgeCards,
      )..where((t) => t.id.equals(card.id))).write(
        KnowledgeCardsCompanion(
          masteryLevel: Value(nextMastery),
          reviewCount: Value(card.reviewCount + 1),
          correctStreak: Value(nextStreak),
          lastReviewedAt: Value(now.millisecondsSinceEpoch),
          dueAt: Value(nextDueAt.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

      await _db
          .into(_db.knowledgeReviewLogs)
          .insert(
            KnowledgeReviewLogsCompanion(
              cardId: Value(card.id),
              quality: Value(boundedQuality),
              previousMastery: Value(previousMastery),
              nextMastery: Value(nextMastery),
              reviewedAt: Value(now.millisecondsSinceEpoch),
              nextDueAt: Value(nextDueAt.millisecondsSinceEpoch),
            ),
          );
    });
  }

  int _nextMastery(int current, int quality) {
    final delta = switch (quality) {
      0 => -1,
      1 => 0,
      2 => 1,
      _ => 2,
    };
    return (current + delta).clamp(0, 5);
  }

  Duration _nextReviewDelay({
    required int quality,
    required int nextMastery,
    required int nextStreak,
  }) {
    if (quality == 0) return const Duration(hours: 4);
    if (quality == 1) return const Duration(days: 1);

    final baseDays = quality == 2
        ? const [2, 3, 5, 8, 13, 21]
        : const [3, 5, 9, 15, 30, 45];
    final masteryIndex = nextMastery.clamp(0, baseDays.length - 1);
    final streakBonus = nextStreak > 2 ? nextStreak - 2 : 0;
    return Duration(days: baseDays[masteryIndex] + streakBonus);
  }

  Future<int> _nextTemplateSortOrder() async {
    final countExp = _db.knowledgeCustomTemplates.id.count();
    final row =
        await (_db.selectOnly(_db.knowledgeCustomTemplates)
              ..addColumns([countExp])
              ..where(_db.knowledgeCustomTemplates.archived.equals(false)))
            .getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<int> _nextModuleSortOrder(int templateId) async {
    final countExp = _db.knowledgeCustomTemplateModules.id.count();
    final row =
        await (_db.selectOnly(_db.knowledgeCustomTemplateModules)
              ..addColumns([countExp])
              ..where(
                _db.knowledgeCustomTemplateModules.archived.equals(false) &
                    _db.knowledgeCustomTemplateModules.templateId.equals(
                      templateId,
                    ),
              ))
            .getSingle();
    return row.read(countExp) ?? 0;
  }

  /// 获取指定时间范围内的复习日志
  Future<List<KnowledgeReviewLog>> getReviewLogsInRange({
    required int startMs,
    required int endMs,
  }) {
    final query = _db.select(_db.knowledgeReviewLogs)
      ..where(
        (t) =>
            t.reviewedAt.isBiggerOrEqualValue(startMs) &
            t.reviewedAt.isSmallerThanValue(endMs),
      );
    return query.get();
  }
}

class KnowledgeCustomTemplateBundle {
  const KnowledgeCustomTemplateBundle({
    required this.template,
    required this.modules,
  });

  final KnowledgeCustomTemplate template;
  final List<KnowledgeCustomTemplateModule> modules;
}
