import 'package:drift/drift.dart';

import '../app_database.dart';

part 'pending_outgoing_messages_dao.g.dart';

@DriftAccessor(tables: [PendingOutgoingMessages])
class PendingOutgoingMessagesDao extends DatabaseAccessor<AppDatabase>
    with _$PendingOutgoingMessagesDaoMixin {
  PendingOutgoingMessagesDao(super.db);

  Future<int> enqueue({
    required String payloadJson,
    required String subject,
    required int attemptCount,
    required DateTime lastAttemptAt,
    required DateTime nextAttemptAt,
    String? lastError,
  }) {
    final now = DateTime.now();
    return into(pendingOutgoingMessages).insert(
      PendingOutgoingMessagesCompanion.insert(
        payloadJson: payloadJson,
        subject: Value(subject),
        attemptCount: Value(attemptCount),
        lastAttemptAt: Value(lastAttemptAt),
        nextAttemptAt: Value(nextAttemptAt),
        lastError: Value(lastError),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<List<PendingOutgoingMessage>> getDueMessages({
    DateTime? now,
    int limit = 50,
  }) {
    final threshold = now ?? DateTime.now();
    return (select(pendingOutgoingMessages)
          ..where(
            (table) =>
                table.nextAttemptAt.isNull() |
                table.nextAttemptAt.isSmallerOrEqualValue(threshold),
          )
          ..orderBy([
            (table) => OrderingTerm.asc(table.nextAttemptAt),
            (table) => OrderingTerm.asc(table.createdAt),
          ])
          ..limit(limit))
        .get();
  }

  Future<List<PendingOutgoingMessage>> getAllQueued() {
    return (select(
      pendingOutgoingMessages,
    )..orderBy([(table) => OrderingTerm.asc(table.createdAt)])).get();
  }

  Future<int> countQueued() async {
    final countExpression = pendingOutgoingMessages.id.count();
    final row = await (selectOnly(
      pendingOutgoingMessages,
    )..addColumns([countExpression])).getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<void> deleteById(int id) {
    return (delete(
      pendingOutgoingMessages,
    )..where((t) => t.id.equals(id))).go();
  }

  Future<void> markRetryFailure({
    required int id,
    required String error,
    required DateTime nextAttemptAt,
  }) async {
    final existing = await (select(
      pendingOutgoingMessages,
    )..where((t) => t.id.equals(id))).getSingle();
    final now = DateTime.now();
    await (update(
      pendingOutgoingMessages,
    )..where((t) => t.id.equals(id))).write(
      PendingOutgoingMessagesCompanion(
        attemptCount: Value(existing.attemptCount + 1),
        lastAttemptAt: Value(now),
        nextAttemptAt: Value(nextAttemptAt),
        lastError: Value(error),
        updatedAt: Value(now),
      ),
    );
  }
}
