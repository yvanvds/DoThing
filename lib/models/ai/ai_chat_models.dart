enum AiMessageRole { system, user, assistant }

enum AiMessageStatus { queued, waiting, streaming, completed, canceled, failed }

enum AiStreamingState { idle, waiting, active, completed, canceled, failed }

class AiErrorState {
  const AiErrorState({
    required this.code,
    required this.message,
    this.retryable = false,
  });

  final String code;
  final String message;
  final bool retryable;
}

class AiRequestContext {
  const AiRequestContext({
    this.kind = 'free_chat',
    this.referenceId,
    this.summary,
    this.metadata = const <String, String>{},
  });

  final String kind;
  final String? referenceId;
  final String? summary;
  final Map<String, String> metadata;
}

class AiConversationModel {
  const AiConversationModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
}

class AiChatMessageModel {
  const AiChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = AiMessageStatus.completed,
    this.error,
    this.providerMessageId,
    this.requestContext,
    this.parentMessageId,
  });

  final String id;
  final String conversationId;
  final AiMessageRole role;
  final String content;
  final DateTime createdAt;
  final AiMessageStatus status;
  final AiErrorState? error;
  final String? providerMessageId;
  final AiRequestContext? requestContext;
  final String? parentMessageId;

  bool get isTerminal {
    return status == AiMessageStatus.completed ||
        status == AiMessageStatus.canceled ||
        status == AiMessageStatus.failed;
  }

  AiChatMessageModel copyWith({
    String? content,
    AiMessageStatus? status,
    AiErrorState? error,
    bool clearError = false,
    String? providerMessageId,
  }) {
    return AiChatMessageModel(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      providerMessageId: providerMessageId ?? this.providerMessageId,
      requestContext: requestContext,
      parentMessageId: parentMessageId,
    );
  }
}
