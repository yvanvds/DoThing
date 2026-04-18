/// How risky the invocation of a tool is, and therefore how the
/// orchestrator should surface or gate it in the chat UI.
///
/// The executor consults this to decide whether to auto-invoke, surface a
/// trace card, or pause for user confirmation.
enum ToolRiskTier {
  /// Pure reads, no side effects. Run silently.
  read,

  /// Mutates transient UI state only (drafts, panels). Run silently.
  prepare,

  /// Writes to an external system with normal-risk side effects.
  /// Auto-invoked, but surfaced as a trace card in the transcript.
  commit,

  /// Destructive or administrative actions. Always require confirmation.
  privileged,
}

extension ToolRiskTierX on ToolRiskTier {
  /// Whether this tier requires an explicit user confirmation step
  /// before the executor invokes the tool.
  bool get requiresConfirmation => this == ToolRiskTier.privileged;

  /// Whether this tier should render an after-the-fact trace card in
  /// the chat transcript.
  bool get emitsTraceCard =>
      this == ToolRiskTier.commit || this == ToolRiskTier.privileged;
}
