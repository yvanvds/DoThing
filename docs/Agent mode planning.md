

Agent Architecture — Review & Implementation Plan
1. Current architecture findings
Shell & navigation
Entry: main.dart → ProviderScope → app_shell.dart.
Layout: left sidebar → fixed ChatView → ContextPanel (switches between empty, settings, messages, chatHistory via context_panel_controller.dart) → StatusTerminal.
The chat panel is always visible on the left — this is architecturally important: it's the natural home for an agent loop UI, including confirmation prompts.
Command bus (already a proto-tool system)
app_command.dart defines AppCommand { id, label, description, icon, execute(Ref) }.
command_bus.dart dispatches by id.
command_registry.dart aggregates feature-scoped lists from definitions/.
Consumed by the F24/Ctrl+Shift+P command palette in app_shell.dart:93-102 and by sidebar buttons.
Key reuse point: this is the app's existing "action vocabulary". Agent tools should extend this concept, not replace it. But AppCommand has no argument schema, no domain, no risk tier — those are the gaps.
AI chat feature (already implemented)
ai_chat_controller.dart: AiChatController extends AsyncNotifier<AiChatUiState>, owns the conversation lifecycle, streaming buffer, cancellation. Single linear flow: sendUserMessage → persist user msg → persist waiting assistant msg → open stream → append deltas via _upsertAssistantProgress → completed|canceled|failed.
ai_chat_transport.dart: abstract transport, events are delta | done | error strings.
openai_chat_service.dart: OpenAI-compat SSE. Payload shape is plain {role, content} — no tool/function call support yet. This will need to be expanded.
ai_chat_models.dart: AiMessageRole { system, user, assistant }, AiChatMessageModel, AiRequestContext. Persisted via ai_chat_repository.dart.
UI: chat_view.dart uses flutter_chat_ui with a custom markdown message builder and a model preset dropdown. Text-only today.
An existing structured AI call exists in ai_reply_quote_service.dart — it uses jsonObjectResponse on the same transport. Good precedent for how to call the same transport in "structured" mode without disrupting the chat.
Existing "actions" the agent should eventually wrap
Mailbox (send): composer_message_sender.dart send(DraftMessage), multi-provider, queue-on-failure.
Mailbox (reply/forward prefill): composer_prefill_service.dart with ComposerPrefillAction { reply, replyAll, forward }.
Mailbox (admin): office365_mail_service.dart:167-213 — markMessageRead/Unread, archiveMessage, deleteMessage; smartschool_messages_controller.dart — markRead, setLabel, archive, trash.
Navigation / UI state: contextPanelProvider.show(...), composerProvider.reset/replace, composerVisibilityProvider.open.
Status feedback: status_controller.dart — services already narrate success/warning into the status terminal; the agent should reuse this.
Reusable vs needs-refactor
Reuse as-is: AppCommand/CommandBus pattern (same invocation philosophy), status controller, Riverpod Ref-passing convention, AiChatTransport (with new event types), AiChatRepository.
Refactor: AiMessageRole (add tool), AiChatMessageModel (carry tool-call / tool-result payloads), AiStreamEvent (add tool-call events), AiChatController (becomes orchestrator instead of linear streamer), chat UI textMessageBuilder (needs to render non-text "agent turn" artefacts).
Does not exist: capability catalog, tool descriptors with schema, planner, executor, domain activation, risk/confirmation model, tool result message class.
2. Gaps vs target agent architecture
Target concern	Current state	Gap
Capability catalog	none	introduce CapabilityDomain / CapabilitySummary
Tool descriptors w/ schema	AppCommand has no args	introduce ToolDescriptor w/ JSON schema, risk, domain, mode
Planner phase	implicit in sendUserMessage	introduce AgentPlanner w/ structured JSON output
Executor phase	direct streaming reply	introduce AgentExecutor w/ tool-loop
Workspace / domain activation	all-or-nothing	planner emits domains → executor exposes only tools in those domains
Risk tiers	absent (send just throws on bad input)	ToolRiskTier; UI confirmation step for high-risk
Confirmation UI	absent	new chat message kind "pending confirmation"
Tool-call transport	not plumbed	extend transport events + payload to carry tool calls
Persistence of tool turns	only role/text	add tool-call & tool-result fields to AiChatMessageModel
3. Proposed agent architecture
I'll keep the existing controllers/ai/ and services/ai/ roots and grow an agent/ subtree alongside them so the split between "chat plumbing" and "agent orchestration" is visible, while sharing transport.

