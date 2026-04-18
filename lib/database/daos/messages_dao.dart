import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../models/smartschool_message.dart';

part 'messages_dao.g.dart';

class ParticipantIdentity {
  const ParticipantIdentity({
    required this.role,
    required this.contactId,
    required this.displayName,
    required this.externalId,
    required this.source,
  });

  final String role;
  final int contactId;
  final String displayName;
  final String externalId;
  final String source;
}

class ContactInboxSummary {
  ContactInboxSummary({
    required this.contactId,
    required this.displayName,
    required this.avatarUrl,
    required this.latestActivityAt,
    required this.itemCount,
    required this.unreadCount,
  });

  final int contactId;
  final String displayName;
  final String? avatarUrl;
  final DateTime latestActivityAt;
  final int itemCount;
  final int unreadCount;
}

@DriftAccessor(tables: [Messages, MessageParticipants])
class MessagesDao extends DatabaseAccessor<AppDatabase>
    with _$MessagesDaoMixin {
  MessagesDao(super.db);

  // ── Messages ─────────────────────────────────────────────────────────────

  Future<int> insertMessage(MessagesCompanion row) =>
      into(messages).insert(row);

  Future<void> updateMessageById(int id, MessagesCompanion row) =>
      (update(messages)..where((t) => t.id.equals(id))).write(row);

  Future<Message?> findMessage({
    required String source,
    required String externalId,
  }) =>
      (select(messages)..where(
            (t) => t.source.equals(source) & t.externalId.equals(externalId),
          ))
          .getSingleOrNull();

  Future<Message?> getMessageById(int id) =>
      (select(messages)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateFlags({
    required int id,
    required bool isRead,
    required bool isArchived,
    required bool isDeleted,
  }) =>
      (update(messages)..where((t) => t.id.equals(id))).write(
        MessagesCompanion(
          isRead: Value(isRead),
          isArchived: Value(isArchived),
          isDeleted: Value(isDeleted),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Stream<List<Message>> watchInbox({String source = 'smartschool'}) =>
      (select(messages)
            ..where(
              (t) =>
                  t.source.equals(source) &
                  t.mailbox.equals('inbox') &
                  t.isDeleted.equals(false) &
                  t.isArchived.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
          .watch();

  Stream<int> watchUnreadCount({String source = 'smartschool'}) {
    final query = selectOnly(messages)
      ..addColumns([messages.id.count()])
      ..where(
        messages.source.equals(source) &
            messages.mailbox.equals('inbox') &
            messages.isRead.equals(false) &
            messages.isDeleted.equals(false) &
            messages.isArchived.equals(false),
      );
    return query.map((row) => row.read(messages.id.count()) ?? 0).watchSingle();
  }

  // ── MessageParticipants ──────────────────────────────────────────────────

  Future<void> replaceParticipants(
    int messageId,
    List<MessageParticipantsCompanion> rows,
  ) async {
    await (delete(messageParticipants)..where(
          (t) => t.messageId.equals(messageId),
        ))
        .go();
    if (rows.isNotEmpty) {
      await batch((b) => b.insertAll(messageParticipants, rows));
    }
  }

  Future<List<MessageParticipant>> getParticipants(int messageId) =>
      (select(messageParticipants)
            ..where((t) => t.messageId.equals(messageId))
            ..orderBy([(t) => OrderingTerm.asc(t.role)]))
          .get();

  Future<List<ParticipantIdentity>> getParticipantsWithIdentity(
    int messageId,
  ) async {
    final rows = await customSelect(
      '''
      SELECT mp.role,
             ci.contact_id AS contact_id,
             COALESCE(ci.display_name, '') AS display_name,
             COALESCE(ci.external_id, '') AS external_id,
             COALESCE(ci.source, '') AS source
      FROM message_participants mp
      JOIN contact_identities ci ON ci.id = mp.contact_identity_id
      WHERE mp.message_id = ?
      ORDER BY mp.role
      ''',
      variables: [Variable<int>(messageId)],
      readsFrom: {messageParticipants, attachedDatabase.contactIdentities},
    ).get();
    return rows
        .map(
          (r) => ParticipantIdentity(
            role: r.read<String>('role'),
            contactId: r.read<int>('contact_id'),
            displayName: r.read<String>('display_name'),
            externalId: r.read<String>('external_id'),
            source: r.read<String>('source'),
          ),
        )
        .toList();
  }

  /// Returns display names of all resolved participants for [messageId].
  ///
  /// Joins [messageParticipants] with [contactIdentities] to read current names.
  Future<List<String>> getParticipantDisplayNames(int messageId) async {
    final rows = await customSelect(
      '''
      SELECT ci.display_name
      FROM message_participants mp
      JOIN contact_identities ci ON ci.id = mp.contact_identity_id
      WHERE mp.message_id = ?
      ''',
      variables: [Variable<int>(messageId)],
      readsFrom: {messageParticipants, attachedDatabase.contactIdentities},
    ).get();
    return rows
        .map((r) => r.read<String?>('display_name') ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
  }

  // ── Contact inbox queries ────────────────────────────────────────────────

  /// Return contacts with related inbox activity, sorted by most recent message.
  ///
  /// Only messages with at least one resolved participant appear here.
  Future<List<ContactInboxSummary>> getInboxContactSummaries({
    String? source,
  }) async {
    final sourceClause = source == null ? '' : 'AND m.source = ?';
    final variables = <Variable<Object>>[
      if (source != null) Variable<String>(source),
    ];

    final rows = await customSelect(
      '''
      SELECT
        ci.contact_id AS contact_id,
        c.display_name AS display_name,
        (
          SELECT ci2.avatar_url
          FROM contact_identities ci2
          WHERE
            ci2.contact_id = ci.contact_id AND
            ci2.avatar_url IS NOT NULL AND
            TRIM(ci2.avatar_url) <> ''
          ORDER BY
            CASE
              WHEN ci2.source = 'smartschool'
                   AND ci2.avatar_url NOT LIKE '%/initials_%' THEN 0
              WHEN ci2.source = 'outlook' THEN 1
              WHEN ci2.source = 'smartschool' THEN 2
              ELSE 3
            END ASC,
            ci2.last_seen_at DESC
          LIMIT 1
        ) AS avatar_url,
        MAX(m.received_at) AS latest_activity_at,
        COUNT(DISTINCT m.id) AS item_count,
        SUM(CASE WHEN m.is_read = 0 THEN 1 ELSE 0 END) AS unread_count
      FROM message_participants mp
      JOIN contact_identities ci ON ci.id = mp.contact_identity_id
      JOIN messages m ON m.id = mp.message_id
      JOIN contacts c ON c.id = ci.contact_id
      WHERE
        m.is_deleted = 0 AND
        m.is_archived = 0 AND
        (
          (m.mailbox = 'inbox' AND mp.role = 'sender') OR
          (m.mailbox = 'sent'  AND mp.role = 'to')
        )
        $sourceClause
      GROUP BY ci.contact_id
      ORDER BY latest_activity_at DESC, c.display_name COLLATE NOCASE ASC
      ''',
      variables: variables,
      readsFrom: {
        messages,
        messageParticipants,
        attachedDatabase.contacts,
        attachedDatabase.contactIdentities,
      },
    ).get();

    return rows.map((row) {
      return ContactInboxSummary(
        contactId: row.read<int>('contact_id'),
        displayName: row.read<String>('display_name'),
        avatarUrl: row.read<String?>('avatar_url'),
        latestActivityAt: _parseSqlDateTime(row.data['latest_activity_at']),
        itemCount: row.read<int>('item_count'),
        unreadCount: row.read<int>('unread_count'),
      );
    }).toList();
  }

  /// Return message headers related to a contact, newest first.
  ///
  /// Includes any participant role (sender/to/cc/bcc), excluding deleted/archived.
  Future<List<SmartschoolMessageHeader>> getInboxHeadersForContact(
    int contactId, {
    String? source,
    bool onlySelfSentToSelf = false,
  }) async {
    final sourceClause = source == null ? '' : 'AND m.source = ?';
    final selfFilterClause = onlySelfSentToSelf
        ? '''
        AND EXISTS (
          SELECT 1 FROM message_participants s
          JOIN contact_identities ci_s ON ci_s.id = s.contact_identity_id
          WHERE s.message_id = m.id AND ci_s.contact_id = ? AND s.role = 'sender'
        )
        AND EXISTS (
          SELECT 1 FROM message_participants r
          JOIN contact_identities ci_r ON ci_r.id = r.contact_identity_id
          WHERE r.message_id = m.id AND ci_r.contact_id = ? AND r.role <> 'sender'
        )
        '''
        : '';

    final variables = <Variable<Object>>[Variable<int>(contactId)];
    if (source != null) variables.add(Variable<String>(source));
    if (onlySelfSentToSelf) {
      variables.add(Variable<int>(contactId));
      variables.add(Variable<int>(contactId));
    }

    final rows = await customSelect(
      '''
      SELECT DISTINCT
        m.id AS local_message_id,
        m.source AS source,
        m.external_id AS external_id,
        m.subject AS subject,
        m.received_at AS activity_at,
        m.is_read AS is_read,
        m.is_deleted AS is_deleted,
        m.has_attachments AS has_attachments,
        m.mailbox AS mailbox,
        COALESCE(m.sender_avatar_url, '') AS sender_avatar_url,
        COALESCE(
          (
            SELECT ci_s.display_name
            FROM message_participants mp_s
            JOIN contact_identities ci_s ON ci_s.id = mp_s.contact_identity_id
            WHERE mp_s.message_id = m.id AND mp_s.role = 'sender'
            LIMIT 1
          ),
          ''
        ) AS sender_name
      FROM message_participants mp
      JOIN contact_identities ci ON ci.id = mp.contact_identity_id
      JOIN messages m ON m.id = mp.message_id
      WHERE
        ci.contact_id = ? AND
        m.is_deleted = 0 AND
        m.is_archived = 0 AND
        (
          (m.mailbox = 'inbox' AND mp.role = 'sender') OR
          (m.mailbox = 'sent'  AND mp.role = 'to')
        )
        $sourceClause
        $selfFilterClause
      ORDER BY m.received_at DESC, m.id DESC
      ''',
      variables: variables,
      readsFrom: {
        messages,
        messageParticipants,
        attachedDatabase.contactIdentities,
      },
    ).get();

    return rows.map((row) {
      final externalId = row.read<String>('external_id');
      final parsedExternalId = int.tryParse(externalId);
      final localId = row.read<int>('local_message_id');
      final messageId = parsedExternalId ?? localId;
      final activityRaw = row.data['activity_at'];
      final activityAt = _parseSqlDateTime(activityRaw).toIso8601String();

      return SmartschoolMessageHeader(
        id: messageId,
        source: row.read<String>('source'),
        from: row.read<String>('sender_name'),
        fromImage: row.read<String>('sender_avatar_url'),
        subject: row.read<String>('subject'),
        date: activityAt,
        status: row.read<bool>('is_read') ? 1 : 0,
        unread: !row.read<bool>('is_read'),
        hasAttachment: row.read<bool>('has_attachments'),
        label: false,
        deleted: row.read<bool>('is_deleted'),
        allowReply: true,
        allowReplyEnabled: true,
        hasReply: false,
        hasForward: false,
        realBox: row.read<String>('mailbox'),
      );
    }).toList();
  }

  /// Return contact IDs that act as sender in the sent mailbox.
  Future<Set<int>> getSentSenderContactIds({String? source}) async {
    final sourceClause = source == null ? '' : 'AND m.source = ?';
    final variables = <Variable<Object>>[
      if (source != null) Variable<String>(source),
    ];

    final rows = await customSelect(
      '''
      SELECT DISTINCT ci.contact_id AS contact_id
      FROM message_participants mp
      JOIN contact_identities ci ON ci.id = mp.contact_identity_id
      JOIN messages m ON m.id = mp.message_id
      WHERE
        m.mailbox = 'sent' AND
        m.is_deleted = 0 AND
        m.is_archived = 0 AND
        mp.role = 'sender'
        $sourceClause
      ''',
      variables: variables,
      readsFrom: {
        messages,
        messageParticipants,
        attachedDatabase.contactIdentities,
      },
    ).get();

    return rows.map((row) => row.read<int>('contact_id')).toSet();
  }

  Future<void> deleteMessageById(int id) => transaction(() async {
    await customStatement('DELETE FROM message_fts WHERE rowid = ?', [id]);
    await (delete(messageParticipants)..where(
          (t) => t.messageId.equals(id),
        ))
        .go();
    await (delete(attachedDatabase.messageAttachments)..where(
          (t) => t.messageId.equals(id),
        ))
        .go();
    await (delete(messages)..where((t) => t.id.equals(id))).go();
  });

  /// Hard-delete messages for [source]/[mailbox] not in [activeExternalIds].
  Future<int> deleteStaleMessages({
    required String source,
    required String mailbox,
    required Set<String> activeExternalIds,
  }) async {
    final allRows = await (selectOnly(messages)
          ..addColumns([messages.id, messages.externalId])
          ..where(
            messages.source.equals(source) & messages.mailbox.equals(mailbox),
          ))
        .map(
          (row) => (
            id: row.read(messages.id)!,
            externalId: row.read(messages.externalId)!,
          ),
        )
        .get();

    final staleIds = allRows
        .where((r) => !activeExternalIds.contains(r.externalId))
        .map((r) => r.id)
        .toList();

    if (staleIds.isEmpty) return 0;

    await transaction(() async {
      for (final id in staleIds) {
        await customStatement('DELETE FROM message_fts WHERE rowid = ?', [id]);
      }
      await (delete(messageParticipants)..where(
            (t) => t.messageId.isIn(staleIds),
          ))
          .go();
      await (delete(attachedDatabase.messageAttachments)..where(
            (t) => t.messageId.isIn(staleIds),
          ))
          .go();
      await (delete(messages)..where((t) => t.id.isIn(staleIds))).go();
    });

    return staleIds.length;
  }

  DateTime _parseSqlDateTime(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is int) return _fromEpochAuto(raw);
    final text = raw?.toString();
    if (text == null || text.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    final parsedIso = DateTime.tryParse(text);
    if (parsedIso != null) return parsedIso;
    final parsedEpoch = int.tryParse(text);
    if (parsedEpoch != null) return _fromEpochAuto(parsedEpoch);
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  DateTime _fromEpochAuto(int value) {
    final abs = value.abs();
    if (abs < 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
    }
    if (abs > 100000000000000) {
      return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
}
