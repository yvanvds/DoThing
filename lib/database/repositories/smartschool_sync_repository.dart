import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';

// Re-exported for convenience
export '../app_database.dart' show Message, MessageParticipant;

// Import SmartschoolMessageHeader and SmartschoolMessageDetail from models.
// The relative import path keeps this repository independent of the service layer.
import '../../models/smartschool_message.dart';

const _kSource = 'smartschool';

/// Orchestrates persistence of Smartschool messages into the local database.
///
/// This class sits between the remote bridge/DTOs and the Drift DAOs.
/// It is responsible for:
///  - deduplication (upsert by source + external_id)
///  - contact/identity resolution (stub contacts when no real ID is available)
///  - participant linking
///  - attachment metadata upsert
///  - FTS index maintenance
///  - sync state bookkeeping
///
/// NOTE: Smartschool message headers currently carry only a display name for
/// the sender, not a stable user ID.  Contact identities are therefore keyed
/// by `display:<name>` until the bridge is extended to expose real user IDs.
/// When real IDs become available, replace the `_identityKey` helper and
/// re-run an enrichment pass.
class SmartschoolSyncRepository {
  SmartschoolSyncRepository(this._db);

  final AppDatabase _db;

  // ── Public API ────────────────────────────────────────────────────────

  /// Persist a batch of inbox message headers.
  ///
  /// Returns the number of new messages inserted (fingerprint changed or new).
  Future<int> syncHeaders(
    List<SmartschoolMessageHeader> headers, {
    String mailbox = 'inbox',
  }) async {
    await _db.syncStateDao.markAttempt(source: _kSource, scope: mailbox);

    int newCount = 0;
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
          // Unchanged — skip.
          continue;
        }

        final companion = MessagesCompanion.insert(
          source: _kSource,
          externalId: externalId,
          mailbox: mailbox,
          subject: Value(header.subject),
          receivedAt: receivedAt,
          isRead: Value(!header.unread),
          hasAttachments: Value(header.hasAttachment),
          isDeleted: Value(header.deleted),
          headerFingerprint: Value(fingerprint),
          rawHeaderJson: Value(jsonEncode(_headerToMap(header))),
          updatedAt: Value(DateTime.now()),
        );

        final localId = await _db.transaction(() async {
          if (existing == null) {
            return _db.messagesDao.insertMessage(companion);
          }

          await _db.messagesDao.updateMessageById(
            existing.id,
            MessagesCompanion(
              mailbox: Value(mailbox),
              subject: Value(header.subject),
              receivedAt: Value(receivedAt),
              isRead: Value(!header.unread),
              hasAttachments: Value(header.hasAttachment),
              isDeleted: Value(header.deleted),
              headerFingerprint: Value(fingerprint),
              rawHeaderJson: Value(jsonEncode(_headerToMap(header))),
              updatedAt: Value(DateTime.now()),
            ),
          );
          return existing.id;
        });

        // Resolve the sender as a stub contact identity.
        final senderId = await _resolveSenderStub(
          displayName: header.from,
          avatarUrl: header.fromImage,
        );

        await _db.messagesDao.replaceParticipants(localId, [
          MessageParticipantsCompanion.insert(
            messageId: localId,
            role: 'sender',
            position: const Value(0),
            displayNameSnapshot: header.from,
            contactId: Value(senderId),
          ),
        ]);

        // Rebuild FTS row for this message (no body yet at header stage).
        await _db.searchDao.upsertFtsRow(
          messageId: localId,
          subject: header.subject,
          participantNames: header.from,
        );

        newCount++;

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