Layering (conceptual)

User prompt
    │
    ▼
AgentOrchestrator (new; lives behind AiChatController.sendUserMessage)
    │
    ├── Phase A: Planner
    │     - input:  user prompt + compact CapabilityCatalog summary
    │     - output: AgentPlan { intent, domains[], rationale, risk }
    │
    ├── Phase B: Domain activation
    │     - controller resolves plan.domains → ToolRegistry subset
    │     - builds bounded tool list for Executor
    │
    ├── Phase C: Executor loop
    │     - streams assistant text and tool_call requests
    │     - for each tool_call:
    │         · look up ToolDescriptor by name
    │         · if risk >= normalCommit requiring confirmation → emit
    │           pending-confirmation chat event, suspend loop
    │         · else execute via ToolInvoker, append ToolResult msg,
    │           re-enter model
    │     - final assistant text → completed
    │
    └── Phase D: Confirmation resume
          - user Confirm → resume executor with approved tool_call
          - user Cancel  → inject synthetic ToolResult { canceled: true }
Services vs controllers split
Services (stateless, Ref-injected): CapabilityCatalog, ToolRegistry, AgentPlannerService, AgentExecutorService, ToolInvoker. No Riverpod state — pure logic, easy to unit test.
Controllers (Riverpod): AgentOrchestratorController owns per-conversation agent state (current plan, pending confirmation, active tool invocation). AiChatController delegates tool-call decisions to it.
Why a planner service and not an orchestrator controller
Planner is a stateless function (prompt, history, catalog) → AgentPlan. Keeping it stateless means unit tests can feed fake transport events and assert JSON parsing. The orchestrator is the Riverpod-hosted state machine; it calls the planner service and the executor service.

Domain activation = data, not code
ToolRegistry.toolsForDomains(Set<CapabilityDomain>) returns a filtered list. No dynamic registration, no runtime code generation. The planner never sees concrete tool names or schemas — only the catalog.

Risk/confirmation model
Four tiers, matching the user's brief:

Tier	Description	Example
read	no side effects	list_inbox_headers, fetch_message_body
prepare	mutates UI state only (drafts, panels)	open_composer_reply, show_messages_panel
commit	sends / writes to external system, normal risk	mark_message_read, send_outlook_message
privileged	destructive or admin	delete_message, block_user, create_account
Rule: commit tools execute directly but are surfaced in chat via a small "did: …" artefact. privileged tools always require confirmation. read/prepare run silently. This is configurable per-tool (e.g. first send could be bumped to privileged via a user setting later).

4. Proposed Dart types and file structure
New folder layout

lib/
  agent/                          ← new top-level feature
    capabilities/
      capability_domain.dart      ← enum
      capability_summary.dart     ← planner-facing summary
      capability_catalog.dart     ← assembles summaries from tools
    tools/
      tool_descriptor.dart
      tool_risk_tier.dart
      tool_mode.dart
      tool_argument_schema.dart
      tool_registry.dart
      tool_invoker.dart
      definitions/                ← mirrors commands/definitions/
        mailbox_tools.dart
        navigation_tools.dart
        composer_tools.dart
    planner/
      agent_plan.dart
      agent_planner_service.dart
      planner_prompt.dart         ← system prompt + catalog serializer
    executor/
      agent_executor_service.dart
      tool_call.dart
      tool_result.dart
      executor_event.dart
    confirmation/
      pending_confirmation.dart
    orchestrator/
      agent_orchestrator_controller.dart
      agent_turn_state.dart
  controllers/ai/
    ai_chat_controller.dart       ← refactored to delegate to orchestrator
  models/ai/
    ai_chat_models.dart           ← extended (see below)
  services/ai/
    ai_chat_transport.dart        ← extended with tool-call events
  widgets/panels/chat/
    agent_confirmation_card.dart  ← new
    agent_tool_trace_card.dart    ← new (for commit-tier surfacing)
