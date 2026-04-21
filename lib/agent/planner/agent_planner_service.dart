import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai/ai_chat_models.dart';
import '../../services/ai/ai_chat_transport.dart';
import '../../services/ai/openai_chat_service.dart';
import '../capabilities/capability_catalog.dart';
import '../capabilities/capability_domain.dart';
import '../tools/tool_risk_tier.dart';
import 'agent_plan.dart';
import 'planner_prompt.dart';

/// Outcome of a planner call. Distinguishes "the planner returned an
/// unusable reply" from "the planner returned a usable plan" so the
/// orchestrator can decide whether to fall through to a plain chat reply.
class PlannerResult {
  const PlannerResult.success(this.plan)
    : error = null,
      rawResponse = null;

  const PlannerResult.failure({
    required this.error,
    this.rawResponse,
  }) : plan = null;

  final AgentPlan? plan;
  final String? error;
  final String? rawResponse;

  bool get isSuccess => plan != null;
}

/// Runs the planner stage: one non-streaming JSON-object call against the
/// same [AiChatTransport] the chat feature uses. The service is stateless;
/// per-conversation planner state lives on the orchestrator.
class AgentPlannerService {
  const AgentPlannerService(this.ref);

  final Ref ref;

  /// Requests a plan for [prompt]. [history] should contain the prior
  /// conversation (user + assistant), so the planner can resolve
  /// references like "archive that one".
  ///
  /// When [catalog] is empty — no domains have tools yet — this returns
  /// a trivially-empty plan without contacting the model; the orchestrator
  /// uses that as the signal to fall through to plain chat.
  Future<PlannerResult> plan({
    required String prompt,
    required List<AiChatMessageModel> history,
    required CapabilityCatalog catalog,
    required String model,
    required String apiKey,
    required String baseUrl,
    String? focusAwareness,
    bool Function()? isCanceled,
  }) async {
    if (catalog.summaries.isEmpty) {
      return const PlannerResult.success(
        AgentPlan(
          intent: '',
          domains: <CapabilityDomain>{},
          rationale: 'No capability domains registered; skipping planner.',
          anticipatedMaxRisk: ToolRiskTier.read,
        ),
      );
    }

    final systemPrompt = PlannerPrompt.systemPrompt(catalog);
    final now = DateTime.now();

    final awareness = focusAwareness?.trim();

    final requestMessages = <AiChatMessageModel>[
      AiChatMessageModel(
        id: 'planner-system',
        conversationId: 'planner',
        role: AiMessageRole.system,
        content: systemPrompt,
        createdAt: now,
      ),
      // Focus awareness is appended as a *second* system message rather
      // than folded into [systemPrompt]. The main prompt is deterministic
      // for a given catalog — keep it cache-friendly. Awareness changes
      // every turn and piggybacks on the same turn.
      if (awareness != null && awareness.isNotEmpty)
        AiChatMessageModel(
          id: 'planner-focus',
          conversationId: 'planner',
          role: AiMessageRole.system,
          content: awareness,
          createdAt: now,
        ),
      for (final entry in _historyForPlanner(history))
        AiChatMessageModel(
          id: 'planner-${entry.id}',
          conversationId: 'planner',
          role: entry.role,
          content: entry.content,
          createdAt: entry.createdAt,
        ),
      AiChatMessageModel(
        id: 'planner-user',
        conversationId: 'planner',
        role: AiMessageRole.user,
        content: prompt,
        createdAt: now,
      ),
    ];

    final transport = ref.read(aiChatTransportProvider);
    final buffer = StringBuffer();
    AiErrorState? streamError;

    try {
      await for (final event in transport.streamCompletion(
        apiKey: apiKey,
        baseUrl: baseUrl,
        request: AiCompletionRequest(
          model: model,
          stream: false,
          jsonObjectResponse: true,
          messages: requestMessages,
          context: const AiRequestContext(
            kind: 'agent_planner',
            summary: 'Pick capability domains for the next executor turn.',
          ),
        ),
      )) {
        if (isCanceled?.call() ?? false) {
          return const PlannerResult.failure(error: 'canceled');
        }
        if (event.error != null) {
          streamError = event.error;
          break;
        }
        if (event.delta.isNotEmpty) {
          buffer.write(event.delta);
        }
      }
    } catch (e) {
      return PlannerResult.failure(error: 'transport_exception: $e');
    }

    if (streamError != null) {
      return PlannerResult.failure(
        error: 'transport_error: ${streamError.code}: ${streamError.message}',
      );
    }

    final raw = buffer.toString().trim();
    if (raw.isEmpty) {
      return const PlannerResult.failure(error: 'empty_response');
    }

    final decoded = _tryDecodeJsonObject(raw);
    if (decoded == null) {
      return PlannerResult.failure(
        error: 'json_parse_error',
        rawResponse: raw,
      );
    }

    final plan = _planFromJson(decoded, catalog);
    if (plan == null) {
      return PlannerResult.failure(
        error: 'schema_violation',
        rawResponse: raw,
      );
    }

    return PlannerResult.success(plan);
  }

