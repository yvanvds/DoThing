import 'package:flutter_test/flutter_test.dart';
import 'package:do_thing/models/draft_message.dart';
import 'package:do_thing/models/recipients/recipient_chip.dart';
import 'package:do_thing/models/recipients/recipient_chip_source.dart';
import 'package:do_thing/models/recipients/recipient_endpoint.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_kind.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_label.dart';

RecipientChip _emailChip(String email) {
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

void main() {
  group('DraftMessage defaults', () {
    test(
      'starts with empty recipients, subject, and a single newline body',
      () {
        final draft = DraftMessage();

        expect(draft.toRecipients, isEmpty);
        expect(draft.ccRecipients, isEmpty);
        expect(draft.bccRecipients, isEmpty);
        expect(draft.subject, '');
        expect(draft.body, [
          {'insert': '\n'},
        ]);
      },
    );
  });

  group('DraftMessage.copyWith', () {
    test('each field can be updated independently', () {
      final original = DraftMessage();

      final withTo = original.copyWith(
        toRecipients: [_emailChip('alice@example.com')],
      );
      expect(withTo.toRecipients, hasLength(1));
      expect(withTo.toRecipients.first.endpoint.value, 'alice@example.com');
      expect(withTo.ccRecipients, isEmpty);
      expect(withTo.subject, '');

      final withSubject = original.copyWith(subject: 'Hello');
      expect(withSubject.subject, 'Hello');
      expect(withSubject.toRecipients, isEmpty);
    });

    test('returns a new instance without mutating the original', () {
      final original = DraftMessage(subject: 'Original');
      final copy = original.copyWith(subject: 'Changed');

      expect(original.subject, 'Original');
      expect(copy.subject, 'Changed');
    });

    test('preserves all other fields when only one is changed', () {
      final full = DraftMessage(
        toRecipients: [_emailChip('a@example.com')],
        ccRecipients: [_emailChip('b@example.com')],
        bccRecipients: [_emailChip('c@example.com')],
        subject: 'S',
        body: [
          {'insert': 'Hello\n'},
        ],
      );

      final changed = full.copyWith(subject: 'New');
      expect(changed.toRecipients, full.toRecipients);
      expect(changed.ccRecipients, full.ccRecipients);
      expect(changed.bccRecipients, full.bccRecipients);
      expect(changed.body, full.body);
      expect(changed.subject, 'New');
    });
  });
}
