import 'package:do_thing/agent/capabilities/capability_domain.dart';
import 'package:do_thing/agent/confirmation/tool_confirmation_decision.dart';
import 'package:do_thing/agent/executor/agent_executor_service.dart';
import 'package:do_thing/agent/executor/tool_call.dart';
import 'package:do_thing/agent/executor/tool_result.dart';
import 'package:do_thing/agent/tools/tool_argument_schema.dart';
import 'package:do_thing/agent/tools/tool_descriptor.dart';
import 'package:do_thing/agent/tools/tool_mode.dart';
import 'package:do_thing/agent/tools/tool_registry.dart';
import 'package:do_thing/agent/tools/tool_risk_tier.dart';
import 'package:do_thing/controllers/status_controller.dart';
import 'package:do_thing/models/ai/ai_chat_models.dart';
import 'package:do_thing/services/ai/ai_chat_transport.dart';
import 'package:do_thing/services/ai/openai_chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransport implements AiChatTransport {
  _FakeTransport(this.respond);

  final Stream<AiStreamEvent> Function(AiCompletionRequest request) respond;
  final List<AiCompletionRequest> requests = [];

  @override
  Stream<AiStreamEvent> streamCompletion({
    required String apiKey,
    required String baseUrl,
    required AiCompletionRequest request,
  }) {
    requests.add(request);
    return respond(request);
  }

  @override
  Future<void> testConnection({
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {}
}

/// Transport that serves a scripted sequence of responses, one per call.
class _ScriptedTransport implements AiChatTransport {
  _ScriptedTransport(this.scripts);

  final List<List<AiStreamEvent>> scripts;
  final List<AiCompletionRequest> requests = [];
  int _index = 0;

  @override
  Stream<AiStreamEvent> streamCompletion({
    required String apiKey,
    required String baseUrl,
    required AiCompletionRequest request,
  }) {
    requests.add(request);
    if (_index >= scripts.length) {
      return const Stream.empty();
    }
    final events = scripts[_index++];
    return Stream.fromIterable(events);
  }

  @override
  Future<void> testConnection({
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {}
}

ToolDescriptor _readTool({
  required String name,
  required Future<ToolResult> Function(Map<String, Object?> args) invoke,
}) {
  return ToolDescriptor(
    name: name,
    description: name,
    domain: CapabilityDomain.mailbox,
    mode: ToolMode.read,
    risk: ToolRiskTier.read,
    arguments: ToolArgumentSchema.empty,
    invoke: (_, args) => invoke(args),
  );
}

ToolDescriptor _prepareTool({
  required String name,
  required Future<ToolResult> Function(Map<String, Object?> args) invoke,
}) {
  return ToolDescriptor(
    name: name,
    description: name,
    domain: CapabilityDomain.navigation,
    mode: ToolMode.prepare,
    risk: ToolRiskTier.prepare,
    arguments: ToolArgumentSchema.empty,
    invoke: (_, args) => invoke(args),
  );
}

ToolDescriptor _privilegedTool({
  required String name,
  required Future<ToolResult> Function(Map<String, Object?> args) invoke,
}) {
  return ToolDescriptor(
    name: name,
    description: name,
    domain: CapabilityDomain.mailbox,
    mode: ToolMode.privileged,
    risk: ToolRiskTier.privileged,
    arguments: ToolArgumentSchema.empty,
    invoke: (_, args) => invoke(args),
  );
}

AiChatMessageModel _userMessage(String text) {
  return AiChatMessageModel(
    id: 'u1',
    conversationId: 'c1',
    role: AiMessageRole.user,
    content: text,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('AgentExecutorService.run', () {
    test('streams text and completes when the model issues no tool calls',
        () async {
      final transport = _FakeTransport(
        (_) => Stream.fromIterable(const [
          AiStreamEvent.delta('Hello '),
          AiStreamEvent.delta('world'),
          AiStreamEvent.done(providerMessageId: 'p-1'),
        ]),
      );
      final container = ProviderContainer(
        overrides: [
          aiChatTransportProvider.overrideWithValue(transport),
          toolRegistryProvider.overrideWithValue(
            ToolRegistry(const <ToolDescriptor>[]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(agentExecutorServiceProvider);
      final events = await service
          .run(
            model: 'm',
            apiKey: 'k',
            baseUrl: 'https://x',
            history: [_userMessage('hi')],
            tools: const <ToolDescriptor>[],
          )
          .toList();

      expect(events, hasLength(3));
      expect(events[0].delta, 'Hello ');
      expect(events[1].delta, 'world');
      expect(events[2].done, isTrue);
      expect(events[2].providerMessageId, 'p-1');
      expect(transport.requests, hasLength(1));
    });

    test(
      'invokes tools, feeds results back, and terminates on the final turn',
      () async {
        final invokedArgs = <Map<String, Object?>>[];
        final tool = _readTool(
          name: 'list_inbox_headers',
          invoke: (args) async {
            invokedArgs.add(args);
            return const ToolResult(
              toolCallId: '',
              summary: 'Found 1 header.',
            );
          },
        );

        final transport = _ScriptedTransport([
          // Turn 1: model requests a tool call, no user-visible text.
          const [
            AiStreamEvent.toolCall(
              ToolCall(
                id: 'call-1',
                toolName: 'list_inbox_headers',
                arguments: <String, Object?>{},
              ),
            ),
            AiStreamEvent.done(),
          ],
          // Turn 2: model answers with plain text.
          const [
            AiStreamEvent.delta('Done.'),
            AiStreamEvent.done(providerMessageId: 'p-end'),
          ],
        ]);

        final container = ProviderContainer(
          overrides: [
            aiChatTransportProvider.overrideWithValue(transport),
            toolRegistryProvider.overrideWithValue(ToolRegistry([tool])),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(agentExecutorServiceProvider);
        final events = await service
            .run(
              model: 'm',
              apiKey: 'k',
              baseUrl: 'https://x',
              history: [_userMessage('what\'s in my inbox')],
              tools: [tool],
            )
            .toList();

        expect(invokedArgs, hasLength(1));
        expect(events.map((e) => e.delta).where((d) => d.isNotEmpty), [
          'Done.',
        ]);
        expect(events.last.done, isTrue);
        expect(events.last.providerMessageId, 'p-end');

        // Two roundtrips: initial + follow-up after tool result.
        expect(transport.requests, hasLength(2));
        final followUp = transport.requests[1];
        // Follow-up should have: user prompt + assistant turn w/ tool_calls
        // + tool result — for the model to pair by tool_call_id.
        expect(followUp.messages.last.role, AiMessageRole.tool);
        expect(followUp.messages.last.toolCallId, 'call-1');
        final assistantTurn = followUp.messages.firstWhere(
          (m) => m.role == AiMessageRole.assistant,
        );
        expect(assistantTurn.toolCalls, hasLength(1));
        expect(assistantTurn.toolCalls!.single.id, 'call-1');

        // Tool invocation should be surfaced on the status terminal.
        final status = container.read(statusProvider);
        expect(
          status.map((e) => e.message).toList(),
          contains(
            'Agent tool list_inbox_headers: Found 1 header.',
          ),
        );
      },
    );

    test('forwards transport errors verbatim', () async {
      final transport = _FakeTransport(
        (_) => Stream.fromIterable(const [
          AiStreamEvent.error(
            AiErrorState(code: 'http_500', message: 'boom'),
          ),
        ]),
      );
      final container = ProviderContainer(
        overrides: [
          aiChatTransportProvider.overrideWithValue(transport),
          toolRegistryProvider.overrideWithValue(
            ToolRegistry(const <ToolDescriptor>[]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(agentExecutorServiceProvider);
      final events = await service
          .run(
            model: 'm',
            apiKey: 'k',
            baseUrl: 'https://x',
            history: [_userMessage('hi')],
            tools: const <ToolDescriptor>[],
          )
          .toList();

      expect(events, hasLength(1));
      expect(events.single.error?.code, 'http_500');
    });

    test('bails with executor_loop_exhausted when tool calls keep repeating',
        () async {
      final tool = _readTool(
        name: 'list_inbox_headers',
        invoke: (_) async =>
            const ToolResult(toolCallId: '', summary: 'ok'),
      );

      Stream<AiStreamEvent> neverCompletingToolLoop(AiCompletionRequest _) {
        return Stream.fromIterable(const [
          AiStreamEvent.toolCall(
            ToolCall(
              id: 'call-repeat',
              toolName: 'list_inbox_headers',
              arguments: <String, Object?>{},
            ),
          ),
          AiStreamEvent.done(),
        ]);
      }

      final transport = _FakeTransport(neverCompletingToolLoop);
      final container = ProviderContainer(
        overrides: [
          aiChatTransportProvider.overrideWithValue(transport),
          toolRegistryProvider.overrideWithValue(ToolRegistry([tool])),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(agentExecutorServiceProvider);
      final events = await service
          .run(
            model: 'm',
            apiKey: 'k',
            baseUrl: 'https://x',
            history: [_userMessage('loop')],
            tools: [tool],
            maxIterations: 3,
          )
          .toList();

      expect(events.last.error?.code, 'executor_loop_exhausted');
      expect(transport.requests, hasLength(3));
    });

    test('reports a warning status entry when a tool handler errors',
        () async {
      final tool = _readTool(
        name: 'list_inbox_headers',
        invoke: (_) async => throw StateError('net down'),
      );

      final transport = _ScriptedTransport([
        const [
          AiStreamEvent.toolCall(
            ToolCall(
              id: 'call-1',
              toolName: 'list_inbox_headers',
              arguments: <String, Object?>{},
            ),
          ),
          AiStreamEvent.done(),
        ],
        const [
          AiStreamEvent.delta('Sorry, could not fetch.'),
          AiStreamEvent.done(),
        ],
      ]);

      final container = ProviderContainer(
        overrides: [
          aiChatTransportProvider.overrideWithValue(transport),
          toolRegistryProvider.overrideWithValue(ToolRegistry([tool])),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(agentExecutorServiceProvider);
      await service
          .run(
            model: 'm',
            apiKey: 'k',
            baseUrl: 'https://x',
            history: [_userMessage('go')],
            tools: [tool],
          )
          .toList();

      final status = container.read(statusProvider);
      expect(
        status.any(
          (e) =>
              e.type == StatusEntryType.warning &&
              e.message.contains('list_inbox_headers failed'),
        ),
        isTrue,
      );
    });

    test('honors the isCanceled callback and halts the loop', () async {
      final tool = _prepareTool(
        name: 'open_messages_panel',
        invoke: (_) async =>
            const ToolResult(toolCallId: '', summary: 'opened'),
      );

      final transport = _ScriptedTransport([
        const [
          AiStreamEvent.toolCall(
            ToolCall(
              id: 'call-1',
              toolName: 'open_messages_panel',
              arguments: <String, Object?>{},
            ),
          ),
          AiStreamEvent.done(),
        ],
      ]);

      final container = ProviderContainer(
        overrides: [
          aiChatTransportProvider.overrideWithValue(transport),
          toolRegistryProvider.overrideWithValue(ToolRegistry([tool])),
        ],
      );
      addTearDown(container.dispose);

      var canceled = false;
      final service = container.read(agentExecutorServiceProvider);
      final events = await service
          .run(
            model: 'm',
            apiKey: 'k',
            baseUrl: 'https://x',
            history: [_userMessage('open')],
            tools: [tool],
            // Cancel immediately after first tool invocation kicks off.
            isCanceled: () {
              final was = canceled;
              canceled = transport.requests.isNotEmpty;
              return was;
            },
          )
          .toList();

      // Loop stops silently — no terminal event is emitted.
      expect(events.any((e) => e.done), isFalse);
      expect(events.any((e) => e.error != null), isFalse);
    });

    test(
      'consults the gate for privileged tools and invokes on approve',
      () async {
        var invoked = false;
        final tool = _privilegedTool(
          name: 'delete_message',
          invoke: (_) async {
            invoked = true;
            return const ToolResult(
              toolCallId: '',
              summary: 'Deleted.',
            );
          },
        );

        final transport = _ScriptedTransport([
          const [
            AiStreamEvent.toolCall(
              ToolCall(
                id: 'call-1',
                toolName: 'delete_message',
                arguments: <String, Object?>{},
              ),
            ),
            AiStreamEvent.done(),
          ],
          const [
            AiStreamEvent.delta('Done.'),
            AiStreamEvent.done(providerMessageId: 'p-end'),
          ],
        ]);

        final container = ProviderContainer(
          overrides: [
            aiChatTransportProvider.overrideWithValue(transport),
            toolRegistryProvider.overrideWithValue(ToolRegistry([tool])),
          ],
        );
        addTearDown(container.dispose);

        final gateCalls = <ToolCall>[];
        final service = container.read(agentExecutorServiceProvider);
        await service
            .run(
              model: 'm',
              apiKey: 'k',
              baseUrl: 'https://x',
              history: [_userMessage('kill it')],
              tools: [tool],
              gate: (call) async {
                gateCalls.add(call);
                return const ConfirmationDecision.approved();
              },
            )
            .toList();

        expect(gateCalls, hasLength(1));
        expect(gateCalls.single.toolName, 'delete_message');
        expect(invoked, isTrue);
        expect(transport.requests, hasLength(2));
      },
    );

    test(
      'onToolExecuted fires for every tool invocation — approved or denied',
      () async {
        final tool = _privilegedTool(
          name: 'delete_message',
          invoke: (_) async =>
              const ToolResult(toolCallId: '', summary: 'Deleted.'),
        );

        final transport = _ScriptedTransport([
          const [
            AiStreamEvent.toolCall(
              ToolCall(
                id: 'call-1',
                toolName: 'delete_message',
                arguments: <String, Object?>{},
              ),
            ),
            AiStreamEvent.done(),
          ],
          const [
            AiStreamEvent.delta('Done.'),
            AiStreamEvent.done(),
          ],
        ]);

        final container = ProviderContainer(
          overrides: [
            aiChatTransportProvider.overrideWithValue(transport),
            toolRegistryProvider.overrideWithValue(ToolRegistry([tool])),
          ],
        );
        addTearDown(container.dispose);

        final traces = <(ToolCall, ToolResult)>[];
        final service = container.read(agentExecutorServiceProvider);
        await service
            .run(
              model: 'm',
              apiKey: 'k',
              baseUrl: 'https://x',
              history: [_userMessage('do it')],
              tools: [tool],
              gate: (_) async => const ConfirmationDecision.approved(),
              onToolExecuted: (call, result) => traces.add((call, result)),
            )
            .toList();

        expect(traces, hasLength(1));
        expect(traces.single.$1.toolName, 'delete_message');
        expect(traces.single.$2.summary, 'Deleted.');
      },
    );

    test(
      'onToolExecuted receives canceled results when the gate denies',
      () async {
        final tool = _privilegedTool(
          name: 'delete_message',
          invoke: (_) async =>
              const ToolResult(toolCallId: '', summary: 'Deleted.'),
        );

        final transport = _ScriptedTransport([
          const [
            AiStreamEvent.toolCall(
              ToolCall(
                id: 'call-1',
                toolName: 'delete_message',
                arguments: <String, Object?>{},
              ),
            ),
            AiStreamEvent.done(),
          ],
          const [
            AiStreamEvent.delta('ok'),
            AiStreamEvent.done(),
          ],
        ]);

        final container = ProviderContainer(
          overrides: [
            aiChatTransportProvider.overrideWithValue(transport),
            toolRegistryProvider.overrideWithValue(ToolRegistry([tool])),
          ],
        );
        addTearDown(container.dispose);

        final traces = <(ToolCall, ToolResult)>[];
        final service = container.read(agentExecutorServiceProvider);
        await service
            .run(
              model: 'm',
              apiKey: 'k',
              baseUrl: 'https://x',
              history: [_userMessage('do it')],
              tools: [tool],
              gate: (_) async =>
                  const ConfirmationDecision.denied(reason: 'no'),
              onToolExecuted: (call, result) => traces.add((call, result)),
            )
            .toList();

        expect(traces, hasLength(1));
        expect(traces.single.$2.isError, isTrue);
        expect(traces.single.$2.structured?['canceled'], isTrue);
      },
    );

    test(
      'on gate denial, injects a canceled tool result without invoking',
      () async {
        var invoked = false;
        final tool = _privilegedTool(
          name: 'delete_message',
          invoke: (_) async {
            invoked = true;
            return const ToolResult(toolCallId: '', summary: 'Deleted.');
          },
        );

        final transport = _ScriptedTransport([
          const [
            AiStreamEvent.toolCall(
              ToolCall(
                id: 'call-1',
                toolName: 'delete_message',
                arguments: <String, Object?>{},
              ),
            ),
            AiStreamEvent.done(),
          ],
          const [
            AiStreamEvent.delta('Okay, standing down.'),
            AiStreamEvent.done(),
          ],
        ]);

        final container = ProviderContainer(
          overrides: [
            aiChatTransportProvider.overrideWithValue(transport),
            toolRegistryProvider.overrideWithValue(ToolRegistry([tool])),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(agentExecutorServiceProvider);
        await service
            .run(
              model: 'm',
              apiKey: 'k',
              baseUrl: 'https://x',
              history: [_userMessage('kill it')],
              tools: [tool],
              gate: (_) async => const ConfirmationDecision.denied(
                reason: 'User declined.',
              ),
            )
            .toList();

        expect(invoked, isFalse);
        final followUp = transport.requests[1];
        final toolTurn = followUp.messages.firstWhere(
          (m) => m.role == AiMessageRole.tool,
        );
        expect(toolTurn.content, contains('User declined.'));
      },
    );
  });
}
