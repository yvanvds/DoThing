import '../../models/ai/ai_chat_models.dart';

class AiCompletionRequest {
  const AiCompletionRequest({
    required this.model,
    required this.messages,
    required this.stream,
    this.context,
    this.jsonObjectResponse = false,
  });

  final String model;
  final List<AiChatMessageModel> messages;
  final bool stream;
  final AiRequestContext? context;
  final bool jsonObjectResponse;
}

class AiStreamEvent {
  const AiStreamEvent.delta(this.delta)
    : done = false,
      providerMessageId = null,
      error = null;

  const AiStreamEvent.done({this.providerMessageId})
    : done = true,
      delta = '',
      error = null;

  const AiStreamEvent.error(this.error)
    : done = true,
      delta = '',
      providerMessageId = null;

  final bool done;
  final String delta;
  final String? providerMessageId;
  final AiErrorState? error;
}

abstract class AiChatTransport {
  Stream<AiStreamEvent> streamCompletion({
    required String apiKey,
    required String baseUrl,
    required AiCompletionRequest request,
  });

  Future<void> testConnection({
    required String apiKey,
    required String baseUrl,
    required String model,
  });
}
