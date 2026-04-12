import 'package:do_thing/models/draft_message.dart';
import 'package:do_thing/models/recipients/recipient_chip.dart';
import 'package:do_thing/models/recipients/recipient_chip_source.dart';
import 'package:do_thing/models/recipients/recipient_endpoint.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_kind.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_label.dart';
import 'package:do_thing/providers/database_provider.dart';
import 'package:do_thing/services/composer/composer_message_sender.dart';
import 'package:do_thing/services/composer/pending_outgoing_retry_service.dart';
import 'package:do_thing/services/composer/queued_draft_codec.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('PendingOutgoingRetryService', () {
    test('retries due rows and deletes them after success', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.pendingOutgoingMessagesDao.enqueue(
        payloadJson: QueuedDraftCodec.encode(
          DraftMessage(
            toRecipients: [emailChip('alice@example.com')],
            subject: 'Queued hello',
          ),
        ),
        subject: 'Queued hello',
        attemptCount: 1,
        lastAttemptAt: DateTime.parse('2026-04-12T10:00:00Z'),
        nextAttemptAt: DateTime.parse('2026-04-12T10:00:00Z'),
        lastError: 'offline',
      );

      late _RecordingComposerSender sender;
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          composerMessageSenderProvider.overrideWith((ref) {
            sender = _RecordingComposerSender(ref);
            return sender;
          }),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(pendingOutgoingRetryServiceProvider)
          .processDueMessages(isStartup: false);

      expect(sender.sentDrafts, hasLength(1));
      expect(sender.sentDrafts.single.subject, 'Queued hello');
      expect(await db.pendingOutgoingMessagesDao.countQueued(), 0);
    });

    test('keeps failed rows and increments retry metadata', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.pendingOutgoingMessagesDao.enqueue(
        payloadJson: QueuedDraftCodec.encode(
          DraftMessage(
            toRecipients: [emailChip('alice@example.com')],
            subject: 'Still failing',
          ),
        ),
        subject: 'Still failing',
        attemptCount: 1,
        lastAttemptAt: DateTime.parse('2026-04-12T10:00:00Z'),
        nextAttemptAt: DateTime.parse('2026-04-12T10:00:00Z'),
        lastError: 'offline',
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          composerMessageSenderProvider.overrideWith(
            _FailingComposerSender.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(pendingOutgoingRetryServiceProvider)
          .processDueMessages(isStartup: false);

      final queued = await db.pendingOutgoingMessagesDao.getAllQueued();
      expect(queued, hasLength(1));
      expect(queued.single.attemptCount, 2);
      expect(queued.single.lastError, contains('Retry still failing'));
      expect(queued.single.nextAttemptAt, isNotNull);
    });
  });
}

class _RecordingComposerSender extends ComposerMessageSender {
  _RecordingComposerSender(super.ref);

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
    throw StateError('Retry still failing');
  }
}
