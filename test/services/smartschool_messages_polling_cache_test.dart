import 'dart:collection';
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_thing/models/smartschool_message.dart';
import 'package:do_thing/providers/database_provider.dart';
import 'package:do_thing/services/smartschool/smartschool_bridge.dart';
import 'package:do_thing/services/smartschool/smartschool_message_cache_controller.dart';
import 'package:do_thing/services/smartschool/smartschool_messages_controller.dart';
import 'package:do_thing/services/smartschool/smartschool_polling_controller.dart';
import 'package:do_thing/services/system_notification_service.dart';
import 'package:do_thing/controllers/status_controller.dart';

class _FakeBridge implements SmartschoolBridge {
  _FakeBridge(this._onGetMessage);

  final Future<List<SmartschoolMessageDetail>> Function(
    int messageId,
    SmartschoolBoxType boxType,
  )
  _onGetMessage;

  int getMessageCalls = 0;

  @override
  Future<List<SmartschoolMessageDetail>> getMessage(
    int messageId, {
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
  }) {
    getMessageCalls++;
    return _onGetMessage(messageId, boxType);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QueueMessagesController extends SmartschoolMessagesController {
  _QueueMessagesController(this._batches);

  final Queue<List<MessageHeader>> _batches;
  FutureOr<void> Function(List<MessageHeader>)? _onNewHeaders;
  int startCalls = 0;
  int stopCalls = 0;
  List<int> latestSeenIds = const [];

  @override
  void build() {}

  @override
  Future<List<MessageHeader>> getHeaders({
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    List<int> alreadySeenIds = const [],
  }) async {
    if (_batches.isEmpty) return const [];
    return _batches.removeFirst();
  }

  @override
  Future<List<SmartschoolMessageDetail>> getMessage(
    int messageId, {
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    bool reportStatus = true,
  }) async {
    // Return empty so the polling controller's eager sync is a no-op in tests.
    return const [];
  }

  @override
  Future<void> startEventDrivenInboxDetection({
    required Iterable<int> seenIds,
    required FutureOr<void> Function(List<MessageHeader>) onNewHeaders,
    void Function(Object error)? onError,
  }) async {
    startCalls++;
    latestSeenIds = seenIds.toList();
    _onNewHeaders = onNewHeaders;
  }

  @override
  Future<void> stopEventDrivenInboxDetection() async {
    stopCalls++;
    _onNewHeaders = null;
  }

  Future<void> emitNewHeaders(List<MessageHeader> headers) async {
    final callback = _onNewHeaders;
    if (callback == null) return;
    await callback(headers);
  }
}

class _FakeSystemNotificationService extends SystemNotificationService {
  final List<({String subject, String sender})> shown = [];

  @override
  Future<void> showSmartschoolMessageReceived({
    required String subject,
    required String sender,
  }) async {
    shown.add((subject: subject, sender: sender));
  }
}

MessageHeader _header({required int id, required bool unread}) {
  return MessageHeader(
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
    test('getOrFetch fetches from bridge and caches in memory', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);
      await repo.syncHeaders([_header(id: 900, unread: true)]);

      final bridge = _FakeBridge((_, a) async {
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
      // Bridge called only once; second result came from in-memory cache.
      expect(bridge.getMessageCalls, 1);
      expect(
        container.read(smartschoolMessageCacheProvider).containsKey(900),
        isTrue,
      );
    });

    test('getOrFetch throws when bridge returns empty list', () async {
      final bridge = _FakeBridge((_, _) async => const []);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        () => container
            .read(smartschoolMessageCacheProvider.notifier)
            .getOrFetch(1, bridge),
        throwsA(isA<StateError>()),
      );
    });

    test('getOrFetch always calls bridge (no DB body cache)', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SmartschoolSyncRepository(db);
      await repo.syncHeaders([_header(id: 901, unread: true)]);

      // Simulate a prior syncDetail (identity links, no body stored).
      await repo.syncDetail(
        const SmartschoolMessageDetail(
          id: 901,
          from: 'Teacher',
          subject: 'Stored',
          body: '<p>Stored body</p>',
          date: '2026-04-10T12:00:00Z',
          replyAllToRecipients: [
            SmartschoolMessageRecipient(displayName: 'Teacher', userId: 1),
          ],
        ),
      );

      final bridge = _FakeBridge((_, a) async {
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

      final detail = await container
          .read(smartschoolMessageCacheProvider.notifier)
          .getOrFetch(901, bridge);

      // Body always comes from bridge; DB body storage was removed.
      expect(detail.subject, 'Remote');
      expect(bridge.getMessageCalls, 1);
    });
  });

  group('SmartschoolPollingController', () {
    test('event update accumulates only unseen messages', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final queuedBatches = Queue<List<MessageHeader>>.from([]);
      final fakeMessages = _QueueMessagesController(queuedBatches);
      final fakeNotifications = _FakeSystemNotificationService();

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          smartschoolMessagesProvider.overrideWith(() => fakeMessages),
          systemNotificationServiceProvider.overrideWithValue(
            fakeNotifications,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(smartschoolPollingProvider.notifier);
      notifier.initializeWithSeenIds([1]);
      await Future<void>.delayed(Duration.zero);

      await fakeMessages.emitNewHeaders([
        _header(id: 1, unread: true),
        _header(id: 2, unread: true),
      ]);

      final polled = container.read(smartschoolPollingProvider);
      expect(polled, hasLength(1));
      expect(polled.first.id, 2);
      expect(fakeMessages.startCalls, 1);
      expect(fakeMessages.latestSeenIds, [1]);
      expect(fakeNotifications.shown, hasLength(1));
      expect(fakeNotifications.shown.first.subject, 'Subject 2');
      expect(fakeNotifications.shown.first.sender, 'Teacher');

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

    test('clearNew empties accumulated new messages', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final queuedBatches = Queue<List<MessageHeader>>.from([]);
      final fakeMessages = _QueueMessagesController(queuedBatches);
      final fakeNotifications = _FakeSystemNotificationService();

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          smartschoolMessagesProvider.overrideWith(() => fakeMessages),
          systemNotificationServiceProvider.overrideWithValue(
            fakeNotifications,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(smartschoolPollingProvider.notifier);
      notifier.initializeWithSeenIds([]);
      await Future<void>.delayed(Duration.zero);

      await fakeMessages.emitNewHeaders([_header(id: 10, unread: true)]);

      expect(container.read(smartschoolPollingProvider), hasLength(1));
      container.read(smartschoolPollingProvider.notifier).clearNew();
      expect(container.read(smartschoolPollingProvider), isEmpty);
      expect(fakeNotifications.shown, hasLength(1));
    });

    test('stopPolling stops event-driven detection', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final queuedBatches = Queue<List<MessageHeader>>.from([]);
      final fakeMessages = _QueueMessagesController(queuedBatches);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          smartschoolMessagesProvider.overrideWith(() => fakeMessages),
          systemNotificationServiceProvider.overrideWithValue(
            _FakeSystemNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(smartschoolPollingProvider.notifier);
      notifier.initializeWithSeenIds(const []);
      await Future<void>.delayed(Duration.zero);

      notifier.stopPolling();
      await Future<void>.delayed(Duration.zero);

      expect(fakeMessages.stopCalls, 1);
    });
  });
}
