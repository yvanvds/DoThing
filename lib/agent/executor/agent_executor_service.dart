import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/status_controller.dart';
import '../../models/ai/ai_chat_models.dart';
import '../../services/ai/ai_chat_transport.dart';
import '../../services/ai/openai_chat_service.dart';
import '../confirmation/tool_confirmation_gate.dart';
import '../tools/tool_descriptor.dart';
import '../tools/tool_invoker.dart';
import 'tool_call.dart';
import 'tool_result.dart';

/// Runs the executor stage of an agent turn: given a plan-bounded tool
/// list and the existing conversation history, drives the multi-turn
/// tool loop against the shared [AiChatTransport] until the model stops
/// issuing tool calls.
///
/// Externally the service looks like a plain [AiChatTransport]: it yields
/// the same [AiStreamEvent] types (`delta`, `done`, `error`) that
/// [AiChatController] already knows how to persist. Tool invocations are
/// handled internally — the caller never sees tool-call events.
///
/// Phase 5 exposes all tiers. Privileged tools pause on the optional
/// [ToolConfirmationGate] before invocation; commit and lower tiers
/// auto-approve. The gate is supplied by the orchestrator so policy and
/// UI both live outside this service.
class AgentExecutorService {
  const AgentExecutorService(this.ref);

  final Ref ref;

  /// Runs the tool loop.
  ///
  /// [history] must already contain the pending user message and should
  /// be filtered (no failed/canceled/empty turns). [tools] is the exact
  /// set of tools the model may call on this turn; an empty list reduces
  /// the loop to a single pass-through completion.
  ///
  /// The loop terminates when:
  ///   * the model returns a turn without tool calls (→ `done`),
  ///   * the transport yields an error (→ `error`),
  ///   * [maxIterations] is exceeded (→ `error` with
  ///     code `executor_loop_exhausted`),
  ///   * [isCanceled] starts returning `true` (stream closes silently).
  Stream<AiStreamEvent> run({
    required String model,
    required String apiKey,
    required String baseUrl,
    required List<AiChatMessageModel> history,
    required List<ToolDescriptor> tools,
    AiRequestContext? context,
    int maxIterations = 6,
    bool Function()? isCanceled,
    ToolConfirmationGate? gate,
  }) async* {
    if (maxIterations <= 0) {
      yield const AiStreamEvent.error(
        AiErrorState(
          code: 'executor_config_invalid',
          message: 'Executor maxIterations must be positive.',
        ),
      );
      return;
    }

    final transport = ref.read(aiChatTransportProvider);
    final invoker = ref.read(toolInvokerProvider);

    var workingHistory = List<AiChatMessageModel>.of(history);
    final now = DateTime.now();

    for (var iteration = 0; iteration < maxIterations; iteration++) {
      if (isCanceled?.call() ?? false) return;

      final toolCalls = <ToolCall>[];
      final assistantText = StringBuffer();
      String? providerMessageId;
      AiErrorState? streamError;
      var streamDone = false;

      await for (final event in transport.streamCompletion(
        apiKey: apiKey,
        baseUrl: baseUrl,
        request: AiCompletionRequest(
          model: model,
          stream: true,
          messages: workingHistory,
          tools: tools,
          context: context,
        ),
      )) {
        if (isCanceled?.call() ?? false) return;

        if (event.error != null) {
          streamError = event.error;
          break;
        }

        final call = event.toolCall;
        if (call != null) {
          toolCalls.add(call);
        }

        if (event.delta.isNotEmpty) {
          assistantText.write(event.delta);
          yield AiStreamEvent.delta(event.delta);
        }

        if (event.done) {
          providerMessageId = event.providerMessageId;
          streamDone = true;
          break;
        }
      }

      if (streamError != null) {
        yield AiStreamEvent.error(streamError);
        return;
      }

      if (toolCalls.isEmpty) {
        yield AiStreamEvent.done(providerMessageId: providerMessageId);
        return;
      }

      // Record the assistant turn that produced the tool calls so the
      // model sees its own tool_calls on the follow-up request — required
      // by OpenAI-compatible providers to pair tool responses by id.
      workingHistory = [
        ...workingHistory,
        AiChatMessageModel(
          id: 'executor-assistant-$iteration',
          conversationId: _kSyntheticConversationId,
          role: AiMessageRole.assistant,
          content: assistantText.toString(),
          createdAt: now,
          status: AiMessageStatus.completed,
          toolCalls: List.unmodifiable(toolCalls),
        ),
      ];

      for (final call in toolCalls) {
        if (isCanceled?.call() ?? false) return;

        final ToolResult result;
        if (gate != null) {
          final decision = await gate(call);
          if (isCanceled?.call() ?? false) return;
          if (!decision.approved) {
            result = ToolResult.canceled(call.id, reason: decision.reason);
            _surfaceToolStatus(call, result);
          } else {
            result = await invoker.invoke(call);
            _surfaceToolStatus(call, result);
          }
        } else {
          result = await invoker.invoke(call);
          _surfaceToolStatus(call, result);
        }

        workingHistory = [
          ...workingHistory,
          AiChatMessageModel(
            id: 'executor-tool-${call.id}',
            conversationId: _kSyntheticConversationId,
            role: AiMessageRole.tool,
            content: result.summary,
            createdAt: DateTime.now(),
            status: AiMessageStatus.completed,
            toolCallId: call.id,
          ),
        ];
      }

      // Defensive: a transport that closed without emitting `done` or
      // `error` after tool_calls is a provider bug; bail rather than
      // looping forever on no new information.
      if (!streamDone) {
        yield const AiStreamEvent.error(
          AiErrorState(
            code: 'executor_stream_incomplete',
            message: 'Provider stream closed without a terminal event.',
          ),
        );
        return;
      }
    }

    yield const AiStreamEvent.error(
      AiErrorState(
        code: 'executor_loop_exhausted',
        message: 'Agent stopped: too many consecutive tool calls.',
      ),
    );
  }

  void _surfaceToolStatus(ToolCall call, ToolResult result) {
    final type = result.isError
        ? StatusEntryType.warning
        : StatusEntryType.info;
    final message = result.isError
        ? 'Agent tool ${call.toolName} failed: ${result.summary}'
        : 'Agent tool ${call.toolName}: ${result.summary}';
    ref.read(statusProvider.notifier).add(type, message);
  }
}

/// Synthetic conversation id stamped on in-flight executor messages.
/// These messages are never persisted — they only exist so the transport
/// can reconstruct the provider-facing `messages` array.
const String _kSyntheticConversationId = 'executor';

/// Riverpod access to the app-wide [AgentExecutorService]. Stateless
/// service — safe to read and discard.
final agentExecutorServiceProvider = Provider<AgentExecutorService>(
  AgentExecutorService.new,
);
