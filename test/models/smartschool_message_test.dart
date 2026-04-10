import 'package:flutter_test/flutter_test.dart';
import 'package:do_thing/models/smartschool_message.dart';

void main() {
  group('SmartschoolMessageHeader.fromJson', () {
    test('inverts unread flag and maps attachment count', () {
      final header = SmartschoolMessageHeader.fromJson({
        'id': 42,
        'from': 'Teacher',
        'from_image': 'https://example.com/avatar.png',
        'subject': 'Exam update',
        'date': '2026-04-10T12:00:00Z',
        'status': 1,
        'unread': true,
        'attachment': 2,
        'label': true,
        'deleted': false,
        'allowreply': true,
        'allowreplyenabled': true,
        'hasreply': true,
        'has_forward': false,
        'real_box': 'inbox',
        'send_date': '2026-04-11T12:00:00Z',
      });

      expect(header.id, 42);
      expect(header.unread, isFalse);
      expect(header.hasAttachment, isTrue);
      expect(header.realBox, 'inbox');
      expect(header.sendDate, '2026-04-11T12:00:00Z');
    });

    test('uses defaults when optional fields are missing', () {
      final header = SmartschoolMessageHeader.fromJson({'id': 7});

      expect(header.id, 7);
      expect(header.from, '');
      expect(header.subject, '');
      expect(header.status, 0);
      expect(header.unread, isFalse);
      expect(header.hasAttachment, isFalse);
      expect(header.realBox, 'inbox');
      expect(header.sendDate, isNull);
    });
  });

  group('SmartschoolAttachment.fromJson', () {
    test('parses int and string sizes', () {
      final intSized = SmartschoolAttachment.fromJson({
        'index': 1,
        'name': 'a.pdf',
        'size': 128,
      });
      final stringSized = SmartschoolAttachment.fromJson({
        'index': 2,
        'name': 'b.png',
        'size': '256',
      });

      expect(intSized.index, 1);
      expect(intSized.size, 128);
      expect(intSized.sizeLabel, isNull);
      expect(stringSized.index, 2);
      expect(stringSized.size, 256);
      expect(stringSized.sizeLabel, '256');
    });

    test('falls back to size 0 when value is invalid', () {
      final attachment = SmartschoolAttachment.fromJson({
        'index': 3,
        'name': 'c.txt',
        'size': 'n/a',
      });

      expect(attachment.index, 3);
      expect(attachment.size, 0);
      expect(attachment.sizeLabel, 'n/a');
    });

    test('parses human-readable binary units', () {
      final attachment = SmartschoolAttachment.fromJson({
        'index': 4,
        'name': 'archive.zip',
        'size': '1.5 MiB',
      });

      expect(attachment.size, 1572864);
      expect(attachment.sizeLabel, '1.5 MiB');
    });
  });

  group('SmartschoolMessageThread.fromJson', () {
    test('maps nested headers and defaults', () {
      final thread = SmartschoolMessageThread.fromJson({
        'thread_key': 'math',
        'subject': 'Math',
        'latest_date': '2026-04-10T12:00:00Z',
        'message_count': 2,
        'has_unread': true,
        'has_reply': false,
        'messages': [
          {
            'id': 1,
            'from': 'A',
            'subject': 'Math',
            'date': '2026-04-10T11:00:00Z',
          },
        ],
      });

      expect(thread.threadKey, 'math');
      expect(thread.messageCount, 2);
      expect(thread.hasUnread, isTrue);
      expect(thread.messages, hasLength(1));
      expect(thread.messages.first.id, 1);
    });
  });
}
