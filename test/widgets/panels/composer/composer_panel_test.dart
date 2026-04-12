import 'package:flutter/material.dart';
import 'package:do_thing/models/draft_message.dart';
import 'package:do_thing/models/recipients/recipient_chip.dart';
import 'package:do_thing/models/recipients/recipient_chip_source.dart';
import 'package:do_thing/models/recipients/recipient_endpoint.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_kind.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_label.dart';
import 'package:do_thing/controllers/status_controller.dart';
import 'package:do_thing/services/composer/composer_message_sender.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:do_thing/controllers/composer_controller.dart';
import 'package:do_thing/controllers/composer_visibility_controller.dart';
import 'package:do_thing/widgets/panels/composer/composer_panel.dart';

Widget _buildApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: const [FlutterQuillLocalizations.delegate],
      home: const Scaffold(body: ComposerPanel()),
    ),
  );
}

void main() {
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

  group('ComposerPanel', () {
    testWidgets('renders header labels and title bar', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      expect(find.text('New message'), findsOneWidget);
      expect(find.text('To:'), findsOneWidget);
      expect(find.text('CC:'), findsOneWidget);
      expect(find.text('BCC:'), findsOneWidget);
      expect(find.text('Subject:'), findsOneWidget);
    });

    testWidgets('renders Cancel and Send buttons', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
    });

    testWidgets('Send button is disabled without recipient and subject', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      final sendFinder = find.text('Send');
      expect(sendFinder, findsOneWidget);

      final visibilityBefore = container.read(composerVisibilityProvider);
      await tester.tap(sendFinder, warnIfMissed: false);
      await tester.pump();
      expect(container.read(composerVisibilityProvider), visibilityBefore);
    });

    testWidgets('Send button stays disabled with subject only', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(composerProvider.notifier).updateSubject('Hello');

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send'), warnIfMissed: false);
      await tester.pump();

      expect(container.read(composerVisibilityProvider), isFalse);
      expect(container.read(composerProvider).subject, 'Hello');
    });

    testWidgets('Send button stays disabled with recipient only', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(composerProvider.notifier).updateToRecipients([
        emailChip('alice@example.com'),
      ]);

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send'), warnIfMissed: false);
      await tester.pump();

      expect(container.read(composerProvider).toRecipients, hasLength(1));
      expect(container.read(composerVisibilityProvider), isFalse);
    });

    testWidgets(
      'Send button sends and closes when recipient and subject exist',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            composerMessageSenderProvider.overrideWith(_FakeComposerSender.new),
          ],
        );
        addTearDown(container.dispose);

        container.read(composerProvider.notifier).updateToRecipients([
          emailChip('alice@example.com'),
        ]);
        container.read(composerProvider.notifier).updateSubject('Hello');
        container.read(composerVisibilityProvider.notifier).open();

        await tester.pumpWidget(_buildApp(container));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Send'));
        await tester.pumpAndSettle();

        final fakeSender =
            container.read(composerMessageSenderProvider)
                as _FakeComposerSender;
        expect(fakeSender.sentDrafts, hasLength(1));
        expect(fakeSender.sentDrafts.single.subject, 'Hello');
        expect(container.read(composerVisibilityProvider), isFalse);
        expect(container.read(composerProvider).subject, '');
        expect(container.read(composerProvider).toRecipients, isEmpty);
      },
    );

    testWidgets('failed send keeps composer open and reports error', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          composerMessageSenderProvider.overrideWith(
            _FailingComposerSender.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(composerProvider.notifier).updateToRecipients([
        emailChip('alice@example.com'),
      ]);
      container.read(composerProvider.notifier).updateSubject('Hello');
      container.read(composerVisibilityProvider.notifier).open();

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(container.read(composerVisibilityProvider), isTrue);
      expect(container.read(composerProvider).subject, 'Hello');
      expect(
        container
            .read(statusProvider)
            .any(
              (entry) =>
                  entry.message.contains('Failed to send message:') &&
                  entry.message.contains('Bad network'),
            ),
        isTrue,
      );
    });

    testWidgets('Cancel closes composer and resets draft', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Pre-populate some draft state and open the composer.
      container.read(composerProvider.notifier).updateSubject('Draft subject');
      container.read(composerVisibilityProvider.notifier).open();

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(container.read(composerVisibilityProvider), isFalse);
      expect(container.read(composerProvider).subject, '');
    });

    testWidgets('typing in Subject field updates composerProvider', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      // Subject is the 4th TextField (To, CC, BCC, Subject).
      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(4));

      await tester.enterText(fields.at(3), 'Hello world');
      await tester.pump();

      expect(container.read(composerProvider).subject, 'Hello world');
    });
  });
}

class _FakeComposerSender extends ComposerMessageSender {
  _FakeComposerSender(super.ref);

  final List<DraftMessage> sentDrafts = [];

  @override
  Future<void> send(
    DraftMessage draft, {
    bool queueOnFailure = true,
    bool reportStatus = true,
  }) async {
    sentDrafts.add(draft);
  }
}

class _FailingComposerSender extends ComposerMessageSender {
  _FailingComposerSender(super.ref);

  @override
  Future<void> send(
    DraftMessage draft, {
    bool queueOnFailure = true,
    bool reportStatus = true,
  }) async {
    throw StateError('Bad network');
  }
}
