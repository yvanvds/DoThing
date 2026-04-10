import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_thing/controllers/smartschool_inbox_controller.dart';
import 'package:do_thing/controllers/status_controller.dart';
import 'package:do_thing/models/smartschool_message.dart';
import 'package:do_thing/providers/database_provider.dart';
import 'package:do_thing/services/smartschool_auth_service.dart';
import 'package:do_thing/services/smartschool_bridge.dart';
import 'package:do_thing/services/smartschool_messages_service.dart';

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
  _FakeMessagesController({required this.onGetHeaders});

  final Future<List<SmartschoolMessageHeader>> Function() onGetHeaders;

  @override
  void build() {}

  @override
  Future<List<SmartschoolMessageHeader>> getHeaders({
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    List<int> alreadySeenIds = const [],
  }) {
    return onGetHeaders();
  }

  @override
  Future<List<SmartschoolMessageThread>> getThreadedHeaders({
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    List<int> alreadySeenIds = const [],
  }) {
    return Future.value(const []);
  }
}

SmartschoolMessageHeader _header({required int id, required bool unread}) {
  return SmartschoolMessageHeader(
    id: id,
    from: 'Sender',
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
              () => _FakeMessagesController(onGetHeaders: () async => const []),
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
              () => _FakeMessagesController(onGetHeaders: () async => headers),
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
                onGetHeaders: () async =>
                    throw Exception('ParseError: no element found'),
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
