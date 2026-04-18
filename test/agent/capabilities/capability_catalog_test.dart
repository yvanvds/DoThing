import 'package:do_thing/agent/capabilities/capability_catalog.dart';
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
  group('CapabilityCatalog.fromTools', () {
    test('emits one summary per domain that has tools, and none otherwise',
        () {
      final tools = [
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
      ];

      final catalog = CapabilityCatalog.fromTools(tools);

      final domains = catalog.summaries.map((s) => s.domain).toSet();
      expect(domains, {
        CapabilityDomain.mailbox,
        CapabilityDomain.navigation,
      });
      expect(catalog.byDomain(CapabilityDomain.composer), isNull);
    });

    test('summary maxRisk reflects the distinct tiers reached by tools', () {
      final tools = [
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
          name: 'm_priv',
          domain: CapabilityDomain.mailbox,
          risk: ToolRiskTier.privileged,
        ),
      ];

      final catalog = CapabilityCatalog.fromTools(tools);
      final mailbox = catalog.byDomain(CapabilityDomain.mailbox);

      expect(mailbox, isNotNull);
      expect(mailbox!.maxRisk, {
        ToolRiskTier.read,
        ToolRiskTier.commit,
        ToolRiskTier.privileged,
      });
    });

    test('default app registry produces a catalog covering expected domains',
        () {
      final registry = ToolRegistry(buildToolRegistry());
      final catalog = CapabilityCatalog.fromTools(registry.all);

      final domains = catalog.summaries.map((s) => s.domain).toSet();
      expect(domains, contains(CapabilityDomain.mailbox));
      expect(domains, contains(CapabilityDomain.navigation));
      expect(domains, contains(CapabilityDomain.composer));
      expect(catalog.byDomain(CapabilityDomain.mailbox)?.title, 'Mailbox');
    });
  });
}
