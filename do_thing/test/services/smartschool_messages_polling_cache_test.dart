import 'dart:collection';

import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_thing/models/smartschool_message.dart';
import 'package:do_thing/providers/database_provider.dart';
import 'package:do_thing/services/smartschool_bridge.dart';
import 'package:do_thing/services/smartschool_messages_service.dart';
import 'package:do_thing/controllers/status_controller.dart';

class _FakeBridge implements SmartschoolBridge {
  _FakeBridge(this._onGetMessage);

  final Future<List<SmartschoolMessageDetail>> Function(int messageId)
  _onGetMessage;

  int getMessageCalls = 0;

  @override
  Future<List<SmartschoolMessageDetail>> getMessage(int messageId) {
    getMessageCalls++;
    return _onGetMessage(messageId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QueueMessagesController extends SmartschoolMessagesController {
  _QueueMessagesController(this._batches);

  final Queue<List<SmartschoolMessageHeader>> _batches;

  @override
  void build() {}

  @override
  Future<List<SmartschoolMessageHeader>> getHeaders({
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    List<int> alreadySeenIds = const [],
  }) async {
    if (_batches.isEmpty) {
      return const [];
    }
    return _batches.removeFirst();
  }
}

SmartschoolMessageHeader _header({required int id, required bool unread}) {
  return SmartschoolMessageHeader(
    id: id,
    from: 'Teacher',
    fromImage: '',
    subject: 'Subject $id',
    date: '2026-04-10T12:00:00Z',
    status: unread ? 0 : 1,
    unread: unread,
    hasAttachment: false,
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
  group('SmartschoolMessageCacheController', () {
    test('getOrFetch caches and avoids duplicate bridge calls', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);
      await repo.syncHeaders([_header(id: 900, unread: true)]);

      final bridge = _FakeBridge((_) async {
        return const [
          SmartschoolMessageDetail(
            id: 900,
            from: 'Teacher',
            subject: 'S',
            body: '<p>Hello</p>',
            date: '2026-04-10T12:00:00Z',
          ),
        ];
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(smartschoolMessageCacheProvider.notifier);

      final first = await notifier.getOrFetch(
        900,
        bridge,
        syncRepository: repo,
      );
      final second = await notifier.getOrFetch(
        900,
        bridge,
        syncRepository: repo,
      );

      expect(first.id, 900);
      expect(second.id, 900);
      expect(bridge.getMessageCalls, 1);
      expect(
        container.read(smartschoolMessageCacheProvider).containsKey(900),
        isTrue,
      );

      final stored = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: '900',
      );
      expect(stored, isNotNull);
      expect(stored!.bodyText, 'Hello');
    });

    test('getOrFetch throws when bridge returns empty detail', () async {
      final bridge = _FakeBridge((_) async => const []);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(smartschoolMessageCacheProvider.notifier);

      await expectLater(
        () => notifier.getOrFetch(1, bridge),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'getOrFetch uses persisted full detail before refetching remote',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = SmartschoolSyncRepository(db);
        await repo.syncHeaders([_header(id: 901, unread: true)]);
        await repo.syncDetail(
          const SmartschoolMessageDetail(
            id: 901,
            from: 'Teacher',
            subject: 'Stored',
            body: '<p>Stored body</p>',
            date: '2026-04-10T12:00:00Z',
          ),
        );

        final bridge = _FakeBridge((_) async {
          return const [
            SmartschoolMessageDetail(
              id: 901,
              from: 'Teacher',
              subject: 'Remote',
              body: '<p>Remote body</p>',
              date: '2026-04-10T12:00:00Z',
            ),
          ];
        });

        final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          smartschoolMessageCacheProvider.notifier,
        );
        final detail = await notifier.getOrFetch(901, bridge);

        expect(detail.subject, 'Stored');
        expect(detail.body, '<p>Stored body</p>');
        expect(bridge.getMessageCalls, 0);
      },
    );
  });

  group('SmartschoolPollingController', () {
    test('poll tick accumulates only unseen messages', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final queuedBatches = Queue<List<SmartschoolMessageHeader>>.from([
        [_header(id: 1, unread: true), _header(id: 2, unread: true)],
      ]);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          smartschoolMessagesProvider.overrideWith(
            () => _QueueMessagesController(queuedBatches),
          ),
        ],
      );
      addTearDown(container.dispose);

      fakeAsync((async) {
        final notifier = container.read(smartschoolPollingProvider.notifier);
        notifier.initializeWithSeenIds([1]);

        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
      });

      final polled = container.read(smartschoolPollingProvider);
      expect(polled, hasLength(1));
      expect(polled.first.id, 2);

      final statusEntries = container.read(statusProvider);
      expect(
        statusEntries.any(
          (entry) =>
              entry.type == StatusEntryType.info &&
              entry.message.contains('new message'),
        ),
        isTrue,
      );
    });

    test('clearNew empties accumulated new messages', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final queuedBatches = Queue<List<SmartschoolMessageHeader>>.from([
        [_header(id: 10, unread: true)],
      ]);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          smartschoolMessagesProvider.overrideWith(
            () => _QueueMessagesController(queuedBatches),
          ),
        ],
      );
      addTearDown(container.dispose);

      fakeAsync((async) {
        final notifier = container.read(smartschoolPollingProvider.notifier);
        notifier.initializeWithSeenIds([]);
        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
      });

      expect(container.read(smartschoolPollingProvider), hasLength(1));
      container.read(smartschoolPollingProvider.notifier).clearNew();
      expect(container.read(smartschoolPollingProvider), isEmpty);
    });
  });
}
