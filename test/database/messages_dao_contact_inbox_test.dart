import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:do_thing/database/app_database.dart';

Future<int> _insertMessage(
  AppDatabase db, {
  required String externalId,
  required DateTime receivedAt,
  DateTime? sentAt,
  String mailbox = 'inbox',
  required bool isRead,
  bool isArchived = false,
  bool isDeleted = false,
}) {
  return db.messagesDao.insertMessage(
    MessagesCompanion.insert(
      source: 'smartschool',
      externalId: externalId,
      mailbox: mailbox,
      subject: Value('Subject $externalId'),
      receivedAt: receivedAt,
      sentAt: Value(sentAt),
      isRead: Value(isRead),
      isArchived: Value(isArchived),
      isDeleted: Value(isDeleted),
    ),
  );
}

void main() {
  group('MessagesDao contact inbox queries', () {
    test(
      'orders contacts by latest item and includes any participant role',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final alice = await db.contactsDao.insertStubContact(
          displayName: 'Alice',
        );
        final bob = await db.contactsDao.insertStubContact(displayName: 'Bob');

        final m1 = await _insertMessage(
          db,
          externalId: '1001',
          receivedAt: DateTime.parse('2026-04-10T10:00:00Z'),
          isRead: true,
        );
        await db.messagesDao.replaceParticipants(m1, [
          MessageParticipantsCompanion.insert(
            messageId: m1,
            contactId: Value(bob.id),
            role: 'sender',
            displayNameSnapshot: 'Bob',
          ),
          MessageParticipantsCompanion.insert(
            messageId: m1,
            contactId: Value(alice.id),
            role: 'to',
            displayNameSnapshot: 'Alice',
            position: const Value(1),
          ),
        ]);

        final m2 = await _insertMessage(
          db,
          externalId: '1002',
          receivedAt: DateTime.parse('2026-04-10T11:00:00Z'),
          isRead: false,
        );
        await db.messagesDao.replaceParticipants(m2, [
          MessageParticipantsCompanion.insert(
            messageId: m2,
            contactId: Value(bob.id),
            role: 'sender',
            displayNameSnapshot: 'Bob',
          ),
          MessageParticipantsCompanion.insert(
            messageId: m2,
            contactId: Value(alice.id),
            role: 'cc',
            displayNameSnapshot: 'Alice',
            position: const Value(1),
          ),
        ]);

        final m3 = await _insertMessage(
          db,
          externalId: '1003',
          receivedAt: DateTime.parse('2026-04-10T12:00:00Z'),
          isRead: true,
        );
        await db.messagesDao.replaceParticipants(m3, [
          MessageParticipantsCompanion.insert(
            messageId: m3,
            contactId: Value(alice.id),
            role: 'sender',
            displayNameSnapshot: 'Alice',
          ),
        ]);

        final m4 = await _insertMessage(
          db,
          externalId: '1004',
          receivedAt: DateTime.parse('2026-04-10T13:00:00Z'),
          isRead: false,
          isDeleted: true,
        );
        await db.messagesDao.replaceParticipants(m4, [
          MessageParticipantsCompanion.insert(
            messageId: m4,
            contactId: Value(bob.id),
            role: 'sender',
            displayNameSnapshot: 'Bob',
          ),
        ]);

        final summaries = await db.messagesDao.getInboxContactSummaries();

        expect(summaries.map((s) => s.displayName), ['Alice', 'Bob']);
        expect(summaries.first.itemCount, 3);
        expect(summaries.first.unreadCount, 1);
        expect(
          summaries.first.latestActivityAt.toUtc().toIso8601String(),
          '2026-04-10T12:00:00.000Z',
        );
        expect(summaries.last.itemCount, 2);
        expect(summaries.last.unreadCount, 1);
      },
    );

    test('returns related headers newest first for selected contact', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final alice = await db.contactsDao.insertStubContact(
        displayName: 'Alice',
      );

      final oldId = await _insertMessage(
        db,
        externalId: '2001',
        receivedAt: DateTime.parse('2026-04-10T08:00:00Z'),
        isRead: true,
      );
      final newId = await _insertMessage(
        db,
        externalId: '2002',
        receivedAt: DateTime.parse('2026-04-10T09:30:00Z'),
        isRead: false,
      );

      await db.messagesDao.replaceParticipants(oldId, [
        MessageParticipantsCompanion.insert(
          messageId: oldId,
          contactId: Value(alice.id),
          role: 'to',
          displayNameSnapshot: 'Alice',
        ),
      ]);
      await db.messagesDao.replaceParticipants(newId, [
        MessageParticipantsCompanion.insert(
          messageId: newId,
          contactId: Value(alice.id),
          role: 'sender',
          displayNameSnapshot: 'Alice',
        ),
      ]);

      final headers = await db.messagesDao.getInboxHeadersForContact(alice.id);

      expect(headers.map((h) => h.id), [2002, 2001]);
      expect(headers.first.unread, isTrue);
      expect(headers.last.unread, isFalse);
    });

    test(
      'includes sent mailbox contacts and filters self contact to self-sent-to-self',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final me = await db.contactsDao.insertStubContact(displayName: 'me');
        final alice = await db.contactsDao.insertStubContact(
          displayName: 'Alice',
        );

        final inboxFromAlice = await _insertMessage(
          db,
          externalId: '3001',
          mailbox: 'inbox',
          receivedAt: DateTime.parse('2026-04-10T08:00:00Z'),
          isRead: true,
        );
        await db.messagesDao.replaceParticipants(inboxFromAlice, [
          MessageParticipantsCompanion.insert(
            messageId: inboxFromAlice,
            contactId: Value(alice.id),
            role: 'sender',
            displayNameSnapshot: 'Alice',
          ),
          MessageParticipantsCompanion.insert(
            messageId: inboxFromAlice,
            contactId: Value(me.id),
            role: 'to',
            displayNameSnapshot: 'me',
            position: const Value(1),
          ),
        ]);

        final sentToAlice = await _insertMessage(
          db,
          externalId: '3002',
          mailbox: 'sent',
          receivedAt: DateTime.parse('2026-04-10T09:00:00Z'),
          isRead: true,
        );
        await db.messagesDao.replaceParticipants(sentToAlice, [
          MessageParticipantsCompanion.insert(
            messageId: sentToAlice,
            contactId: Value(me.id),
            role: 'sender',
            displayNameSnapshot: 'me',
          ),
          MessageParticipantsCompanion.insert(
            messageId: sentToAlice,
            contactId: Value(alice.id),
            role: 'to',
            displayNameSnapshot: 'Alice',
            position: const Value(1),
          ),
        ]);

        final sentToSelf = await _insertMessage(
          db,
          externalId: '3003',
          mailbox: 'sent',
          receivedAt: DateTime.parse('2026-04-10T10:00:00Z'),
          isRead: false,
        );
        await db.messagesDao.replaceParticipants(sentToSelf, [
          MessageParticipantsCompanion.insert(
            messageId: sentToSelf,
            contactId: Value(me.id),
            role: 'sender',
            displayNameSnapshot: 'me',
          ),
          MessageParticipantsCompanion.insert(
            messageId: sentToSelf,
            contactId: Value(me.id),
            role: 'to',
            displayNameSnapshot: 'me',
            position: const Value(1),
          ),
        ]);

        final summaries = await db.messagesDao.getInboxContactSummaries();
        expect(summaries.map((s) => s.displayName), ['me', 'Alice']);

        final selfHeaders = await db.messagesDao.getInboxHeadersForContact(
          me.id,
          onlySelfSentToSelf: true,
        );
        expect(selfHeaders.map((h) => h.id), [3003]);

        final aliceHeaders = await db.messagesDao.getInboxHeadersForContact(
          alice.id,
        );
        expect(aliceHeaders.map((h) => h.id), [3002, 3001]);
      },
    );

    test('detects self contact IDs from sent mailbox sender rows', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final me = await db.contactsDao.insertStubContact(displayName: 'me');
      final alice = await db.contactsDao.insertStubContact(
        displayName: 'Alice',
      );

      final sentMessage = await _insertMessage(
        db,
        externalId: '4001',
        mailbox: 'sent',
        receivedAt: DateTime.parse('2026-04-10T14:00:00Z'),
        isRead: true,
      );
      await db.messagesDao.replaceParticipants(sentMessage, [
        MessageParticipantsCompanion.insert(
          messageId: sentMessage,
          contactId: Value(me.id),
          role: 'sender',
          displayNameSnapshot: 'me',
        ),
        MessageParticipantsCompanion.insert(
          messageId: sentMessage,
          contactId: Value(alice.id),
          role: 'to',
          displayNameSnapshot: 'Alice',
          position: const Value(1),
        ),
      ]);

      final ids = await db.messagesDao.getSentSenderContactIds();
      expect(ids, {me.id});
    });
  });
}
