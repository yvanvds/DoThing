import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/status_controller.dart';
import '../../providers/database_provider.dart';
import '../system_notification_service.dart';
import 'smartschool_messages_controller.dart';

/// Manages event-driven detection for new Smartschool messages.
///
/// Tracks already-seen message IDs, seeds the incremental baseline on startup,
/// and then reacts to new message counter events from flutter_smartschool.
/// New messages are accumulated in the state.
class SmartschoolPollingController
    extends Notifier<List<SmartschoolMessageHeader>> {
  final Set<int> _seenIds = {};
  bool _isPolling = false;
  SmartschoolMessagesController? _messagesController;

  @override
  List<SmartschoolMessageHeader> build() {
    ref.onDispose(() {
      unawaited(_stopEventDetection());
    });
    return [];
  }

  /// Initialize polling with a set of already-seen message IDs.
  ///
  /// This prepares the event-driven mechanism and returns immediately.
  /// The event stream listener starts on the first call.
  void initializeWithSeenIds(List<int> seenIds) {
    _seenIds.clear();
    _seenIds.addAll(seenIds);
    _startEventDetectionIfNeeded();
  }

  /// Start event-driven detection if not already running.
  void _startEventDetectionIfNeeded() {
    if (_isPolling) {
      return;
    }

    _isPolling = true;

    Future<void>.microtask(() async {
      try {
        if (!ref.mounted) {
          _isPolling = false;
          return;
        }

        final messagesService = ref.read(smartschoolMessagesProvider.notifier);
        _messagesController = messagesService;
        await messagesService.startEventDrivenInboxDetection(
          seenIds: _seenIds,
          onNewHeaders: _onEventHeaders,
          onError: (error) {
            if (!ref.mounted) return;
            ref
                .read(statusProvider.notifier)
                .add(
                  StatusEntryType.warning,
                  'Smartschool event stream error: $error',
                );
          },
        );
      } catch (error) {
        _isPolling = false;
        _messagesController = null;
        if (!ref.mounted) {
          return;
        }
        ref
            .read(statusProvider.notifier)
            .add(
              StatusEntryType.warning,
              'Smartschool event detection start failed: $error',
            );
      }
    });
  }

  /// Process headers detected by the event-driven inbox refresh.
  Future<void> _onEventHeaders(
    List<SmartschoolMessageHeader> allMessages,
  ) async {
    var foundNewMessages = false;

    try {
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
              'Smartschool event sync: ${allMessages.length} headers scanned · $persisted new/updated persisted.',
            );
      } catch (error) {
        ref
            .read(statusProvider.notifier)
            .add(StatusEntryType.warning, 'Event local sync failed: $error');
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

        final notifier = ref.read(systemNotificationServiceProvider);
        for (final message in newMessages) {
          unawaited(
            notifier.showSmartschoolMessageReceived(
              subject: message.subject,
              sender: message.from,
            ),
          );
        }
      }
    } catch (e) {
      // Silently fail on event processing errors.
    }

    // Emit a state change on every event tick so listeners can refresh UI.
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
    unawaited(_stopEventDetection());
  }

  Future<void> _stopEventDetection() async {
    if (!_isPolling) return;

    try {
      final messagesService = _messagesController;
      if (messagesService != null) {
        await messagesService.stopEventDrivenInboxDetection();
      } else if (ref.mounted) {
        await ref
            .read(smartschoolMessagesProvider.notifier)
            .stopEventDrivenInboxDetection();
      }
    } catch (_) {
      // Best effort during shutdown.
    }

    _messagesController = null;
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
