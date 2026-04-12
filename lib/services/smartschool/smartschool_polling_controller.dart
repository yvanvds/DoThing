import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/status_controller.dart';
import '../../models/smartschool_message.dart';
import '../../providers/database_provider.dart';
import 'smartschool_messages_controller.dart';

/// Manages polling for new messages every 5 minutes.
///
/// Tracks already-seen message IDs and periodically fetches new ones.
/// Uses client-side filtering to ensure only truly new messages are shown.
/// New messages are accumulated in the state.
class SmartschoolPollingController
    extends Notifier<List<SmartschoolMessageHeader>> {
  Timer? _pollTimer;
  final Set<int> _seenIds = {};
  bool _isPolling = false;

  @override
  List<SmartschoolMessageHeader> build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
    });
    return [];
  }

  /// Initialize polling with a set of already-seen message IDs.
  ///
  /// This prepares the polling mechanism and returns immediately.
  /// The actual polling timer starts on the first call.
  void initializeWithSeenIds(List<int> seenIds) {
    _seenIds.clear();
    _seenIds.addAll(seenIds);
    _startPollingIfNeeded();
  }

  /// Start polling if not already running.
  void _startPollingIfNeeded() {
    if (_isPolling || _pollTimer != null) {
      return;
    }

    _isPolling = true;

    // Wait one full interval before first poll, since inbox was just fetched on startup.
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _pollOnce();
    });
  }

  /// Perform a single poll for new messages.
  Future<void> _pollOnce() async {
    var foundNewMessages = false;

    try {
      final messagesService = ref.read(smartschoolMessagesProvider.notifier);

      // Fetch all messages (don't rely on server-side filtering).
      final allMessages = await messagesService.getHeaders(
        boxType: SmartschoolBoxType.inbox,
        alreadySeenIds: const [],
      );

      // Persist all fetched headers to the local database (idempotent upsert).
      // This runs before the in-memory new-message check so the DB stays in
      // sync regardless of how the UI layer tracks state.
      try {
        final persisted = await ref
            .read(smartschoolSyncRepositoryProvider)
            .syncHeaders(allMessages);
        ref
            .read(statusProvider.notifier)
            .add(
              StatusEntryType.info,
              'Smartschool poll sync: ${allMessages.length} headers scanned · $persisted new/updated persisted.',
            );
      } catch (error) {
        ref
            .read(statusProvider.notifier)
            .add(StatusEntryType.warning, 'Polling local sync failed: $error');
      }

      // Filter client-side: only messages not in our local cache are truly new.
      final newMessages = allMessages
          .where((msg) => !_seenIds.contains(msg.id))
          .toList();

      if (newMessages.isNotEmpty) {
        foundNewMessages = true;

        // Add new IDs to seen list
        for (final msg in newMessages) {
          _seenIds.add(msg.id);
        }

        // Accumulate new messages in state
        state = [...state, ...newMessages];

        // Notify user of new messages
        final msg = newMessages.length == 1 ? 'message' : 'messages';
        ref
            .read(statusProvider.notifier)
            .add(
              StatusEntryType.info,
              '📬 ${newMessages.length} new $msg arrived.',
            );
      }
    } catch (e) {
      // Silently fail on poll error; will try again next interval
      // (Avoid spamming the user with notifications for polling errors)
    }

    // Emit a state change on every poll tick so listeners can refresh UI.
    if (!foundNewMessages) {
      state = [...state];
    }
  }

  /// Clear accumulated new messages.
  void clearNew() {
    state = [];
  }

  /// Stop polling.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }
}

/// Provides the polling service for new messages.
///
/// New messages polled every 5 minutes are accumulated here.
/// Use [clearNew] to reset the list after processing them.
final smartschoolPollingProvider =
    NotifierProvider<
      SmartschoolPollingController,
      List<SmartschoolMessageHeader>
    >(SmartschoolPollingController.new);
