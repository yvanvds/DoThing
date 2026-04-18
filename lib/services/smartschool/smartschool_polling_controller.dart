import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/status_controller.dart';
import '../../providers/database_provider.dart';
import '../system_notification_service.dart';
import 'smartschool_messages_controller.dart';

/// Manages event-driven detection for new Smartschool messages.
///
/// When new headers are detected, this controller:
///  1. Persists all headers via [syncHeaders] (metadata only, no participants).
///  2. For each newly inserted message, eagerly fetches full detail via the
///     bridge and calls [syncDetail] so that stable identities and participant
///     links are resolved before the inbox view renders.
///  3. Accumulates truly new (unseen) headers in state for UI notification.
class SmartschoolPollingController extends Notifier<List<MessageHeader>> {
  final Set<int> _seenIds = {};
  bool _isPolling = false;
  SmartschoolMessagesController? _messagesController;

  @override
  List<MessageHeader> build() {
    ref.onDispose(() {
      unawaited(_stopEventDetection());
    });
    return [];
  }

  void initializeWithSeenIds(List<int> seenIds) {
    _seenIds.clear();
    _seenIds.addAll(seenIds);
    _startEventDetectionIfNeeded();
  }

  void _startEventDetectionIfNeeded() {
    if (_isPolling) return;
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
        if (!ref.mounted) return;
        ref
            .read(statusProvider.notifier)
            .add(
              StatusEntryType.warning,
              'Smartschool event detection start failed: $error',
            );
      }
    });
  }

  Future<void> _onEventHeaders(List<MessageHeader> allMessages) async {
    var foundNewMessages = false;

    try {
      // Persist metadata for all headers; collect which ones are brand-new.
      List<MessageHeader> newlyInserted = const [];
      try {
        newlyInserted = await ref
            .read(smartschoolSyncRepositoryProvider)
            .syncHeaders(allMessages);
        ref
            .read(statusProvider.notifier)
            .add(
              StatusEntryType.info,
              'Smartschool sync: ${allMessages.length} headers scanned'
              ' · ${newlyInserted.length} new.',
            );
      } catch (error) {
        ref
            .read(statusProvider.notifier)
            .add(StatusEntryType.warning, 'Event local sync failed: $error');
      }

      // Eagerly fetch and persist full detail for newly inserted messages so
      // that stable identities are resolved before the inbox view renders.
      if (newlyInserted.isNotEmpty) {
        final repo = ref.read(smartschoolSyncRepositoryProvider);
        final mc = _messagesController;
        int detailFailed = 0;
        for (final header in newlyInserted) {
          try {
            final SmartschoolMessagesController svc =
                mc ?? ref.read(smartschoolMessagesProvider.notifier);
            final details = await svc.getMessage(
              header.id,
              reportStatus: false,
            );
            if (details.isNotEmpty) {
              await repo.syncDetail(details.first);
            }
          } catch (_) {
            detailFailed++;
          }
        }
        if (detailFailed > 0) {
          ref
              .read(statusProvider.notifier)
              .add(
                StatusEntryType.warning,
                'Could not resolve participants for $detailFailed/${newlyInserted.length} new messages — they will be visible once opened.',
              );
        }
      }

      // Filter client-side: only messages not in the seen set are user-visible.
      final unseenMessages = allMessages
          .where((msg) => !_seenIds.contains(msg.id))
          .toList();

      if (unseenMessages.isNotEmpty) {
        foundNewMessages = true;
        for (final msg in unseenMessages) {
          _seenIds.add(msg.id);
        }
        state = [...state, ...unseenMessages];

        final msg = unseenMessages.length == 1 ? 'message' : 'messages';
        ref
            .read(statusProvider.notifier)
            .add(
              StatusEntryType.info,
              '📬 ${unseenMessages.length} new $msg arrived.',
            );

        final notifier = ref.read(systemNotificationServiceProvider);
        for (final message in unseenMessages) {
          unawaited(
            notifier.showSmartschoolMessageReceived(
              subject: message.subject,
              sender: message.from,
            ),
          );
        }
      }
    } catch (_) {
      // Silently ignore event processing errors.
    }

    if (!foundNewMessages) {
      state = [...state];
    }
  }

  void clearNew() => state = [];

  void stopPolling() => unawaited(_stopEventDetection());

  Future<void> _stopEventDetection() async {
    if (!_isPolling) return;
    try {
      final mc = _messagesController;
      if (mc != null) {
        await mc.stopEventDrivenInboxDetection();
      } else if (ref.mounted) {
        await ref
            .read(smartschoolMessagesProvider.notifier)
            .stopEventDrivenInboxDetection();
      }
    } catch (_) {}
    _messagesController = null;
    _isPolling = false;
  }
}

final smartschoolPollingProvider =
    NotifierProvider<SmartschoolPollingController, List<MessageHeader>>(
      SmartschoolPollingController.new,
    );
