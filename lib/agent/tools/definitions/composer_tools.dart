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
        'Open the composer with a drafted message. Switches the context '
        'panel to Messages so the composer is visible. Provide the '
        'subject and body_text you want the user to see; recipients '
        'remain empty for the user to fill in.',
    domain: CapabilityDomain.composer,
    mode: ToolMode.prepare,
    risk: ToolRiskTier.prepare,
    arguments: const ToolArgumentSchema(<String, Object?>{
      'type': 'object',
      'required': ['body_text'],
      'properties': <String, Object?>{
        'subject': <String, Object?>{'type': 'string'},
        'body_text': <String, Object?>{
          'type': 'string',
          'description':
              'Plain-text body. Use \\n for line breaks; paragraphs are '
              'separated by blank lines.',
        },
      },
    }),
    invoke: (ref, args) async {
      final subject = (args['subject'] as String?)?.trim() ?? '';
      final bodyText = (args['body_text'] as String?) ?? '';

      ref.read(contextPanelProvider.notifier).show(ContextView.messages);
      final composer = ref.read(composerProvider.notifier);
      composer.reset();
      if (subject.isNotEmpty) {
        composer.updateSubject(subject);
      }
      if (bodyText.trim().isNotEmpty) {
        composer.updateBody(_plainTextToDelta(bodyText));
      }
      ref.read(composerVisibilityProvider.notifier).open();
      return const ToolResult(
        toolCallId: '',
        summary: 'Composer opened with drafted message.',
      );
    },
  ),
  ToolDescriptor(
    name: 'open_reply_composer',
    description:
        'Prefill the composer with a reply, reply-all, or forward of the '
        'currently selected Smartschool or Outlook message. Requires a '
        'message to be selected first. Does not send. Provide body_text '
        'to author the reply; the original message is quoted below it.',
    domain: CapabilityDomain.composer,
    mode: ToolMode.prepare,
    risk: ToolRiskTier.prepare,
    arguments: const ToolArgumentSchema(<String, Object?>{
      'type': 'object',
      'required': ['action', 'body_text'],
      'properties': <String, Object?>{
        'action': <String, Object?>{
          'type': 'string',
          'enum': ['reply', 'reply_all', 'forward'],
        },
        'body_text': <String, Object?>{
          'type': 'string',
          'description':
              'Plain-text reply body inserted above the quoted original. '
              'Use \\n for line breaks.',
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
      final replyBody = (args['body_text'] as String?) ?? '';

      await ref
          .read(composerPrefillServiceProvider)
          .applyFromSelected(action, replyBody: replyBody);

      return ToolResult(
        toolCallId: '',
        summary: 'Composer prefilled for ${args['action']}.',
      );
    },
  ),
];

List<Map<String, dynamic>> _plainTextToDelta(String text) {
  final ops = <Map<String, dynamic>>[];
  for (final line in text.split('\n')) {
    if (line.isNotEmpty) {
      ops.add({'insert': line});
    }
    ops.add({'insert': '\n'});
  }
  if (ops.isEmpty) {
    ops.add({'insert': '\n'});
  }
  return ops;
}