    return newCount;
  }

  /// Delete local headers for [mailbox] whose external ID is not among
  /// [activeIds] (i.e. they no longer exist on Smartschool).
  ///
  /// Returns the number of deleted rows.
  Future<int> deleteStaleHeaders({
    required String mailbox,
    required Set<String> activeIds,
  }) => _db.messagesDao.deleteStaleMessages(
    source: _kSource,
    mailbox: mailbox,
    activeExternalIds: activeIds,
  );

  /// Persist the full body detail for a message.
  ///
  /// Also resolves all participant roles (to, cc, bcc) from the detail payload
  /// and rebuilds the FTS row.
  Future<void> syncDetail(SmartschoolMessageDetail detail) async {
    final externalId = detail.id.toString();

    final existing = await _db.messagesDao.findMessage(
      source: _kSource,
      externalId: externalId,
    );

    if (existing == null) return;

    final bodyRaw = detail.body;
    final bodyText = _stripHtml(bodyRaw);

    await _db.messagesDao.updateMessageDetail(
      id: existing.id,
      bodyRaw: bodyRaw,
      bodyText: bodyText,
      bodyFormat: 'html',
      rawDetailJson: jsonEncode(_detailToMap(detail)),
    );

    // Build participant list from detail (sender + all recipient groups).
    final participants = <MessageParticipantsCompanion>[];
    int pos = 0;
    final senderAvatarUrl = _resolveDetailSenderAvatar(existing, detail);

    final senderId = await _resolveSenderStub(
      displayName: detail.from,
      avatarUrl: senderAvatarUrl,
    );

    participants.add(
      MessageParticipantsCompanion.insert(
        messageId: existing.id,
        role: 'sender',
        position: Value(pos++),
        displayNameSnapshot: detail.from,
        contactId: Value(senderId),
      ),
    );

    for (final name in _parseRecipients(detail.receivers)) {
      final cid = await _resolveSenderStub(displayName: name);
      participants.add(
        MessageParticipantsCompanion.insert(
          messageId: existing.id,
          role: 'to',
          position: Value(pos++),
          displayNameSnapshot: name,
          contactId: Value(cid),
        ),
      );
    }

    for (final name in _parseRecipients(detail.ccReceivers)) {
      final cid = await _resolveSenderStub(displayName: name);
      participants.add(
        MessageParticipantsCompanion.insert(
          messageId: existing.id,
          role: 'cc',
          position: Value(pos++),
          displayNameSnapshot: name,
          contactId: Value(cid),
        ),
      );
    }

    for (final name in _parseRecipients(detail.bccReceivers)) {
      final cid = await _resolveSenderStub(displayName: name);
      participants.add(
        MessageParticipantsCompanion.insert(
          messageId: existing.id,
          role: 'bcc',
          position: Value(pos++),
          displayNameSnapshot: name,
          contactId: Value(cid),
        ),
      );
    }

    await _db.messagesDao.replaceParticipants(existing.id, participants);

    // Rebuild FTS with body and all participant names.
    final participantNames = participants
        .map((p) => p.displayNameSnapshot.value)
        .join(' ');

    await _db.searchDao.upsertFtsRow(
      messageId: existing.id,
      subject: detail.subject,
      bodyText: bodyText,
      participantNames: participantNames,
    );
  }

  /// Persist attachment metadata for a message.
  ///
  /// Also appends attachment filenames to the FTS row.
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

    // Refresh FTS row: append attachment filenames.
    final msg = existing;
    final allParticipants = await _db.messagesDao.getParticipants(msg.id);
    final participantNames = allParticipants
        .map((p) => p.displayNameSnapshot)
        .join(' ');
    final attachmentNames = attachments.map((a) => a.name).join(' ');

    await _db.searchDao.upsertFtsRow(
      messageId: msg.id,
      subject: msg.subject,
      bodyText: msg.bodyText,
      participantNames: participantNames,
      attachmentNames: attachmentNames,
    );
  }

  // ── Convenience streams (delegate to DAO) ────────────────────────────

  Stream<List<Message>> watchInbox() => _db.messagesDao.watchInbox();

  Stream<int> watchUnreadCount() => _db.messagesDao.watchUnreadCount();

  // ── Private helpers ──────────────────────────────────────────────────

  /// Resolve a sender display name to a local contact ID.
  ///
  /// Uses a `display:<name>` stub key until the bridge exposes real user IDs.
  Future<int?> _resolveSenderStub({
    required String displayName,
    String? avatarUrl,
  }) async {
    if (displayName.isEmpty) return null;

    return _db.contactsDao.upsertIdentity(
      source: _kSource,
      externalId: _identityKey(displayName),
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  /// Temporary stub key: a display-name-based identifier.
  ///
  /// Replace with the real Smartschool user ID once the bridge provides it.
  String _identityKey(String displayName) =>
      'display:${displayName.toLowerCase().trim()}';

  /// Compute a simple but stable fingerprint of the mutable header fields.
  String _headerFingerprint(SmartschoolMessageHeader h) {
    // Include only fields that can change on subsequent polls.
    return '${h.unread}|${h.deleted}|${h.hasAttachment}|${h.status}';
  }

  /// Parse an ISO-8601 date string, returning null on failure.
  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Strip HTML tags to produce searchable plain text.
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), ' ')
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  List<String> _parseRecipients(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map((e) => e is Map ? (e['name'] as String? ?? '') : e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.isNotEmpty) return [raw];
    return [];
  }

  String? _resolveDetailSenderAvatar(
    Message existing,
    SmartschoolMessageDetail d,
  ) {
    final fromHeader = _extractHeaderAvatarUrl(existing.rawHeaderJson);
    if (_isValidAvatarUrl(fromHeader)) return fromHeader;
    if (_isValidAvatarUrl(d.senderPicture)) return d.senderPicture;
    return null;
  }

  String? _extractHeaderAvatarUrl(String? rawHeaderJson) {
    if (rawHeaderJson == null || rawHeaderJson.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawHeaderJson);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded['from_image'] as String?;
    } catch (_) {
      return null;
    }
  }

  bool _isValidAvatarUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  Map<String, dynamic> _headerToMap(SmartschoolMessageHeader h) => {
    'id': h.id,
    'from': h.from,
    'from_image': h.fromImage,
    'subject': h.subject,
    'date': h.date,
    'status': h.status,
    'unread': h.unread,
    'attachment': h.hasAttachment,
    'deleted': h.deleted,
    'real_box': h.realBox,
    'send_date': h.sendDate,
  };

  Map<String, dynamic> _detailToMap(SmartschoolMessageDetail d) => {
    'id': d.id,
    'from': d.from,
    'subject': d.subject,
    'date': d.date,
    'status': d.status,
    'attachment': d.attachment,
    'unread': d.unread,
  };
}
