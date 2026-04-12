import 'recipients/recipient_chip.dart';
import 'recipients/recipient_chip_source.dart';
import 'recipients/recipient_endpoint.dart';
import 'recipients/recipient_endpoint_kind.dart';
import 'recipients/recipient_endpoint_label.dart';

/// Represents a message being composed, shared across Smartschool and Outlook.
///
/// The [body] field stores a Quill Delta as a list of operation maps.
/// No conversion to HTML is performed here — that is deferred to a future layer.
class DraftMessage {
  DraftMessage({
    List<RecipientChip> toRecipients = const [],
    List<RecipientChip> ccRecipients = const [],
    List<RecipientChip> bccRecipients = const [],
    List<String> to = const [],
    List<String> cc = const [],
    List<String> bcc = const [],
    this.subject = '',
    this.body = const [
      {'insert': '\n'},
    ],
  }) : toRecipients = toRecipients.isNotEmpty
           ? toRecipients
           : _legacyToRecipients(to),
       ccRecipients = ccRecipients.isNotEmpty
           ? ccRecipients
           : _legacyToRecipients(cc),
       bccRecipients = bccRecipients.isNotEmpty
           ? bccRecipients
           : _legacyToRecipients(bcc);

  /// Fully resolved delivery targets for the To header.
  final List<RecipientChip> toRecipients;

  /// Fully resolved delivery targets for the CC header.
  final List<RecipientChip> ccRecipients;

  /// Fully resolved delivery targets for the BCC header.
  final List<RecipientChip> bccRecipients;

  /// Legacy convenience view used by existing UI/tests.
  List<String> get to =>
      toRecipients.map((chip) => chip.endpoint.value).toList(growable: false);

  /// Legacy convenience view used by existing UI/tests.
  List<String> get cc =>
      ccRecipients.map((chip) => chip.endpoint.value).toList(growable: false);

  /// Legacy convenience view used by existing UI/tests.
  List<String> get bcc =>
      bccRecipients.map((chip) => chip.endpoint.value).toList(growable: false);

  final String subject;

  /// Rich text body stored as a Quill Delta (list of operation maps).
  final List<Map<String, dynamic>> body;

  DraftMessage copyWith({
    List<RecipientChip>? toRecipients,
    List<RecipientChip>? ccRecipients,
    List<RecipientChip>? bccRecipients,
    List<String>? to,
    List<String>? cc,
    List<String>? bcc,
    String? subject,
    List<Map<String, dynamic>>? body,
  }) {
    return DraftMessage(
      toRecipients:
          toRecipients ??
          (to != null ? _legacyToRecipients(to) : this.toRecipients),
      ccRecipients:
          ccRecipients ??
          (cc != null ? _legacyToRecipients(cc) : this.ccRecipients),
      bccRecipients:
          bccRecipients ??
          (bcc != null ? _legacyToRecipients(bcc) : this.bccRecipients),
      subject: subject ?? this.subject,
      body: body ?? this.body,
    );
  }

  static List<RecipientChip> _legacyToRecipients(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map(
          (value) => RecipientChip(
            displayName: value,
            endpoint: RecipientEndpoint(
              kind: RecipientEndpointKind.email,
              value: value.toLowerCase(),
              label: RecipientEndpointLabel.other,
            ),
            source: RecipientChipSource.manual,
            autoSelectedPreferred: false,
          ),
        )
        .toList(growable: false);
  }
}
