import 'package:do_thing/agent/capabilities/capability_domain.dart';
import 'package:do_thing/agent/executor/tool_call.dart';
import 'package:do_thing/agent/executor/tool_result.dart';
import 'package:do_thing/agent/orchestrator/agent_orchestrator_controller.dart';
import 'package:do_thing/agent/orchestrator/agent_turn_state.dart';
import 'package:do_thing/agent/tools/tool_argument_schema.dart';
import 'package:do_thing/agent/tools/tool_descriptor.dart';
import 'package:do_thing/agent/tools/tool_mode.dart';
import 'package:do_thing/agent/tools/tool_registry.dart';
import 'package:do_thing/agent/tools/tool_risk_tier.dart';
import 'package:do_thing/controllers/ai/ai_settings_controller.dart';
import 'package:do_thing/models/ai/ai_settings.dart';
import 'package:do_thing/services/ai/ai_chat_transport.dart';
import 'package:do_thing/services/ai/openai_chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAiSettingsController extends AiSettingsController {
  _FakeAiSettingsController({required this.settings, this.apiKey});

  final AiSettings settings;
  final String? apiKey;

  @override
  Future<AiSettings> build() async => settings;

  @override
  Future<String?> readApiKey() async => apiKey;
}

class _FakeTransport implements AiChatTransport {
  _FakeTransport(this.respond);

