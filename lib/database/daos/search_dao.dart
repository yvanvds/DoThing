import 'package:drift/drift.dart';

import '../app_database.dart';

part 'search_dao.g.dart';

/// Result row returned by a full-text search query.
class MessageSearchResult {
  final int messageId;
  final String subject;
  final String? bodyText;
  final DateTime receivedAt;
  final bool isRead;
  final double? rank;

  const MessageSearchResult({
    required this.messageId,
    required this.subject,
    this.bodyText,
    required this.receivedAt,
    required this.isRead,
    this.rank,
  });
}

@DriftAccessor(tables: [Messages])
class SearchDao extends DatabaseAccessor<AppDatabase> with _$SearchDaoMixin {
  SearchDao(super.db);

  // ── FTS index maintenance ─────────────────────────────────────────────

  /// Insert or replace a row in the FTS virtual table.
  ///
  /// FTS5 virtual tables do not support ON CONFLICT / UPSERT, so we use a
  /// delete-then-insert pattern.  Both statements must run inside the same
  /// enclosing transaction to keep the index consistent.
  Future<void> upsertFtsRow({
    required int messageId,
    required String subject,
    String? bodyText,
    String participantNames = '',
    String attachmentNames = '',
  }) async {
    await db.customStatement('DELETE FROM message_fts WHERE rowid = ?', [
      messageId,
    ]);
    await db.customInsert(
      '''
      INSERT INTO message_fts
        (rowid, message_id, subject, body_text, participant_names, attachment_names)
      VALUES
        (?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withInt(messageId),
        Variable.withInt(messageId),
        Variable.withString(subject),
        Variable.withString(bodyText ?? ''),
        Variable.withString(participantNames),
        Variable.withString(attachmentNames),
      ],
    );
  }

  /// Remove an FTS row when the parent message is deleted.
  Future<void> deleteFtsRow(int messageId) {
    return db.customStatement('DELETE FROM message_fts WHERE rowid = ?', [
      messageId,
    ]);
  }

  // ── Queries ───────────────────────────────────────────────────────────

  /// Full-text search returning matched messages, ordered by rank.
  ///
  /// [query] supports standard FTS5 syntax (phrase, prefix, boolean).
  Future<List<MessageSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final rows = await db
        .customSelect(
          '''
      SELECT
        m.id          AS message_id,
        m.subject     AS subject,
        m.body_text   AS body_text,
        m.received_at AS received_at,
        m.is_read     AS is_read,
        bm25(message_fts) AS rank
      FROM message_fts
      JOIN messages m ON m.id = message_fts.rowid
      WHERE message_fts MATCH ?
        AND m.is_deleted = 0
      ORDER BY rank
      LIMIT 200
      ''',
          variables: [Variable.withString(query)],
          readsFrom: {messages},
        )
        .get();

    return rows.map((row) {
      return MessageSearchResult(
        messageId: row.read<int>('message_id'),
        subject: row.read<String>('subject'),
        bodyText: row.readNullable<String>('body_text'),
        receivedAt: DateTime.fromMillisecondsSinceEpoch(
          row.read<int>('received_at') * 1000,
        ),
        isRead: row.read<bool>('is_read'),
        rank: row.readNullable<double>('rank'),
      );
    }).toList();
  }
}
