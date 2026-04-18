import 'package:do_thing/agent/capabilities/capability_domain.dart';
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

    test('produces a markdown preamble when the planner returns a plan',
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
      expect(outcome.preamble, contains('**Plan:** triage inbox'));
      expect(outcome.preamble, contains('mailbox'));
      expect(outcome.preamble, endsWith('\n\n---\n\n'));

      final state = container.read(agentOrchestratorControllerProvider);
      expect(state.phase, AgentTurnPhase.planned);
      expect(state.currentPlan?.intent, 'triage inbox');
    });

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