Core types (sketch)

// agent/capabilities/capability_domain.dart
enum CapabilityDomain {
  mailbox,
  composer,
  documents,       // reserved
  todos,           // reserved
  calendar,        // reserved
  accountManagement,
  navigation,
  system,
}

// agent/capabilities/capability_summary.dart
class CapabilitySummary {
  final CapabilityDomain domain;
  final String title;                // "Mailbox"
  final String purpose;              // 1-line — planner reads this
  final List<String> exampleActions; // "read headers", "archive", "reply"
  final Set<ToolRiskTier> maxRisk;   // what this domain is allowed to do
}

// agent/tools/tool_mode.dart
enum ToolMode { read, prepare, commit, privileged }

// agent/tools/tool_risk_tier.dart
enum ToolRiskTier { read, prepare, commit, privileged }

// agent/tools/tool_argument_schema.dart
class ToolArgumentSchema {
  final Map<String, Object?> jsonSchema; // strict JSON schema
  Object? validate(Map<String, Object?> args); // returns error or null
}

// agent/tools/tool_descriptor.dart
class ToolDescriptor {
  final String name;                 // snake_case, stable
  final String description;          // plain-English, tool-facing
  final CapabilityDomain domain;
  final ToolMode mode;
  final ToolRiskTier risk;
  final ToolArgumentSchema arguments;
  final Future<ToolResult> Function(Ref ref, Map<String, Object?> args) invoke;
  final String Function(Map<String, Object?> args)? humanPreview; // for confirm UI
}

// agent/tools/tool_registry.dart
class ToolRegistry {
  List<ToolDescriptor> get all;
  List<ToolDescriptor> forDomains(Set<CapabilityDomain>);
  ToolDescriptor? byName(String name);
}

// agent/planner/agent_plan.dart
class AgentPlan {
  final String intent;                     // "Summarize and archive"
  final Set<CapabilityDomain> domains;
  final String rationale;                  // shown to user optionally
  final ToolRiskTier anticipatedMaxRisk;
  final bool needsMoreInformation;         // planner clarification path
  final String? clarifyingQuestion;
}

// agent/executor/tool_call.dart
class ToolCall {
  final String id;                         // provider-assigned
  final String toolName;
  final Map<String, Object?> arguments;
}

// agent/executor/tool_result.dart
class ToolResult {
  final String toolCallId;
  final bool isError;
  final String summary;                    // short — goes back to model
  final Map<String, Object?>? structured;  // optional richer payload
}

// agent/confirmation/pending_confirmation.dart
class PendingConfirmation {
  final String id;                         // matches ToolCall.id
  final ToolDescriptor descriptor;
  final Map<String, Object?> arguments;
  final String humanPreview;               // "Send message to X..."
  final ToolRiskTier risk;
  final String? reason;                    // from model
}

// extensions to models/ai/ai_chat_models.dart
enum AiMessageRole { system, user, assistant, tool }   // + tool

class AiChatMessageModel {
  // existing +
  final List<ToolCall>? toolCalls;         // assistant messages
  final String? toolCallId;                // for role=tool
  final PendingConfirmation? pending;      // for role=assistant, awaiting user
  // Store pending/tool payloads as JSON in the existing content column or
  // add sibling columns — decide in Phase 1.
}

// extensions to services/ai/ai_chat_transport.dart
class AiStreamEvent {
  // add:
  final ToolCall? toolCall;                // emitted when provider yields one
  // existing delta/done/error remain
}
Orchestrator state

