import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/focus/focused_item_content.dart';
import '../../../models/focus/focused_item_metadata.dart';
import '../../../models/focus/focused_item_type.dart';
import '../../../models/smartschool_message.dart';
import '../../../providers/database_provider.dart';
import '../../office365/office365_mail_service.dart';
import '../../office365/outlook_message_body_cache_controller.dart';
import '../../smartschool/smartschool_selected_message_controller.dart';
import '../focused_item_provider.dart';

const String kOutlookFocusedItemSource = 'outlook';

/// Focused-item adapter over the Outlook message selection.
///
/// Metadata is built from the shared selected-header Notifier (same one
/// the Smartschool adapter uses, distinguished by `header.source`).
/// Content resolution mirrors [OutlookMessageDetailView]'s load path —
/// DB row + participants + attachments, and the body cache populated by
/// [Office365MailService.refreshMessageDetail]. The refresh is triggered
/// on-demand when the cache is empty, so the agent gets the same data
/// the UI would show without forcing an extra network roundtrip when it
/// is already warm.
class OutlookFocusedItemProvider extends FocusedItemProvider {
  const OutlookFocusedItemProvider();

  @override
  String get source => kOutlookFocusedItemSource;

  @override
  FocusedItemMetadata? currentMetadata(Ref ref) {
    final header = ref.watch(smartschoolSelectedMessageProvider);
    if (header == null || header.source != kOutlookFocusedItemSource) {
      return null;
    }
    return _metadataFromHeader(header);
  }

  @override
  Future<FocusedItemContent?> resolveContent(
    Ref ref,
    FocusedItemMetadata metadata,
  ) async {
    final localId = int.tryParse(metadata.id);
    if (localId == null) return null;

    final db = ref.read(appDatabaseProvider);
    Message? row = await db.messagesDao.getMessageById(localId);
    if (row == null || row.source != kOutlookFocusedItemSource) {
      row = await db.messagesDao.findMessage(
        source: kOutlookFocusedItemSource,
        externalId: metadata.id,
      );
    }
    if (row == null) return null;

    final bodyCacheBefore = ref.read(outlookMessageBodyCacheProvider);
    if (!bodyCacheBefore.containsKey(row.id)) {
      try {
        await ref
            .read(office365MailServiceProvider)
            .refreshMessageDetail(row.id);
      } catch (_) {
        // Keep whatever DB state we have — adapter is best-effort.
      }
    }

    final refreshedRow = await db.messagesDao.getMessageById(row.id) ?? row;
    final participants = await db.messagesDao.getParticipantsWithIdentity(
      refreshedRow.id,
    );
    final attachments = await db.attachmentsDao.getAttachmentsForMessage(
      refreshedRow.id,
    );
    final body = ref.read(outlookMessageBodyCacheProvider)[refreshedRow.id];
    final rawBody = body?.raw?.trim();
    final format = body?.format?.toLowerCase();
    final isHtml = rawBody != null &&
        rawBody.isNotEmpty &&
        format != null &&
        format.contains('html');
    final bodyHtml = isHtml ? rawBody : null;
    final bodyText = (rawBody == null || rawBody.isEmpty)
        ? null
        : (isHtml ? _htmlToText(rawBody) : rawBody);

    return FocusedItemContent(
      metadata: metadata,
      bodyHtml: bodyHtml,
      bodyText: bodyText,
      participants: _participantNames(participants),
      attachmentNames: attachments
          .map((a) => a.filename)
          .where((name) => name.trim().isNotEmpty)
          .toList(growable: false),
    );
  }

  static FocusedItemMetadata _metadataFromHeader(MessageHeader header) {
    final timestamp = DateTime.tryParse(header.date);
    final snippet = header.subject.trim();
    return FocusedItemMetadata(
      type: FocusedItemType.message,
      source: kOutlookFocusedItemSource,
      id: header.id.toString(),
      title: header.subject.trim().isEmpty
          ? '(no subject)'
          : header.subject.trim(),
      subtitle: header.from.trim().isEmpty ? null : header.from.trim(),
      snippet: snippet.isEmpty ? null : snippet,
      timestamp: timestamp,
    );
  }

  static List<String> _participantNames(List<ParticipantIdentity> items) {
    final senders = items
        .where((p) => p.role == 'sender')
        .map((p) => p.displayName.trim())
        .where((name) => name.isNotEmpty);
    final others = items
        .where((p) => p.role != 'sender')
        .map((p) => p.displayName.trim())
        .where((name) => name.isNotEmpty);
    return <String>[...senders, ...others];
  }

  /// Minimal HTML → text. Good enough for prompt injection; not a
  /// renderer.
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
