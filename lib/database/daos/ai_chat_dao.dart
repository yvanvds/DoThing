import 'package:drift/drift.dart';

import '../app_database.dart';

part 'ai_chat_dao.g.dart';

@DriftAccessor(tables: [AiConversations, AiChatMessages])
class AiChatDao extends DatabaseAccessor<AppDatabase> with _$AiChatDaoMixin {
  AiChatDao(super.db);

  Future<void> upsertConversation(AiConversationsCompanion row) {
    return into(aiConversations).insertOnConflictUpdate(row);
  }

  Future<AiConversation?> getConversation(String id) {
    return (select(
      aiConversations,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateConversationById(String id, AiConversationsCompanion row) {
    return (update(aiConversations)..where((t) => t.id.equals(id))).write(row);
  }

  Future<void> deleteConversationById(String id) {
    return (delete(aiConversations)..where((t) => t.id.equals(id))).go();
  }

  Future<List<AiConversation>> listConversations() {
    return (select(
      aiConversations,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
  }

  Stream<List<AiConversation>> watchConversations() {
    return (select(
      aiConversations,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  Future<void> touchConversation(String id, DateTime updatedAt) {
    return (update(aiConversations)..where((t) => t.id.equals(id))).write(
      AiConversationsCompanion(updatedAt: Value(updatedAt)),
    );
  }

  Future<void> deleteEmptyConversations() async {
    final nonEmptyIds =
        await (selectOnly(aiChatMessages)
              ..addColumns([aiChatMessages.conversationId]))
            .map((row) => row.read(aiChatMessages.conversationId)!)
            .get();

    if (nonEmptyIds.isEmpty) {
      await delete(aiConversations).go();
    } else {
      await (delete(
        aiConversations,
      )..where((t) => t.id.isNotIn(nonEmptyIds))).go();
    }
  }

  Future<int> countConversationMessages(String conversationId) {
    final countExp = aiChatMessages.id.count();
    final query = selectOnly(aiChatMessages)
      ..addColumns([countExp])
      ..where(aiChatMessages.conversationId.equals(conversationId));

    return query.map((row) => row.read(countExp) ?? 0).getSingle();
  }

  Future<void> upsertMessage(AiChatMessagesCompanion row) {
    return into(aiChatMessages).insertOnConflictUpdate(row);
  }

  Future<void> updateMessageById(String id, AiChatMessagesCompanion row) {
    return (update(aiChatMessages)..where((t) => t.id.equals(id))).write(row);
  }

  Future<AiChatMessage?> getMessageById(String id) {
    return (select(
      aiChatMessages,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<AiChatMessage>> listConversationMessages(String conversationId) {
    return (select(aiChatMessages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Stream<List<AiChatMessage>> watchConversationMessages(String conversationId) {
    return (select(aiChatMessages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }
}
