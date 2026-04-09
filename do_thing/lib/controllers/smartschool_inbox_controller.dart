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
    try {
      final headers = await _fetchInboxHeaders();
      return _unreadCountFromHeaders(headers);
    } catch (error) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, _friendlyInboxError(error));
      return 0;
    }
  }

  /// Manual refresh for future usage.
  Future<void> refreshInbox() async {
    await refreshInboxAndGetHeaders();
  }

  /// Refresh inbox and return latest headers.
  ///
  /// When [showLoading] is false, keeps the current state visible while
  /// refreshing in the background.
  Future<List<SmartschoolMessageHeader>> refreshInboxAndGetHeaders({
    bool showLoading = true,
  }) async {
    if (showLoading) {
      state = const AsyncLoading();
    }

    try {
      final headers = await _fetchInboxHeaders();
      state = AsyncData(_unreadCountFromHeaders(headers));
      return headers;
    } catch (error) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, _friendlyInboxError(error));

      if (showLoading) {
        state = const AsyncData(0);
      }

      return const [];
    }
  }

  /// Refresh inbox and return latest headers grouped into threads.
  Future<List<SmartschoolMessageThread>> refreshInboxAndGetThreads({
    bool showLoading = true,
  }) async {
    if (showLoading) {
      state = const AsyncLoading();
    }

    try {
      final threads = await _fetchInboxThreads();
      final unread = threads.fold<int>(
        0,
        (sum, t) => sum + t.messages.where((h) => h.unread).length,
      );
      state = AsyncData(unread);
      return threads;
    } catch (error) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, _friendlyInboxError(error));

      if (showLoading) {
        state = const AsyncData(0);
      }

      return const [];
    }
  }

  Future<List<SmartschoolMessageHeader>> _fetchInboxHeaders() async {
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
      return const [];
    }

    final headers = await ref
        .read(smartschoolMessagesProvider.notifier)
        .getHeaders(boxType: SmartschoolBoxType.inbox);

    // Initialize polling with the seen message IDs
    final messageIds = headers.map((h) => h.id).toList();
    ref
        .read(smartschoolPollingProvider.notifier)
        .initializeWithSeenIds(messageIds);

    return headers;
  }

  Future<List<SmartschoolMessageThread>> _fetchInboxThreads() async {
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
      return const [];
    }

    final threads = await ref
        .read(smartschoolMessagesProvider.notifier)
        .getThreadedHeaders(boxType: SmartschoolBoxType.inbox);

    // Initialize polling with all seen message IDs across threads
    final messageIds = threads
        .expand((t) => t.messages.map((m) => m.id))
        .toList();
    ref
        .read(smartschoolPollingProvider.notifier)
        .initializeWithSeenIds(messageIds);

    return threads;
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
