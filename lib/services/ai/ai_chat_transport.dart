import '../../agent/executor/tool_call.dart';
import '../../agent/tools/tool_descriptor.dart';
import '../../models/ai/ai_chat_models.dart';

class AiCompletionRequest {
  const AiCompletionRequest({
    required this.model,
    required this.messages,
    required this.stream,
    this.context,
    this.jsonObjectResponse = false,
    this.tools = const <ToolDescriptor>[],
  });

  final String model;
  final List<AiChatMessageModel> messages;
  final bool stream;
  final AiRequestContext? context;
  final bool jsonObjectResponse;

  /// Tools exposed to the model for this turn. When empty, the transport
  /// omits the `tools` field entirely and the request behaves like a
  /// plain chat completion.
  final List<ToolDescriptor> tools;
}

class AiStreamEvent {
  const AiStreamEvent.delta(this.delta)
    : done = false,
      providerMessageId = null,
      error = null,
      toolCall = null;

  const AiStreamEvent.toolCall(this.toolCall)
    : done = false,
      delta = '',
      providerMessageId = null,
      error = null;

  const AiStreamEvent.done({this.providerMessageId})
    : done = true,
      delta = '',
      error = null,
      toolCall = null;

  const AiStreamEvent.error(this.error)
    : done = true,
      delta = '',
      providerMessageId = null,
      toolCall = null;

  final bool done;
  final String delta;
  final String? providerMessageId;
  final AiErrorState? error;

  /// Set when the provider emitted a fully-assembled tool call on this
  /// turn. Multiple tool calls in the same turn arrive as separate
  /// [AiStreamEvent.toolCall] events, in provider-assigned order.
  final ToolCall? toolCall;
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
