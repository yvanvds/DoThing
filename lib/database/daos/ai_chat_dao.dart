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

  Future<void> touchConversation(String id, DateTime updatedAt) {
    return (update(aiConversations)..where((t) => t.id.equals(id))).write(
      AiConversationsCompanion(updatedAt: Value(updatedAt)),
    );
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
