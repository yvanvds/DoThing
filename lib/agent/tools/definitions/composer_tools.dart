import '../../../controllers/composer_controller.dart';
import '../../../controllers/composer_visibility_controller.dart';
import '../../../controllers/context_panel_controller.dart';
import '../../../services/composer/composer_prefill_service.dart';
import '../../capabilities/capability_domain.dart';
import '../../executor/tool_result.dart';
import '../tool_argument_schema.dart';
import '../tool_descriptor.dart';
import '../tool_mode.dart';
import '../tool_risk_tier.dart';

/// Tools that prepare drafts in the composer panel. These never send —
/// sending belongs to the mailbox domain (`send_outlook_message`).
List<ToolDescriptor> composerTools() => [
  ToolDescriptor(
    name: 'open_new_composer',
    description:
        'Open the composer with a blank draft. Also switches the context '
        'panel to Messages so the composer is visible.',
    domain: CapabilityDomain.composer,
    mode: ToolMode.prepare,
    risk: ToolRiskTier.prepare,
    arguments: ToolArgumentSchema.empty,
    invoke: (ref, _) async {
      ref.read(contextPanelProvider.notifier).show(ContextView.messages);
      ref.read(composerProvider.notifier).reset();
      ref.read(composerVisibilityProvider.notifier).open();
      return const ToolResult(
        toolCallId: '',
        summary: 'Composer opened with a blank draft.',
      );
    },
  ),
  ToolDescriptor(
    name: 'open_reply_composer',
    description:
        'Prefill the composer with a reply, reply-all, or forward of the '
        'currently selected Smartschool or Outlook message. Requires a '
        'message to be selected first. Does not send.',
    domain: CapabilityDomain.composer,
    mode: ToolMode.prepare,
    risk: ToolRiskTier.prepare,
    arguments: const ToolArgumentSchema(<String, Object?>{
      'type': 'object',
      'required': ['action'],
      'properties': <String, Object?>{
        'action': <String, Object?>{
          'type': 'string',
          'enum': ['reply', 'reply_all', 'forward'],
        },
      },
    }),
    invoke: (ref, args) async {
      final action = switch (args['action'] as String) {
        'reply' => ComposerPrefillAction.reply,
        'reply_all' => ComposerPrefillAction.replyAll,
        'forward' => ComposerPrefillAction.forward,
        _ => ComposerPrefillAction.reply,
      };

      await ref
          .read(composerPrefillServiceProvider)
          .applyFromSelected(action);

      return ToolResult(
        toolCallId: '',
        summary: 'Composer prefilled for ${args['action']}.',
      );
    },
  ),
];
