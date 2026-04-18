import 'tool_confirmation_decision.dart';
import '../executor/tool_call.dart';

/// Policy callback invoked by the executor before each tool invocation.
///
/// Implementations decide — based on the tool's risk tier and any UI
/// state — whether the call should proceed, be denied, or be paused
/// pending a user confirmation. The executor stays policy-free: it simply
/// awaits the returned decision and then either invokes the tool or
/// feeds a canceled [ToolResult] back to the model.
typedef ToolConfirmationGate =
    Future<ConfirmationDecision> Function(ToolCall call);
