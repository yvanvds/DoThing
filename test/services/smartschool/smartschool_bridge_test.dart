import 'package:do_thing/models/smartschool_message.dart';
import 'package:do_thing/services/smartschool/smartschool_bridge.dart';
import 'package:do_thing/services/smartschool/smartschool_bridge_exception.dart';
import 'package:flutter_smartschool/flutter_smartschool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmartschoolBridge behavior', () {
    test('archive accepts int and forwards as single-item list', () async {
      final messages = _FakeMessagesApi();
      final bridge = SmartschoolBridge.forTesting(
        session: _FakeSessionApi(),
        messages: messages,
      );

      await bridge.archive(42);

      expect(messages.archivedIds, [42]);
    });

    test('archive filters non-int values from dynamic list', () async {
      final messages = _FakeMessagesApi();
      final bridge = SmartschoolBridge.forTesting(
        session: _FakeSessionApi(),
        messages: messages,
      );

      await bridge.archive([1, 'x', 2, 3.5, 4]);

      expect(messages.archivedIds, [1, 2, 4]);
    });

    test('archive ignores unsupported payload types', () async {
      final messages = _FakeMessagesApi();
      final bridge = SmartschoolBridge.forTesting(
        session: _FakeSessionApi(),
        messages: messages,
      );

      await bridge.archive({'id': 1});

      expect(messages.archivedIds, isEmpty);
    });

    test('markUnread, setLabel, and trash delegate to messages API', () async {
      final messages = _FakeMessagesApi();
      final bridge = SmartschoolBridge.forTesting(
        session: _FakeSessionApi(),
        messages: messages,
      );

      await bridge.markUnread(10);
      await bridge.setLabel(11, SmartschoolMessageLabel.blueFlag);
      await bridge.trash(12);

      expect(messages.markUnreadCalls, [10]);
      expect(messages.trashCalls, [12]);
      expect(messages.setLabelCalls, hasLength(1));
      expect(messages.setLabelCalls.single.messageId, 11);
      expect(messages.setLabelCalls.single.label, MessageLabel.blueFlag);
    });

    test('ping and isAuthenticated reflect session success/failure', () async {
      final okBridge = SmartschoolBridge.forTesting(
        session: _FakeSessionApi(),
        messages: _FakeMessagesApi(),
      );
      final failingBridge = SmartschoolBridge.forTesting(
        session: _FakeSessionApi(throwOnAuth: true),
        messages: _FakeMessagesApi(),
      );

      expect(await okBridge.ping(), isTrue);
      expect(await okBridge.isAuthenticated(), isTrue);
      expect(await failingBridge.ping(), isFalse);
      expect(await failingBridge.isAuthenticated(), isFalse);
    });

    test(
      'logout wraps session failure in SmartschoolBridgeException',
      () async {
        final bridge = SmartschoolBridge.forTesting(
          session: _FakeSessionApi(throwOnLogout: true),
          messages: _FakeMessagesApi(),
        );

        expect(
          () => bridge.logout(),
          throwsA(isA<SmartschoolBridgeException>()),
        );
      },
    );
  });
}

class _SetLabelCall {
  const _SetLabelCall({required this.messageId, required this.label});

  final int messageId;
  final MessageLabel label;
}

class _FakeSessionApi implements SmartschoolSessionApi {
  _FakeSessionApi({this.throwOnAuth = false, this.throwOnLogout = false});

  final bool throwOnAuth;
  final bool throwOnLogout;

  @override
  Future<void> clearCookies() async {
    if (throwOnLogout) {
      throw StateError('logout failed');
    }
  }

  @override
  Future<void> ensureAuthenticated() async {
    if (throwOnAuth) {
      throw StateError('auth failed');
    }
  }
}

class _FakeMessagesApi implements SmartschoolMessagesApi {
  final List<int> archivedIds = [];
  final List<int> markUnreadCalls = [];
  final List<int> trashCalls = [];
  final List<_SetLabelCall> setLabelCalls = [];

  @override
  Future<void> markUnread(int messageId) async {
    markUnreadCalls.add(messageId);
  }

  @override
  Future<void> moveToArchive(List<int> messageIds) async {
    archivedIds.addAll(messageIds);
  }

  @override
  Future<void> moveToTrash(int messageId) async {
    trashCalls.add(messageId);
  }

  @override
  Future<void> setLabel(int messageId, MessageLabel label) async {
    setLabelCalls.add(_SetLabelCall(messageId: messageId, label: label));
  }

  @override
  Future<List<ShortMessage>> getHeaders({
    required BoxType boxType,
    required List<int> alreadySeenIds,
  }) async {
    return const [];
  }

  @override
  Future<FullMessage?> getMessage(int messageId) async {
    return null;
  }

  @override
  Future<List<dynamic>> getAttachments(int messageId) async {
    return const [];
  }
}
