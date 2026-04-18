import '../tools/tool_risk_tier.dart';
import 'capability_domain.dart';

/// Planner-facing description of a single domain.
///
/// Contains only natural-language hints — never tool names or schemas.
/// The planner uses these to decide which domains should be activated
/// for a given user prompt.
class CapabilitySummary {
  const CapabilitySummary({
    required this.domain,
    required this.title,
    required this.purpose,
    required this.exampleActions,
    required this.maxRisk,
  });

  final CapabilityDomain domain;
  final String title;
  final String purpose;
  final List<String> exampleActions;
  final Set<ToolRiskTier> maxRisk;
}
