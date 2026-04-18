import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_thing/controllers/smartschool_inbox_controller.dart';
import 'package:do_thing/controllers/status_controller.dart';
import 'package:do_thing/models/smartschool_message.dart';
import 'package:do_thing/providers/database_provider.dart';
import 'package:do_thing/services/smartschool/smartschool_auth_controller.dart';
import 'package:do_thing/services/smartschool/smartschool_bridge.dart';
import 'package:do_thing/services/smartschool/smartschool_messages_controller.dart';

class _FakeAuthController extends SmartschoolAuthController {
  _FakeAuthController({required this.connectedAfterConnect});

  final bool connectedAfterConnect;

  @override
  Future<SmartschoolConnectionState> build() async => connectedAfterConnect
      ? SmartschoolConnectionState.connected
      : SmartschoolConnectionState.disconnected;

  @override
  Future<void> connect() async {
    state = AsyncData(
      connectedAfterConnect
          ? SmartschoolConnectionState.connected
          : SmartschoolConnectionState.disconnected,
    );
  }

  @override
  SmartschoolBridge get bridge => throw UnimplementedError();
}

class _FakeMessagesController extends SmartschoolMessagesController {
  _FakeMessagesController({required this.onGetHeaders, this.onGetMessage});

  final Future<List<SmartschoolMessageHeader>> Function(SmartschoolBoxType)
  onGetHeaders;
  final Future<List<SmartschoolMessageDetail>> Function(int)? onGetMessage;

  @override
  void build() {}

  @override
  Future<List<SmartschoolMessageHeader>> getHeaders({
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    List<int> alreadySeenIds = const [],
  }) {
    return onGetHeaders(boxType);
  }

  @override
  Future<List<SmartschoolMessageThread>> getThreadedHeaders({
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    List<int> alreadySeenIds = const [],
  }) {
    return Future.value(const []);
  }

  @override
  Future<List<SmartschoolMessageDetail>> getMessage(
    int messageId, {
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    bool reportStatus = true,
  }) {
    return onGetMessage?.call(messageId) ?? Future.value(const []);
  }
}

