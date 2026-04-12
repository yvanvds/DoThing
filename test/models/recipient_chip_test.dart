import 'package:do_thing/models/recipients/recipient_chip.dart';
import 'package:do_thing/models/recipients/recipient_chip_source.dart';
import 'package:do_thing/models/recipients/recipient_endpoint.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_kind.dart';
import 'package:flutter_test/flutter_test.dart';

RecipientChip _chip({
  String name = 'Alice',
  RecipientEndpointKind kind = RecipientEndpointKind.email,
  String value = 'alice@example.com',
}) {
  return RecipientChip(
    displayName: name,
    endpoint: RecipientEndpoint(kind: kind, value: value),
    source: RecipientChipSource.local,
  );
}

void main() {
  group('RecipientChip', () {
    test('dedupeKey delegates to endpoint', () {
      final chip = _chip(
        kind: RecipientEndpointKind.email,
        value: 'Alice@Example.COM',
      );
      expect(chip.dedupeKey, 'email:alice@example.com');
    });

    test('dedupeKey uses smartschool kind prefix', () {
      final chip = _chip(kind: RecipientEndpointKind.smartschool, value: 'u1');
      expect(chip.dedupeKey, 'smartschool:u1');
    });

    test('copyWith updates only displayName', () {
      final original = _chip(name: 'Bob', value: 'bob@example.com');
      final updated = original.copyWith(displayName: 'Robert');
      expect(updated.displayName, 'Robert');
      expect(updated.endpoint.value, 'bob@example.com');
      expect(updated.source, RecipientChipSource.local);
    });

    test('copyWith updates autoSelectedPreferred', () {
      final original = _chip();
      expect(original.autoSelectedPreferred, isFalse);
      final updated = original.copyWith(autoSelectedPreferred: true);
      expect(updated.autoSelectedPreferred, isTrue);
      expect(updated.displayName, original.displayName);
    });

    test('copyWith updates source', () {
      final original = _chip();
      final updated = original.copyWith(source: RecipientChipSource.manual);
      expect(updated.source, RecipientChipSource.manual);
    });
  });
}
