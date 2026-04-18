import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tools/tool_descriptor.dart';
import '../tools/tool_registry.dart';
import 'capability_domain.dart';
import 'capability_summary.dart';

/// Hand-authored, planner-facing metadata for a domain.
///
/// Purpose and exampleActions are the only cues the planner receives —
/// tool names and schemas are deliberately withheld so the planner picks
/// *domains*, never tools.
class _CapabilityDomainMeta {
  const _CapabilityDomainMeta({
    required this.title,
    required this.purpose,
    required this.exampleActions,
  });

  final String title;
  final String purpose;
  final List<String> exampleActions;
}

const Map<CapabilityDomain, _CapabilityDomainMeta> _domainMetadata = {
  CapabilityDomain.mailbox: _CapabilityDomainMeta(
    title: 'Mailbox',
    purpose:
        'Read, triage, and dispatch email and Smartschool messages in the '
        'user\'s inbox.',
    exampleActions: [
      'list recent inbox headers',
      'mark a message as read or unread',
      'archive a message',
      'delete a message',
      'send an email',
    ],
  ),
  CapabilityDomain.composer: _CapabilityDomainMeta(
    title: 'Composer',
    purpose:
        'Prepare a draft message in the composer panel (reply, forward, '
        'new). Does not send.',
    exampleActions: [
      'open a blank composer',
      'prefill a reply to the selected message',
      'prefill a forward of the selected message',
    ],
  ),
  CapabilityDomain.navigation: _CapabilityDomainMeta(
    title: 'Navigation',
    purpose: 'Switch which panel is shown on the right-hand side of the app.',
    exampleActions: [
      'open the messages panel',
      'open the chat history panel',
      'open the settings panel',
    ],
  ),
  CapabilityDomain.documents: _CapabilityDomainMeta(
    title: 'Documents',
    purpose: 'Reserved for document management. No tools yet.',
    exampleActions: [],
  ),
  CapabilityDomain.todos: _CapabilityDomainMeta(
    title: 'Todos',
    purpose: 'Reserved for task / todo management. No tools yet.',
    exampleActions: [],
  ),
  CapabilityDomain.calendar: _CapabilityDomainMeta(
    title: 'Calendar',
    purpose: 'Reserved for calendar operations. No tools yet.',
    exampleActions: [],
  ),
  CapabilityDomain.accountManagement: _CapabilityDomainMeta(
    title: 'Account management',
    purpose:
        'Reserved for administrative user-account operations. No tools yet.',
    exampleActions: [],
  ),
  CapabilityDomain.system: _CapabilityDomainMeta(
    title: 'System',
    purpose: 'Reserved for app-level diagnostics. No tools yet.',
    exampleActions: [],
  ),
};

/// Assembles planner-facing [CapabilitySummary]s from the registered tools.
///
/// The catalog includes exactly those domains that contain at least one
/// registered tool. Each summary's [CapabilitySummary.maxRisk] is derived
/// from the risk tiers actually reached by the tools in that domain —
/// never higher than the [capabilityDomainRiskCeiling] (which is enforced
/// by [ToolRegistry] at construction time).
class CapabilityCatalog {
  const CapabilityCatalog(this.summaries);

  /// Builds the catalog from [tools], keeping one summary per domain that
  /// has at least one tool. Domains without tools are omitted so the
  /// planner is never tempted to select an empty capability.
  factory CapabilityCatalog.fromTools(List<ToolDescriptor> tools) {
    final toolsByDomain = <CapabilityDomain, List<ToolDescriptor>>{};
    for (final tool in tools) {
      toolsByDomain.putIfAbsent(tool.domain, () => []).add(tool);
    }

    final summaries = <CapabilitySummary>[];
    for (final domain in CapabilityDomain.values) {
      final domainTools = toolsByDomain[domain];
      if (domainTools == null || domainTools.isEmpty) continue;
      final meta = _domainMetadata[domain];
      if (meta == null) continue;

      summaries.add(
        CapabilitySummary(
          domain: domain,
          title: meta.title,
          purpose: meta.purpose,
          exampleActions: meta.exampleActions,
          maxRisk: domainTools.map((t) => t.risk).toSet(),
        ),
      );
    }

    return CapabilityCatalog(summaries);
  }

  final List<CapabilitySummary> summaries;

  /// Returns the summary for [domain], or `null` when that domain has no
  /// tools registered.
  CapabilitySummary? byDomain(CapabilityDomain domain) {
    for (final summary in summaries) {
      if (summary.domain == domain) return summary;
    }
    return null;
  }
}

/// Provides the app-wide [CapabilityCatalog], derived from the current
/// [ToolRegistry]. This is what the planner consumes.
final capabilityCatalogProvider = Provider<CapabilityCatalog>((ref) {
  final registry = ref.watch(toolRegistryProvider);
  return CapabilityCatalog.fromTools(registry.all);
});
