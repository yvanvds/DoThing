import 'package:do_thing/services/smartschool/smartschool_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmartschoolBridge helper utilities', () {
    test('normalizeSubjectForThreading strips reply prefixes', () {
      expect(
        SmartschoolBridge.normalizeSubjectForThreading('Re: Fwd: Hello world'),
        'hello world',
      );
      expect(
        SmartschoolBridge.normalizeSubjectForThreading('  AW[2]: Report  '),
        'report',
      );
    });

    test('normalizeSubjectForThreading handles empty values', () {
      expect(
        SmartschoolBridge.normalizeSubjectForThreading('   '),
        '(no subject)',
      );
    });

    test('parseIsoForSorting returns epoch for invalid values', () {
      final parsed = SmartschoolBridge.parseIsoForSorting('not-a-date');
      expect(parsed.toUtc().toIso8601String(), '1970-01-01T00:00:00.000Z');
    });

    test('parseAttachmentSizeBytes parses plain integer and units', () {
      expect(SmartschoolBridge.parseAttachmentSizeBytes('1024'), 1024);
      expect(SmartschoolBridge.parseAttachmentSizeBytes('1kb'), 1024);
      expect(SmartschoolBridge.parseAttachmentSizeBytes('1.5MB'), 1572864);
      expect(SmartschoolBridge.parseAttachmentSizeBytes('2 gb'), 2147483648);
      expect(SmartschoolBridge.parseAttachmentSizeBytes('bad size'), 0);
    });
  });
}
