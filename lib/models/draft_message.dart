/// Represents a message being composed, shared across Smartschool and Outlook.
///
/// The [body] field stores a Quill Delta as a list of operation maps.
/// No conversion to HTML is performed here — that is deferred to a future layer.
class DraftMessage {
  const DraftMessage({
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.subject = '',
    this.body = const [
      {'insert': '\n'},
    ],
  });

  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String subject;

  /// Rich text body stored as a Quill Delta (list of operation maps).
  final List<Map<String, dynamic>> body;

  DraftMessage copyWith({
    List<String>? to,
    List<String>? cc,
    List<String>? bcc,
    String? subject,
    List<Map<String, dynamic>>? body,
  }) {
    return DraftMessage(
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      body: body ?? this.body,
    );
  }
}
