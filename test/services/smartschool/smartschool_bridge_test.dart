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

    test(
      'markRead, markUnread, setLabel, and trash delegate to messages API',
      () async {
        final messages = _FakeMessagesApi();
        final bridge = SmartschoolBridge.forTesting(
          session: _FakeSessionApi(),
          messages: messages,
        );

        await bridge.markRead(9);
        await bridge.markUnread(10);
        await bridge.setLabel(11, SmartschoolMessageLabel.blueFlag);
        await bridge.trash(12);

        expect(messages.markReadCalls, [9]);
        expect(messages.markUnreadCalls, [10]);
        expect(messages.trashCalls, [12]);
        expect(messages.setLabelCalls, hasLength(1));
        expect(messages.setLabelCalls.single.messageId, 11);
        expect(messages.setLabelCalls.single.label, MessageLabel.blueFlag);
      },
    );

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

    test(
      'startInboxEventDrivenDetection throws without live client context',
      () async {
        final bridge = SmartschoolBridge.forTesting(
          session: _FakeSessionApi(),
          messages: _FakeMessagesApi(),
        );

        await expectLater(
          () => bridge.startInboxEventDrivenDetection(
            seenIds: const [1, 2],
            onNewHeaders: (_) async {},
          ),
          throwsA(isA<SmartschoolBridgeException>()),
        );
      },
    );

    test('stopInboxEventDrivenDetection is safe when never started', () async {
      final bridge = SmartschoolBridge.forTesting(
        session: _FakeSessionApi(),
        messages: _FakeMessagesApi(),
      );

      await bridge.stopInboxEventDrivenDetection();
    });
  });

  group('SmartschoolBridge.getMessage — sent box', () {
    test('calls getSentMessageRecipients for sent box', () async {
      final messages = _FakeMessagesApi();
      messages.messageResult = _fullMessage(1);
      messages.sentRecipientsResult = (
        [
          const MessageSearchUser(
            userId: 42,
            displayName: 'Steven Claes',
            ssId: 7,
          ),
        ],
        [],
      );
      final bridge = SmartschoolBridge.forTesting(
        session: _FakeSessionApi(),
        messages: messages,
      );

      final details = await bridge.getMessage(
        1,
        boxType: SmartschoolBoxType.sent,
      );

      expect(details, hasLength(1));
      expect(messages.getSentRecipientsCalls, [1]);
    });

    test(
      'returns empty list when getSentMessageRecipients is empty (self-sent)',
      () async {
        final messages = _FakeMessagesApi();
        messages.messageResult = _fullMessage(2);
        // sentRecipientsResult defaults to empty
        final bridge = SmartschoolBridge.forTesting(
          session: _FakeSessionApi(),
          messages: messages,
        );

        final details = await bridge.getMessage(
          2,
          boxType: SmartschoolBoxType.sent,
        );

        expect(details, isEmpty);
      },
    );

    test('does not call getSentMessageRecipients for inbox box', () async {
      final messages = _FakeMessagesApi();
      messages.messageResult = _fullMessage(3);
      final bridge = SmartschoolBridge.forTesting(
        session: _FakeSessionApi(),
        messages: messages,
      );

      await bridge.getMessage(3, boxType: SmartschoolBoxType.inbox);

      expect(messages.getSentRecipientsCalls, isEmpty);
    });

    test('strips +/- prefix from receiver display names', () async {
      final messages = _FakeMessagesApi();
      messages.messageResult = _fullMessage(
        4,
        receivers: ['+Steven Claes', '-Bob Smith', 'No Prefix'],
      );
      messages.sentRecipientsResult = (
        [
          const MessageSearchUser(
            userId: 1,
            displayName: 'Steven Claes',
            ssId: 0,
          ),
        ],
        [],
      );
      final bridge = SmartschoolBridge.forTesting(
        session: _FakeSessionApi(),
        messages: messages,
      );

      final details = await bridge.getMessage(
        4,
        boxType: SmartschoolBoxType.sent,
      );

      expect(details, hasLength(1));
      expect(details.first.receivers.map((r) => r.displayName).toList(), [
        'Steven Claes',
        'Bob Smith',
        'No Prefix',
      ]);
    });
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
  final List<int> markReadCalls = [];
  final List<int> markUnreadCalls = [];
  final List<int> trashCalls = [];
  final List<_SetLabelCall> setLabelCalls = [];
  final List<int> getSentRecipientsCalls = [];

  FullMessage? messageResult;
  (List<MessageSearchUser>, List<MessageSearchUser>) sentRecipientsResult =
      (<MessageSearchUser>[], <MessageSearchUser>[]);

  @override
  Future<void> markRead(int messageId) async {
    markReadCalls.add(messageId);
  }

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
  Future<FullMessage?> getMessage(
    int messageId, {
    required BoxType boxType,
    required bool includeAllRecipients,
  }) async {
    return messageResult;
  }

  @override
  Future<(List<MessageSearchUser>, List<MessageSearchUser>)>
  getReplyAllRecipients(int messageId, {required BoxType boxType}) async {
    return (<MessageSearchUser>[], <MessageSearchUser>[]);
  }

  @override
  Future<(List<MessageSearchUser>, List<MessageSearchUser>)>
  getSentMessageRecipients(int messageId) async {
    getSentRecipientsCalls.add(messageId);
    return sentRecipientsResult;
  }

  @override
  Future<List<dynamic>> getAttachments(int messageId) async {
    return const [];
  }

  @override
  Future<(List<MessageSearchUser>, List<MessageSearchGroup>)>
  searchRecipientsForCompose(String query) async {
    return (<MessageSearchUser>[], <MessageSearchGroup>[]);
  }

  @override
  Future<void> sendMessage({
    required List<MessageSearchUser> to,
    List<MessageSearchUser> cc = const [],
    List<MessageSearchUser> bcc = const [],
    required String subject,
    required String bodyHtml,
  }) async {}
}

FullMessage _fullMessage(int id, {List<String> receivers = const []}) {
  return FullMessage(
    id: id,
    subject: 'Subject $id',
    date: DateTime(2026, 4, 10),
    body: '<p>Hello</p>',
    status: 1,
    attachment: 0,
    unread: false,
    receivers: receivers,
    ccReceivers: const [],
    bccReceivers: const [],
    senderPicture: '',
    fromTeam: 0,
    totalNrOtherToReceivers: 0,
    totalNrOtherCcReceivers: 0,
    totalNrOtherBccReceivers: 0,
    canReply: true,
    hasReply: false,
    hasForward: false,
    sender: 'Yvan',
  );
}
