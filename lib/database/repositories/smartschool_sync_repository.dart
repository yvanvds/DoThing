import 'package:drift/drift.dart';

import '../app_database.dart';

export '../app_database.dart' show Message, MessageParticipant;

import '../../models/smartschool_message.dart';

const _kSource = 'smartschool';

/// Orchestrates persistence of Smartschool messages into the local database.
///
/// Design contract:
///  - [syncHeaders] stores message metadata only. No participants are created.
///    Returns the list of newly inserted headers so the caller can eagerly
///    fetch and sync their full detail.
///  - [syncDetail] resolves stable provider identities from the detail payload,
///    creates participant rows, and updates the FTS index. A participant row is
///    only written when a stable provider ID is available — never from a display
///    name alone.
///  - Messages with no resolved participants are invisible to contact-grouped
///    inbox queries. This is intentional.
class SmartschoolSyncRepository {
  SmartschoolSyncRepository(this._db);

  final AppDatabase _db;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Persist a batch of message headers.
  ///
  /// Returns headers that were newly inserted (not previously known).
  /// Updated headers (fingerprint change only) are persisted but not returned —
  /// their participants and identities are already resolved.
  Future<List<SmartschoolMessageHeader>> syncHeaders(
    List<SmartschoolMessageHeader> headers, {
    String mailbox = 'inbox',
  }) async {
    await _db.syncStateDao.markAttempt(source: _kSource, scope: mailbox);

    final newHeaders = <SmartschoolMessageHeader>[];
    DateTime? latestReceivedAt;
    String? latestExternalId;

    try {
      for (final header in headers) {
        final externalId = header.id.toString();
        final fingerprint = _headerFingerprint(header);
        final receivedAt = _parseDate(header.date) ?? DateTime.now();

        final existing = await _db.messagesDao.findMessage(
          source: _kSource,
          externalId: externalId,
        );

        if (existing != null && existing.headerFingerprint == fingerprint) {
          continue;
        }

        // Sender avatar URL: only use it for inbox messages because for sent
        // messages fromImage contains the current user's avatar, not the
        // recipient's.
        final senderAvatarUrl =
            mailbox != 'sent' && _isValidAvatarUrl(header.fromImage)
            ? header.fromImage
            : null;

        if (existing == null) {
          await _db.messagesDao.insertMessage(
            MessagesCompanion.insert(
              source: _kSource,
              externalId: externalId,
              mailbox: mailbox,
              subject: Value(header.subject),
              senderAvatarUrl: Value(senderAvatarUrl),
              receivedAt: receivedAt,
              isRead: Value(!header.unread),
              hasAttachments: Value(header.hasAttachment),
              isDeleted: Value(header.deleted),
              headerFingerprint: Value(fingerprint),
              updatedAt: Value(DateTime.now()),
            ),
          );
          newHeaders.add(header);
        } else {
          await _db.messagesDao.updateMessageById(
            existing.id,
            MessagesCompanion(
              mailbox: Value(mailbox),
              subject: Value(header.subject),
              senderAvatarUrl: Value(senderAvatarUrl),
              receivedAt: Value(receivedAt),
              isRead: Value(!header.unread),
              hasAttachments: Value(header.hasAttachment),
              isDeleted: Value(header.deleted),
              headerFingerprint: Value(fingerprint),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }

        if (latestReceivedAt == null || receivedAt.isAfter(latestReceivedAt)) {
          latestReceivedAt = receivedAt;
          latestExternalId = externalId;
        }
      }

      await _db.syncStateDao.markSuccess(
        source: _kSource,
        scope: mailbox,
        highWaterReceivedAt: latestReceivedAt,
        highWaterExternalId: latestExternalId,
      );
    } catch (e, st) {
      await _db.syncStateDao.markFailure(
        source: _kSource,
        scope: mailbox,
        error: '$e\n$st',
      );
      rethrow;
    }

    return newHeaders;
  }

  /// Delete local headers for [mailbox] not in [activeIds].
  Future<int> deleteStaleHeaders({
    required String mailbox,
    required Set<String> activeIds,
  }) => _db.messagesDao.deleteStaleMessages(
    source: _kSource,
    mailbox: mailbox,
    activeExternalIds: activeIds,
  );

  /// Resolve identities from [detail] and persist participant links.
  ///
  /// Participant rows are only created for identities with stable provider IDs
  /// found in [detail.replyAllToRecipients] / [detail.replyAllCcRecipients].
  /// Recipients without a stable ID are silently skipped.
  ///
  /// Also updates the FTS index with the computed body text and participant
  /// names, and refreshes [senderAvatarUrl] on the message row when the detail
  /// provides a valid picture URL.
  Future<void> syncDetail(SmartschoolMessageDetail detail) async {
    final externalId = detail.id.toString();
    final existing = await _db.messagesDao.findMessage(
      source: _kSource,
      externalId: externalId,
    );
    if (existing == null) return;

    // Index replyAll recipients for stable-ID lookup.
    final resolvedToIndex = _indexResolvedRecipients(
      detail.replyAllToRecipients,
    );
    final resolvedCcIndex = _indexResolvedRecipients(
      detail.replyAllCcRecipients,
    );

    final participants = <MessageParticipantsCompanion>[];
    final participantNames = <String>[];

    // ── Sender ──────────────────────────────────────────────────────────────
    // Try to find the sender in replyAllToRecipients for a stable ID.
    final senderResolved = _takeResolvedRecipient(
      resolvedToIndex,
      SmartschoolMessageRecipient(displayName: detail.from),
    );
    final senderAvatar =
        _isValidAvatarUrl(detail.senderPicture) ? detail.senderPicture : null;
    final senderRecipient = SmartschoolMessageRecipient(
      displayName: detail.from,
      userId: senderResolved?.userId,
      ssId: senderResolved?.ssId,
      picture: senderAvatar ?? senderResolved?.picture,
    );
    final senderResult = await _resolveRecipient(senderRecipient);
    if (senderResult != null) {
      participants.add(
        MessageParticipantsCompanion.insert(
          messageId: existing.id,
          contactIdentityId: senderResult.identityId,
          role: 'sender',
        ),
      );
      participantNames.add(senderResult.displayName);
    }

    // ── To recipients ────────────────────────────────────────────────────────
    for (final recipient in detail.receivers) {
      final resolved = _takeResolvedRecipient(resolvedToIndex, recipient);
      final result = await _resolveRecipient(recipient, resolved: resolved);
      if (result != null) {
        participants.add(
          MessageParticipantsCompanion.insert(
            messageId: existing.id,
            contactIdentityId: result.identityId,
            role: 'to',
          ),
        );
        participantNames.add(result.displayName);
      }
    }

    // ── CC recipients ────────────────────────────────────────────────────────
    for (final recipient in detail.ccReceivers) {
      final resolved = _takeResolvedRecipient(resolvedCcIndex, recipient);
      final result = await _resolveRecipient(recipient, resolved: resolved);
      if (result != null) {
        participants.add(
          MessageParticipantsCompanion.insert(
            messageId: existing.id,
            contactIdentityId: result.identityId,
            role: 'cc',
          ),
        );
        participantNames.add(result.displayName);
      }
    }

    // ── BCC recipients ───────────────────────────────────────────────────────
    // No replyAllBcc list is available from the API, so BCC recipients without
    // an explicit stable ID cannot be resolved. Skipped intentionally.
    for (final recipient in detail.bccReceivers) {
      final result = await _resolveRecipient(recipient);
      if (result != null) {
        participants.add(
          MessageParticipantsCompanion.insert(
            messageId: existing.id,
            contactIdentityId: result.identityId,
            role: 'bcc',
          ),
        );
        participantNames.add(result.displayName);
      }
    }

    await _db.messagesDao.replaceParticipants(existing.id, participants);

    // Refresh sender avatar URL if detail provides a better one.
    if (senderAvatar != null) {
      await _db.messagesDao.updateMessageById(
        existing.id,
        MessagesCompanion(senderAvatarUrl: Value(senderAvatar)),
      );
    }

    // Update FTS with ephemerally computed body text.
    final bodyText = _stripHtml(detail.body);
    await _db.searchDao.upsertFtsRow(
      messageId: existing.id,
      subject: detail.subject,
      bodyText: bodyText.isEmpty ? null : bodyText,
      participantNames: participantNames.join(' '),
    );
  }

  /// Persist attachment metadata and refresh the FTS row.
  Future<void> syncAttachments(
    int messageExternalId,
    List<SmartschoolAttachment> attachments,
  ) async {
    final existing = await _db.messagesDao.findMessage(
      source: _kSource,
      externalId: messageExternalId.toString(),
    );
    if (existing == null || attachments.isEmpty) return;

    final rows = attachments
        .map(
          (a) => MessageAttachmentsCompanion.insert(
            messageId: existing.id,
            source: _kSource,
            externalId: Value(a.index.toString()),
            filename: a.name,
            sizeBytes: Value(a.size > 0 ? a.size : null),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .toList();

    await _db.attachmentsDao.upsertAttachments(rows);

    final participantNames = await _db.messagesDao.getParticipantDisplayNames(
      existing.id,
    );
    final attachmentNames = attachments.map((a) => a.name).join(' ');

    await _db.searchDao.upsertFtsRow(
      messageId: existing.id,
      subject: existing.subject,
      participantNames: participantNames.join(' '),
      attachmentNames: attachmentNames,
    );
  }

  // ── Convenience streams ───────────────────────────────────────────────────

  Stream<List<Message>> watchInbox() => _db.messagesDao.watchInbox();

  Stream<int> watchUnreadCount() => _db.messagesDao.watchUnreadCount();

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Resolve [recipient] to a stable identity, preferring [resolved] for IDs.
  ///
  /// Returns null when no stable provider ID (userId / ssId) is available.
  Future<_ResolvedParticipant?> _resolveRecipient(
    SmartschoolMessageRecipient recipient, {
    SmartschoolMessageRecipient? resolved,
  }) async {
    final candidate = resolved ?? recipient;
    final extId = _stableExternalId(candidate);
    if (extId == null) return null;

    final name = candidate.displayName.trim().isNotEmpty
        ? candidate.displayName.trim()
        : recipient.displayName.trim();
    if (name.isEmpty) return null;

    final identityId = await _db.contactsDao.upsertIdentity(
      source: _kSource,
      externalId: extId,
      displayName: name,
      avatarUrl:
          _isValidAvatarUrl(candidate.picture) ? candidate.picture : null,
    );

    return _ResolvedParticipant(identityId: identityId, displayName: name);
  }

  String? _stableExternalId(SmartschoolMessageRecipient r) {
    if (r.userId != null) return 'user:${r.userId}';
    if (r.ssId != null) return 'ss:${r.ssId}';
    return null;
  }

  Map<String, List<SmartschoolMessageRecipient>> _indexResolvedRecipients(
    List<SmartschoolMessageRecipient> recipients,
  ) {
    final index = <String, List<SmartschoolMessageRecipient>>{};
    for (final r in recipients) {
      final key = r.normalizedDisplayName;
      if (key.isNotEmpty) index.putIfAbsent(key, () => []).add(r);
    }
    return index;
  }

  SmartschoolMessageRecipient? _takeResolvedRecipient(
    Map<String, List<SmartschoolMessageRecipient>> index,
    SmartschoolMessageRecipient recipient,
  ) {
    final matches = index[recipient.normalizedDisplayName];
    if (matches == null || matches.isEmpty) return null;
    return matches.removeAt(0);
  }

  String _headerFingerprint(SmartschoolMessageHeader h) =>
      '${h.unread}|${h.deleted}|${h.hasAttachment}|${h.status}';

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool _isValidAvatarUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), ' ')
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}

class _ResolvedParticipant {
  const _ResolvedParticipant({
    required this.identityId,
    required this.displayName,
  });

  final int identityId;
  final String displayName;
}
