import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_thing/controllers/status_controller.dart';
import 'package:do_thing/models/smartschool_message.dart';
import 'package:do_thing/services/smartschool_auth_service.dart';
import 'package:do_thing/services/smartschool_bridge.dart';
import 'package:do_thing/services/smartschool_messages_service.dart';

class _FakeBridge implements SmartschoolBridge {
  int? markedUnreadId;
  int? trashedId;
  dynamic archivedPayload;
  int? labeledId;
  SmartschoolMessageLabel? labeledValue;
  int getMessageCalls = 0;
  int? lastGetMessageId;

  @override
  Future<void> markUnread(int messageId) async {
    markedUnreadId = messageId;
  }

  @override
  Future<void> setLabel(int messageId, SmartschoolMessageLabel label) async {
    labeledId = messageId;
    labeledValue = label;
  }

  @override
  Future<void> archive(dynamic messageId) async {
    archivedPayload = messageId;
  }

  @override
  Future<void> trash(int messageId) async {
    trashedId = messageId;
  }

  @override
  Future<List<SmartschoolMessageDetail>> getMessage(int messageId) async {
    getMessageCalls++;
    lastGetMessageId = messageId;
    return const [
      SmartschoolMessageDetail(
        id: 1,
        from: 'Teacher',
        subject: 'Subject',
        body: '<p>Body</p>',
        date: '2026-04-10T12:00:00Z',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthController extends SmartschoolAuthController {
  _FakeAuthController(this._bridge);

  final SmartschoolBridge _bridge;

  @override
  Future<SmartschoolConnectionState> build() async =>
      SmartschoolConnectionState.connected;

  @override
  SmartschoolBridge get bridge => _bridge;
}

void main() {
  group('SmartschoolMessagesController actions', () {
    late _FakeBridge bridge;
    late ProviderContainer container;

    setUp(() {
      bridge = _FakeBridge();
      container = ProviderContainer(
        overrides: [
          smartschoolAuthProvider.overrideWith(
            () => _FakeAuthController(bridge),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('markUnread delegates to bridge and reports status', () async {
      final svc = container.read(smartschoolMessagesProvider.notifier);

      await svc.markUnread(10);

      expect(bridge.markedUnreadId, 10);
      expect(
        container
            .read(statusProvider)
            .any((entry) => entry.message == 'Message marked as unread.'),
        isTrue,
      );
    });

    test('setLabel delegates label value and reports status', () async {
      final svc = container.read(smartschoolMessagesProvider.notifier);

      await svc.setLabel(11, SmartschoolMessageLabel.blueFlag);

      expect(bridge.labeledId, 11);
      expect(bridge.labeledValue, SmartschoolMessageLabel.blueFlag);
      expect(
        container
            .read(statusProvider)
            .any(
              (entry) => entry.message.contains('Message labeled: blueFlag.'),
            ),
        isTrue,
      );
    });

    test('archive reports singular and plural counts', () async {
      final svc = container.read(smartschoolMessagesProvider.notifier);

      await svc.archive(12);
      expect(bridge.archivedPayload, 12);
      expect(
        container
            .read(statusProvider)
            .any((entry) => entry.message == 'Archived 1 message.'),
        isTrue,
      );

      await svc.archive([1, 2, 3]);
      expect(bridge.archivedPayload, [1, 2, 3]);
      expect(
        container
            .read(statusProvider)
            .any((entry) => entry.message == 'Archived 3 messages.'),
        isTrue,
      );
    });

    test('trash delegates to bridge and reports status', () async {
      final svc = container.read(smartschoolMessagesProvider.notifier);

      await svc.trash(13);

      expect(bridge.trashedId, 13);
      expect(
        container
            .read(statusProvider)
            .any((entry) => entry.message == 'Message moved to trash.'),
        isTrue,
      );
    });

    test('markRead triggers getMessage bridge call', () async {
      final svc = container.read(smartschoolMessagesProvider.notifier);

      await svc.markRead(14);

      expect(bridge.getMessageCalls, 1);
      expect(bridge.lastGetMessageId, 14);
    });
  });
}
