import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_thing/controllers/composer_controller.dart';
import 'package:do_thing/controllers/composer_visibility_controller.dart';
import 'package:do_thing/models/draft_message.dart';
import 'package:do_thing/models/recipients/recipient_chip.dart';
import 'package:do_thing/models/recipients/recipient_chip_source.dart';
import 'package:do_thing/models/recipients/recipient_endpoint.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_kind.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_label.dart';

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
      autoSelectedPreferred: false,
    );
  }

  group('ComposerController', () {
    test('builds with a blank DraftMessage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final draft = container.read(composerProvider);
      expect(draft.toRecipients, isEmpty);
      expect(draft.ccRecipients, isEmpty);
      expect(draft.bccRecipients, isEmpty);
      expect(draft.subject, '');
    });

    test('updateToRecipients replaces the To list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(composerProvider.notifier).updateToRecipients([
        emailChip('alice@example.com'),
        emailChip('bob@example.com'),
      ]);

      final toRecipients = container.read(composerProvider).toRecipients;
      expect(
        toRecipients.map((chip) => chip.endpoint.value).toList(growable: false),
        ['alice@example.com', 'bob@example.com'],
      );
    });

    test('updateToRecipients stores deterministic endpoint chips', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(composerProvider.notifier).updateToRecipients([
        const RecipientChip(
          displayName: 'Jan Peeters',
          endpoint: RecipientEndpoint(
            kind: RecipientEndpointKind.smartschool,
            value: 'ss-jan',
            label: RecipientEndpointLabel.smartschool,
          ),
          source: RecipientChipSource.local,
          autoSelectedPreferred: true,
        ),
      ]);

      final draft = container.read(composerProvider);
      expect(draft.toRecipients, hasLength(1));
      expect(
        draft.toRecipients.first.endpoint.kind,
        RecipientEndpointKind.smartschool,
      );
      expect(draft.toRecipients.first.endpoint.value, 'ss-jan');
    });

    test('updateCcRecipients and updateBccRecipients update their fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(composerProvider.notifier).updateCcRecipients([
        emailChip('cc@example.com'),
      ]);
      container.read(composerProvider.notifier).updateBccRecipients([
        emailChip('bcc@example.com'),
      ]);

      final draft = container.read(composerProvider);
      expect(draft.ccRecipients.map((chip) => chip.endpoint.value), [
        'cc@example.com',
      ]);
      expect(draft.bccRecipients.map((chip) => chip.endpoint.value), [
        'bcc@example.com',
      ]);
    });

    test('updateSubject replaces the subject', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(composerProvider.notifier).updateSubject('Meeting notes');
      expect(container.read(composerProvider).subject, 'Meeting notes');
    });

    test('updateBody replaces the Quill delta', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final delta = [
        {'insert': 'Hello world\n'},
      ];
      container.read(composerProvider.notifier).updateBody(delta);
      expect(container.read(composerProvider).body, delta);
    });

    test('reset returns draft to blank state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(composerProvider.notifier).updateToRecipients([
        emailChip('alice@example.com'),
      ]);
      container.read(composerProvider.notifier).updateSubject('Meeting notes');

      container.read(composerProvider.notifier).reset();

      final draft = container.read(composerProvider);
      expect(draft.toRecipients, isEmpty);
      expect(draft.subject, '');
      expect(draft.body, DraftMessage().body);
    });

    test('updates to individual fields do not affect other fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(composerProvider.notifier).updateToRecipients([
        emailChip('a@example.com'),
      ]);
      container.read(composerProvider.notifier).updateSubject('Hello');

      final draft = container.read(composerProvider);
      expect(draft.toRecipients.map((chip) => chip.endpoint.value), [
        'a@example.com',
      ]);
      expect(draft.subject, 'Hello');
      // cc / bcc untouched
      expect(draft.ccRecipients, isEmpty);
      expect(draft.bccRecipients, isEmpty);
    });
  });

  group('ComposerVisibilityController', () {
    test('starts closed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(composerVisibilityProvider), isFalse);
    });

    test('open() sets state to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(composerVisibilityProvider.notifier).open();
      expect(container.read(composerVisibilityProvider), isTrue);
    });

    test('close() sets state to false after open', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(composerVisibilityProvider.notifier).open();
      container.read(composerVisibilityProvider.notifier).close();
      expect(container.read(composerVisibilityProvider), isFalse);
    });

    test('calling close when already closed is a no-op', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(composerVisibilityProvider.notifier).close();
      expect(container.read(composerVisibilityProvider), isFalse);
    });
  });
}
