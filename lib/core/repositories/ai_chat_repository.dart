import 'package:drift/drift.dart';
import '../database/app_database.dart';

class AiChatRepository {
  AiChatRepository(this._db);
  final AppDatabase _db;

  Future<int> saveMessage({
    required String sessionId,
    int? cardId,
    required String role,
    required String content,
  }) {
    return _db.into(_db.aiChatMessages).insert(
      AiChatMessagesCompanion.insert(
        sessionId: sessionId,
        cardId: Value(cardId),
        role: role,
        content: content,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<List<AiChatMessage>> getMessagesBySession(String sessionId) {
    return (_db.select(_db.aiChatMessages)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<String>> getRecentSessionIds({int limit = 20}) async {
    final query = _db.selectOnly(_db.aiChatMessages)
      ..addColumns([_db.aiChatMessages.sessionId])
      ..groupBy([_db.aiChatMessages.sessionId])
      ..orderBy([OrderingTerm.desc(_db.aiChatMessages.createdAt)])
      ..limit(limit);
    final results = await query.get();
    return results
        .map((r) => r.read(_db.aiChatMessages.sessionId)!)
        .toList();
  }

  Future<void> deleteSession(String sessionId) {
    return (_db.delete(_db.aiChatMessages)
          ..where((t) => t.sessionId.equals(sessionId)))
        .go();
  }

  Future<void> deleteAll() {
    return _db.delete(_db.aiChatMessages).go();
  }
}
