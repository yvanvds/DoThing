import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/smartschool_message.dart';
import '../../providers/database_provider.dart';
import 'smartschool_bridge.dart';

/// In-memory cache of fetched full messages by ID.
///
/// Message bodies are NOT stored in the local database; this cache avoids
/// re-fetching the same message within a single app session.
///
/// A [syncRepository] is accepted so that resolved identities and FTS entries
/// can be written to the database as a side-effect of display — this covers
/// messages opened before the background poll has had a chance to run
/// [syncDetail] for them.
class SmartschoolMessageCacheController
    extends Notifier<Map<int, SmartschoolMessageDetail>> {
  @override
  Map<int, SmartschoolMessageDetail> build() => {};

  /// Return the cached detail for [messageId], fetching from [bridge] if needed.
  ///
  /// After a successful bridge fetch, [syncDetail] is called on [syncRepository]
  /// so that participant links and the FTS index are kept up to date.
  Future<SmartschoolMessageDetail> getOrFetch(
    int messageId,
    SmartschoolBridge bridge, {
    SmartschoolSyncRepository? syncRepository,
    MessageHeader? fallbackHeader,
  }) async {
    if (state.containsKey(messageId)) return state[messageId]!;

    final messages = await bridge.getMessage(
      messageId,
      boxType: _boxTypeForHeader(fallbackHeader),
    );
    if (messages.isEmpty) {
      throw StateError('No message detail returned for ID $messageId');
    }

    final detail = _normalizeDetail(
      messages.first,
      fallbackHeader: fallbackHeader,
    );
    state = {...state, messageId: detail};

    // Persist identity/participant links as a side-effect (non-fatal).
    var repository = syncRepository;
    if (repository == null) {
      try {
        repository = ref.read(smartschoolSyncRepositoryProvider);
      } catch (_) {}
    }
    if (repository != null) {
      try {
        await repository.syncDetail(detail);
      } catch (_) {}
    }

    return detail;
  }

  void clear() => state = {};

  SmartschoolBoxType _boxTypeForHeader(MessageHeader? header) {
    final rawBox = (header?.realBox ?? '').trim().toLowerCase();
    return switch (rawBox) {
      'draft' => SmartschoolBoxType.draft,
      'scheduled' => SmartschoolBoxType.scheduled,
      'sent' => SmartschoolBoxType.sent,
      'trash' => SmartschoolBoxType.trash,
      _ => SmartschoolBoxType.inbox,
    };
  }

  SmartschoolMessageDetail _normalizeDetail(
    SmartschoolMessageDetail detail, {
    MessageHeader? fallbackHeader,
  }) {
    final isSent = _isSentMailbox(fallbackHeader?.realBox);
    final fallbackSubject = fallbackHeader?.subject ?? '';
    final fallbackFrom = isSent ? '' : (fallbackHeader?.from ?? '');
    final fallbackAvatar =
        (!isSent &&
            fallbackHeader != null &&
            fallbackHeader.fromImage.trim().isNotEmpty)
        ? fallbackHeader.fromImage
        : null;

    final normalizedSubject = _preferFallbackSubject(
      detail.subject,
      fallbackSubject,
    );
    final normalizedFrom = isSent
        ? _preferSentSender(detail.from)
        : _preferFallbackSender(detail.from, fallbackFrom);
    final normalizedDate = _preferFallbackDate(
      detail.date,
      fallbackHeader?.date,
    );

    String normalizedBody;
    if (detail.body.isNotEmpty) {
      normalizedBody = detail.body;
    } else if (isSent) {
      normalizedBody =
          '<p><em>Berichtinhoud is niet beschikbaar voor berichten in de '
          'verzonden map via de Smartschool API.</em></p>';
    } else {
      normalizedBody = detail.body;
    }

    final normalizedReceivers = _normalizeSentReceivers(
      detail.receivers,
      isSent: isSent,
      headerFrom: fallbackHeader?.from,
    );

    return SmartschoolMessageDetail(
      id: detail.id,
      from: normalizedFrom,
      subject: normalizedSubject,
      body: normalizedBody,
      date: normalizedDate,
      to: detail.to,
      status: detail.status,
      attachment: detail.attachment,
      unread: detail.unread,
      label: detail.label,
      receivers: normalizedReceivers,
      ccReceivers: detail.ccReceivers,
      bccReceivers: detail.bccReceivers,
      replyAllToRecipients: detail.replyAllToRecipients,
      replyAllCcRecipients: detail.replyAllCcRecipients,
      senderPicture: detail.senderPicture ?? fallbackAvatar,
      fromTeam: detail.fromTeam,
      totalNrOtherToReceivers: detail.totalNrOtherToReceivers,
      totalNrOtherCcReceivers: detail.totalNrOtherCcReceivers,
      totalNrOtherBccReceivers: detail.totalNrOtherBccReceivers,
      canReply: detail.canReply,
      hasReply: detail.hasReply,
      hasForward: detail.hasForward,
      sendDate: detail.sendDate,
    );
  }

  bool _isSentMailbox(String? realBox) {
    if (realBox == null) return false;
    final n = realBox.toLowerCase().trim();
    return n == 'sent' || n == 'outbox';
  }

  String _preferSentSender(String candidate) {
    final c = candidate.trim();
    if (c.isEmpty || _isUnavailableSender(c)) return 'You';
    return candidate;
  }

  String _preferFallbackDate(String detailDate, String? fallbackDate) {
    if (fallbackDate == null) return detailDate;
    final dt = DateTime.tryParse(detailDate);
    if (dt == null || dt.year < 2000) return fallbackDate;
    return detailDate;
  }

  List<SmartschoolMessageRecipient> _normalizeSentReceivers(
    List<SmartschoolMessageRecipient> receivers, {
    required bool isSent,
    String? headerFrom,
  }) {
    if (!isSent) return receivers;
    if (receivers.isEmpty && headerFrom != null && headerFrom.isNotEmpty) {
      return [SmartschoolMessageRecipient(displayName: headerFrom)];
    }
    return receivers;
  }

  String _preferFallbackSubject(String candidate, String fallback) {
    final c = candidate.trim();
    final f = fallback.trim();
    if (c.isEmpty || _isMissingSubject(c)) return f.isNotEmpty ? f : candidate;
    return candidate;
  }

  String _preferFallbackSender(String candidate, String fallback) {
    final c = candidate.trim();
    final f = fallback.trim();
    if (c.isEmpty || _isUnavailableSender(c)) {
      return f.isNotEmpty ? f : candidate;
    }
    return candidate;
  }

  bool _isMissingSubject(String value) {
    final n = _normalizeLabel(value);
    return n.contains('bericht zonder onderwerp') ||
        n.contains('zonder onderwerp') ||
        n.contains('no subject') ||
        n.contains('without subject') ||
        n.contains('subject unavailable');
  }

  bool _isUnavailableSender(String value) {
    final n = _normalizeLabel(value);
    return n.contains('niet beschikbaar') ||
        n.contains('not available') ||
        n.contains('onbekend');
  }

  String _normalizeLabel(String value) => value
      .toLowerCase()
      .replaceAll('*', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

final smartschoolMessageCacheProvider =
    NotifierProvider<
      SmartschoolMessageCacheController,
      Map<int, SmartschoolMessageDetail>
    >(SmartschoolMessageCacheController.new);
