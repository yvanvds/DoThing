import '../../../controllers/context_panel_controller.dart';
import '../../capabilities/capability_domain.dart';
import '../../executor/tool_result.dart';
import '../tool_argument_schema.dart';
import '../tool_descriptor.dart';
import '../tool_mode.dart';
import '../tool_risk_tier.dart';

/// Tools that switch which view is shown in the right-hand context panel.
List<ToolDescriptor> navigationTools() => [
  ToolDescriptor(
    name: 'open_messages_panel',
    description:
        'Switch the right-hand context panel to the Messages view so the '
        'user can see their inbox.',
    domain: CapabilityDomain.navigation,
    mode: ToolMode.prepare,
    risk: ToolRiskTier.prepare,
    arguments: ToolArgumentSchema.empty,
    invoke: (ref, _) async {
      ref.read(contextPanelProvider.notifier).show(ContextView.messages);
      return const ToolResult(
        toolCallId: '',
        summary: 'Messages panel opened.',
      );
    },
  ),
  ToolDescriptor(
    name: 'open_chat_history_panel',
    description:
        'Switch the right-hand context panel to the Chat History view.',
    domain: CapabilityDomain.navigation,
    mode: ToolMode.prepare,
    risk: ToolRiskTier.prepare,
    arguments: ToolArgumentSchema.empty,
    invoke: (ref, _) async {
      ref.read(contextPanelProvider.notifier).show(ContextView.chatHistory);
      return const ToolResult(
        toolCallId: '',
        summary: 'Chat history panel opened.',
      );
    },
  ),
  ToolDescriptor(
    name: 'open_settings_panel',
    description:
        'Switch the right-hand context panel to the Settings view.',
    domain: CapabilityDomain.navigation,
    mode: ToolMode.prepare,
    risk: ToolRiskTier.prepare,
    arguments: ToolArgumentSchema.empty,
    invoke: (ref, _) async {
      ref.read(contextPanelProvider.notifier).show(ContextView.settings);
      return const ToolResult(
        toolCallId: '',
        summary: 'Settings panel opened.',
      );
    },
  ),
];
