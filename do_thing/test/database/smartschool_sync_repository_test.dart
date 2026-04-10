import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:do_thing/database/app_database.dart';
import 'package:do_thing/database/repositories/smartschool_sync_repository.dart';
import 'package:do_thing/models/smartschool_message.dart';

SmartschoolMessageHeader _header({
  required int id,
  required bool unread,
  bool hasAttachment = false,
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
    realBox: 'inbox',
  );
}

void main() {
  group('SmartschoolSyncRepository.syncHeaders', () {
    test('inserts new headers and maps unread to isRead=false', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      final inserted = await repo.syncHeaders([
        _header(id: 101, unread: true, hasAttachment: true),
      ]);

      expect(inserted, 1);

      final row = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '101',
      );

      expect(row, isNotNull);
      expect(row!.isRead, isFalse);
      expect(row.hasAttachments, isTrue);
      expect(row.subject, 'Subject 101');
    });

    test('skips unchanged headers by fingerprint', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      final first = await repo.syncHeaders([_header(id: 102, unread: true)]);
      final second = await repo.syncHeaders([_header(id: 102, unread: true)]);

      expect(first, 1);
      expect(second, 0);
    });

    test('updates existing header when mutable fields change', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);

      await repo.syncHeaders([_header(id: 103, unread: true)]);
      final updated = await repo.syncHeaders([_header(id: 103, unread: false)]);

      expect(updated, 1);

      final row = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '103',
      );

      expect(row, isNotNull);
      expect(row!.isRead, isTrue);
    });
  });

  group('SmartschoolSyncRepository.syncDetail', () {
    test('stores body detail and replaces participants', () async {
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
          receivers: ['Alice', 'Bob'],
          ccReceivers: ['Counselor'],
        ),
      );

      final row = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '200',
      );
      expect(row, isNotNull);
      expect(row!.bodyRaw, '<p>Hello <b>class</b></p>');
      expect(row.bodyText, 'Hello class');

      final participants = await db.messagesDao.getParticipants(row.id);
      expect(participants, hasLength(4));
      expect(
        participants
            .where((p) => p.role == 'sender')
            .single
            .displayNameSnapshot,
        'Teacher',
      );
    });
  });
}
