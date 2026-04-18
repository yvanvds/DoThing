import '../tools/tool_risk_tier.dart';

/// High-level area of the app the agent can operate in.
///
/// Domains are the only vocabulary the planner sees; it never picks
/// concrete tools. The orchestrator maps the planner's chosen domains to
/// a bounded set of tools for the executor.
enum CapabilityDomain {
  mailbox,
  composer,
  documents,
  todos,
  calendar,
  accountManagement,
  navigation,
  system,
}

/// Maximum risk tier a given domain is allowed to reach.
///
/// Enforced at registry construction time, independent of what the model
/// requests. A domain cannot grow a higher-risk tool later without the
/// ceiling also being lifted here.
const Map<CapabilityDomain, ToolRiskTier> capabilityDomainRiskCeiling = {
  CapabilityDomain.mailbox: ToolRiskTier.privileged,
  CapabilityDomain.composer: ToolRiskTier.commit,
  CapabilityDomain.documents: ToolRiskTier.commit,
  CapabilityDomain.todos: ToolRiskTier.commit,
  CapabilityDomain.calendar: ToolRiskTier.commit,
  CapabilityDomain.accountManagement: ToolRiskTier.privileged,
  CapabilityDomain.navigation: ToolRiskTier.prepare,
  CapabilityDomain.system: ToolRiskTier.read,
};