class AgentTurnState {
  final String conversationId;
  final AgentPlan? currentPlan;
  final PendingConfirmation? pending;
  final List<ToolCall> toolCallsInTurn;
  final AiStreamingState streaming;
}
5. Integration with existing AI chat and UI
Controller wiring
AiChatController.sendUserMessage becomes thin. It still:

validates API key / persists the user message (reuse current logic lines 144-170),
hands the prompt to AgentOrchestratorController.run(prompt, conversationId).
AgentOrchestratorController:

calls AgentPlannerService.plan(prompt, history, catalog) → AgentPlan,
persists a synthetic assistant "plan" message (role=assistant, hidden or collapsible),
calls AgentExecutorService.run(plan, history, toolRegistry.forDomains(plan.domains)),
interprets ExecutorEvents: text delta → stream into assistant message as today; tool_call → gate on risk tier; tool_result → persist + feed back; done → complete.
Where state lives
Conversation transcript: unchanged — ai_chat_repository.dart + InMemoryChatController. Extended schema carries tool calls/results.
Per-turn agent state (active plan, pending confirmation, domain activation): a new agentOrchestratorProvider keyed by conversationId (just like AiChatController).
ToolRegistry / CapabilityCatalog: static Providers, built at app start analogous to commandBusProvider.
Transport changes
AiChatTransport.streamCompletion gains a tools: List<ToolDescriptor> parameter. Implementation translates to OpenAI's tools / tool_choice fields and parses delta.tool_calls from the SSE stream. The existing AiChatMessageModel→payload mapping in openai_chat_service.dart:26-32 must serialize tool-role messages and toolCalls for assistant turns.
Planner calls the same transport with jsonObjectResponse: true (precedent: ai_reply_quote_service.dart:22) and no tools — it just returns JSON matching the AgentPlan schema.
Status terminal
Tool invocations already have a natural home there — ToolInvoker pushes StatusEntrys exactly like existing services do, so users see the same timeline they're used to.

6. Chat UI impact
Message builder branches
Current chat_view_state.dart:44-61 already branches isSentByMe vs markdown. Add two more artefact types, rendered inside assistant turns:

AgentConfirmationCard — shown when message.pending != null:
Title: descriptor.humanPreview (e.g. "Send message to teacher@school")
Subtitle/reason block (from model)
Risk badge (color-coded by tier)
Args summary in a subtle block
Confirm / Cancel buttons wired to AgentOrchestratorController.confirmPending(id) / cancelPending(id)
AgentToolTraceCard — compact one-liner for commit tier execution: ✔ Archived message "…" with optional "undo" when the tool declares it.
Because flutter_chat_ui keys on the existing Chat message type, the cleanest approach is to represent both as specially-structured markdown in the assistant message, or to bypass textMessageBuilder for these ids by keeping a sidecar Map<messageId, AgentArtefact> on the orchestrator state and rendering a stack of cards above/below the Chat. I recommend the sidecar approach — mixing confirmation UI into markdown risks rendering-layer bugs and breaks the clean separation between transcript text and agent control surfaces.

Composer
The existing chat _ChatComposer stays as the single input box. No new input widget needed.

Sidebar
Optional: add a tiny agent-state pill ("Planning…" / "Awaiting confirmation") near the existing _AiStatusBar (chat_view_state.dart:23-35). Reuses the AI status bar pattern already in place.

7. Incremental implementation roadmap
Each phase is standalone-shippable; nothing is half-wired.

