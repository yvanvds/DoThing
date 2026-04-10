import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../models/smartschool_message.dart';

part 'messages_dao.g.dart';

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

  /// Insert a message row.
  ///
  /// Returns the local row id.
  Future<int> insertMessage(MessagesCompanion row) {
    return into(messages).insert(row);
  }

  /// Update an existing message by local [id].
  Future<void> updateMessageById(int id, MessagesCompanion row) {
    return (update(messages)..where((t) => t.id.equals(id))).write(row);
  }

  /// Find a message by (source, externalId).
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

  /// Set the full message body after a detail fetch.
  Future<void> updateMessageDetail({
    required int id,
    required String bodyRaw,
    required String bodyText,
    required String bodyFormat,
    String? rawDetailJson,
  }) async {
    await (update(messages)..where((t) => t.id.equals(id))).write(
      MessagesCompanion(
        bodyRaw: Value(bodyRaw),
        bodyText: Value(bodyText),
        bodyFormat: Value(bodyFormat),
        rawDetailJson: Value(rawDetailJson),
        detailFetchedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update only the mutable remote state flags (read, archive, delete).
  Future<void> updateFlags({
    required int id,
    required bool isRead,
    required bool isArchived,
    required bool isDeleted,
  }) async {
    await (update(messages)..where((t) => t.id.equals(id))).write(
      MessagesCompanion(
        isRead: Value(isRead),
        isArchived: Value(isArchived),
        isDeleted: Value(isDeleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Watch all inbox messages, newest first.
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

  /// Watch the count of unread inbox messages.
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

  /// Replace all participants for a message in a single batch.
  Future<void> replaceParticipants(
    int messageId,
    List<MessageParticipantsCompanion> rows,
  ) async {
    await (delete(
      messageParticipants,
    )..where((t) => t.messageId.equals(messageId))).go();
    await batch((b) => b.insertAll(messageParticipants, rows));
  }

  Future<List<MessageParticipant>> getParticipants(int messageId) =>
      (select(messageParticipants)
            ..where((t) => t.messageId.equals(messageId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.role),
              (t) => OrderingTerm.asc(t.position),
            ]))
          .get();

  Stream<List<MessageParticipant>> watchParticipants(int messageId) =>
      (select(messageParticipants)
            ..where((t) => t.messageId.equals(messageId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.role),
              (t) => OrderingTerm.asc(t.position),
            ]))
          .watch();

  /// Return contacts with related inbox activity, newest first.
  ///
  /// Includes any participant role (sender/to/cc/bcc), excluding
  /// archived/deleted messages.
  Future<List<ContactInboxSummary>> getInboxContactSummaries({
    String source = 'smartschool',
  }) async {
    final rows = await customSelect(
      '''
      SELECT
        mp.contact_id AS contact_id,
        COALESCE(c.display_name, MAX(mp.display_name_snapshot), '') AS display_name,
        c.primary_avatar_url AS avatar_url,
        MAX(COALESCE(m.sent_at, m.received_at)) AS latest_activity_at,
        COUNT(DISTINCT m.id) AS item_count,
        SUM(CASE WHEN m.is_read = 0 THEN 1 ELSE 0 END) AS unread_count
      FROM message_participants mp
      INNER JOIN messages m ON m.id = mp.message_id
      LEFT JOIN contacts c ON c.id = mp.contact_id
      WHERE
        m.source = ? AND
        m.mailbox IN ('inbox', 'sent') AND
        m.is_deleted = 0 AND
        m.is_archived = 0 AND
        mp.contact_id IS NOT NULL
      GROUP BY mp.contact_id, c.display_name, c.primary_avatar_url
      ORDER BY latest_activity_at DESC, display_name COLLATE NOCASE ASC
      ''',
      variables: [Variable<String>(source)],
      readsFrom: {messages, messageParticipants},
    ).get();

    return rows.map((row) {
      final contactId = row.read<int>('contact_id');
      final displayName = row.read<String>('display_name');
      final avatarUrl = row.read<String?>('avatar_url');
      final latestRaw = row.data['latest_activity_at'];
      final latestActivityAt = _parseSqlDateTime(latestRaw);
      final itemCount = row.read<int>('item_count');
      final unreadCount = row.read<int>('unread_count');

      return ContactInboxSummary(
        contactId: contactId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        latestActivityAt: latestActivityAt,
        itemCount: itemCount,
        unreadCount: unreadCount,
      );
    }).toList();
  }

  /// Return message headers related to a contact, newest first.
  ///
  /// Includes any participant role (sender/to/cc/bcc), excluding
  /// archived/deleted messages.
  Future<List<SmartschoolMessageHeader>> getInboxHeadersForContact(
    int contactId, {
    String source = 'smartschool',
    bool onlySelfSentToSelf = false,
  }) async {
    final selfFilterClause = onlySelfSentToSelf
        ? '''
        AND EXISTS (
          SELECT 1
          FROM message_participants s
          WHERE s.message_id = m.id AND s.contact_id = ? AND s.role = 'sender'
        )
        AND EXISTS (
          SELECT 1
          FROM message_participants r
          WHERE r.message_id = m.id AND r.contact_id = ? AND r.role <> 'sender'
        )
      '''
        : '';

    final variables = <Variable<Object>>[
      Variable<int>(contactId),
      Variable<String>(source),
    ];
    if (onlySelfSentToSelf) {
      variables.add(Variable<int>(contactId));
      variables.add(Variable<int>(contactId));
    }

    final rows = await customSelect(
      '''
      SELECT DISTINCT
        m.id AS local_message_id,
        m.external_id AS external_id,
        m.subject AS subject,
        COALESCE(m.sent_at, m.received_at) AS activity_at,
        m.is_read AS is_read,
        m.is_deleted AS is_deleted,
        m.has_attachments AS has_attachments,
        m.mailbox AS mailbox,
        COALESCE(
          (
            SELECT sp.display_name_snapshot
            FROM message_participants sp
            WHERE sp.message_id = m.id AND sp.role = 'sender'
            ORDER BY sp.position ASC
            LIMIT 1
          ),
          ''
        ) AS sender_name
      FROM message_participants mp
      INNER JOIN messages m ON m.id = mp.message_id
      WHERE
        mp.contact_id = ? AND
        m.source = ? AND
        m.mailbox IN ('inbox', 'sent') AND
        m.is_deleted = 0 AND
        m.is_archived = 0
        $selfFilterClause
      ORDER BY activity_at DESC, m.id DESC
      ''',
      variables: variables,
      readsFrom: {messages, messageParticipants},
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
        from: row.read<String>('sender_name'),
        fromImage: '',
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
  ///
  /// In Smartschool this maps to the currently authenticated account contact.
  Future<Set<int>> getSentSenderContactIds({
    String source = 'smartschool',
  }) async {
    final rows = await customSelect(
      '''
      SELECT DISTINCT mp.contact_id AS contact_id
      FROM message_participants mp
      INNER JOIN messages m ON m.id = mp.message_id
      WHERE
        m.source = ? AND
        m.mailbox = 'sent' AND
        m.is_deleted = 0 AND
        m.is_archived = 0 AND
        mp.role = 'sender' AND
        mp.contact_id IS NOT NULL
      ''',
      variables: [Variable<String>(source)],
      readsFrom: {messages, messageParticipants},
    ).get();

    return rows.map((row) => row.read<int>('contact_id')).toSet();
  }

  DateTime _parseSqlDateTime(Object? raw) {
    if (raw is DateTime) return raw;

    if (raw is int) {
      return _fromEpochAuto(raw);
    }

    final text = raw?.toString();
    if (text == null || text.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    final parsedIso = DateTime.tryParse(text);
    if (parsedIso != null) return parsedIso;

    final parsedEpoch = int.tryParse(text);
    if (parsedEpoch != null) {
      return _fromEpochAuto(parsedEpoch);
    }

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
