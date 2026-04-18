import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:do_thing/database/app_database.dart';
import 'package:do_thing/database/repositories/smartschool_sync_repository.dart';
import 'package:do_thing/models/smartschool_message.dart';

SmartschoolMessageHeader _header({
  required int id,
  required bool unread,
  bool hasAttachment = false,
  String mailbox = 'inbox',
}) {
  return SmartschoolMessageHeader(
    id: id,
    from: 'Teacher',
    fromImage: 'https://example.com/avatar.png',
    subject: 'Subject $id',
    date: '2026-04-10T12:00:00Z',
    status: unread ? 0 : 1,
    unread: unread,
    hasAttachment: hasAttachment,
    label: false,
    deleted: false,
    allowReply: true,
    allowReplyEnabled: true,
    hasReply: false,
    hasForward: false,
    realBox: mailbox,
  );
}

void main() {
  group('SmartschoolSyncRepository.syncHeaders', () {
    test('inserts new headers and returns them as newly inserted', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      final newHeaders = await repo.syncHeaders([
        _header(id: 101, unread: true, hasAttachment: true),
      ]);

      expect(newHeaders, hasLength(1));
      expect(newHeaders.first.id, 101);

      final row = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '101',
      );
      expect(row, isNotNull);
      expect(row!.isRead, isFalse);
      expect(row.hasAttachments, isTrue);
      expect(row.subject, 'Subject 101');
    });

    test('stores senderAvatarUrl for inbox messages', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      await repo.syncHeaders([_header(id: 102, unread: true)]);

      final row = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '102',
      );
      expect(row!.senderAvatarUrl, 'https://example.com/avatar.png');
    });

    test('does not create any participant rows at header stage', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      await repo.syncHeaders([_header(id: 103, unread: true)]);

      final row = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '103',
      );
      final participants = await db.messagesDao.getParticipants(row!.id);
      expect(participants, isEmpty);
    });

    test('skips unchanged headers by fingerprint', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      final first = await repo.syncHeaders([_header(id: 104, unread: true)]);
      final second = await repo.syncHeaders([_header(id: 104, unread: true)]);

      expect(first, hasLength(1));
      expect(second, isEmpty);
    });

    test('updates existing header on fingerprint change but does not re-add to new list',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      await repo.syncHeaders([_header(id: 105, unread: true)]);
      final updated = await repo.syncHeaders([_header(id: 105, unread: false)]);

      expect(updated, isEmpty);

      final row = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '105',
      );
      expect(row!.isRead, isTrue);
    });
  });

  group('SmartschoolSyncRepository.syncDetail', () {
    test('creates participants only for recipients with stable IDs', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      await repo.syncHeaders([_header(id: 200, unread: true)]);

      await repo.syncDetail(
        const SmartschoolMessageDetail(
          id: 200,
          from: 'Teacher',
          subject: 'Exam update',
          body: '<p>Hello <b>class</b></p>',
          date: '2026-04-10T12:00:00Z',
          receivers: [
            // Alice has no stable ID — skipped
            SmartschoolMessageRecipient(displayName: 'Alice'),
            // Bob has a stable userId — kept
            SmartschoolMessageRecipient(displayName: 'Bob', userId: 99),
          ],
          replyAllToRecipients: [
            SmartschoolMessageRecipient(displayName: 'Bob', userId: 99),
          ],
        ),
      );

      final row = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '200',
      );
      final participants = await db.messagesDao.getParticipants(row!.id);

      // Only Bob (stable userId) should produce a participant row.
      // Teacher (sender) is not in replyAllToRecipients → no row.
      // Alice (no ID) → no row.
      expect(participants, hasLength(1));
      expect(participants.single.role, 'to');

      final identity = await db.contactsDao.findIdentity(
        source: 'smartschool',
        externalId: 'user:99',
      );
      expect(identity, isNotNull);
      expect(participants.single.contactIdentityId, identity!.id);
    });

    test('resolves sender identity from replyAllToRecipients', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      await repo.syncHeaders([_header(id: 201, unread: true)]);

      await repo.syncDetail(
        const SmartschoolMessageDetail(
          id: 201,
          from: 'Teacher',
          subject: 'Reply all',
          body: '<p>Hello</p>',
          date: '2026-04-10T12:00:00Z',
          receivers: [SmartschoolMessageRecipient(displayName: 'Alice')],
          replyAllToRecipients: [
            // Teacher is in replyAllToRecipients with a stable ID.
            SmartschoolMessageRecipient(
              displayName: 'Teacher',
              userId: 111,
              ssId: 222,
            ),
          ],
        ),
      );

      final row = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '201',
      );
      final participants = await db.messagesDao.getParticipants(row!.id);

      // Sender resolved via replyAllToRecipients.
      final senderParticipant = participants.where((p) => p.role == 'sender');
      expect(senderParticipant, hasLength(1));

      final identity = await db.contactsDao.findIdentity(
        source: 'smartschool',
        externalId: 'user:111',
      );
      expect(identity, isNotNull);
      expect(senderParticipant.single.contactIdentityId, identity!.id);

      // Alice has no stable ID → no participant row.
      final toParticipants = participants.where((p) => p.role == 'to');
      expect(toParticipants, isEmpty);
    });

    test('never stores display:-prefixed external IDs', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      await repo.syncHeaders([_header(id: 202, unread: true)]);

      // Detail where no one has a stable ID.
      await repo.syncDetail(
        const SmartschoolMessageDetail(
          id: 202,
          from: 'Unknown Person',
          subject: 'No IDs',
          body: '<p>Hi</p>',
          date: '2026-04-10T12:00:00Z',
          receivers: [SmartschoolMessageRecipient(displayName: 'Someone')],
        ),
      );

      // The contact_identities table must remain empty (no display: keys).
      final allIdentities = await db.select(db.contactIdentities).get();
      expect(
        allIdentities.any((i) => i.externalId.startsWith('display:')),
        isFalse,
      );
    });

    test('resolves CC recipients from replyAllCcRecipients', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      await repo.syncHeaders([_header(id: 203, unread: true)]);

      await repo.syncDetail(
        const SmartschoolMessageDetail(
          id: 203,
          from: 'Teacher',
          subject: 'CC test',
          body: '<p>Test</p>',
          date: '2026-04-10T12:00:00Z',
          ccReceivers: [SmartschoolMessageRecipient(displayName: 'Counselor')],
          replyAllCcRecipients: [
            SmartschoolMessageRecipient(
              displayName: 'Counselor',
              userId: 333,
              ssId: 444,
            ),
          ],
        ),
      );

      final row = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '203',
      );
      final participants = await db.messagesDao.getParticipants(row!.id);
      final ccRows = participants.where((p) => p.role == 'cc').toList();
      expect(ccRows, hasLength(1));

      final identity = await db.contactsDao.findIdentity(
        source: 'smartschool',
        externalId: 'user:333',
      );
      expect(identity, isNotNull);
      expect(ccRows.single.contactIdentityId, identity!.id);
    });

    test('updates FTS row with body text on syncDetail', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      await repo.syncHeaders([_header(id: 204, unread: true)]);
      await repo.syncDetail(
        const SmartschoolMessageDetail(
          id: 204,
          from: 'Teacher',
          subject: 'FTS test',
          body: '<p>Searchable content here</p>',
          date: '2026-04-10T12:00:00Z',
        ),
      );

      final row = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '204',
      );
      final results = await db.searchDao.search('searchable');
      expect(results.any((r) => r.messageId == row!.id), isTrue);
    });
  });

  group('SmartschoolSyncRepository.discardMessage', () {
    test('removes the message row by external ID', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      await repo.syncHeaders(
        [_header(id: 300, unread: false)],
        mailbox: 'sent',
      );
      final before = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '300',
      );
      expect(before, isNotNull);

      await repo.discardMessage(300);

      final after = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '300',
      );
      expect(after, isNull);
    });

    test('also removes participant rows for the discarded message', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      await repo.syncHeaders(
        [_header(id: 301, unread: false)],
        mailbox: 'sent',
      );
      await repo.syncDetail(
        const SmartschoolMessageDetail(
          id: 301,
          from: 'Yvan',
          subject: 'Self-sent',
          body: '<p>Test</p>',
          date: '2026-04-10T12:00:00Z',
          receivers: [SmartschoolMessageRecipient(displayName: 'Recipient', userId: 55)],
          replyAllToRecipients: [
            SmartschoolMessageRecipient(displayName: 'Recipient', userId: 55),
          ],
        ),
      );

      final row = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '301',
      );
      final participantsBefore = await db.messagesDao.getParticipants(row!.id);
      expect(participantsBefore, isNotEmpty);

      await repo.discardMessage(301);

      // Message is gone; participant query on the old local ID returns nothing.
      final participantsAfter = await db.messagesDao.getParticipants(row.id);
      expect(participantsAfter, isEmpty);
    });

    test('is a no-op for an unknown external ID', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      // Should not throw.
      await repo.discardMessage(99999);
    });
  });
}
