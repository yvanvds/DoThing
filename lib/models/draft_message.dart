import 'recipients/recipient_chip.dart';

/// Represents a message being composed, shared across Smartschool and Outlook.
///
/// The [body] field stores a Quill Delta as a list of operation maps.
/// No conversion to HTML is performed here — that is deferred to a future layer.
class DraftMessage {
  DraftMessage({
    this.toRecipients = const [],
    this.ccRecipients = const [],
    this.bccRecipients = const [],
    this.subject = '',
    this.body = const [
      {'insert': '\n'},
    ],
  });

  /// Fully resolved delivery targets for the To header.
  final List<RecipientChip> toRecipients;

  /// Fully resolved delivery targets for the CC header.
  final List<RecipientChip> ccRecipients;

  /// Fully resolved delivery targets for the BCC header.
  final List<RecipientChip> bccRecipients;

  final String subject;

  /// Rich text body stored as a Quill Delta (list of operation maps).
  final List<Map<String, dynamic>> body;

  DraftMessage copyWith({
    List<RecipientChip>? toRecipients,
    List<RecipientChip>? ccRecipients,
    List<RecipientChip>? bccRecipients,
    String? subject,
    List<Map<String, dynamic>>? body,
  }) {
    return DraftMessage(
      toRecipients: toRecipients ?? this.toRecipients,
      ccRecipients: ccRecipients ?? this.ccRecipients,
      bccRecipients: bccRecipients ?? this.bccRecipients,
      subject: subject ?? this.subject,
      body: body ?? this.body,
    );
  }
}
