import '../capabilities/capability_domain.dart';
import '../tools/tool_risk_tier.dart';

/// Output of the planner phase.
///
/// The planner never sees concrete tool names — only the capability
/// catalog — so it commits to a set of domains and an anticipated risk
/// ceiling. The executor then receives only tools whose domain is in
/// [domains] and whose risk is at most [anticipatedMaxRisk].
class AgentPlan {
  const AgentPlan({
    required this.intent,
    required this.domains,
    required this.rationale,
    required this.anticipatedMaxRisk,
    this.needsMoreInformation = false,
    this.clarifyingQuestion,
  });

  /// One-line paraphrase of what the user wants done, e.g.
  /// "Summarize and archive today's inbox".
  final String intent;

  /// Domains the executor should activate for this turn.
  final Set<CapabilityDomain> domains;

  /// Short explanation of why this plan was chosen; may be shown to the
  /// user behind a "show reasoning" toggle.
  final String rationale;

  /// Upper-bound risk the planner expects this turn to require.
  final ToolRiskTier anticipatedMaxRisk;

  /// When true, the orchestrator should ask [clarifyingQuestion] before
  /// handing off to the executor.
  final bool needsMoreInformation;
  final String? clarifyingQuestion;
}
