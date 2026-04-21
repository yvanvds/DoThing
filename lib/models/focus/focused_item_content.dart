import 'focused_item_metadata.dart';

/// Full normalized content of a focused item, fetched on demand by the
/// focused-item service.
///
/// Keep the shape source-agnostic: adapters flatten provider-specific
/// fields (Smartschool `receivers`, Outlook `toRecipients`, ...) into
/// the shared [participants] / [attachmentNames] lists. Anything truly
/// provider-specific belongs in [extra] so callers can opt in.
class FocusedItemContent {
  const FocusedItemContent({
    required this.metadata,
    this.bodyText,
    this.bodyHtml,
    this.participants = const <String>[],
    this.attachmentNames = const <String>[],
    this.extra = const <String, Object?>{},
  });

  /// The same lightweight descriptor available without fetching. Echoed
  /// back so callers have a single object to reason about.
  final FocusedItemMetadata metadata;

  /// Plain-text rendering of the item body, if the adapter can produce
  /// one. Preferred by the agent for prompt injection — HTML is only
  /// useful when the model will render it.
  final String? bodyText;

  /// Raw body in the adapter's native format (typically HTML for mail).
  /// Present so future consumers — summary generators, rich previews —
  /// can use the richer content when needed.
  final String? bodyHtml;

  /// Flat list of participant display names (sender first, then to/cc
  /// in any order). Keeps the content payload readable in planner
  /// logs without coupling to the messaging schema.
  final List<String> participants;

  /// Attachment filenames; presence signals the agent that attachments
  /// exist even when it cannot open them directly.
  final List<String> attachmentNames;

  /// Adapter-specific fields that do not fit the shared shape. Only
  /// include things that are genuinely useful downstream — this is not
  /// a dumping ground for raw provider payloads.
  final Map<String, Object?> extra;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'metadata': metadata.toJson(),
      if (bodyText != null && bodyText!.isNotEmpty) 'body_text': bodyText,
      if (bodyHtml != null && bodyHtml!.isNotEmpty) 'body_html': bodyHtml,
      if (participants.isNotEmpty) 'participants': participants,
      if (attachmentNames.isNotEmpty) 'attachment_names': attachmentNames,
      if (extra.isNotEmpty) 'extra': extra,
    };
  }
}
