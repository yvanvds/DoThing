import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/ai/ai_settings_controller.dart';
import '../../controllers/status_controller.dart';
import '../../models/ai/ai_chat_models.dart';
import '../../models/ai/ai_settings.dart';
import '../capabilities/capability_catalog.dart';
import '../planner/agent_plan.dart';
import '../planner/agent_planner_service.dart';
import '../planner/planner_prompt.dart';
import '../tools/tool_descriptor.dart';
import '../tools/tool_registry.dart';
import '../tools/tool_risk_tier.dart';
import 'agent_turn_state.dart';

/// Return value of [AgentOrchestratorController.planTurn]. Tells the
/// caller whether the planner produced a usable plan, and provides the
/// text the caller can seed the assistant message with.
class PlannerOutcome {
  const PlannerOutcome({
    required this.plan,
    required this.preamble,
    required this.error,
  });

  /// The parsed plan, or `null` when the planner failed or was skipped.
  final AgentPlan? plan;

  /// Markdown snippet to prepend to the assistant message. Empty when
  /// the plan carried nothing worth surfacing (e.g. pure chat).
  final String preamble;

  /// Short diagnostic when the planner failed, surfaced in the status
  /// terminal. `null` on success or skip.
  final String? error;

  bool get didPlan => plan != null;
}

/// Per-conversation agent state machine. In Phase 3 it owns:
///   * the current plan (set each turn),
///   * the phase (idle → planning → planned / plannerFailed),
///   * a short preamble to seed into the assistant message.
///
/// Phase 4 wires this to the executor; Phase 5 adds pending-confirmation
/// handling. Splitting it out now avoids bloating [AiChatController].
class AgentOrchestratorController extends Notifier<AgentTurnState> {
  @override
  AgentTurnState build() {
    return const AgentTurnState(conversationId: '');
  }

  /// Binds the orchestrator to a different conversation, resetting all
  /// per-turn state. Called by [AiChatController] when the user opens,
  /// creates, or switches to a conversation.
  void bindConversation(String conversationId) {
    state = AgentTurnState(conversationId: conversationId);
  }

  /// Runs the planner for [prompt]. On success returns a [PlannerOutcome]
  /// with a usable plan and a markdown preamble. On failure returns an
  /// outcome with a `null` plan — [AiChatController] should fall through
  /// to plain chat in that case.
  Future<PlannerOutcome> planTurn({
    required String conversationId,
    required String prompt,
    required List<AiChatMessageModel> history,
  }) async {
    if (state.conversationId != conversationId) {
      state = AgentTurnState(conversationId: conversationId);
    }

    final catalog = ref.read(capabilityCatalogProvider);
    if (catalog.summaries.isEmpty) {
      state = state.copyWith(
        phase: AgentTurnPhase.idle,
        clearPlan: true,
        clearPlannerError: true,
      );
      return const PlannerOutcome(plan: null, preamble: '', error: null);
    }

    state = state.copyWith(
      phase: AgentTurnPhase.planning,
      clearPlan: true,
      clearPlannerError: true,
    );

    final settings = await ref.read(aiSettingsProvider.future);
    if (!settings.hasApiKey) {
      state = state.copyWith(
        phase: AgentTurnPhase.plannerFailed,
        lastPlannerError: 'missing_api_key',
      );
      return const PlannerOutcome(
        plan: null,
        preamble: '',
        error: 'missing_api_key',
      );
    }

    final apiKey = await ref.read(aiSettingsProvider.notifier).readApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(
        phase: AgentTurnPhase.plannerFailed,
        lastPlannerError: 'missing_api_key',
      );
      return const PlannerOutcome(
        plan: null,
        preamble: '',
        error: 'missing_api_key',
      );
    }

    final plannerModel = _plannerModelFromSettings(settings);
    final service = ref.read(agentPlannerServiceProvider);
    final result = await service.plan(
      prompt: prompt,
      history: history,
      catalog: catalog,
      model: plannerModel,
      apiKey: apiKey,
      baseUrl: settings.baseUrl,
    );