SmartschoolMessageHeader _header({
  required int id,
  required bool unread,
  String from = 'Sender',
  String date = '2026-04-10T12:00:00Z',
}) {
  return SmartschoolMessageHeader(
    id: id,
    from: from,
    fromImage: '',
    subject: 'Subject $id',
    date: date,
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
  group('SmartschoolInboxController', () {
    test(
      'refreshInboxAndGetHeaders returns empty when auth stays disconnected',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            smartschoolAuthProvider.overrideWith(
              () => _FakeAuthController(connectedAfterConnect: false),
            ),
            smartschoolMessagesProvider.overrideWith(
              () =>
                  _FakeMessagesController(onGetHeaders: (_) async => const []),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(smartschoolInboxProvider.notifier);
        final headers = await notifier.refreshInboxAndGetHeaders();

        expect(headers, isEmpty);
        expect(
          container
              .read(smartschoolInboxProvider)
              .maybeWhen(data: (value) => value, orElse: () => null),
          0,
        );

        final statusEntries = container.read(statusProvider);
        expect(
          statusEntries.any(
            (entry) =>
                entry.type == StatusEntryType.warning &&
                entry.message.contains('not connected'),
          ),
          isTrue,
        );
      },
    );

    test(
      'refreshInboxAndGetHeaders updates unread count when connected',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final headers = [
          _header(id: 1, unread: true),
          _header(id: 2, unread: false),
        ];

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            smartschoolAuthProvider.overrideWith(
              () => _FakeAuthController(connectedAfterConnect: true),
            ),
            smartschoolMessagesProvider.overrideWith(
              () => _FakeMessagesController(
                onGetHeaders: (box) async =>
                    box == SmartschoolBoxType.inbox ? headers : const [],
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(smartschoolInboxProvider.notifier);
        final fetched = await notifier.refreshInboxAndGetHeaders();

        expect(fetched, hasLength(2));
        expect(
          container
              .read(smartschoolInboxProvider)
              .maybeWhen(data: (value) => value, orElse: () => null),
          1,
        );
      },
    );

    test(
      'refreshInboxAndGetContactInboxes orders contacts and related items by newest first',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final headers = [
          _header(
            id: 1,
            unread: true,
            from: 'Alice',
            date: '2026-04-10T10:00:00Z',
          ),
          _header(
            id: 2,
            unread: false,
            from: 'Bob',
            date: '2026-04-10T11:00:00Z',
          ),
          _header(
            id: 3,
            unread: false,
            from: 'Alice',
            date: '2026-04-10T12:00:00Z',
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            smartschoolAuthProvider.overrideWith(
              () => _FakeAuthController(connectedAfterConnect: true),
            ),
            smartschoolMessagesProvider.overrideWith(
              () => _FakeMessagesController(
                onGetHeaders: (box) async =>
                    box == SmartschoolBoxType.inbox ? headers : const [],
                onGetMessage: (id) async {
                  final header = headers.firstWhere(
                    (h) => h.id == id,
                    orElse: () => headers.first,
                  );
                  final userId = header.from == 'Alice' ? 1 : 2;
                  return [
                    SmartschoolMessageDetail(
                      id: id,
                      from: header.from,
                      subject: header.subject,
                      body: '<p>Test</p>',
                      date: header.date,
                      replyAllToRecipients: [
                        SmartschoolMessageRecipient(
                          displayName: header.from,
                          userId: userId,
                        ),
                      ],
                    ),
                  ];
                },
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(smartschoolInboxProvider.notifier);
        final contacts = await notifier.refreshInboxAndGetContactInboxes();

        expect(contacts.map((c) => c.displayName), ['Alice', 'Bob']);
        expect(contacts.first.items.map((item) => item.messageHeader.id), [
          3,
          1,
        ]);
        expect(contacts.first.unreadCount, 1);
        expect(contacts.last.items.map((item) => item.messageHeader.id), [2]);
      },
    );

    test(
      'self-sent message from sent bootstrap is discarded and logged as info',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        // Inbox has one regular message; sent has one self-sent message.
        final inboxHeaders = [_header(id: 400, unread: false)];
        final sentHeaders = [_header(id: 500, unread: false)];

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            smartschoolAuthProvider.overrideWith(
              () => _FakeAuthController(connectedAfterConnect: true),
            ),
            smartschoolMessagesProvider.overrideWith(
              () => _FakeMessagesController(
                onGetHeaders: (box) async =>
                    box == SmartschoolBoxType.inbox ? inboxHeaders : sentHeaders,
                // Returning [] from getMessage signals self-sent for the sent box.
                onGetMessage: (_) async => const [],
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(smartschoolInboxProvider.notifier);
        await notifier.refreshInboxAndGetHeaders();

        // Sent message 500 should have been discarded.
        final sentRow = await db.messagesDao.findMessage(
          source: 'smartschool',
          externalId: '500',
        );
        expect(sentRow, isNull);

        // Status log should contain a "self-sent, discarded" info entry.
        final statusEntries = container.read(statusProvider);
        expect(
          statusEntries.any(
            (entry) =>
                entry.type == StatusEntryType.info &&
                entry.message.contains('self-sent, discarded'),
          ),
          isTrue,
        );
      },
    );

    test(
      'refreshInboxAndGetHeaders maps parse error to friendly status message',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            smartschoolAuthProvider.overrideWith(
              () => _FakeAuthController(connectedAfterConnect: true),
            ),
            smartschoolMessagesProvider.overrideWith(
              () => _FakeMessagesController(
                onGetHeaders: (box) async {
                  if (box == SmartschoolBoxType.inbox) {
                    throw Exception('ParseError: no element found');
                  }
                  return const [];
                },
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(smartschoolInboxProvider.notifier);
        final headers = await notifier.refreshInboxAndGetHeaders();

        expect(headers, isEmpty);
        expect(
          container
              .read(smartschoolInboxProvider)
              .maybeWhen(data: (value) => value, orElse: () => null),
          0,
        );

        final statusEntries = container.read(statusProvider);
        expect(
          statusEntries.any(
            (entry) =>
                entry.type == StatusEntryType.error &&
                entry.message.contains('invalid/empty XML'),
          ),
          isTrue,
        );
      },
    );
  });
}
