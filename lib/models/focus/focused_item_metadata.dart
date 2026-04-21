import 'focused_item_type.dart';

/// Source-agnostic, lightweight descriptor of the currently focused item.
///
/// Safe to include in planner prompts and awareness payloads — no body
/// content, no participant lists. The full content lives on
/// [FocusedItemContent], fetched on demand through the focused-item
/// service or the `get_focused_item_content` agent tool.
class FocusedItemMetadata {
  const FocusedItemMetadata({
    required this.type,
    required this.source,
    required this.id,
    required this.title,
    this.subtitle,
    this.snippet,
    this.timestamp,
    this.contentAvailable = true,
  });

  /// What kind of entity this is (message, document, ...). The tool
  /// schema exposes [type] as a stable snake_case key.
  final FocusedItemType type;

  /// Provider key identifying which adapter produced this item
  /// (e.g. 'smartschool', 'outlook'). Lowercase, stable.
  final String source;

  /// Stable id unique within [source]. Providers are free to choose a
  /// natural id (numeric, string, uri) — callers round-trip it back
  /// through the focused-item service to fetch content.
  final String id;

  /// Primary human-readable label. For messages this is the subject;
  /// for documents it would be the filename, etc.
  final String title;

  /// Optional second-line label, e.g. sender name for a message.
  final String? subtitle;

  /// Short text preview. Intentionally truncated by the adapter to keep
  /// the metadata payload small — planner/awareness callers never see
  /// full bodies here.
  final String? snippet;

  /// Provider-native timestamp, when known (e.g. receivedAt for mail).
  final DateTime? timestamp;

  /// Whether the adapter can return a [FocusedItemContent] for this
  /// item via `get_focused_item_content`. False means the agent should
  /// not try — e.g. body fetch is unavailable for some items.
  final bool contentAvailable;

  /// Wire-format payload used by the agent tools and the planner hint.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': focusedItemTypeKey(type),
      'source': source,
      'id': id,
      'title': title,
      if (subtitle != null && subtitle!.isNotEmpty) 'subtitle': subtitle,
      if (snippet != null && snippet!.isNotEmpty) 'snippet': snippet,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      'content_available': contentAvailable,
    };
  }
}
