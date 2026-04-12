import 'package:do_thing/providers/database_provider.dart';
import 'package:drift/native.dart';
import 'package:do_thing/models/draft_message.dart';
import 'package:do_thing/models/recipients/recipient_chip.dart';
import 'package:do_thing/models/recipients/recipient_chip_source.dart';
import 'package:do_thing/models/recipients/recipient_endpoint.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_kind.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_label.dart';
import 'package:do_thing/services/composer/composer_message_sender.dart';
import 'package:do_thing/services/office365/office365_mail_service.dart';
import 'package:do_thing/services/smartschool/smartschool_auth_controller.dart';
import 'package:do_thing/services/smartschool/smartschool_bridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smartschool/flutter_smartschool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RecipientChip smartschoolChip({required String name, required String ssId}) {
    return RecipientChip(
      displayName: name,
      endpoint: RecipientEndpoint(
        kind: RecipientEndpointKind.smartschool,
        value: ssId,
        label: RecipientEndpointLabel.smartschool,
        externalId: ssId,
      ),
      source: RecipientChipSource.local,
    );
  }

  RecipientChip emailChip(String email) {
    return RecipientChip(
      displayName: email,
      endpoint: RecipientEndpoint(
        kind: RecipientEndpointKind.email,
        value: email,
        label: RecipientEndpointLabel.other,
      ),
      source: RecipientChipSource.manual,
    );
  }

  group('ComposerMessageSender', () {
    test('rejects drafts without a subject', () async {
      final bridge = _FakeBridge(users: const []);
      final container = ProviderContainer(
        overrides: [
          smartschoolAuthProvider.overrideWith(
            () => _FakeAuthController(bridge),
          ),
          office365MailServiceProvider.overrideWith(
            _FakeOffice365MailService.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final sender = container.read(composerMessageSenderProvider);
      await expectLater(
        () => sender.send(
          DraftMessage(toRecipients: [emailChip('alice@example.com')]),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'A subject is required before sending.',
          ),
        ),
      );
    });

    test('rejects drafts without any recipients', () async {
      final bridge = _FakeBridge(users: const []);
      final container = ProviderContainer(
        overrides: [
          smartschoolAuthProvider.overrideWith(
            () => _FakeAuthController(bridge),
          ),
          office365MailServiceProvider.overrideWith(
            _FakeOffice365MailService.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final sender = container.read(composerMessageSenderProvider);
      await expectLater(
        () => sender.send(DraftMessage(subject: 'Hello')),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Add at least one recipient before sending.',
          ),
        ),
      );
    });

    test(
      'splits mixed recipients into Smartschool and Outlook sends',
      () async {
        final bridge = _FakeBridge(
          users: const [
            MessageSearchUser(userId: 1, displayName: 'Jan', ssId: 1001),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            smartschoolAuthProvider.overrideWith(
              () => _FakeAuthController(bridge),
            ),
            office365MailServiceProvider.overrideWith(
              _FakeOffice365MailService.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        final sender = container.read(composerMessageSenderProvider);
        await sender.send(
          DraftMessage(
            toRecipients: [
              smartschoolChip(name: 'Jan', ssId: '1001'),
              emailChip('alice@example.com'),
            ],
            subject: 'Exam update',
            body: const [
              {'insert': 'Hi all\n'},
            ],
          ),
        );

        final fakeOffice =
            container.read(office365MailServiceProvider)
                as _FakeOffice365MailService;

        expect(bridge.sendCalls, hasLength(1));
        expect(bridge.sendCalls.single.to.map((u) => u.ssId), [1001]);
        expect(bridge.sendCalls.single.bodyHtml, '<p>Hi all</p>');
        expect(fakeOffice.sendCalls, hasLength(1));
        expect(fakeOffice.sendCalls.single.toRecipients, ['alice@example.com']);
        expect(fakeOffice.sendCalls.single.subject, 'Exam update');
        expect(fakeOffice.sendCalls.single.bodyHtml, '<p>Hi all</p>');
      },
    );

    test(
      'sends only Smartschool batch when only Smartschool recipients exist',
      () async {
        final bridge = _FakeBridge(
          users: const [
            MessageSearchUser(userId: 1, displayName: 'Jan', ssId: 1001),
            MessageSearchUser(userId: 2, displayName: 'Piet', ssId: 1002),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            smartschoolAuthProvider.overrideWith(
              () => _FakeAuthController(bridge),
            ),
            office365MailServiceProvider.overrideWith(
              _FakeOffice365MailService.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        final sender = container.read(composerMessageSenderProvider);
        await sender.send(
          DraftMessage(
            toRecipients: [smartschoolChip(name: 'Jan', ssId: '1001')],
            ccRecipients: [smartschoolChip(name: 'Piet', ssId: '1002')],
            subject: 'School trip',
          ),
        );

        final fakeOffice =
            container.read(office365MailServiceProvider)
                as _FakeOffice365MailService;

        expect(bridge.sendCalls, hasLength(1));
        expect(bridge.sendCalls.single.to.map((u) => u.ssId), [1001]);
        expect(bridge.sendCalls.single.cc.map((u) => u.ssId), [1002]);
        expect(fakeOffice.sendCalls, isEmpty);
      },
    );

    test(
      'dedupes repeated Outlook and Smartschool recipients per batch',
      () async {
        final bridge = _FakeBridge(
          users: const [
            MessageSearchUser(userId: 1, displayName: 'Jan', ssId: 1001),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            smartschoolAuthProvider.overrideWith(
              () => _FakeAuthController(bridge),
            ),
            office365MailServiceProvider.overrideWith(
              _FakeOffice365MailService.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        final sender = container.read(composerMessageSenderProvider);
        await sender.send(
          DraftMessage(
            toRecipients: [
              smartschoolChip(name: 'Jan', ssId: '1001'),
              smartschoolChip(name: 'Jan', ssId: '1001'),
              emailChip('alice@example.com'),
              emailChip('alice@example.com'),
            ],
            subject: 'Duplicate check',
          ),
        );

        final fakeOffice =
            container.read(office365MailServiceProvider)
                as _FakeOffice365MailService;

        expect(bridge.sendCalls, hasLength(1));
        expect(bridge.sendCalls.single.to, hasLength(1));
        expect(fakeOffice.sendCalls, hasLength(1));
        expect(fakeOffice.sendCalls.single.toRecipients, ['alice@example.com']);
      },
    );

    test(
      'resolves Smartschool recipients by exact display name when id is not numeric',
      () async {
        final bridge = _FakeBridge(
          users: const [
            MessageSearchUser(
              userId: 7,
              displayName: 'Jan Peeters',
              ssId: 4007,
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            smartschoolAuthProvider.overrideWith(
              () => _FakeAuthController(bridge),
            ),
            office365MailServiceProvider.overrideWith(
              _FakeOffice365MailService.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        final sender = container.read(composerMessageSenderProvider);
        await sender.send(
          DraftMessage(
            toRecipients: [
              smartschoolChip(name: 'Jan Peeters', ssId: 'ss-jan'),
            ],
            subject: 'Name resolution',
          ),
        );

        expect(bridge.sendCalls, hasLength(1));
        expect(bridge.sendCalls.single.to.single.userId, 7);
      },
    );

    test('converts multiline rich text into escaped HTML', () async {
      final bridge = _FakeBridge(users: const []);
      final container = ProviderContainer(
        overrides: [
          smartschoolAuthProvider.overrideWith(
            () => _FakeAuthController(bridge),
          ),
          office365MailServiceProvider.overrideWith(
            _FakeOffice365MailService.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final sender = container.read(composerMessageSenderProvider);
      await sender.send(
        DraftMessage(
          toRecipients: [emailChip('alice@example.com')],
          subject: 'HTML body',
          body: const [
            {'insert': 'Line <one>&\nLine "two"\n'},
          ],
        ),
      );

      final fakeOffice =
          container.read(office365MailServiceProvider)
              as _FakeOffice365MailService;
      expect(
        fakeOffice.sendCalls.single.bodyHtml,
        '<p>Line &lt;one&gt;&amp;<br/>Line &quot;two&quot;</p>',
      );
    });

    test('queues only the failed provider batch for retry', () async {
      final bridge = _FakeBridge(
        users: const [
          MessageSearchUser(userId: 1, displayName: 'Jan', ssId: 1001),
        ],
      );
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          smartschoolAuthProvider.overrideWith(
            () => _FakeAuthController(bridge),
          ),
          office365MailServiceProvider.overrideWith(
            _FailingOffice365MailService.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final sender = container.read(composerMessageSenderProvider);
      await expectLater(
        () => sender.send(
          DraftMessage(
            toRecipients: [
              smartschoolChip(name: 'Jan', ssId: '1001'),
              emailChip('alice@example.com'),
            ],
            subject: 'Mixed failure',
          ),
        ),
        throwsA(isA<StateError>()),
      );

      final queued = await db.pendingOutgoingMessagesDao.getAllQueued();
      expect(bridge.sendCalls, hasLength(1));
      expect(queued, hasLength(1));
      expect(queued.single.subject, 'Mixed failure');
      expect(queued.single.attemptCount, 1);
      expect(queued.single.lastError, contains('Outlook unavailable'));
    });
  });
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

class _FakeBridge implements SmartschoolBridge {
  _FakeBridge({required this.users});

  final List<MessageSearchUser> users;
  final List<_SmartschoolSendCall> sendCalls = [];

  @override
  Future<List<MessageSearchUser>> searchRecipientsForCompose(
    String query,
  ) async {
    final q = query.trim().toLowerCase();
    return users
        .where(
          (user) =>
              user.displayName.toLowerCase().contains(q) ||
              user.userId.toString() == q ||
              user.ssId.toString() == q,
        )
        .toList(growable: false);
  }

  @override
  Future<void> sendMessage({
    required List<MessageSearchUser> to,
    List<MessageSearchUser> cc = const [],
    List<MessageSearchUser> bcc = const [],
    required String subject,
    required String bodyHtml,
  }) async {
    sendCalls.add(
      _SmartschoolSendCall(
        to: to,
        cc: cc,
        bcc: bcc,
        subject: subject,
        bodyHtml: bodyHtml,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOffice365MailService extends Office365MailService {
  _FakeOffice365MailService(super.ref);

  final List<_OutlookSendCall> sendCalls = [];

  @override
  Future<void> sendMail({
    required List<String> toRecipients,
    List<String> ccRecipients = const [],
    List<String> bccRecipients = const [],
    required String subject,
    required String bodyHtml,
  }) async {
    sendCalls.add(
      _OutlookSendCall(
        toRecipients: toRecipients,
        ccRecipients: ccRecipients,
        bccRecipients: bccRecipients,
        subject: subject,
        bodyHtml: bodyHtml,
      ),
    );
  }
}

class _FailingOffice365MailService extends Office365MailService {
  _FailingOffice365MailService(super.ref);

  @override
  Future<void> sendMail({
    required List<String> toRecipients,
    List<String> ccRecipients = const [],
    List<String> bccRecipients = const [],
    required String subject,
    required String bodyHtml,
  }) async {
    throw StateError('Outlook unavailable');
  }
}

class _SmartschoolSendCall {
  _SmartschoolSendCall({
    required this.to,
    required this.cc,
    required this.bcc,
    required this.subject,
    required this.bodyHtml,
  });

  final List<MessageSearchUser> to;
  final List<MessageSearchUser> cc;
  final List<MessageSearchUser> bcc;
  final String subject;
  final String bodyHtml;
}

class _OutlookSendCall {
  _OutlookSendCall({
    required this.toRecipients,
    required this.ccRecipients,
    required this.bccRecipients,
    required this.subject,
    required this.bodyHtml,
  });

  final List<String> toRecipients;
  final List<String> ccRecipients;
  final List<String> bccRecipients;
  final String subject;
  final String bodyHtml;
}
