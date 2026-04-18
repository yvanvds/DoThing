import 'dart:convert';

import 'package:do_thing/agent/capabilities/capability_catalog.dart';
import 'package:do_thing/agent/capabilities/capability_domain.dart';
import 'package:do_thing/agent/executor/tool_result.dart';
import 'package:do_thing/agent/planner/planner_prompt.dart';
import 'package:do_thing/agent/tools/tool_argument_schema.dart';
import 'package:do_thing/agent/tools/tool_descriptor.dart';
import 'package:do_thing/agent/tools/tool_mode.dart';
import 'package:do_thing/agent/tools/tool_risk_tier.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  group('PlannerPrompt key roundtrips', () {
    test('every CapabilityDomain has a key that roundtrips', () {
      for (final domain in CapabilityDomain.values) {
        final key = PlannerPrompt.domainKey(domain);
        expect(key, isNotEmpty);
        expect(PlannerPrompt.domainFromKey(key), domain);
      }
    });

    test('every ToolRiskTier has a key that roundtrips', () {
      for (final tier in ToolRiskTier.values) {
        final key = PlannerPrompt.riskKey(tier);
        expect(key, isNotEmpty);
        expect(PlannerPrompt.riskFromKey(key), tier);
      }
    });

    test('unknown keys return null from reverse lookups', () {
      expect(PlannerPrompt.domainFromKey('nonsense'), isNull);
      expect(PlannerPrompt.riskFromKey('ludicrous'), isNull);
    });
  });

  group('PlannerPrompt.serializeCatalog', () {
    test('emits one entry per catalog summary with planner-facing fields only',
        () {
      final catalog = CapabilityCatalog.fromTools([
        _stub(
          name: 'm_read',
          domain: CapabilityDomain.mailbox,
          risk: ToolRiskTier.read,
        ),
        _stub(
          name: 'm_commit',
          domain: CapabilityDomain.mailbox,
          risk: ToolRiskTier.commit,
        ),
        _stub(
          name: 'nav_open',
          domain: CapabilityDomain.navigation,
          risk: ToolRiskTier.prepare,
        ),
      ]);

      final json = PlannerPrompt.serializeCatalog(catalog);
      final domains = json['domains'] as List<dynamic>;
      expect(domains.length, 2);

      final mailbox = domains.firstWhere(
        (e) => (e as Map<String, Object?>)['key'] == 'mailbox',
      ) as Map<String, Object?>;
      expect(mailbox['title'], 'Mailbox');
      expect(mailbox['purpose'], isNotNull);
      expect(mailbox['example_actions'], isA<List<dynamic>>());
      expect(mailbox['risk_tiers_available'], containsAll(['read', 'commit']));

      // Must not leak any tool names.
      final serialized = jsonEncode(json);
      expect(serialized.contains('m_read'), isFalse);
      expect(serialized.contains('m_commit'), isFalse);
      expect(serialized.contains('nav_open'), isFalse);
    });
  });

  group('PlannerPrompt.systemPrompt', () {
    test('embeds the catalog JSON and the response schema', () {
      final catalog = CapabilityCatalog.fromTools([
        _stub(
          name: 'x',
          domain: CapabilityDomain.navigation,
          risk: ToolRiskTier.prepare,
        ),
      ]);

      final prompt = PlannerPrompt.systemPrompt(catalog);

      expect(prompt, contains('"key": "navigation"'));
      expect(prompt, contains('"domains"'));
      expect(prompt, contains('"anticipated_max_risk"'));
      expect(prompt, contains('"clarifying_question"'));
      // Risk tiers must all be documented so the model learns the vocabulary.
      expect(prompt, contains('read'));
      expect(prompt, contains('prepare'));
      expect(prompt, contains('commit'));
      expect(prompt, contains('privileged'));
      // Must NOT leak tool names.
      expect(prompt.contains('"x"'), isFalse);
    });
  });
}
