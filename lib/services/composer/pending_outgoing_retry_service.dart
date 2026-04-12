import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/status_controller.dart';
import '../../providers/database_provider.dart';
import 'composer_message_sender.dart';
import 'queued_draft_codec.dart';

class PendingOutgoingRetryService {
  PendingOutgoingRetryService(this.ref);

  final Ref ref;

  Future<void> processDueMessages({required bool isStartup}) async {
    final db = ref.read(appDatabaseProvider);
    final dueMessages = await db.pendingOutgoingMessagesDao.getDueMessages();
    if (dueMessages.isEmpty) {
      return;
    }

    var resentCount = 0;
    var failedCount = 0;
    final now = DateTime.now();

    for (final queued in dueMessages) {
      try {
        final draft = QueuedDraftCodec.decode(queued.payloadJson);
        await ref
            .read(composerMessageSenderProvider)
            .send(draft, queueOnFailure: false, reportStatus: false);
        await db.pendingOutgoingMessagesDao.deleteById(queued.id);
        resentCount++;
      } catch (error) {
        failedCount++;
        await db.pendingOutgoingMessagesDao.markRetryFailure(
          id: queued.id,
          error: error.toString(),
          nextAttemptAt: now.add(const Duration(minutes: 5)),
        );
      }
    }

    if (resentCount == 0 && failedCount == 0) {
      return;
    }

    final status = ref.read(statusProvider.notifier);
    final total = resentCount + failedCount;
    final prefix = isStartup
        ? 'Queued send startup retry'
        : 'Queued send retry';
    if (failedCount == 0) {
      status.add(
        StatusEntryType.success,
        '$prefix: resent $resentCount of $total queued message${total == 1 ? '' : 's'}.',
      );
      return;
    }

    status.add(
      StatusEntryType.warning,
      '$prefix: resent $resentCount of $total queued message${total == 1 ? '' : 's'}; $failedCount still pending.',
    );
  }
}

final pendingOutgoingRetryServiceProvider =
    Provider<PendingOutgoingRetryService>(PendingOutgoingRetryService.new);
