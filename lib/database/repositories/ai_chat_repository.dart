import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../models/ai/ai_chat_models.dart';

class AiChatRepository {
  AiChatRepository(this._db);

  final AppDatabase _db;

  static const defaultConversationId = 'default';

  Future<String> ensureDefaultConversation() async {
    final now = DateTime.now();
    await _db.aiChatDao.upsertConversation(
      AiConversationsCompanion(
        id: const Value(defaultConversationId),
        title: const Value('AI Chat'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return defaultConversationId;
  }

  Future<List<AiChatMessageModel>> listMessages(String conversationId) async {
    final rows = await _db.aiChatDao.listConversationMessages(conversationId);
    return rows.map(_mapMessage).toList(growable: false);
  }

  Stream<List<AiChatMessageModel>> watchMessages(String conversationId) {
    return _db.aiChatDao
        .watchConversationMessages(conversationId)
        .map((rows) => rows.map(_mapMessage).toList(growable: false));
  }

  Future<void> upsertMessage(AiChatMessageModel message) async {
    await _db.aiChatDao.upsertMessage(
      AiChatMessagesCompanion(
        id: Value(message.id),
        conversationId: Value(message.conversationId),
        role: Value(_roleToDb(message.role)),
        content: Value(message.content),
        status: Value(_statusToDb(message.status)),
        errorCode: Value(message.error?.code),
        errorMessage: Value(message.error?.message),
        providerMessageId: Value(message.providerMessageId),
        parentMessageId: Value(message.parentMessageId),
        contextKind: Value(message.requestContext?.kind),
        contextReferenceId: Value(message.requestContext?.referenceId),
        contextSummary: Value(message.requestContext?.summary),
        createdAt: Value(message.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _db.aiChatDao.touchConversation(
      message.conversationId,
      DateTime.now(),
    );
  }

  Future<void> updateMessageState({
    required String id,
    required String content,
    required AiMessageStatus status,
    AiErrorState? error,
    String? providerMessageId,
  }) async {
    await _db.aiChatDao.updateMessageById(
      id,
      AiChatMessagesCompanion(
        content: Value(content),
        status: Value(_statusToDb(status)),
        errorCode: Value(error?.code),
        errorMessage: Value(error?.message),
        providerMessageId: Value(providerMessageId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  AiChatMessageModel _mapMessage(AiChatMessage row) {
    final errorCode = row.errorCode?.trim();
    final errorMessage = row.errorMessage?.trim();
    final hasError =
        errorCode != null && errorCode.isNotEmpty && errorMessage != null;

    final contextKind = row.contextKind?.trim();
    final context = (contextKind != null && contextKind.isNotEmpty)
        ? AiRequestContext(
            kind: contextKind,
            referenceId: row.contextReferenceId,
            summary: row.contextSummary,
          )
        : null;

    return AiChatMessageModel(
      id: row.id,
      conversationId: row.conversationId,
      role: _roleFromDb(row.role),
      content: row.content,
      createdAt: row.createdAt,
      status: _statusFromDb(row.status),
      error: hasError
          ? AiErrorState(
              code: errorCode,
              message: errorMessage,
              retryable: true,
            )
          : null,
      providerMessageId: row.providerMessageId,
      parentMessageId: row.parentMessageId,
      requestContext: context,
    );
  }

  String _roleToDb(AiMessageRole role) => role.name;

  AiMessageRole _roleFromDb(String role) {
    return AiMessageRole.values.firstWhere(
      (value) => value.name == role,
      orElse: () => AiMessageRole.user,
    );
  }

  String _statusToDb(AiMessageStatus status) => status.name;

  AiMessageStatus _statusFromDb(String status) {
    return AiMessageStatus.values.firstWhere(
      (value) => value.name == status,
      orElse: () => AiMessageStatus.completed,
    );
  }
}
