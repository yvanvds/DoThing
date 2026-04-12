import 'package:flutter_test/flutter_test.dart';
import 'package:do_thing/models/draft_message.dart';

void main() {
  group('DraftMessage defaults', () {
    test(
      'starts with empty recipients, subject, and a single newline body',
      () {
        final draft = DraftMessage();

        expect(draft.to, isEmpty);
        expect(draft.cc, isEmpty);
        expect(draft.bcc, isEmpty);
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

      final withTo = original.copyWith(to: ['alice@example.com']);
      expect(withTo.to, ['alice@example.com']);
      expect(withTo.cc, isEmpty);
      expect(withTo.subject, '');

      final withSubject = original.copyWith(subject: 'Hello');
      expect(withSubject.subject, 'Hello');
      expect(withSubject.to, isEmpty);
    });

    test('returns a new instance without mutating the original', () {
      final original = DraftMessage(subject: 'Original');
      final copy = original.copyWith(subject: 'Changed');

      expect(original.subject, 'Original');
      expect(copy.subject, 'Changed');
    });

    test('preserves all other fields when only one is changed', () {
      final full = DraftMessage(
        to: ['a@example.com'],
        cc: ['b@example.com'],
        bcc: ['c@example.com'],
        subject: 'S',
        body: [
          {'insert': 'Hello\n'},
        ],
      );

      final changed = full.copyWith(subject: 'New');
      expect(changed.to, full.to);
      expect(changed.cc, full.cc);
      expect(changed.bcc, full.bcc);
      expect(changed.body, full.body);
      expect(changed.subject, 'New');
    });
  });
}