  final Stream<AiStreamEvent> Function(AiCompletionRequest req) respond;
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

ToolDescriptor _mailboxRead() {
  return ToolDescriptor(
    name: 'list_inbox_headers',
    description: 'list inbox headers',
    domain: CapabilityDomain.mailbox,
    mode: ToolMode.read,
    risk: ToolRiskTier.read,
    arguments: ToolArgumentSchema.empty,
    invoke: (_, _) async => const ToolResult(toolCallId: '', summary: 'ok'),
  );
}

ToolDescriptor _mailboxCommit() {
  return ToolDescriptor(
    name: 'archive_message',
    description: 'archive one message',
    domain: CapabilityDomain.mailbox,
    mode: ToolMode.commit,
    risk: ToolRiskTier.commit,
    arguments: ToolArgumentSchema.empty,
    humanPreview: (args) => 'Archive message ${args['id']}',
    invoke: (_, _) async =>
        const ToolResult(toolCallId: '', summary: 'Archived 42.'),
  );
}

ToolDescriptor _mailboxPrivileged() {
  return ToolDescriptor(
    name: 'delete_message',
    description: 'destructive deletion',
    domain: CapabilityDomain.mailbox,
    mode: ToolMode.privileged,
    risk: ToolRiskTier.privileged,
    arguments: ToolArgumentSchema.empty,
    humanPreview: (args) => 'Delete message ${args['id']}',
    invoke: (_, _) async => const ToolResult(toolCallId: '', summary: 'gone'),
  );
}

Stream<AiStreamEvent> _jsonShot(String json) async* {
  yield AiStreamEvent.delta(json);
  yield const AiStreamEvent.done();
}

void main() {
  group('AgentOrchestratorController', () {
    test('skips the planner when the catalog is empty', () async {
      final transport = _FakeTransport((_) => const Stream.empty());
      final container = ProviderContainer(
        overrides: [
          toolRegistryProvider.overrideWithValue(
            ToolRegistry(const <ToolDescriptor>[]),
          ),
          aiChatTransportProvider.overrideWithValue(transport),
          aiSettingsProvider.overrideWith(
            () => _FakeAiSettingsController(
              settings: const AiSettings(hasApiKey: true),
              apiKey: 'token',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final orchestrator = container.read(
        agentOrchestratorControllerProvider.notifier,
      );

      final outcome = await orchestrator.planTurn(
        conversationId: 'c1',
        prompt: 'say hi',
        history: const [],
      );

      expect(outcome.plan, isNull);
      expect(outcome.preamble, isEmpty);
      expect(outcome.error, isNull);
      expect(outcome.didPlan, isFalse);
      expect(transport.requests, isEmpty);
      expect(
        container.read(agentOrchestratorControllerProvider).phase,
        AgentTurnPhase.idle,
      );
    });

    test('fails gracefully when the API key is missing', () async {
      final transport = _FakeTransport((_) => const Stream.empty());
      final container = ProviderContainer(
        overrides: [
          toolRegistryProvider.overrideWithValue(
            ToolRegistry([_mailboxRead()]),
          ),
          aiChatTransportProvider.overrideWithValue(transport),
          aiSettingsProvider.overrideWith(
            () => _FakeAiSettingsController(
              settings: const AiSettings(hasApiKey: false),
              apiKey: null,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final orchestrator = container.read(
        agentOrchestratorControllerProvider.notifier,
      );

      final outcome = await orchestrator.planTurn(
        conversationId: 'c1',
        prompt: 'p',
        history: const [],
      );

      expect(outcome.plan, isNull);
      expect(outcome.error, 'missing_api_key');
      expect(transport.requests, isEmpty);
      final state = container.read(agentOrchestratorControllerProvider);
      expect(state.phase, AgentTurnPhase.plannerFailed);
      expect(state.lastPlannerError, 'missing_api_key');
    });

    test(
      'produces a markdown preamble when the planner returns a plan and '
      'showAgentReasoning is on',
      () async {
        final transport = _FakeTransport(
          (_) => _jsonShot(
            '{"intent":"triage inbox",'
            '"domains":["mailbox"],'
            '"rationale":"user asked to triage",'
            '"anticipated_max_risk":"read",'
            '"needs_more_information":false,'
            '"clarifying_question":null}',
          ),
        );
        final container = ProviderContainer(
          overrides: [
            toolRegistryProvider.overrideWithValue(
              ToolRegistry([_mailboxRead()]),
            ),
            aiChatTransportProvider.overrideWithValue(transport),
            aiSettingsProvider.overrideWith(
              () => _FakeAiSettingsController(
                settings: const AiSettings(
                  hasApiKey: true,
                  showAgentReasoning: true,
                ),
                apiKey: 'token',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final orchestrator = container.read(
          agentOrchestratorControllerProvider.notifier,
        );

        final outcome = await orchestrator.planTurn(
          conversationId: 'c1',
          prompt: 'triage',
          history: const [],
        );

        expect(outcome.plan, isNotNull);
        expect(outcome.preamble, contains('**Plan:** triage inbox'));
        expect(outcome.preamble, contains('mailbox'));
        expect(outcome.preamble, endsWith('\n\n---\n\n'));

        final state = container.read(agentOrchestratorControllerProvider);
        expect(state.phase, AgentTurnPhase.planned);
        expect(state.currentPlan?.intent, 'triage inbox');
      },
    );

    test(
      'omits the reasoning preamble by default but keeps the plan',
      () async {
        final transport = _FakeTransport(
          (_) => _jsonShot(
            '{"intent":"triage inbox",'
            '"domains":["mailbox"],'
            '"rationale":"user asked to triage",'
            '"anticipated_max_risk":"read",'
            '"needs_more_information":false,'
            '"clarifying_question":null}',
          ),
        );
        final container = ProviderContainer(
          overrides: [
            toolRegistryProvider.overrideWithValue(
              ToolRegistry([_mailboxRead()]),
            ),
            aiChatTransportProvider.overrideWithValue(transport),
            aiSettingsProvider.overrideWith(
              () => _FakeAiSettingsController(
                settings: const AiSettings(hasApiKey: true),
                apiKey: 'token',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final orchestrator = container.read(
          agentOrchestratorControllerProvider.notifier,
        );

        final outcome = await orchestrator.planTurn(
          conversationId: 'c1',
          prompt: 'triage',
          history: const [],
        );

        expect(outcome.plan, isNotNull);
        expect(outcome.preamble, isEmpty);
        expect(
          container.read(agentOrchestratorControllerProvider).phase,
          AgentTurnPhase.planned,
        );
      },
    );

    test('uses the clarifying question as the preamble when asked for info',
        () async {
      final transport = _FakeTransport(
        (_) => _jsonShot(
          '{"intent":"",'
          '"domains":[],'
          '"rationale":"",'
          '"anticipated_max_risk":"read",'
          '"needs_more_information":true,'
          '"clarifying_question":"Which account should I use?"}',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          toolRegistryProvider.overrideWithValue(
            ToolRegistry([_mailboxRead()]),
          ),
          aiChatTransportProvider.overrideWithValue(transport),
          aiSettingsProvider.overrideWith(
            () => _FakeAiSettingsController(
              settings: const AiSettings(hasApiKey: true),
              apiKey: 'token',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final orchestrator = container.read(
        agentOrchestratorControllerProvider.notifier,
      );

      final outcome = await orchestrator.planTurn(
        conversationId: 'c1',
        prompt: 'send a reply',
        history: const [],
      );

      expect(outcome.preamble, contains('Which account should I use?'));
      expect(
        container.read(agentOrchestratorControllerProvider).phase,
        AgentTurnPhase.awaitingClarification,
      );
    });

    test(
      'confirmationGate auto-approves non-privileged tools without pending',
      () async {
        final transport = _FakeTransport((_) => const Stream.empty());
        final container = ProviderContainer(
          overrides: [
            toolRegistryProvider.overrideWithValue(
              ToolRegistry([_mailboxRead()]),
            ),
            aiChatTransportProvider.overrideWithValue(transport),
            aiSettingsProvider.overrideWith(
              () => _FakeAiSettingsController(
                settings: const AiSettings(hasApiKey: true),
                apiKey: 'token',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final orchestrator = container.read(
          agentOrchestratorControllerProvider.notifier,
        );

        final decision = await orchestrator.confirmationGate(
          const ToolCall(
            id: 'c1',
            toolName: 'list_inbox_headers',
            arguments: <String, Object?>{},
          ),
        );
        expect(decision.approved, isTrue);
        expect(
          container.read(agentOrchestratorControllerProvider).pending,
          isNull,
        );
      },
    );

    test(
      'confirmationGate stages a pending and completes on confirmPending',
      () async {
        final transport = _FakeTransport((_) => const Stream.empty());
        final container = ProviderContainer(
          overrides: [
            toolRegistryProvider.overrideWithValue(
              ToolRegistry([_mailboxPrivileged()]),
            ),
            aiChatTransportProvider.overrideWithValue(transport),
            aiSettingsProvider.overrideWith(
              () => _FakeAiSettingsController(
                settings: const AiSettings(hasApiKey: true),
                apiKey: 'token',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final orchestrator = container.read(
          agentOrchestratorControllerProvider.notifier,
        );

        final future = orchestrator.confirmationGate(
          const ToolCall(
            id: 'call-9',
            toolName: 'delete_message',
            arguments: <String, Object?>{'id': 42},
          ),
        );

        final pending = container
            .read(agentOrchestratorControllerProvider)
            .pending;
        expect(pending, isNotNull);
        expect(pending!.id, 'call-9');
        expect(pending.humanPreview, 'Delete message 42');
        expect(
          container.read(agentOrchestratorControllerProvider).phase,
          AgentTurnPhase.awaitingConfirmation,
        );

        orchestrator.confirmPending('call-9');
        final decision = await future;
        expect(decision.approved, isTrue);
        expect(
          container.read(agentOrchestratorControllerProvider).pending,
          isNull,
        );
        expect(
          container.read(agentOrchestratorControllerProvider).phase,
          AgentTurnPhase.executing,
        );
      },
    );

    test(
      'confirmationGate returns a denied decision on cancelPending',
      () async {
        final transport = _FakeTransport((_) => const Stream.empty());
        final container = ProviderContainer(
          overrides: [
            toolRegistryProvider.overrideWithValue(
              ToolRegistry([_mailboxPrivileged()]),
            ),
            aiChatTransportProvider.overrideWithValue(transport),
            aiSettingsProvider.overrideWith(
              () => _FakeAiSettingsController(
                settings: const AiSettings(hasApiKey: true),
                apiKey: 'token',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final orchestrator = container.read(
          agentOrchestratorControllerProvider.notifier,
        );

        final future = orchestrator.confirmationGate(
          const ToolCall(
            id: 'call-x',
            toolName: 'delete_message',
            arguments: <String, Object?>{'id': 99},
          ),
        );

        orchestrator.cancelPending('call-x', reason: 'nope');
        final decision = await future;
        expect(decision.approved, isFalse);
        expect(decision.reason, 'nope');
        expect(
          container.read(agentOrchestratorControllerProvider).pending,
          isNull,
        );
      },
    );

    test(
      'markTurnFinished resolves any pending decision as denied',
      () async {
        final transport = _FakeTransport((_) => const Stream.empty());
        final container = ProviderContainer(
          overrides: [
            toolRegistryProvider.overrideWithValue(
              ToolRegistry([_mailboxPrivileged()]),
            ),
            aiChatTransportProvider.overrideWithValue(transport),
            aiSettingsProvider.overrideWith(
              () => _FakeAiSettingsController(
                settings: const AiSettings(hasApiKey: true),
                apiKey: 'token',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final orchestrator = container.read(
          agentOrchestratorControllerProvider.notifier,
        );

        final future = orchestrator.confirmationGate(
          const ToolCall(
            id: 'call-z',
            toolName: 'delete_message',
            arguments: <String, Object?>{'id': 1},
          ),
        );

        orchestrator.markTurnFinished();
        final decision = await future;
        expect(decision.approved, isFalse);
        final state = container.read(agentOrchestratorControllerProvider);
        expect(state.pending, isNull);
        expect(state.phase, AgentTurnPhase.idle);
      },
    );

    test(
      'resolveExecutorTools now includes commit and privileged tiers',
      () async {
        final transport = _FakeTransport(
          (_) => _jsonShot(
            '{"intent":"tidy",'
            '"domains":["mailbox"],'
            '"rationale":"",'
            '"anticipated_max_risk":"privileged",'
            '"needs_more_information":false,'
            '"clarifying_question":null}',
          ),
        );
        final container = ProviderContainer(
          overrides: [
            toolRegistryProvider.overrideWithValue(
              ToolRegistry([_mailboxRead(), _mailboxPrivileged()]),
            ),
            aiChatTransportProvider.overrideWithValue(transport),
            aiSettingsProvider.overrideWith(
              () => _FakeAiSettingsController(
                settings: const AiSettings(hasApiKey: true),
                apiKey: 'token',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final orchestrator = container.read(
          agentOrchestratorControllerProvider.notifier,
        );

        await orchestrator.planTurn(
          conversationId: 'c1',
          prompt: 'tidy inbox',
          history: const [],
        );

        final tools = orchestrator.resolveExecutorTools();
        expect(
          tools.map((t) => t.name).toSet(),
          {'list_inbox_headers', 'delete_message'},
        );
      },
    );

    test(
      'recordToolTrace appends commit-tier tools to the sidecar trace list',
      () async {
        final transport = _FakeTransport((_) => const Stream.empty());
        final container = ProviderContainer(
          overrides: [
            toolRegistryProvider.overrideWithValue(
              ToolRegistry([_mailboxRead(), _mailboxCommit()]),
            ),
            aiChatTransportProvider.overrideWithValue(transport),
            aiSettingsProvider.overrideWith(
              () => _FakeAiSettingsController(
                settings: const AiSettings(hasApiKey: true),
                apiKey: 'token',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final orchestrator = container.read(
          agentOrchestratorControllerProvider.notifier,
        );

        // Read tier: should NOT emit a trace card.
        orchestrator.recordToolTrace(
          const ToolCall(
            id: 'r1',
            toolName: 'list_inbox_headers',
            arguments: <String, Object?>{},
          ),
          const ToolResult(toolCallId: 'r1', summary: 'ok'),
        );
        expect(
          container.read(agentOrchestratorControllerProvider).traces,
          isEmpty,
        );

        // Commit tier: should emit a trace card with the humanPreview label.
        orchestrator.recordToolTrace(
          const ToolCall(
            id: 'c1',
            toolName: 'archive_message',
            arguments: <String, Object?>{'id': 42},
          ),
          const ToolResult(toolCallId: 'c1', summary: 'Archived 42.'),
        );
        final traces =
            container.read(agentOrchestratorControllerProvider).traces;
        expect(traces, hasLength(1));
        expect(traces.single.label, 'Archive message 42');
        expect(traces.single.canceled, isFalse);
        expect(traces.single.isError, isFalse);
      },
    );

    test(
      'recordToolTrace flags canceled results distinctly from errors',
      () async {
        final transport = _FakeTransport((_) => const Stream.empty());
        final container = ProviderContainer(
          overrides: [
            toolRegistryProvider.overrideWithValue(
              ToolRegistry([_mailboxCommit()]),
            ),
            aiChatTransportProvider.overrideWithValue(transport),
            aiSettingsProvider.overrideWith(
              () => _FakeAiSettingsController(
                settings: const AiSettings(hasApiKey: true),
                apiKey: 'token',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final orchestrator = container.read(
          agentOrchestratorControllerProvider.notifier,
        );

        orchestrator.recordToolTrace(
          const ToolCall(
            id: 'c9',
            toolName: 'archive_message',
            arguments: <String, Object?>{'id': 7},
          ),
          ToolResult.canceled('c9', reason: 'User declined.'),
        );

        final trace =
            container.read(agentOrchestratorControllerProvider).traces.single;
        expect(trace.canceled, isTrue);
        expect(trace.isError, isFalse);
      },
    );

    test(
      'planTurn clears traces from the previous turn',
      () async {
        final transport = _FakeTransport(
          (_) => _jsonShot(
            '{"intent":"t",'
            '"domains":["mailbox"],'
            '"rationale":"",'
            '"anticipated_max_risk":"read",'
            '"needs_more_information":false,'
            '"clarifying_question":null}',
          ),
        );
        final container = ProviderContainer(
          overrides: [
            toolRegistryProvider.overrideWithValue(
              ToolRegistry([_mailboxRead(), _mailboxCommit()]),
            ),
            aiChatTransportProvider.overrideWithValue(transport),
            aiSettingsProvider.overrideWith(
              () => _FakeAiSettingsController(
                settings: const AiSettings(hasApiKey: true),
                apiKey: 'token',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final orchestrator = container.read(
          agentOrchestratorControllerProvider.notifier,
        );

        orchestrator.recordToolTrace(
          const ToolCall(
            id: 'c1',
            toolName: 'archive_message',
            arguments: <String, Object?>{'id': 1},
          ),
          const ToolResult(toolCallId: 'c1', summary: 'ok'),
        );
        expect(
          container.read(agentOrchestratorControllerProvider).traces,
          hasLength(1),
        );

        await orchestrator.planTurn(
          conversationId: 'c1',
          prompt: 'next turn',
          history: const [],
        );

        expect(
          container.read(agentOrchestratorControllerProvider).traces,
          isEmpty,
        );
      },
    );

    test('bindConversation resets state and clears any prior plan', () async {
      final container = ProviderContainer(
        overrides: [
          toolRegistryProvider.overrideWithValue(
            ToolRegistry(const <ToolDescriptor>[]),
          ),
          aiChatTransportProvider.overrideWithValue(
            _FakeTransport((_) => const Stream.empty()),
          ),
          aiSettingsProvider.overrideWith(
            () => _FakeAiSettingsController(
              settings: const AiSettings(hasApiKey: true),
              apiKey: 'token',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final orchestrator = container.read(
        agentOrchestratorControllerProvider.notifier,
      );

      orchestrator.bindConversation('conv-a');
      expect(
        container.read(agentOrchestratorControllerProvider).conversationId,
        'conv-a',
      );

      orchestrator.bindConversation('conv-b');
      final state = container.read(agentOrchestratorControllerProvider);
      expect(state.conversationId, 'conv-b');
      expect(state.currentPlan, isNull);
      expect(state.phase, AgentTurnPhase.idle);
    });
  });
}
