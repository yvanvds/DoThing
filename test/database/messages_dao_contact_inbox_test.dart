import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:do_thing/database/app_database.dart';

/// Insert a bare message row and return its local id.
Future<int> _insertMessage(
  AppDatabase db, {
  required String externalId,
  required DateTime receivedAt,
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
      isRead: Value(isRead),
      isArchived: Value(isArchived),
      isDeleted: Value(isDeleted),
    ),
  );
}

/// Create an identity (and its parent contact) and return the identity id.
Future<int> _insertIdentity(
  AppDatabase db, {
  required String displayName,
  required String externalId,
}) {
  return db.contactsDao.upsertIdentity(
    source: 'smartschool',
    externalId: externalId,
    displayName: displayName,
  );
}

void main() {
  group('MessagesDao contact inbox queries', () {
    test(
      'orders contacts by latest activity (inbox=sender, sent=to)',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final aliceId = await _insertIdentity(
          db,
          displayName: 'Alice',
          externalId: 'user:1',
        );
        final bobId = await _insertIdentity(
          db,
          displayName: 'Bob',
          externalId: 'user:2',
        );

        // m1: Bob → Alice (oldest)
        final m1 = await _insertMessage(
          db,
          externalId: '1001',
          receivedAt: DateTime.parse('2026-04-10T10:00:00Z'),
          isRead: true,
        );
        await db.messagesDao.replaceParticipants(m1, [
          MessageParticipantsCompanion.insert(
            messageId: m1,
            contactIdentityId: bobId,
            role: 'sender',
          ),
          MessageParticipantsCompanion.insert(
            messageId: m1,
            contactIdentityId: aliceId,
            role: 'to',
          ),
        ]);

        // m2: Bob → Alice (cc) – unread
        final m2 = await _insertMessage(
          db,
          externalId: '1002',
          receivedAt: DateTime.parse('2026-04-10T11:00:00Z'),
          isRead: false,
        );
        await db.messagesDao.replaceParticipants(m2, [
          MessageParticipantsCompanion.insert(
            messageId: m2,
            contactIdentityId: bobId,
            role: 'sender',
          ),
          MessageParticipantsCompanion.insert(
            messageId: m2,
            contactIdentityId: aliceId,
            role: 'cc',
          ),
        ]);

        // m3: Alice sends (newest active)
        final m3 = await _insertMessage(
          db,
          externalId: '1003',
          receivedAt: DateTime.parse('2026-04-10T12:00:00Z'),
          isRead: true,
        );
        await db.messagesDao.replaceParticipants(m3, [
          MessageParticipantsCompanion.insert(
            messageId: m3,
            contactIdentityId: aliceId,
            role: 'sender',
          ),
        ]);

        // m4: Bob – deleted, must be excluded
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
            contactIdentityId: bobId,
            role: 'sender',
          ),
        ]);

        final summaries = await db.messagesDao.getInboxContactSummaries();

        // Only sender (inbox) role counts. Alice is sender in m3 only;
        // Bob is sender in m1 and m2 (m4 excluded — deleted).
        expect(summaries.map((s) => s.displayName), ['Alice', 'Bob']);
        expect(summaries.first.itemCount, 1); // m3 only (Alice as sender)
        expect(summaries.first.unreadCount, 0); // m3 is read
        expect(
          summaries.first.latestActivityAt.toUtc().toIso8601String(),
          '2026-04-10T12:00:00.000Z',
        );
        expect(summaries.last.itemCount, 2); // m1, m2 (m4 excluded)
        expect(summaries.last.unreadCount, 1); // m2
      },
    );

    test('returns message headers for a contact, newest first', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final aliceId = await _insertIdentity(
        db,
        displayName: 'Alice',
        externalId: 'user:10',
      );

      // 2001: sent message with Alice as 'to' (visible under sent=to rule)
      final oldId = await _insertMessage(
        db,
        externalId: '2001',
        mailbox: 'sent',
        receivedAt: DateTime.parse('2026-04-10T08:00:00Z'),
        isRead: true,
      );
      // 2002: inbox message with Alice as sender (visible under inbox=sender rule)
      final newId = await _insertMessage(
        db,
        externalId: '2002',
        receivedAt: DateTime.parse('2026-04-10T09:30:00Z'),
        isRead: false,
      );

      await db.messagesDao.replaceParticipants(oldId, [
        MessageParticipantsCompanion.insert(
          messageId: oldId,
          contactIdentityId: aliceId,
          role: 'to',
        ),
      ]);
      await db.messagesDao.replaceParticipants(newId, [
        MessageParticipantsCompanion.insert(
          messageId: newId,
          contactIdentityId: aliceId,
          role: 'sender',
        ),
      ]);

      // Derive contactId from the identity row
      final identity = await db.contactsDao.findIdentity(
        source: 'smartschool',
        externalId: 'user:10',
      );
      final headers = await db.messagesDao.getInboxHeadersForContact(
        identity!.contactId,
      );

      expect(headers.map((h) => h.id), [2002, 2001]);
      expect(headers.first.unread, isTrue);
      expect(headers.last.unread, isFalse);
    });

    test('filters self-sent-to-self correctly', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final meId = await _insertIdentity(
        db,
        displayName: 'me',
        externalId: 'user:99',
      );
      final aliceId = await _insertIdentity(
        db,
        displayName: 'Alice',
        externalId: 'user:100',
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
          contactIdentityId: aliceId,
          role: 'sender',
        ),
        MessageParticipantsCompanion.insert(
          messageId: inboxFromAlice,
          contactIdentityId: meId,
          role: 'to',
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
          contactIdentityId: meId,
          role: 'sender',
        ),
        MessageParticipantsCompanion.insert(
          messageId: sentToAlice,
          contactIdentityId: aliceId,
          role: 'to',
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
          contactIdentityId: meId,
          role: 'sender',
        ),
        MessageParticipantsCompanion.insert(
          messageId: sentToSelf,
          contactIdentityId: meId,
          role: 'to',
        ),
      ]);

      final meIdentity = await db.contactsDao.findIdentity(
        source: 'smartschool',
        externalId: 'user:99',
      );
      final aliceIdentity = await db.contactsDao.findIdentity(
        source: 'smartschool',
        externalId: 'user:100',
      );

      final summaries = await db.messagesDao.getInboxContactSummaries();
      expect(summaries.map((s) => s.displayName), containsAll(['me', 'Alice']));

      final selfHeaders = await db.messagesDao.getInboxHeadersForContact(
        meIdentity!.contactId,
        onlySelfSentToSelf: true,
      );
      expect(selfHeaders.map((h) => h.id), [3003]);

      final aliceHeaders = await db.messagesDao.getInboxHeadersForContact(
        aliceIdentity!.contactId,
      );
      expect(aliceHeaders.map((h) => h.id), [3002, 3001]);
    });

    test('detects self contact IDs from sent mailbox sender rows', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final meId = await _insertIdentity(
        db,
        displayName: 'me',
        externalId: 'user:200',
      );
      final aliceId = await _insertIdentity(
        db,
        displayName: 'Alice',
        externalId: 'user:201',
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
          contactIdentityId: meId,
          role: 'sender',
        ),
        MessageParticipantsCompanion.insert(
          messageId: sentMessage,
          contactIdentityId: aliceId,
          role: 'to',
        ),
      ]);

      final meIdentity = await db.contactsDao.findIdentity(
        source: 'smartschool',
        externalId: 'user:200',
      );
      final ids = await db.messagesDao.getSentSenderContactIds();
      expect(ids, {meIdentity!.contactId});
    });

    test('messages with no participants are excluded from summaries', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // A message with no detail sync yet (no participants).
      await _insertMessage(
        db,
        externalId: '5001',
        receivedAt: DateTime.parse('2026-04-10T10:00:00Z'),
        isRead: false,
      );

      final summaries = await db.messagesDao.getInboxContactSummaries();
      expect(summaries, isEmpty);
    });
  });
}