Phase 0 — Scaffolding (no behavior change)
Create lib/agent/ skeleton, enums, value types (CapabilityDomain, ToolRiskTier, ToolMode, ToolDescriptor, ToolArgumentSchema, AgentPlan, ToolCall, ToolResult, PendingConfirmation).
No providers wired yet. Pure types + unit tests for ToolArgumentSchema.validate.
Phase 1 — Extend chat models & transport
Extend AiMessageRole with tool, add toolCalls/toolCallId fields to AiChatMessageModel, migrate DB schema (new columns; existing rows tolerate nulls).
Extend AiStreamEvent with a toolCall variant.
Update OpenAiChatTransport to (a) serialize tool-role messages, (b) forward tools, (c) parse streaming tool_calls.
No executor yet — AI chat still behaves as before because no tools are passed in. Dependency: DB migration.
Phase 2 — Capability catalog + tool registry + first tools
Implement CapabilityCatalog and ToolRegistry with initial tools, all in mailbox / navigation / composer domains (see Phase 4). Each ToolDescriptor.invoke wraps existing services. Providers: toolRegistryProvider, capabilityCatalogProvider. No AI integration yet — these are just in-memory lookup tables. Unit-tested in isolation.
Covers: list_inbox_headers (read), open_messages_panel (prepare), open_reply_composer (prepare), mark_message_read (commit), archive_message (commit), delete_message (privileged), send_outlook_message (privileged — start strict, relax later).
Phase 3 — Planner wiring
Implement AgentPlannerService using AiChatTransport in JSON-object mode.
Compose planner_prompt.dart from CapabilityCatalog (domain title + purpose + example actions — no tool names).
AgentOrchestratorController created; AiChatController.sendUserMessage splits: planner call happens before the existing streaming path, but for now the orchestrator only prints the plan's intent/rationale as a preamble to the assistant message. Still no tool execution. This lets the planner be validated end-to-end with low risk.
Phase 4 — Executor + first read/prepare tools
Implement AgentExecutorService: given a plan + bounded tool list, runs the tool loop against the transport. For this phase, only expose read and prepare tools — zero-risk path, no confirmation UI needed yet.
Integrate into orchestrator. User can now say "open the messages panel" or "show me my inbox headers" and the agent will call tools.
Phase 5 — Confirmation flow
Implement PendingConfirmation state in orchestrator, confirmPending / cancelPending methods.
Build AgentConfirmationCard widget + sidecar render in ChatView.
Promote archive_message and mark_message_read to the executor's allowed set (commit tier) — these execute silently. Promote delete_message and send_outlook_message (privileged) — these require confirmation.
End-to-end risky path now works.
Phase 6 — Polish / trace cards / status surfacing
AgentToolTraceCard for commit-tier.
Status terminal: executor pushes entries for each tool call.
Hide planner preamble behind a "Show reasoning" toggle.
Refactors expected, by phase
Phase 1: AI DB schema migration; transport signature breaks → caller in ai_chat_controller.dart:197-207 and ai_reply_quote_service.dart need a trivial named-arg update.
Phase 3: sendUserMessage split. No other code touched.
Phase 5: textMessageBuilder plus a sidecar renderer; does not disturb existing markdown path.
8. Minimal first slice
Smallest end-to-end path that exercises every architectural seam:

Scenario: user types "open my inbox and mark the top message read".

Tools in registry: 3 total — show_messages_panel (prepare), list_inbox_headers (read), mark_message_read (commit, no confirm).

Flow:

AgentOrchestratorController.run(prompt) →
Planner returns { domains: [mailbox, navigation], intent: "Open inbox + mark first as read", anticipatedMaxRisk: commit }.
ToolRegistry.forDomains({mailbox, navigation}) → 3 tools above.
Executor loop:
model calls show_messages_panel {} → contextPanelProvider.show(ContextView.messages) → ToolResult summary "ok".
model calls list_inbox_headers {} → wraps smartschoolMessagesProvider.getHeaders() → ToolResult {first_id: 123, first_subject: "..."}.
model calls mark_message_read { id: 123 } → wraps smartschoolMessagesProvider.markRead(123) → commit tool, no confirmation, status entry pushed.
model final text: "Opened your inbox and marked the top message as read."
This slice proves: catalog→planner→domain activation→bounded registry→tool loop→risk-tier handling→status integration, with real behavior, and touches zero speculative domains.

