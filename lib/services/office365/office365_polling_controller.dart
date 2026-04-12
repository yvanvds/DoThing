import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/status_controller.dart';
import '../../providers/database_provider.dart';
import 'office365_mail_service.dart';

const _kOffice365Source = 'outlook';

class Office365PollingController extends Notifier<int> {
  Timer? _timer;
  bool _started = false;

  @override
  int build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
      _started = false;
    });
    return 0;
  }

  void ensureStarted() {
    if (_started) return;
    _started = true;

    Future<void>.microtask(() => _syncOnce(isStartup: true));

    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _syncOnce(isStartup: false);
    });
  }

  Future<void> _syncOnce({required bool isStartup}) async {
    final status = ref.read(statusProvider.notifier);
    try {
      final result = await ref
          .read(office365MailServiceProvider)
          .syncInboxDelta(silentWhenNotReady: true);

      if (isStartup) {
        status.add(
          StatusEntryType.info,
          'Outlook startup sync: ${result.scannedCount} headers scanned · ${result.newCount} new · ${result.removedCount} removed.',
        );
      } else if (result.newCount > 0 || result.removedCount > 0) {
        final messageWord = result.newCount == 1 ? 'message' : 'messages';
        status.add(
          StatusEntryType.info,
          'Outlook poll: ${result.scannedCount} headers scanned · ${result.newCount} new $messageWord · ${result.removedCount} removed.',
        );
      }
    } catch (error) {
      if (!isStartup) {
        status.add(StatusEntryType.warning, 'Outlook polling failed: $error');
      }
    } finally {
      state = state + 1;
    }
  }
}

final office365PollingProvider =
    NotifierProvider<Office365PollingController, int>(
      Office365PollingController.new,
    );

final office365InboxSyncStateProvider = FutureProvider<SyncStateData?>((
  ref,
) async {
  ref.watch(office365PollingProvider);
  final db = ref.watch(appDatabaseProvider);
  return db.syncStateDao.getState(source: _kOffice365Source, scope: 'inbox');
});
