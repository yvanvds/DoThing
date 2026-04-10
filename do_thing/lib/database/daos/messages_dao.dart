import 'package:drift/drift.dart';

import '../app_database.dart';

part 'messages_dao.g.dart';

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
}