    if (!result.isSuccess) {
      final message = result.error ?? 'planner_failed';
      state = state.copyWith(
        phase: AgentTurnPhase.plannerFailed,
        lastPlannerError: message,
      );
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.warning, 'Agent planner failed: $message');
      return PlannerOutcome(
        plan: null,
        preamble: '',
        error: message,
      );
    }

    final plan = result.plan!;
    final nextPhase = plan.needsMoreInformation
        ? AgentTurnPhase.awaitingClarification
        : AgentTurnPhase.planned;

    state = state.copyWith(phase: nextPhase, currentPlan: plan);

    return PlannerOutcome(
      plan: plan,
      preamble: _formatPreamble(plan),
      error: null,
    );
  }

  /// Resolves the tools the executor may call this turn, filtered by the
  /// most-recent plan. Returns an empty list when no plan is active, the
  /// plan has no domains, or no domain tool survives the Phase 4 ceiling.
  ///
  /// Phase 4 only exposes [ToolRiskTier.read] and [ToolRiskTier.prepare]
  /// tools — the confirmation surface for commit/privileged tiers lands
  /// in Phase 5. The filter is applied here (not in the executor) so the
  /// executor stays a pure tool-loop runner.
  List<ToolDescriptor> resolveExecutorTools() {
    final plan = state.currentPlan;
    if (plan == null || plan.domains.isEmpty) {
      return const <ToolDescriptor>[];
    }
    if (plan.needsMoreInformation) {
      return const <ToolDescriptor>[];
    }

    final registry = ref.read(toolRegistryProvider);
    final domainTools = registry.forDomains(plan.domains);
    return domainTools
        .where(_isExecutableThisPhase)
        .toList(growable: false);
  }

  /// Flips the orchestrator into the executing phase so external
  /// observers (future sidebar pill, status UI) can distinguish planning
  /// from execution. No-op when the orchestrator has no active plan.
  void markExecutionStarted() {
    if (state.currentPlan == null) return;
    if (state.phase == AgentTurnPhase.executing) return;
    state = state.copyWith(phase: AgentTurnPhase.executing);
  }

  /// Marks the orchestrator idle again. Called by [AiChatController]
  /// when the assistant turn finishes or is canceled, so the next turn
  /// starts from a clean slate.
  void markTurnFinished() {
    if (state.phase == AgentTurnPhase.idle) return;
    state = state.copyWith(phase: AgentTurnPhase.idle);
  }

  /// Phase 4 restricts the executor to read + prepare. Higher tiers
  /// remain registered but are withheld until the confirmation flow
  /// ships in Phase 5.
  static bool _isExecutableThisPhase(ToolDescriptor tool) {
    switch (tool.risk) {
      case ToolRiskTier.read:
      case ToolRiskTier.prepare:
        return true;
      case ToolRiskTier.commit:
      case ToolRiskTier.privileged:
        return false;
    }
  }

  /// Picks the model used for planner calls. Phase 3 keeps this simple:
  /// prefer the fast mini model, fall back to the complex model. The
  /// planner response is short, so the fast model is the right default.
  String _plannerModelFromSettings(AiSettings settings) {
    final fast = settings.fastModel.trim();
    if (fast.isNotEmpty) return fast;
    return settings.complexModel.trim();
  }

  /// Renders the plan into the markdown preamble seeded into the
  /// assistant message. Keep terse — users can always hide it via the
  /// Phase 6 "show reasoning" toggle.
  String _formatPreamble(AgentPlan plan) {
    if (plan.needsMoreInformation) {
      final question = plan.clarifyingQuestion?.trim();
      if (question != null && question.isNotEmpty) {
        return '_Planner:_ $question\n\n';
      }
    }

    final intent = plan.intent.trim();
    if (intent.isEmpty && plan.domains.isEmpty) {
      return '';
    }

    final parts = <String>[];
    if (intent.isNotEmpty) {
      parts.add('**Plan:** $intent');
    }

    final domainLabels = plan.domains
        .map(PlannerPrompt.domainKey)
        .toList(growable: false)
      ..sort();
    if (domainLabels.isNotEmpty) {
      parts.add('_Domains: ${domainLabels.join(', ')}._');
    }

    parts.add('_Risk: ${PlannerPrompt.riskKey(plan.anticipatedMaxRisk)}._');

    return '${parts.join('\n')}\n\n---\n\n';
  }
}

final agentOrchestratorControllerProvider =
    NotifierProvider<AgentOrchestratorController, AgentTurnState>(
      AgentOrchestratorController.new,
    );

/// Convenience accessor when external code only needs to know whether a
/// plan has been produced for the active conversation (e.g. future
/// sidebar pill). Keeps callers off the whole state object.
final currentAgentPlanProvider = Provider<AgentPlan?>((ref) {
  return ref.watch(agentOrchestratorControllerProvider).currentPlan;
});

