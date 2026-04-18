import 'package:do_thing/agent/capabilities/capability_domain.dart';
import 'package:do_thing/agent/executor/tool_result.dart';
import 'package:do_thing/agent/tools/tool_argument_schema.dart';
import 'package:do_thing/agent/tools/tool_descriptor.dart';
import 'package:do_thing/agent/tools/tool_mode.dart';
import 'package:do_thing/agent/tools/tool_registry.dart';
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
  group('ToolRegistry', () {
    test('indexes tools by name and exposes them all', () {
      final registry = ToolRegistry([
        _stub(
          name: 'alpha',
          domain: CapabilityDomain.mailbox,
          risk: ToolRiskTier.read,
        ),
        _stub(
          name: 'bravo',
          domain: CapabilityDomain.navigation,
          risk: ToolRiskTier.prepare,
        ),
      ]);

      expect(registry.all.map((t) => t.name), ['alpha', 'bravo']);
      expect(registry.byName('alpha')?.domain, CapabilityDomain.mailbox);
      expect(registry.byName('missing'), isNull);
    });

    test('forDomains returns only tools in the requested domains', () {
      final registry = ToolRegistry([
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
        _stub(
          name: 'c_draft',
          domain: CapabilityDomain.composer,
          risk: ToolRiskTier.prepare,
        ),
      ]);

      final subset = registry.forDomains({
        CapabilityDomain.mailbox,
        CapabilityDomain.composer,
      });

      expect(subset.map((t) => t.name).toSet(), {'m_read', 'c_draft'});
    });

    test('forDomains returns empty list for empty domain set', () {
      final registry = ToolRegistry([
        _stub(
          name: 'only',
          domain: CapabilityDomain.mailbox,
          risk: ToolRiskTier.read,
        ),
      ]);

      expect(registry.forDomains(const {}), isEmpty);
    });

    test('rejects duplicate tool names at construction time', () {
      expect(
        () => ToolRegistry([
          _stub(
            name: 'dup',
            domain: CapabilityDomain.mailbox,
            risk: ToolRiskTier.read,
          ),
          _stub(
            name: 'dup',
            domain: CapabilityDomain.mailbox,
            risk: ToolRiskTier.read,
          ),
        ]),
        throwsA(isA<ToolRegistryConfigurationError>()),
      );
    });

    test('rejects a tool whose risk exceeds the domain ceiling', () {
      // Navigation has a ceiling of `prepare`; a `commit` tool is invalid.
      expect(
        () => ToolRegistry([
          _stub(
            name: 'bad',
            domain: CapabilityDomain.navigation,
            risk: ToolRiskTier.commit,
          ),
        ]),
        throwsA(isA<ToolRegistryConfigurationError>()),
      );
    });

    test('hasRisk reflects actual tools present', () {
      final registry = ToolRegistry([
        _stub(
          name: 'm',
          domain: CapabilityDomain.mailbox,
          risk: ToolRiskTier.privileged,
        ),
      ]);

      expect(registry.hasRisk(ToolRiskTier.privileged), isTrue);
      expect(registry.hasRisk(ToolRiskTier.prepare), isFalse);
    });

    test('default buildToolRegistry produces a valid registry', () {
      final registry = ToolRegistry(buildToolRegistry());

      expect(registry.byName('list_inbox_headers'), isNotNull);
      expect(registry.byName('open_messages_panel'), isNotNull);
      expect(registry.byName('open_new_composer'), isNotNull);
      expect(registry.byName('delete_message')?.risk, ToolRiskTier.privileged);
      expect(
        registry.byName('send_outlook_message')?.domain,
        CapabilityDomain.mailbox,
      );
    });
  });
}
