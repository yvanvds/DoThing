import 'package:do_thing/agent/capabilities/capability_catalog.dart';
import 'package:do_thing/agent/capabilities/capability_domain.dart';
import 'package:do_thing/agent/capabilities/capability_summary.dart';
import 'package:do_thing/agent/executor/tool_result.dart';
import 'package:do_thing/agent/planner/agent_planner_service.dart';
import 'package:do_thing/agent/tools/tool_argument_schema.dart';
import 'package:do_thing/agent/tools/tool_descriptor.dart';
import 'package:do_thing/agent/tools/tool_mode.dart';
import 'package:do_thing/agent/tools/tool_risk_tier.dart';
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

ToolDescriptor _stub({
  required String name,
  required CapabilityDomain domain,
  required ToolRiskTier risk,
}) {
  return ToolDescriptor(
    name: name,
    description: name,
    domain: domain,
    mode: ToolMode.read,
    risk: risk,
    arguments: ToolArgumentSchema.empty,
    invoke: (_, _) async => ToolResult(toolCallId: '', summary: name),
  );
}

CapabilityCatalog _catalogWithMailboxAndNav() {
  return CapabilityCatalog.fromTools([
    _stub(
      name: 'm_read',
      domain: CapabilityDomain.mailbox,
      risk: ToolRiskTier.read,
    ),
    _stub(
      name: 'nav_open',
      domain: CapabilityDomain.navigation,
      risk: ToolRiskTier.prepare,
    ),
  ]);
}

Stream<AiStreamEvent> _oneShotText(String text) async* {
  yield AiStreamEvent.delta(text);
  yield const AiStreamEvent.done();
}

