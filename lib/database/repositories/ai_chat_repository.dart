import 'package:drift/drift.dart';

import '../../models/ai/ai_chat_models.dart';
import '../app_database.dart';

class AiChatRepository {
  AiChatRepository(this._db);

  final AppDatabase _db;

  Future<String> createConversation({String? title}) async {
    final now = DateTime.now();
    final conversationId = 'conv-${now.microsecondsSinceEpoch}';

    await _db.aiChatDao.upsertConversation(
      AiConversationsCompanion(
        id: Value(conversationId),
        title: Value(
          (title?.trim().isNotEmpty ?? false) ? title!.trim() : 'New chat',
        ),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    return conversationId;
  }

  Future<void> deleteConversation(String conversationId) {
    return _db.aiChatDao.deleteConversationById(conversationId);
  }

  Future<void> deleteEmptyConversations() {
    return _db.aiChatDao.deleteEmptyConversations();
  }

  Future<void> updateConversationTitle(String conversationId, String title) {
    return _db.aiChatDao.updateConversationById(
      conversationId,
      AiConversationsCompanion(
        title: Value(title.trim().isEmpty ? 'New chat' : title.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<AiConversationModel>> listConversations() async {
    final rows = await _db.aiChatDao.listConversations();
    return rows.map(_mapConversation).toList(growable: false);
  }

  Stream<List<AiConversationModel>> watchConversations() {
    return _db.aiChatDao.watchConversations().map(
      (rows) => rows.map(_mapConversation).toList(growable: false),
    );
  }

  Future<bool> hasMessages(String conversationId) async {
    final count = await _db.aiChatDao.countConversationMessages(conversationId);
    return count > 0;
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

  AiConversationModel _mapConversation(AiConversation row) {
    return AiConversationModel(
      id: row.id,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      title: row.title,
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
