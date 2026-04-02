import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/smartschool_message.dart';
import 'status_controller.dart';
import '../services/smartschool_auth_service.dart';
import '../services/smartschool_messages_service.dart';

/// Startup inbox loader.
///
/// When first watched (sidebar badge), it:
/// 1. Connects to Smartschool.
/// 2. Fetches inbox message headers.
/// 3. Returns the unread count.
///
/// Important: Smartschool's `header.unread == true` means the message is
/// already read, so unread state must be inverted.
class SmartschoolInboxController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final status = ref.read(statusProvider.notifier);

    await ref.read(smartschoolAuthProvider.notifier).connect();
    final connection = ref.read(smartschoolAuthProvider);
    final connected = connection.maybeWhen(
      data: (value) => value == SmartschoolConnectionState.connected,
      orElse: () => false,
    );

    if (!connected) {
      status.add(
        StatusEntryType.warning,
        'Inbox fetch skipped because Smartschool is not connected.',
      );
      return 0;
    }

    try {
      final headers = await ref
          .read(smartschoolMessagesProvider.notifier)
          .getHeaders(boxType: SmartschoolBoxType.inbox);

      // Initialize polling with the seen message IDs
      final messageIds = headers.map((h) => h.id).toList();
      ref
          .read(smartschoolPollingProvider.notifier)
          .initializeWithSeenIds(messageIds);

      return _unreadCountFromHeaders(headers);
    } catch (error) {
      status.add(StatusEntryType.error, _friendlyInboxError(error));
      return 0;
    }
  }

  /// Manual refresh for future usage.
  Future<void> refreshInbox() async {
    final status = ref.read(statusProvider.notifier);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final headers = await ref
            .read(smartschoolMessagesProvider.notifier)
            .getHeaders(boxType: SmartschoolBoxType.inbox);

        // Reinitialize polling with updated message IDs
        final messageIds = headers.map((h) => h.id).toList();
        ref
            .read(smartschoolPollingProvider.notifier)
            .initializeWithSeenIds(messageIds);

        return _unreadCountFromHeaders(headers);
      } catch (error) {
        status.add(StatusEntryType.error, _friendlyInboxError(error));
        return 0;
      }
    });
  }

  int _unreadCountFromHeaders(List<SmartschoolMessageHeader> headers) {
    // header.unread is already corrected (inverted) in SmartschoolMessageHeader.fromJson.
    return headers.where((header) => header.unread).length;
  }

  String _friendlyInboxError(Object error) {
    final text = error.toString();

    if (text.contains('ParseError') && text.contains('no element found')) {
      return 'Inbox fetch failed: Smartschool returned invalid/empty XML (likely auth/session issue).';
    }

    if (text.contains('ConnectionError') ||
        text.contains('getaddrinfo failed')) {
      return 'Inbox fetch failed: network/DNS error while reaching Smartschool.';
    }

    return 'Inbox fetch failed: $error';
  }
}

final smartschoolInboxProvider =
    AsyncNotifierProvider<SmartschoolInboxController, int>(
      SmartschoolInboxController.new,
    );
