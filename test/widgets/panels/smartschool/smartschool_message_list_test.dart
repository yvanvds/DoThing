import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:do_thing/controllers/smartschool_inbox_controller.dart';
import 'package:do_thing/services/smartschool/smartschool_messages_controller.dart';
import 'package:do_thing/widgets/panels/messages/message_list.dart';

class _FakeInboxController extends SmartschoolInboxController {
  _FakeInboxController(this._contacts);

  final List<SmartschoolContactInbox> _contacts;

  @override
  Future<int> build() async =>
      _contacts.fold<int>(0, (sum, contact) => sum + contact.unreadCount);

  @override
  Future<List<SmartschoolContactInbox>> refreshInboxAndGetContactInboxes({
    bool showLoading = true,
  }) async {
    return _contacts;
  }
}

class _FakeMessagesController extends SmartschoolMessagesController {
  final List<dynamic> archivedCalls = [];
  final List<int> trashedCalls = [];

  @override
  void build() {}

  @override
  Future<void> archive(dynamic messageId) async {
    archivedCalls.add(messageId);
  }

  @override
  Future<void> trash(int messageId) async {
    trashedCalls.add(messageId);
  }
}

MessageHeader _header({
  required int id,
  required String from,
  required String date,
}) {
  return MessageHeader(
    id: id,
    from: from,
    fromImage: '',
    subject: 'Subject $id',
    date: date,
    status: 0,
    unread: true,
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
  testWidgets('shows empty state when there are no contacts', (tester) async {
    final container = ProviderContainer(
      overrides: [
        smartschoolInboxProvider.overrideWith(
          () => _FakeInboxController(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MessageList())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No people yet'), findsOneWidget);
  });

  testWidgets('filters contacts by case-insensitive contains', (tester) async {
    final contacts = [
      SmartschoolContactInbox(
        contactId: 1,
        displayName: 'Alice',
        avatarUrl: null,
        latestActivityAt: DateTime.parse('2026-04-10T11:00:00Z'),
        unreadCount: 1,
        items: [
          SmartschoolRelatedItem(
            type: SmartschoolRelatedItemType.message,
            activityAt: DateTime.parse('2026-04-10T11:00:00Z'),
            messageHeader: _header(
              id: 1,
              from: 'Alice',
              date: '2026-04-10T11:00:00Z',
            ),
          ),
        ],
      ),
      SmartschoolContactInbox(
        contactId: 2,
        displayName: 'Bob',
        avatarUrl: null,
        latestActivityAt: DateTime.parse('2026-04-10T10:00:00Z'),
        unreadCount: 1,
        items: [
          SmartschoolRelatedItem(
            type: SmartschoolRelatedItemType.message,
            activityAt: DateTime.parse('2026-04-10T10:00:00Z'),
            messageHeader: _header(
              id: 2,
              from: 'Bob',
              date: '2026-04-10T10:00:00Z',
            ),
          ),
        ],
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        smartschoolInboxProvider.overrideWith(
          () => _FakeInboxController(contacts),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MessageList())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ali');
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsNothing);

    await tester.enterText(find.byType(TextField), 'BO');
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Alice'), findsNothing);
  });

  testWidgets('opening a contact closes previously opened contact', (
    tester,
  ) async {
    final contacts = [
      SmartschoolContactInbox(
        contactId: 1,
        displayName: 'Alice',
        avatarUrl: null,
        latestActivityAt: DateTime.parse('2026-04-10T11:00:00Z'),
        unreadCount: 1,
        items: [
          SmartschoolRelatedItem(
            type: SmartschoolRelatedItemType.message,
            activityAt: DateTime.parse('2026-04-10T11:00:00Z'),
            messageHeader: _header(
              id: 1,
              from: 'Alice',
              date: '2026-04-10T11:00:00Z',
            ),
          ),
        ],
      ),
      SmartschoolContactInbox(
        contactId: 2,
        displayName: 'Bob',
        avatarUrl: null,
        latestActivityAt: DateTime.parse('2026-04-10T10:00:00Z'),
        unreadCount: 1,
        items: [
          SmartschoolRelatedItem(
            type: SmartschoolRelatedItemType.message,
            activityAt: DateTime.parse('2026-04-10T10:00:00Z'),
            messageHeader: _header(
              id: 2,
              from: 'Bob',
              date: '2026-04-10T10:00:00Z',
            ),
          ),
        ],
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        smartschoolInboxProvider.overrideWith(
          () => _FakeInboxController(contacts),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MessageList())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    expect(find.text('Subject 1'), findsOneWidget);

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(find.text('Subject 1'), findsNothing);
    expect(find.text('Subject 2'), findsOneWidget);
  });

  testWidgets('shows no matching people when query filters out all contacts', (
    tester,
  ) async {
    final contacts = [
      SmartschoolContactInbox(
        contactId: 1,
        displayName: 'Alice',
        avatarUrl: null,
        latestActivityAt: DateTime.parse('2026-04-10T11:00:00Z'),
        unreadCount: 0,
        items: [
          SmartschoolRelatedItem(
            type: SmartschoolRelatedItemType.message,
            activityAt: DateTime.parse('2026-04-10T11:00:00Z'),
            messageHeader: _header(
              id: 1,
              from: 'Alice',
              date: '2026-04-10T11:00:00Z',
            ),
          ),
        ],
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        smartschoolInboxProvider.overrideWith(
          () => _FakeInboxController(contacts),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MessageList())),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No matching people'), findsOneWidget);
  });

  testWidgets('bulk archive dialog can be opened and canceled', (tester) async {
    final contacts = [
      SmartschoolContactInbox(
        contactId: 1,
        displayName: 'Alice',
        avatarUrl: null,
        latestActivityAt: DateTime.parse('2026-04-10T11:00:00Z'),
        unreadCount: 2,
        items: [
          SmartschoolRelatedItem(
            type: SmartschoolRelatedItemType.message,
            activityAt: DateTime.parse('2026-04-10T11:00:00Z'),
            messageHeader: _header(
              id: 11,
              from: 'Alice',
              date: '2026-04-10T11:00:00Z',
            ),
          ),
        ],
      ),
    ];

    final fakeMessages = _FakeMessagesController();
    final container = ProviderContainer(
      overrides: [
        smartschoolInboxProvider.overrideWith(
          () => _FakeInboxController(contacts),
        ),
        smartschoolMessagesProvider.overrideWith(() => fakeMessages),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MessageList())),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.text('Alice')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Archive all for this contact'));
    await tester.pumpAndSettle();

    expect(find.text('Archive all messages?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Archive all messages?'), findsNothing);
    expect(fakeMessages.archivedCalls, isEmpty);
  });

  testWidgets('bulk delete confirm calls trash on smartschool message ids', (
    tester,
  ) async {
    final contacts = [
      SmartschoolContactInbox(
        contactId: 1,
        displayName: 'Alice',
        avatarUrl: null,
        latestActivityAt: DateTime.parse('2026-04-10T11:00:00Z'),
        unreadCount: 1,
        items: [
          SmartschoolRelatedItem(
            type: SmartschoolRelatedItemType.message,
            activityAt: DateTime.parse('2026-04-10T11:00:00Z'),
            messageHeader: _header(
              id: 21,
              from: 'Alice',
              date: '2026-04-10T11:00:00Z',
            ),
          ),
          SmartschoolRelatedItem(
            type: SmartschoolRelatedItemType.message,
            activityAt: DateTime.parse('2026-04-10T10:00:00Z'),
            messageHeader: _header(
              id: 22,
              from: 'Alice',
              date: '2026-04-10T10:00:00Z',
            ),
          ),
        ],
      ),
    ];

    final fakeMessages = _FakeMessagesController();
    final container = ProviderContainer(
      overrides: [
        smartschoolInboxProvider.overrideWith(
          () => _FakeInboxController(contacts),
        ),
        smartschoolMessagesProvider.overrideWith(() => fakeMessages),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MessageList())),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.text('Alice')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete all for this contact'));
    await tester.pumpAndSettle();

    expect(find.text('Delete all messages?'), findsOneWidget);
    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();

    expect(fakeMessages.trashedCalls, [21, 22]);
  });
}