  /// Keeps only user/assistant content relevant to the planner — drops
  /// system messages (planner has its own), drops tool messages (planner
  /// never saw them), drops empty/failed assistant turns.
  Iterable<AiChatMessageModel> _historyForPlanner(
    List<AiChatMessageModel> history,
  ) {
    return history.where((message) {
      if (message.role != AiMessageRole.user &&
          message.role != AiMessageRole.assistant) {
        return false;
      }
      if (message.status == AiMessageStatus.failed ||
          message.status == AiMessageStatus.canceled) {
        return false;
      }
      return message.content.trim().isNotEmpty;
    });
  }

  /// Parses the planner's JSON response into an [AgentPlan]. Returns
  /// `null` when required fields are missing or malformed. Unknown domain
  /// keys are silently dropped — that is the strictest-reasonable policy
  /// since the planner prompt enumerates the valid keys.
  AgentPlan? _planFromJson(
    Map<String, Object?> json,
    CapabilityCatalog catalog,
  ) {
    final intent = (json['intent'] as String?)?.trim() ?? '';
    final rationale = (json['rationale'] as String?)?.trim() ?? '';
    final riskRaw = (json['anticipated_max_risk'] as String?)?.trim() ?? 'read';
    final risk = PlannerPrompt.riskFromKey(riskRaw) ?? ToolRiskTier.read;
    final needsInfo = json['needs_more_information'] as bool? ?? false;
    final question = (json['clarifying_question'] as String?)?.trim();

    final domainsRaw = json['domains'];
    final domains = <CapabilityDomain>{};
    if (domainsRaw is List) {
      for (final entry in domainsRaw) {
        if (entry is String) {
          final domain = PlannerPrompt.domainFromKey(entry);
          if (domain != null && catalog.byDomain(domain) != null) {
            domains.add(domain);
          }
        }
      }
    }

    if (intent.isEmpty && !needsInfo) {
      return null;
    }

    return AgentPlan(
      intent: intent,
      domains: domains,
      rationale: rationale,
      anticipatedMaxRisk: risk,
      needsMoreInformation: needsInfo,
      clarifyingQuestion: question?.isNotEmpty == true ? question : null,
    );
  }
}

/// Extracts a `{...}` object from [raw], tolerating fenced blocks and
/// leading/trailing prose the model may emit despite the JSON-object
/// request. Returns `null` if no valid object can be parsed.
Map<String, Object?>? _tryDecodeJsonObject(String raw) {
  final trimmed = raw.trim();
  String candidate = trimmed;

  if (!trimmed.startsWith('{')) {
    final fenced = RegExp(
      r'```(?:json)?\s*(\{[\s\S]*\})\s*```',
    ).firstMatch(trimmed);
    if (fenced != null) {
      candidate = fenced.group(1)!;
    } else {
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start >= 0 && end > start) {
        candidate = trimmed.substring(start, end + 1);
      }
    }
  }

  try {
    final decoded = jsonDecode(candidate);
    if (decoded is Map<String, dynamic>) {
      return Map<String, Object?>.from(decoded);
    }
  } catch (_) {}
  return null;
}

/// Riverpod access to the app-wide [AgentPlannerService]. Stateless
/// service — safe to read and discard.
final agentPlannerServiceProvider = Provider<AgentPlannerService>(
  AgentPlannerService.new,
);
