import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/smartschool_message.dart';
import '../../providers/database_provider.dart';
import 'smartschool_bridge.dart';

/// In-memory cache of fetched full messages by ID.
///
/// Stores results to avoid re-fetching the same message on multiple clicks.
/// Cache is cleared when the app restarts (in-memory, not persistent).
class SmartschoolMessageCacheController
    extends Notifier<Map<int, SmartschoolMessageDetail>> {
  @override
  Map<int, SmartschoolMessageDetail> build() => {};

  /// Get a cached message, fetching if not present.
  ///
  /// If [messageId] is already in cache, returns immediately.
  /// Otherwise fetches from Smartschool, caches the result, and persists it
  /// to the local database.
  Future<SmartschoolMessageDetail> getOrFetch(
    int messageId,
    SmartschoolBridge bridge, {
    SmartschoolSyncRepository? syncRepository,
    SmartschoolMessageHeader? fallbackHeader,
  }) async {
    if (state.containsKey(messageId)) {
      return state[messageId]!;
    }

    AppDatabase? db;
    try {
      db = ref.read(appDatabaseProvider);
    } catch (_) {
      db = null;
    }

    if (db != null) {
      final local = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: messageId.toString(),
      );
      if (_hasPersistedFullDetail(local)) {
        final localDetail = _normalizeDetail(
          _detailFromLocalRow(local!, messageId),
          fallbackHeader: fallbackHeader,
          fallbackHeaderFromDb: _headerFromLocalRow(local),
        );
        state = {...state, messageId: localDetail};
        return localDetail;
      }
    }

    final messages = await bridge.getMessage(messageId);
    if (messages.isEmpty) {
      throw StateError('No message detail returned for ID $messageId');
    }

    final detail = _normalizeDetail(
      messages.first,
      fallbackHeader: fallbackHeader,
      fallbackHeaderFromDb: db == null
          ? null
          : await _loadHeaderFromDb(db, messageId),
    );
    state = {...state, messageId: detail};

    var repository = syncRepository;
    if (repository == null) {
      try {
        repository = ref.read(smartschoolSyncRepositoryProvider);
      } catch (_) {
        repository = null;
      }
    }

    // Persist detail to local database (non-fatal if it fails).
    if (repository != null) {
      try {
        await repository.syncDetail(detail);
      } catch (_) {}
    }

    return detail;
  }

  Future<SmartschoolMessageHeader?> _loadHeaderFromDb(
    AppDatabase db,
    int messageId,
  ) async {
    final local = await db.messagesDao.findMessage(
      source: 'smartschool',
      externalId: messageId.toString(),
    );
    if (local == null) return null;
    return _headerFromLocalRow(local);
  }

  bool _hasPersistedFullDetail(Message? row) {
    if (row == null) return false;
    if (row.detailFetchedAt == null) return false;

    final raw = row.bodyRaw?.trim() ?? '';
    final text = row.bodyText?.trim() ?? '';
    return raw.isNotEmpty || text.isNotEmpty;
  }

  SmartschoolMessageDetail _detailFromLocalRow(Message row, int messageId) {
    Map<String, dynamic>? rawDetail;
    final rawJson = row.rawDetailJson;
    if (rawJson != null && rawJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          rawDetail = decoded;
        }
      } catch (_) {}
    }

    return SmartschoolMessageDetail(
      id: messageId,
      from: (rawDetail?['from'] as String?) ?? '',
      subject: (rawDetail?['subject'] as String?) ?? row.subject,
      body: row.bodyRaw ?? row.bodyText ?? '',
      date: (rawDetail?['date'] as String?) ?? row.receivedAt.toIso8601String(),
      to: rawDetail?['to'] as String?,
      status: (rawDetail?['status'] as int?) ?? (row.isRead ? 1 : 0),
      attachment:
          (rawDetail?['attachment'] as int?) ?? (row.hasAttachments ? 1 : 0),
      unread: (rawDetail?['unread'] as bool?) ?? !row.isRead,
      label: rawDetail?['label'] as bool?,
      receivers: rawDetail?['receivers'],
      ccReceivers: rawDetail?['ccreceivers'],
      bccReceivers: rawDetail?['bccreceivers'],
      senderPicture: rawDetail?['sender_picture'] as String?,
      fromTeam: rawDetail?['from_team'] as int?,
      totalNrOtherToReceivers:
          rawDetail?['total_nr_other_to_reciviers'] as int?,
      totalNrOtherCcReceivers:
          rawDetail?['total_nr_other_cc_receivers'] as int?,
      totalNrOtherBccReceivers:
          rawDetail?['total_nr_other_bcc_receivers'] as int?,
      canReply: rawDetail?['can_reply'] as bool?,
      hasReply: rawDetail?['has_reply'] as bool?,
      hasForward: rawDetail?['has_forward'] as bool?,
      sendDate: rawDetail?['send_date'] as String?,
    );
  }

  SmartschoolMessageHeader? _headerFromLocalRow(Message row) {
    final rawHeader = row.rawHeaderJson;
    if (rawHeader == null || rawHeader.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(rawHeader);
      if (decoded is! Map<String, dynamic>) return null;

      final externalId = int.tryParse(row.externalId) ?? row.id;
      return SmartschoolMessageHeader(
        id: externalId,
        source: row.source,
        from: (decoded['from'] as String?) ?? '',
        fromImage: (decoded['from_image'] as String?) ?? '',
        subject: (decoded['subject'] as String?) ?? row.subject,
        date: (decoded['date'] as String?) ?? row.receivedAt.toIso8601String(),
        status: (decoded['status'] as int?) ?? (row.isRead ? 1 : 0),
        unread: (decoded['unread'] as bool?) ?? !row.isRead,
        hasAttachment: (decoded['attachment'] as bool?) ?? row.hasAttachments,
        label: false,
        deleted: (decoded['deleted'] as bool?) ?? row.isDeleted,
        allowReply: true,
        allowReplyEnabled: true,
        hasReply: false,
        hasForward: false,
        realBox: (decoded['real_box'] as String?) ?? row.mailbox,
        sendDate: decoded['send_date'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  SmartschoolMessageDetail _normalizeDetail(
    SmartschoolMessageDetail detail, {
    SmartschoolMessageHeader? fallbackHeader,
    SmartschoolMessageHeader? fallbackHeaderFromDb,
  }) {
    final header = fallbackHeader ?? fallbackHeaderFromDb;
    final isSent = _isSentMailbox(header?.realBox);
    final fallbackSubject = header?.subject ?? '';

    // For sent messages header.from is the RECIPIENT, not the sender.
    // Using it as a sender fallback would show the wrong name.
    final fallbackFrom = isSent ? '' : (header?.from ?? '');
    final fallbackAvatar =
        (!isSent && header != null && header.fromImage.trim().isNotEmpty)
        ? header.fromImage
        : null;

    final normalizedSubject = _preferFallbackSubject(
      detail.subject,
      fallbackSubject,
    );
    // For sent messages keep a friendly sender label instead of the recipient name.
    final normalizedFrom = isSent
        ? _preferSentSender(detail.from)
        : _preferFallbackSender(detail.from, fallbackFrom);

    // Fall back to header date when the API returns epoch/bad date.
    final normalizedDate = _preferFallbackDate(detail.date, header?.date);

    // For sent messages with empty body the API simply does not return content.
    // Persist an informative placeholder so repeated opens don't re-fetch.
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

    // For sent messages the API returns no recipients.
    // Use header.from (the correspondent) as the primary To recipient.
    final normalizedReceivers = _normalizeSentReceivers(
      detail.receivers,
      isSent: isSent,
      headerFrom: header?.from,
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

  /// True when [realBox] indicates an outbox / sent mailbox.
  bool _isSentMailbox(String? realBox) {
    if (realBox == null) return false;
    final n = realBox.toLowerCase().trim();
    return n == 'sent' || n == 'outbox';
  }

  /// Sent-message detail payloads can omit sender; show a stable local label.
  String _preferSentSender(String candidate) {
    final c = candidate.trim();
    if (c.isEmpty || _isUnavailableSender(c)) {
      return 'You';
    }
    return candidate;
  }

  /// Returns [detailDate] unless it looks like epoch / year < 2000.
  /// Falls back to [fallbackDate] when available.
  String _preferFallbackDate(String detailDate, String? fallbackDate) {
    if (fallbackDate == null) return detailDate;
    final dt = DateTime.tryParse(detailDate);
    if (dt == null || dt.year < 2000) {
      return fallbackDate;
    }
    return detailDate;
  }

  /// For sent messages with no recipients, inject [headerFrom] as the sole To.
  dynamic _normalizeSentReceivers(
    dynamic receivers, {
    required bool isSent,
    String? headerFrom,
  }) {
    if (!isSent) return receivers;
    final isEmpty =
        receivers == null ||
        (receivers is List && receivers.isEmpty) ||
        (receivers is String && receivers.trim().isEmpty);
    if (isEmpty && headerFrom != null && headerFrom.isNotEmpty) {
      return <String>[headerFrom];
    }
    return receivers;
  }

  String _preferFallbackSubject(String candidate, String fallback) {
    final c = candidate.trim();
    final f = fallback.trim();
    if (c.isEmpty || _isMissingSubject(c)) {
      return f.isNotEmpty ? f : candidate;
    }
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
    final normalized = _normalizeLabel(value);
    return normalized.contains('bericht zonder onderwerp') ||
        normalized.contains('zonder onderwerp') ||
        normalized.contains('no subject') ||
        normalized.contains('without subject') ||
        normalized.contains('subject unavailable');
  }

  bool _isUnavailableSender(String value) {
    final normalized = _normalizeLabel(value);
    return normalized.contains('niet beschikbaar') ||
        normalized.contains('not available') ||
        normalized.contains('onbekend');
  }

  String _normalizeLabel(String value) {
    return value
        .toLowerCase()
        .replaceAll('*', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Clear the cache.
  void clear() => state = {};
}

/// Provides the message cache.
final smartschoolMessageCacheProvider =
    NotifierProvider<
      SmartschoolMessageCacheController,
      Map<int, SmartschoolMessageDetail>
    >(SmartschoolMessageCacheController.new);
