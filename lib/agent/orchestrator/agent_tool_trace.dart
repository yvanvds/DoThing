import '../tools/tool_risk_tier.dart';

/// After-the-fact record of a commit or privileged tool invocation,
/// rendered in the chat sidecar so users can see what the agent did.
///
/// Traces are turn-scoped: they accumulate during an agent turn and are
/// cleared when the next turn's planner runs. Read and prepare tiers do
/// not produce traces — they stay silent by design.
class AgentToolTrace {
  const AgentToolTrace({
    required this.id,
    required this.toolName,
    required this.label,
    required this.risk,
    required this.isError,
    required this.canceled,
    required this.createdAt,
    this.detail,
  });

  /// Matches the [ToolCall.id] that produced this trace. Used by the UI
  /// as a stable key.
  final String id;

  /// Snake-case tool identifier (matches [ToolDescriptor.name]).
  final String toolName;

  /// Human-readable one-liner. Falls back to [toolName] when the tool
  /// has no [ToolDescriptor.humanPreview].
  final String label;

  final ToolRiskTier risk;

  /// True when the tool handler raised or otherwise returned an error
  /// result (other than user cancellation — see [canceled]).
  final bool isError;

  /// True when the invocation was rejected by the confirmation gate
  /// rather than executed. Rendered differently than a handler error.
  final bool canceled;

  /// Optional terse summary from [ToolResult.summary]. Shown as a
  /// secondary line on the trace card.
  final String? detail;

  final DateTime createdAt;
}
