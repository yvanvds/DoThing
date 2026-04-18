import 'dart:math';

import 'package:do_thing/services/busy_status_message_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusyStatusMessageCatalog', () {
    test('exposes reusable generic phrases', () {
      expect(BusyStatusMessageCatalog.genericPhrases, isNotEmpty);
      expect(
        BusyStatusMessageCatalog.genericPhrases,
        contains('I am reading between the lines...'),
      );
    });

    test('randomIndex returns zero for an empty phrase list', () {
      expect(
        BusyStatusMessageCatalog.randomIndex(Random(1), phrases: const []),
        0,
      );
    });

    test('nextIndex avoids returning the current index when possible', () {
      final phrases = ['alpha', 'beta'];

      expect(
        BusyStatusMessageCatalog.nextIndex(
          Random(1),
          currentIndex: 1,
          phrases: phrases,
        ),
        0,
      );
    });

    test('phraseAt returns an empty string for an empty phrase list', () {
      expect(BusyStatusMessageCatalog.phraseAt(0, phrases: const []), '');
    });
  });
}