ProviderContainer _containerWith(_FakeTransport transport) {
  final container = ProviderContainer(
    overrides: [aiChatTransportProvider.overrideWithValue(transport)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('AgentPlannerService.plan', () {
    test('returns a trivially-empty plan when the catalog is empty', () async {
      final transport = _FakeTransport((_) => const Stream.empty());
      final container = _containerWith(transport);
      final service = container.read(agentPlannerServiceProvider);

      final result = await service.plan(
        prompt: 'hello',
        history: const [],
        catalog: const CapabilityCatalog(<CapabilitySummary>[]),
        model: 'm',
        apiKey: 'k',
        baseUrl: 'https://x',
      );

      expect(result.isSuccess, isTrue);
      expect(result.plan!.domains, isEmpty);
      expect(transport.requests, isEmpty,
          reason: 'empty catalog must skip the transport call');
    });

    test('parses a well-formed JSON plan from the model', () async {
      final transport = _FakeTransport(
        (_) => _oneShotText(
          '{"intent":"open inbox",'
          '"domains":["mailbox","navigation"],'
          '"rationale":"user asked to triage",'
          '"anticipated_max_risk":"commit",'
          '"needs_more_information":false,'
          '"clarifying_question":null}',
        ),
      );
      final container = _containerWith(transport);
      final service = container.read(agentPlannerServiceProvider);

      final result = await service.plan(
        prompt: 'open my inbox',
        history: const [],
        catalog: _catalogWithMailboxAndNav(),
        model: 'm',
        apiKey: 'k',
        baseUrl: 'https://x',
      );

      expect(result.isSuccess, isTrue);
      final plan = result.plan!;
      expect(plan.intent, 'open inbox');
      expect(plan.domains, {
        CapabilityDomain.mailbox,
        CapabilityDomain.navigation,
      });
      expect(plan.anticipatedMaxRisk, ToolRiskTier.commit);
      expect(plan.needsMoreInformation, isFalse);
      expect(plan.clarifyingQuestion, isNull);

      // Planner request must be non-streaming + JSON object + no tools.
      expect(transport.requests.length, 1);
      final req = transport.requests.first;
      expect(req.stream, isFalse);
      expect(req.jsonObjectResponse, isTrue);
      expect(req.tools, isEmpty);
      expect(req.messages.first.role, AiMessageRole.system);
      expect(req.messages.last.role, AiMessageRole.user);
      expect(req.messages.last.content, 'open my inbox');
    });

    test('tolerates fenced code-block wrappers around the JSON', () async {
      final transport = _FakeTransport(
        (_) => _oneShotText(
          '```json\n'
          '{"intent":"x","domains":[],'
          '"rationale":"","anticipated_max_risk":"read",'
          '"needs_more_information":false}\n'
          '```',
        ),
      );
      final container = _containerWith(transport);
      final service = container.read(agentPlannerServiceProvider);

      final result = await service.plan(
        prompt: 'chat only',
        history: const [],
        catalog: _catalogWithMailboxAndNav(),
        model: 'm',
        apiKey: 'k',
        baseUrl: 'https://x',
      );

      expect(result.isSuccess, isTrue);
      expect(result.plan!.intent, 'x');
      expect(result.plan!.domains, isEmpty);
      expect(result.plan!.anticipatedMaxRisk, ToolRiskTier.read);
    });

    test('silently drops unknown domain keys', () async {
      final transport = _FakeTransport(
        (_) => _oneShotText(
          '{"intent":"y","domains":["mailbox","mystery"],'
          '"rationale":"","anticipated_max_risk":"read",'
          '"needs_more_information":false}',
        ),
      );
      final container = _containerWith(transport);
      final service = container.read(agentPlannerServiceProvider);

      final result = await service.plan(
        prompt: 'p',
        history: const [],
        catalog: _catalogWithMailboxAndNav(),
        model: 'm',
        apiKey: 'k',
        baseUrl: 'https://x',
      );

      expect(result.isSuccess, isTrue);
      expect(result.plan!.domains, {CapabilityDomain.mailbox});
    });

    test('returns a schema_violation failure when intent is missing', () async {
      final transport = _FakeTransport(
        (_) => _oneShotText('{"domains":[],"anticipated_max_risk":"read"}'),
      );
      final container = _containerWith(transport);
      final service = container.read(agentPlannerServiceProvider);

      final result = await service.plan(
        prompt: 'p',
        history: const [],
        catalog: _catalogWithMailboxAndNav(),
        model: 'm',
        apiKey: 'k',
        baseUrl: 'https://x',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, 'schema_violation');
    });

    test('returns a json_parse_error failure when the model returns prose',
        () async {
      final transport = _FakeTransport(
        (_) => _oneShotText('Sorry, I cannot comply.'),
      );
      final container = _containerWith(transport);
      final service = container.read(agentPlannerServiceProvider);

      final result = await service.plan(
        prompt: 'p',
        history: const [],
        catalog: _catalogWithMailboxAndNav(),
        model: 'm',
        apiKey: 'k',
        baseUrl: 'https://x',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, 'json_parse_error');
      expect(result.rawResponse, 'Sorry, I cannot comply.');
    });

    test('forwards a transport_error when the stream emits an error event',
        () async {
      final transport = _FakeTransport(
        (_) => Stream.fromIterable(const [
          AiStreamEvent.error(
            AiErrorState(code: 'http_500', message: 'upstream'),
          ),
        ]),
      );
      final container = _containerWith(transport);
      final service = container.read(agentPlannerServiceProvider);

      final result = await service.plan(
        prompt: 'p',
        history: const [],
        catalog: _catalogWithMailboxAndNav(),
        model: 'm',
        apiKey: 'k',
        baseUrl: 'https://x',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('http_500'));
    });

    test('accepts a clarifying question even when intent is empty', () async {
      final transport = _FakeTransport(
        (_) => _oneShotText(
          '{"intent":"","domains":[],"rationale":"",'
          '"anticipated_max_risk":"read",'
          '"needs_more_information":true,'
          '"clarifying_question":"Which inbox?"}',
        ),
      );
      final container = _containerWith(transport);
      final service = container.read(agentPlannerServiceProvider);

      final result = await service.plan(
        prompt: 'triage',
        history: const [],
        catalog: _catalogWithMailboxAndNav(),
        model: 'm',
        apiKey: 'k',
        baseUrl: 'https://x',
      );

      expect(result.isSuccess, isTrue);
      expect(result.plan!.needsMoreInformation, isTrue);
      expect(result.plan!.clarifyingQuestion, 'Which inbox?');
    });
  });
}

