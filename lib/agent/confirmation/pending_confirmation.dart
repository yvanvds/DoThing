import '../tools/tool_descriptor.dart';
import '../tools/tool_risk_tier.dart';

/// Snapshot of a tool call the executor has paused on, awaiting the
/// user's Confirm / Cancel decision.
///
/// Rendered in chat via a confirmation card. On Confirm the orchestrator
/// resumes by invoking [descriptor] with [arguments]; on Cancel a
/// synthetic canceled [ToolResult] is injected and the model is allowed
/// to continue or abandon.
class PendingConfirmation {
  const PendingConfirmation({
    required this.id,
    required this.descriptor,
    required this.arguments,
    required this.humanPreview,
    required this.risk,
    this.reason,
  });

  /// Matches the [ToolCall.id] that triggered this pause.
  final String id;

  final ToolDescriptor descriptor;
  final Map<String, Object?> arguments;

  /// Human-readable one-liner shown at the top of the confirmation
  /// card, typically produced by [ToolDescriptor.humanPreview].
  final String humanPreview;

  final ToolRiskTier risk;

  /// Optional free-form justification surfaced by the model alongside
  /// the tool call.
  final String? reason;
}
