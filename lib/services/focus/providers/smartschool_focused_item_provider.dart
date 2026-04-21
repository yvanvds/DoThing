import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/focus/focused_item_content.dart';
import '../../../models/focus/focused_item_metadata.dart';
import '../../../models/focus/focused_item_type.dart';
import '../../../models/smartschool_message.dart';
import '../../smartschool/smartschool_auth_controller.dart';
import '../../smartschool/smartschool_message_cache_controller.dart';
import '../../smartschool/smartschool_messages_controller.dart';
import '../../smartschool/smartschool_selected_message_controller.dart';
import '../focused_item_provider.dart';

const String kSmartschoolFocusedItemSource = 'smartschool';

/// Focused-item adapter over the Smartschool message selection.
///
/// Synchronous probe uses the selection Notifier; content fetch goes
/// through the in-memory cache (falling back to the bridge) the detail
/// view already relies on, so a cache entry created by the detail view
/// is reused for the agent and vice versa.
class SmartschoolFocusedItemProvider extends FocusedItemProvider {
  const SmartschoolFocusedItemProvider();

  @override
  String get source => kSmartschoolFocusedItemSource;

  @override
  FocusedItemMetadata? currentMetadata(Ref ref) {
    final header = ref.watch(smartschoolSelectedMessageProvider);
    if (header == null || header.source != kSmartschoolFocusedItemSource) {
      return null;
    }
    return _metadataFromHeader(header);
  }

  @override
  Future<FocusedItemContent?> resolveContent(
    Ref ref,
    FocusedItemMetadata metadata,
  ) async {
    final messageId = int.tryParse(metadata.id);
    if (messageId == null) return null;

    final bridge = ref.read(smartschoolAuthProvider.notifier).bridge;
    final cachedHeaders = await ref
        .read(smartschoolMessagesProvider.notifier)
        .getHeaders()
        .catchError((_) => const <MessageHeader>[]);
    final fallbackHeader = cachedHeaders.firstWhere(
      (h) => h.id == messageId,
      orElse: () => MessageHeader(
        id: messageId,
        from: metadata.subtitle ?? '',
        fromImage: '',
        subject: metadata.title,
        date: metadata.timestamp?.toIso8601String() ?? '',
        status: 0,
        unread: false,
        hasAttachment: false,
        label: false,
        deleted: false,
        allowReply: false,
        allowReplyEnabled: false,
        hasReply: false,
        hasForward: false,
        realBox: 'inbox',
      ),
    );

    final detail = await ref
        .read(smartschoolMessageCacheProvider.notifier)
        .getOrFetch(
          messageId,
          bridge,
          fallbackHeader: fallbackHeader,
        );

    final participants = <String>[
      if (detail.from.trim().isNotEmpty) detail.from.trim(),
      ..._recipientNames(detail.receivers),
      ..._recipientNames(detail.ccReceivers),
    ];

    return FocusedItemContent(
      metadata: metadata,
      bodyHtml: detail.body,
      bodyText: _htmlToText(detail.body),
      participants: participants,
    );
  }

  static FocusedItemMetadata _metadataFromHeader(MessageHeader header) {
    final timestamp = DateTime.tryParse(header.date);
    final snippet = header.subject.trim();
    return FocusedItemMetadata(
      type: FocusedItemType.message,
      source: kSmartschoolFocusedItemSource,
      id: header.id.toString(),
      title: header.subject.trim().isEmpty
          ? '(no subject)'
          : header.subject.trim(),
      subtitle: header.from.trim().isEmpty ? null : header.from.trim(),
      snippet: snippet.isEmpty ? null : snippet,
      timestamp: timestamp,
    );
  }

  static List<String> _recipientNames(
    List<SmartschoolMessageRecipient> recipients,
  ) {
    return recipients
        .map((r) => r.displayName.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  /// Rough HTML → plain-text conversion good enough for agent prompt
  /// injection. Intentionally simple: strip tags, collapse whitespace.
  /// Not a renderer.
  static String _htmlToText(String html) {
    if (html.isEmpty) return '';
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
