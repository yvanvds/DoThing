import 'package:do_thing/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingOutgoingMessagesDao', () {
    test('stores queued payloads and returns only due rows', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final now = DateTime.parse('2026-04-12T10:00:00Z');
      await db.pendingOutgoingMessagesDao.enqueue(
        payloadJson: '{"subject":"due"}',
        subject: 'Due message',
        attemptCount: 1,
        lastAttemptAt: now,
        nextAttemptAt: now,
        lastError: 'offline',
      );
      await db.pendingOutgoingMessagesDao.enqueue(
        payloadJson: '{"subject":"future"}',
        subject: 'Future message',
        attemptCount: 1,
        lastAttemptAt: now,
        nextAttemptAt: now.add(const Duration(minutes: 10)),
        lastError: 'offline',
      );

      final due = await db.pendingOutgoingMessagesDao.getDueMessages(now: now);
      final all = await db.pendingOutgoingMessagesDao.getAllQueued();

      expect(all, hasLength(2));
      expect(due, hasLength(1));
      expect(due.single.subject, 'Due message');
      expect(await db.pendingOutgoingMessagesDao.countQueued(), 2);
    });

    test(
      'markRetryFailure increments attempts and updates retry metadata',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final now = DateTime.parse('2026-04-12T10:00:00Z');
        final id = await db.pendingOutgoingMessagesDao.enqueue(
          payloadJson: '{"subject":"retry"}',
          subject: 'Retry me',
          attemptCount: 1,
          lastAttemptAt: now,
          nextAttemptAt: now,
          lastError: 'offline',
        );

        final nextAttemptAt = now.add(const Duration(minutes: 5));
        await db.pendingOutgoingMessagesDao.markRetryFailure(
          id: id,
          error: 'still offline',
          nextAttemptAt: nextAttemptAt,
        );

        final queued = await db.pendingOutgoingMessagesDao.getAllQueued();
        expect(queued.single.attemptCount, 2);
        expect(queued.single.lastError, 'still offline');
        expect(queued.single.nextAttemptAt?.toUtc(), nextAttemptAt.toUtc());
        expect(queued.single.lastAttemptAt, isNotNull);
      },
    );
  });
}
