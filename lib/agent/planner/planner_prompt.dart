import 'dart:convert';

import '../capabilities/capability_catalog.dart';
import '../capabilities/capability_domain.dart';
import '../tools/tool_risk_tier.dart';

/// Composes the planner-facing system prompt and the plan-JSON schema
/// description. The planner only ever sees capability-level metadata —
/// domain title, purpose, example actions — never concrete tool names or
/// schemas. This guarantees tool identifiers can be renamed without
/// reshaping the planner prompt.
class PlannerPrompt {
  const PlannerPrompt._();

  /// Builds the system prompt the planner model receives.
  ///
  /// Contains: the planner's role, the catalog (as JSON), the response
  /// schema, and strict formatting rules. The prompt is deterministic
  /// for a given [catalog] so it is cache-friendly.
  static String systemPrompt(CapabilityCatalog catalog) {
    final catalogJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(serializeCatalog(catalog));
    return '''
You are the planner stage of an agent that operates a desktop productivity app.
Your job is to read the user's latest request, in context of the prior conversation,
and pick the minimal set of *capability domains* the executor stage needs to satisfy
that request. You never pick tools by name — the executor will do that.

Available capability domains (JSON):
$catalogJson

Response format — return STRICT JSON with this exact shape, and nothing else:
{
  "intent": "one short sentence paraphrasing what the user wants done",
  "domains": ["<domain-key>", ...],            // must be a subset of the domain keys above
  "rationale": "one short sentence explaining why these domains",
  "anticipated_max_risk": "read" | "prepare" | "commit" | "privileged",
  "needs_more_information": false,              // true only when the request is ambiguous
  "clarifying_question": null                   // string when needs_more_information is true
}

Rules:
- Keep "domains" minimal. If the request can be answered with plain conversation,
  return an empty "domains" array and set "anticipated_max_risk" to "read".
- "anticipated_max_risk" must be the highest tier you expect the executor to reach,
  not the ceiling of every selected domain.
- Never include tool names, tool arguments, or step-by-step plans.
- Never return prose outside the JSON object.
- If the user's intent is ambiguous, set "needs_more_information" to true and put
  a single-sentence question in "clarifying_question"; leave "domains" empty.
''';
  }

  /// Serializes [catalog] into a plain JSON map the planner can read.
  /// Only planner-facing fields are exposed; domains with no registered
  /// tools are already filtered out by [CapabilityCatalog.fromTools].
  static Map<String, Object?> serializeCatalog(CapabilityCatalog catalog) {
    return <String, Object?>{
      'domains': catalog.summaries
          .map(
            (summary) => <String, Object?>{
              'key': _domainKey(summary.domain),
              'title': summary.title,
              'purpose': summary.purpose,
              'example_actions': summary.exampleActions,
              'risk_tiers_available': summary.maxRisk
                  .map(_riskKey)
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
    };
  }

  /// Stable string key for a [CapabilityDomain], shared between the
  /// prompt and the JSON parser. Snake_case matches the executor's
  /// tool-naming convention.
  static String domainKey(CapabilityDomain domain) => _domainKey(domain);

  /// Stable string key for a [ToolRiskTier].
  static String riskKey(ToolRiskTier tier) => _riskKey(tier);

  /// Reverse lookup for [domainKey], returning `null` for unknown keys.
  static CapabilityDomain? domainFromKey(String key) {
    for (final domain in CapabilityDomain.values) {
      if (_domainKey(domain) == key) return domain;
    }
    return null;
  }

  /// Reverse lookup for [riskKey], returning `null` for unknown keys.
  static ToolRiskTier? riskFromKey(String key) {
    for (final tier in ToolRiskTier.values) {
      if (_riskKey(tier) == key) return tier;
    }
    return null;
  }
}

String _domainKey(CapabilityDomain domain) {
  switch (domain) {
    case CapabilityDomain.mailbox:
      return 'mailbox';
    case CapabilityDomain.composer:
      return 'composer';
    case CapabilityDomain.documents:
      return 'documents';
    case CapabilityDomain.todos:
      return 'todos';
    case CapabilityDomain.calendar:
      return 'calendar';
    case CapabilityDomain.accountManagement:
      return 'account_management';
    case CapabilityDomain.navigation:
      return 'navigation';
    case CapabilityDomain.system:
      return 'system';
  }
}

String _riskKey(ToolRiskTier tier) {
  switch (tier) {
    case ToolRiskTier.read:
      return 'read';
    case ToolRiskTier.prepare:
      return 'prepare';
    case ToolRiskTier.commit:
      return 'commit';
    case ToolRiskTier.privileged:
      return 'privileged';
  }
}
