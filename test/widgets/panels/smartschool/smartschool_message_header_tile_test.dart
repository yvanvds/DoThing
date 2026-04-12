import 'dart:ui';

import 'package:do_thing/controllers/smartschool_inbox_controller.dart';
import 'package:do_thing/services/office365/office365_mail_service.dart';
import 'package:do_thing/services/smartschool/smartschool_messages_controller.dart';
import 'package:do_thing/services/smartschool/smartschool_selected_message_controller.dart';
import 'package:do_thing/widgets/panels/smartschool/smartschool_message_header_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmartschoolMessageHeaderTile', () {
    testWidgets('opening unread smartschool message marks it as read', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          smartschoolMessagesProvider.overrideWith(_FakeMessagesController.new),
          smartschoolInboxProvider.overrideWith(_FakeInboxController.new),
          office365MailServiceProvider.overrideWith(
            _FakeOffice365MailService.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final updatedHeaders = <SmartschoolMessageHeader>[];
      final removedIds = <int>[];

      final header = _header(id: 101, source: 'smartschool', unread: true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SmartschoolMessageHeaderTile(
                header: header,
                onRemoveFromList: removedIds.add,
                onHeaderUpdated: updatedHeaders.add,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Subject 101'));
      await tester.pumpAndSettle();

      final fakeMessages =
          container.read(smartschoolMessagesProvider.notifier)
              as _FakeMessagesController;
      final fakeInbox =
          container.read(smartschoolInboxProvider.notifier)
              as _FakeInboxController;

      expect(fakeMessages.markReadCalls, [101]);
      expect(fakeInbox.refreshHeadersCalls, 1);
      expect(updatedHeaders, hasLength(1));
      expect(updatedHeaders.single.unread, isFalse);
      expect(removedIds, isEmpty);

      final selected = container.read(smartschoolSelectedMessageProvider);
      expect(selected, isNotNull);
      expect(selected!.id, 101);
      expect(selected.unread, isFalse);
    });

    testWidgets('archive action uses Office365 service for outlook message', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          smartschoolMessagesProvider.overrideWith(_FakeMessagesController.new),
          smartschoolInboxProvider.overrideWith(_FakeInboxController.new),
          office365MailServiceProvider.overrideWith(
            _FakeOffice365MailService.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final removedIds = <int>[];

      final header = _header(id: 202, source: 'outlook', unread: false);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SmartschoolMessageHeaderTile(
                header: header,
                onRemoveFromList: removedIds.add,
                onHeaderUpdated: (_) {},
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer();
      await gesture.moveTo(
        tester.getCenter(find.byType(SmartschoolMessageHeaderTile)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Archive'));
      await tester.pumpAndSettle();

      final fakeOffice365 =
          container.read(office365MailServiceProvider)
              as _FakeOffice365MailService;
      expect(fakeOffice365.archiveCalls, [202]);
      expect(removedIds, [202]);
    });

    testWidgets('mark as unread action is disabled when already unread', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          smartschoolMessagesProvider.overrideWith(_FakeMessagesController.new),
          smartschoolInboxProvider.overrideWith(_FakeInboxController.new),
          office365MailServiceProvider.overrideWith(
            _FakeOffice365MailService.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final header = _header(id: 303, source: 'smartschool', unread: true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SmartschoolMessageHeaderTile(
                header: header,
                onRemoveFromList: (_) {},
                onHeaderUpdated: (_) {},
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer();
      await gesture.moveTo(
        tester.getCenter(find.byType(SmartschoolMessageHeaderTile)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mark as unread'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final fakeMessages =
          container.read(smartschoolMessagesProvider.notifier)
              as _FakeMessagesController;
      expect(fakeMessages.markUnreadCalls, isEmpty);
    });

    testWidgets('trash action uses Office365 service for outlook message', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          smartschoolMessagesProvider.overrideWith(_FakeMessagesController.new),
          smartschoolInboxProvider.overrideWith(_FakeInboxController.new),
          office365MailServiceProvider.overrideWith(
            _FakeOffice365MailService.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final removedIds = <int>[];

      final header = _header(id: 404, source: 'outlook', unread: false);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SmartschoolMessageHeaderTile(
                header: header,
                onRemoveFromList: removedIds.add,
                onHeaderUpdated: (_) {},
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer();
      await gesture.moveTo(
        tester.getCenter(find.byType(SmartschoolMessageHeaderTile)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      final fakeOffice365 =
          container.read(office365MailServiceProvider)
              as _FakeOffice365MailService;
      expect(fakeOffice365.deleteCalls, [404]);
      expect(removedIds, [404]);
    });

    testWidgets('mark as unread on read smartschool message updates header', (
      tester,
    ) async {
      final fakeMessages = _FakeMessagesController();
      final container = ProviderContainer(
        overrides: [
          smartschoolMessagesProvider.overrideWith(() => fakeMessages),
          smartschoolInboxProvider.overrideWith(_FakeInboxController.new),
          office365MailServiceProvider.overrideWith(
            _FakeOffice365MailService.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final updatedHeaders = <SmartschoolMessageHeader>[];

      final header = _header(id: 505, source: 'smartschool', unread: false);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SmartschoolMessageHeaderTile(
                header: header,
                onRemoveFromList: (_) {},
                onHeaderUpdated: updatedHeaders.add,
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer();
      await gesture.moveTo(
        tester.getCenter(find.byType(SmartschoolMessageHeaderTile)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mark as unread'));
      await tester.pumpAndSettle();

      final fakeInbox =
          container.read(smartschoolInboxProvider.notifier)
              as _FakeInboxController;

      expect(fakeMessages.markUnreadCalls, [505]);
      expect(fakeInbox.refreshHeadersCalls, 1);
      expect(updatedHeaders, hasLength(1));
      expect(updatedHeaders.single.unread, isTrue);
    });

    testWidgets('archive failure shows snackbar', (tester) async {
      final fakeMessages = _FakeMessagesController(throwOnArchive: true);
      final container = ProviderContainer(
        overrides: [
          smartschoolMessagesProvider.overrideWith(() => fakeMessages),
          smartschoolInboxProvider.overrideWith(_FakeInboxController.new),
          office365MailServiceProvider.overrideWith(
            _FakeOffice365MailService.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final header = _header(id: 606, source: 'smartschool', unread: false);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SmartschoolMessageHeaderTile(
                header: header,
                onRemoveFromList: (_) {},
                onHeaderUpdated: (_) {},
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer();
      await gesture.moveTo(
        tester.getCenter(find.byType(SmartschoolMessageHeaderTile)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Archive'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to archive:'), findsOneWidget);
    });
  });
}

SmartschoolMessageHeader _header({
  required int id,
  required String source,
  required bool unread,
}) {
  return SmartschoolMessageHeader(
    id: id,
    source: source,
    from: 'Sender $id',
    fromImage: '',
    subject: 'Subject $id',
    date: '2026-04-12T12:10:00Z',
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

class _FakeMessagesController extends SmartschoolMessagesController {
  _FakeMessagesController({this.throwOnArchive = false});

  final bool throwOnArchive;
  final List<int> markReadCalls = [];
  final List<int> markUnreadCalls = [];
  final List<dynamic> archiveCalls = [];
  final List<int> trashCalls = [];

  @override
  void build() {}

  @override
  Future<void> markRead(int messageId) async {
    markReadCalls.add(messageId);
  }

  @override
  Future<void> markUnread(int messageId) async {
    markUnreadCalls.add(messageId);
  }

  @override
  Future<void> trash(int messageId) async {
    trashCalls.add(messageId);
  }

  @override
  Future<void> archive(dynamic messageId) async {
    if (throwOnArchive) {
      throw StateError('archive failed');
    }
    archiveCalls.add(messageId);
  }
}

class _FakeInboxController extends SmartschoolInboxController {
  int refreshHeadersCalls = 0;
  int refreshUnreadCalls = 0;

  @override
  Future<int> build() async => 0;

  @override
  Future<List<SmartschoolMessageHeader>> refreshInboxAndGetHeaders({
    bool showLoading = true,
  }) async {
    refreshHeadersCalls++;
    return const [];
  }

  @override
  Future<int> refreshUnreadFromLocal({bool showLoading = true}) async {
    refreshUnreadCalls++;
    return 0;
  }
}

class _FakeOffice365MailService extends Office365MailService {
  _FakeOffice365MailService(super.ref);

  final List<int> archiveCalls = [];
  final List<int> deleteCalls = [];
  final List<int> markReadCalls = [];
  final List<int> markUnreadCalls = [];

  @override
  Future<void> archiveMessage(int localMessageId) async {
    archiveCalls.add(localMessageId);
  }

  @override
  Future<void> deleteMessage(int localMessageId) async {
    deleteCalls.add(localMessageId);
  }

  @override
  Future<void> markMessageRead(int localMessageId) async {
    markReadCalls.add(localMessageId);
  }

  @override
  Future<void> markMessageUnread(int localMessageId) async {
    markUnreadCalls.add(localMessageId);
  }
}
