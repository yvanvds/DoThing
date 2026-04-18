import '../confirmation/pending_confirmation.dart';
import '../executor/tool_call.dart';
import '../planner/agent_plan.dart';
import 'agent_tool_trace.dart';

/// Phase of the agent loop for the conversation currently being observed
/// by the orchestrator. Expands in Phase 4+ with executor states.
enum AgentTurnPhase {
  /// No agent work underway. The conversation is either fresh or at rest.
  idle,

  /// Planner call is in flight.
  planning,

  /// Planner returned a plan and the orchestrator is preparing the
  /// executor (or — in Phase 3 — passing through to plain chat).
  planned,

  /// Executor is running the tool loop for the active plan.
  executing,

  /// Executor is paused on a privileged tool call; waiting for the user
  /// to Confirm or Cancel via [AgentConfirmationCard].
  awaitingConfirmation,

  /// Planner failed; orchestrator fell back to plain chat.
  plannerFailed,

  /// Planner asked for a clarification; awaiting the user's next input.
  awaitingClarification,
}

/// Snapshot of the orchestrator's per-conversation state.
///
/// Kept deliberately small for Phase 3 — only the plan and phase are in
/// use. [pending] and [toolCallsInTurn] are reserved for Phases 4–5 so
/// the shape doesn't need to change again then.
class AgentTurnState {
  const AgentTurnState({
    required this.conversationId,
    this.phase = AgentTurnPhase.idle,
    this.currentPlan,
    this.pending,
    this.toolCallsInTurn = const <ToolCall>[],
    this.traces = const <AgentToolTrace>[],
    this.lastPlannerError,
  });

  final String conversationId;
  final AgentTurnPhase phase;
  final AgentPlan? currentPlan;
  final PendingConfirmation? pending;
  final List<ToolCall> toolCallsInTurn;

  /// Commit/privileged tool invocations recorded during the active turn,
  /// surfaced above the chat via the trace sidecar. Cleared at the start
  /// of each new planner turn and on [bindConversation].
  final List<AgentToolTrace> traces;

  /// Short diagnostic from the last planner failure, surfaced in the
  /// status terminal. `null` when the last plan succeeded or none ran.
  final String? lastPlannerError;

  AgentTurnState copyWith({
    AgentTurnPhase? phase,
    AgentPlan? currentPlan,
    bool clearPlan = false,
    PendingConfirmation? pending,
    bool clearPending = false,
    List<ToolCall>? toolCallsInTurn,
    List<AgentToolTrace>? traces,
    bool clearTraces = false,
    String? lastPlannerError,
    bool clearPlannerError = false,
  }) {
    return AgentTurnState(
      conversationId: conversationId,
      phase: phase ?? this.phase,
      currentPlan: clearPlan ? null : (currentPlan ?? this.currentPlan),
      pending: clearPending ? null : (pending ?? this.pending),
      toolCallsInTurn: toolCallsInTurn ?? this.toolCallsInTurn,
      traces: clearTraces
          ? const <AgentToolTrace>[]
          : (traces ?? this.traces),
      lastPlannerError: clearPlannerError
          ? null
          : (lastPlannerError ?? this.lastPlannerError),
    );
  }
}