To add confirmation-gated behavior in the same slice, swap mark_message_read for delete_message (privileged) — the orchestrator pauses, AgentConfirmationCard renders, user clicks Confirm, execution resumes. That validates the full high-risk path.

9. Risks, tradeoffs, open questions
Architectural risks
Planner/executor drift: if the planner can't see tool names, it may propose domains the user's prompt requires no tools from — wasting a round trip. Mitigation: catalog includes exampleActions so the planner has concrete verbs; also allow the executor to terminate cleanly with "no tool needed" as a valid outcome.
Schema drift: JSON schemas per tool will rot unless generated. Start hand-written (small number); once tools >10, consider a codegen pass from ToolDescriptor using source_gen or a simple build script. Don't over-engineer now.
Local model dependency: the user is explicit that no local model should decide exposed tools. The design respects this — domain activation is a pure Set<Enum> → List<Tool> function. Easy to keep that way; beware of creeping "let the model pick" shortcuts.
Tool-name coupling: the planner returns CapabilityDomain (enum) not tool names, so planner prompt stability doesn't break when tools are renamed. Keep it that way — do not let the planner reference tool identifiers.
Confirmation bypass: a cleverly-worded prompt shouldn't bypass confirmations. Since confirmation is enforced by ToolDescriptor.risk at the executor layer (not by the model), model output cannot disable it. Good property — preserve it.
Tradeoffs / decisions to lock in
One controller or split? I recommend orchestrator as a separate controller (not merged into AiChatController). AiChatController stays focused on conversation persistence + streaming UX; orchestrator owns plan/tool state. Splitting now costs little; merging later is easy, splitting later is painful.
Strictness of schemas: start strict (reject unknown keys, required fields enforced) — looser is always easier to allow later. Encode via ToolArgumentSchema.validate returning structured errors that get fed back as tool results so the model can self-correct.
Where does AppCommand fit? Don't merge AppCommand and ToolDescriptor. Commands are UI-triggered (palette, buttons); tools are model-triggered. They may wrap the same underlying service call via a shared helper, but their metadata (icon vs schema, label vs description for model, no-risk vs risk) serve different audiences. Keeping them separate avoids contorting either.
Storage of tool-call payloads: add dedicated tool_calls_json / tool_call_id columns to the AI messages table rather than cramming into content. Easier to query and migrate later.
Confirmation UI placement: sidecar renderer above/below Chat, not a custom message builder (see §5).
Future domains (documents, todos, calendar, account_management): already reserved in the enum. Adding them later = adding a CapabilitySummary + tool definitions file. No planner/executor changes required. The enum's privileged tier covers the sensitive account-management cases on day one.
Open questions for you
Undo semantics: for commit-tier tools (archive, mark read), do we want a chat-surfaced Undo action? Easy to model (tool returns an undoToolCall), but adds complexity. Defer unless valuable.
Planner latency: each turn now does 2 model calls (planner → executor). For simple prompts this is wasteful. Consider a fast-path: if the prompt is short / matches a "no-tool-needed" heuristic, skip the planner and go straight to executor with all domains at read+prepare only. Keep this as a Phase 6+ optimization — premature otherwise.
Cross-conversation memory: the current design is per-conversation. User preferences about risk ("always auto-confirm archiving") should live in settings, not memory — explicit.
Tool usage in non-chat contexts: does the reply-quote service (ai_reply_quote_service.dart) need to use tools? Probably not — it's a narrow structured extraction. Keep non-agent AI features on the plain transport.
Summary: the codebase already has most of the raw material — a command bus pattern, a clean AI transport abstraction, a persistent chat repository, and service-layer actions for mailbox/composer/navigation that map 1:1 to future tools. The missing pieces are the agent-specific types (catalog, tool descriptors, plan, confirmation) and a two-phase orchestrator that sits between AiChatController and the transport. None of the proposed changes require rewriting existing features; the foundational phases are strict additions, and the integration points (models extension, transport signature, chat message builder) are small and localized.

Let me know which phase you'd like me to tackle first, or whether any of the open questions should change the design before we start.