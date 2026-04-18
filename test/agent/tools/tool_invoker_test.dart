import 'package:do_thing/agent/capabilities/capability_domain.dart';
import 'package:do_thing/agent/executor/tool_call.dart';
import 'package:do_thing/agent/executor/tool_result.dart';
import 'package:do_thing/agent/tools/tool_argument_schema.dart';
import 'package:do_thing/agent/tools/tool_descriptor.dart';
import 'package:do_thing/agent/tools/tool_invoker.dart';
import 'package:do_thing/agent/tools/tool_mode.dart';
import 'package:do_thing/agent/tools/tool_registry.dart';
import 'package:do_thing/agent/tools/tool_risk_tier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ToolDescriptor _echoTool() {
  return ToolDescriptor(
    name: 'echo',
    description: 'echo the provided message back',
    domain: CapabilityDomain.mailbox,
    mode: ToolMode.read,
    risk: ToolRiskTier.read,
    arguments: const ToolArgumentSchema(<String, Object?>{
      'type': 'object',
      'required': ['message'],
      'properties': <String, Object?>{
        'message': <String, Object?>{'type': 'string'},
      },
    }),
    invoke: (_, args) async => ToolResult(
      toolCallId: '',
      summary: 'echoed ${args['message']}',
      structured: <String, Object?>{'echoed': args['message']},
    ),
  );
}

ToolDescriptor _boomTool() {
  return ToolDescriptor(
    name: 'boom',
    description: 'throws on purpose',
    domain: CapabilityDomain.mailbox,
    mode: ToolMode.read,
    risk: ToolRiskTier.read,
    arguments: ToolArgumentSchema.empty,
    invoke: (_, _) async => throw StateError('kaboom'),
  );
}

void main() {
  late List<ProviderContainer> disposables;

  setUp(() {
    disposables = [];
  });

  tearDown(() {
    for (final c in disposables) {
      c.dispose();
    }
  });

  ToolInvoker makeInvoker(List<ToolDescriptor> tools) {
    final container = ProviderContainer(
      overrides: [
        toolRegistryProvider.overrideWithValue(ToolRegistry(tools)),
      ],
    );
    disposables.add(container);
    return container.read(toolInvokerProvider);
  }

  test('successful invocation stamps the tool call id onto the result', () async {
    final invoker = makeInvoker([_echoTool()]);

    final result = await invoker.invoke(
      const ToolCall(
        id: 'call_42',
        toolName: 'echo',
        arguments: <String, Object?>{'message': 'hi'},
      ),
    );

    expect(result.isError, isFalse);
    expect(result.toolCallId, 'call_42');
    expect(result.summary, 'echoed hi');
    expect(result.structured?['echoed'], 'hi');
  });

  test('unknown tool name produces an error result, never throws', () async {
    final invoker = makeInvoker([_echoTool()]);

    final result = await invoker.invoke(
      const ToolCall(id: 'call_1', toolName: 'missing', arguments: {}),
    );

    expect(result.isError, isTrue);
    expect(result.toolCallId, 'call_1');
    expect(result.summary, contains('Unknown tool'));
  });

  test('invalid arguments short-circuit with a structured validation error',
      () async {
    final invoker = makeInvoker([_echoTool()]);

    final result = await invoker.invoke(
      const ToolCall(
        id: 'call_2',
        toolName: 'echo',
        arguments: <String, Object?>{},
      ),
    );

    expect(result.isError, isTrue);
    expect(result.toolCallId, 'call_2');
    expect(result.structured?['validation'], isA<Map<String, Object?>>());
    final validation = result.structured!['validation'] as Map<String, Object?>;
    expect(validation['code'], 'missing_required');
  });

  test('handler exceptions are captured as error tool results', () async {
    final invoker = makeInvoker([_boomTool()]);

    final result = await invoker.invoke(
      const ToolCall(id: 'call_3', toolName: 'boom', arguments: {}),
    );

    expect(result.isError, isTrue);
    expect(result.toolCallId, 'call_3');
    expect(result.summary, contains('kaboom'));
  });
}
