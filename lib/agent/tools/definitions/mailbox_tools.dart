import '../../../services/office365/office365_mail_service.dart';
import '../../../services/smartschool/smartschool_messages_controller.dart';
import '../../capabilities/capability_domain.dart';
import '../../executor/tool_result.dart';
import '../tool_argument_schema.dart';
import '../tool_descriptor.dart';
import '../tool_mode.dart';
import '../tool_risk_tier.dart';

const _kHeaderPreviewLimit = 20;

/// Tools that read or mutate mailbox state (Smartschool + Outlook).
///
/// Send is classified under mailbox (not composer) because the composer
/// domain is UI-only: the composer prepares a draft; the mailbox domain
/// is where a message actually transits an external system.
List<ToolDescriptor> mailboxTools() => [
  ToolDescriptor(
    name: 'list_inbox_headers',
    description:
        'List the most recent headers from the Smartschool inbox. Use '
        'this to discover message ids before acting on them. Does not '
        'load bodies or attachments.',
    domain: CapabilityDomain.mailbox,
    mode: ToolMode.read,
    risk: ToolRiskTier.read,
    arguments: const ToolArgumentSchema(<String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'limit': <String, Object?>{'type': 'integer'},
      },
    }),
    invoke: (ref, args) async {
      final limit = args['limit'] as int? ?? _kHeaderPreviewLimit;
      final headers = await ref
          .read(smartschoolMessagesProvider.notifier)
          .getHeaders();
      final capped = headers.take(limit).toList(growable: false);

      final structured = <String, Object?>{
        'count': capped.length,
        'total_available': headers.length,
        'headers': [
          for (final h in capped)
            <String, Object?>{
              'id': h.id,
              'subject': h.subject,
              'from': h.from,
              'date': h.date,
              'unread': h.unread,
              'has_attachment': h.hasAttachment,
            },
        ],
      };

      final summary = capped.isEmpty
          ? 'Inbox is empty.'
          : 'Returned ${capped.length} of ${headers.length} inbox headers.';

      return ToolResult(
        toolCallId: '',
        summary: summary,
        structured: structured,
      );
    },
  ),
  ToolDescriptor(
    name: 'mark_message_read',
    description:
        'Mark a single Smartschool message as read, given its numeric '
        'id (as returned by list_inbox_headers).',
    domain: CapabilityDomain.mailbox,
    mode: ToolMode.commit,
    risk: ToolRiskTier.commit,
    arguments: const ToolArgumentSchema(<String, Object?>{
      'type': 'object',
      'required': ['id'],
      'properties': <String, Object?>{
        'id': <String, Object?>{'type': 'integer'},
      },
    }),
    humanPreview: (args) => 'Mark message ${args['id']} as read',
    invoke: (ref, args) async {
      final id = args['id'] as int;
      await ref.read(smartschoolMessagesProvider.notifier).markRead(id);
      return ToolResult(
        toolCallId: '',
        summary: 'Message $id marked as read.',
      );
    },
  ),
  ToolDescriptor(
    name: 'archive_message',
    description:
        'Archive a single Smartschool message by numeric id. Moves the '
        'message out of the active inbox; it is not destroyed.',
    domain: CapabilityDomain.mailbox,
    mode: ToolMode.commit,
    risk: ToolRiskTier.commit,
    arguments: const ToolArgumentSchema(<String, Object?>{
      'type': 'object',
      'required': ['id'],
      'properties': <String, Object?>{
        'id': <String, Object?>{'type': 'integer'},
      },
    }),
    humanPreview: (args) => 'Archive message ${args['id']}',
    invoke: (ref, args) async {
      final id = args['id'] as int;
      await ref.read(smartschoolMessagesProvider.notifier).archive(id);
      return ToolResult(
        toolCallId: '',
        summary: 'Message $id archived.',
      );
    },
  ),
  ToolDescriptor(
    name: 'delete_message',
    description:
        'Move a single Smartschool message to the trash. Destructive — '
        'always presented to the user for confirmation before execution.',
    domain: CapabilityDomain.mailbox,
    mode: ToolMode.privileged,
    risk: ToolRiskTier.privileged,
    arguments: const ToolArgumentSchema(<String, Object?>{
      'type': 'object',
      'required': ['id'],
      'properties': <String, Object?>{
        'id': <String, Object?>{'type': 'integer'},
      },
    }),
    humanPreview: (args) => 'Delete message ${args['id']} (move to trash)',
    invoke: (ref, args) async {
      final id = args['id'] as int;
      await ref.read(smartschoolMessagesProvider.notifier).trash(id);
      return ToolResult(
        toolCallId: '',
        summary: 'Message $id moved to trash.',
      );
    },
  ),
  ToolDescriptor(
    name: 'send_outlook_message',
    description:
        'Send an email via the user\'s Outlook/Microsoft 365 account. '
        'Bypasses the composer panel — supply the complete recipient '
        'list, subject, and HTML body.',
    domain: CapabilityDomain.mailbox,
    mode: ToolMode.privileged,
    risk: ToolRiskTier.privileged,
    arguments: const ToolArgumentSchema(<String, Object?>{
      'type': 'object',
      'required': ['to', 'subject', 'body_html'],
      'properties': <String, Object?>{
        'to': <String, Object?>{
          'type': 'array',
          'items': <String, Object?>{'type': 'string'},
        },
        'cc': <String, Object?>{
          'type': 'array',
          'items': <String, Object?>{'type': 'string'},
        },
        'bcc': <String, Object?>{
          'type': 'array',
          'items': <String, Object?>{'type': 'string'},
        },
        'subject': <String, Object?>{'type': 'string'},
        'body_html': <String, Object?>{'type': 'string'},
      },
    }),
    humanPreview: (args) {
      final to = (args['to'] as List?)?.join(', ') ?? '';
      final subject = args['subject'] as String? ?? '';
      return 'Send Outlook email to $to — "$subject"';
    },
    invoke: (ref, args) async {
      final to = _stringList(args['to']);
      final cc = _stringList(args['cc']);
      final bcc = _stringList(args['bcc']);
      final subject = (args['subject'] as String).trim();
      final bodyHtml = args['body_html'] as String;

      await ref.read(office365MailServiceProvider).sendMail(
        toRecipients: to,
        ccRecipients: cc,
        bccRecipients: bcc,
        subject: subject,
        bodyHtml: bodyHtml,
      );

      return ToolResult(
        toolCallId: '',
        summary: 'Outlook message sent to ${to.join(', ')}.',
      );
    },
  ),
];

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return [
    for (final item in value)
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];
}
