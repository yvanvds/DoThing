import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/smartschool_message.dart';
import '../providers/database_provider.dart';
import 'smartschool_settings_controller.dart';
import 'status_controller.dart';
import '../services/smartschool_auth_service.dart';
import '../services/smartschool_messages_service.dart';

enum SmartschoolRelatedItemType { message }

class SmartschoolRelatedItem {
  const SmartschoolRelatedItem({
    required this.type,
    required this.activityAt,
    required this.messageHeader,
  });

  final SmartschoolRelatedItemType type;
  final DateTime activityAt;
  final SmartschoolMessageHeader messageHeader;
}

class SmartschoolContactInbox {
  const SmartschoolContactInbox({
    required this.contactId,
    required this.displayName,
    required this.avatarUrl,
    required this.latestActivityAt,
    required this.unreadCount,
    required this.items,
  });

  final int contactId;
  final String displayName;
  final String? avatarUrl;
  final DateTime latestActivityAt;
  final int unreadCount;
  final List<SmartschoolRelatedItem> items;

  int get itemCount => items.length;
}

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
  List<SmartschoolMessageThread>? _cachedThreads; // add this
  bool _sentBootstrapDone = false;

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
    // Return cached threads if already loaded and not explicitly refreshing
    if (_cachedThreads != null && !showLoading) {
      return _cachedThreads!;
    }

    if (showLoading) {
      state = const AsyncLoading();
    }

    try {
      final threads = await _fetchInboxThreads();
      _cachedThreads = threads; // cache the result
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

  /// Refresh inbox and return latest headers grouped by contact.
  ///
  /// Contacts are ordered by latest related item (desc).
  /// Items in each contact are ordered newest first.
  Future<List<SmartschoolContactInbox>> refreshInboxAndGetContactInboxes({
    bool showLoading = true,
  }) async {
    if (showLoading) {
      state = const AsyncLoading();
    }

    try {
      await _fetchInboxHeaders();

      final db = ref.read(appDatabaseProvider);
      final settings = await ref.read(smartschoolSettingsProvider.future);
      final currentUserName = settings.username.trim().toLowerCase();
      final selfContactIds = await db.messagesDao.getSentSenderContactIds();
      final summaries = await db.messagesDao.getInboxContactSummaries();

      final contacts = <SmartschoolContactInbox>[];
      for (final summary in summaries) {
        final isCurrentUserContact =
            selfContactIds.contains(summary.contactId) ||
            (currentUserName.isNotEmpty &&
                summary.displayName.trim().toLowerCase() == currentUserName);

        final headers = await db.messagesDao.getInboxHeadersForContact(
          summary.contactId,
          onlySelfSentToSelf: isCurrentUserContact,
        );
        final items = headers
            .map(
              (header) => SmartschoolRelatedItem(
                type: SmartschoolRelatedItemType.message,
                activityAt:
                    DateTime.tryParse(header.date) ?? summary.latestActivityAt,
                messageHeader: header,
              ),
            )
            .toList();

        if (items.isEmpty) continue;

        contacts.add(
          SmartschoolContactInbox(
            contactId: summary.contactId,
            displayName: summary.displayName,
            avatarUrl: summary.avatarUrl,
            latestActivityAt: items.first.activityAt,
            unreadCount: headers.where((h) => h.unread).length,
            items: items,
          ),
        );
      }

      contacts.sort((a, b) => b.latestActivityAt.compareTo(a.latestActivityAt));

      final unread = contacts.fold<int>(0, (sum, c) => sum + c.unreadCount);
      state = AsyncData(unread);
      return contacts;
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

    await _bootstrapSentHeadersAndDetailsOnce();

    // Persist headers to the local database.
    try {
      final persisted = await ref
          .read(smartschoolSyncRepositoryProvider)
          .syncHeaders(headers);
      status.add(
        StatusEntryType.info,
        'Inbox: ${headers.length} headers fetched · $persisted new/updated persisted.',
      );
    } catch (error) {
      status.add(StatusEntryType.warning, 'Local inbox sync failed: $error');
    }

    // Initialize polling with the seen message IDs
    final messageIds = headers.map((h) => h.id).toList();
    ref
        .read(smartschoolPollingProvider.notifier)
        .initializeWithSeenIds(messageIds);

    return headers;
  }

  Future<void> _bootstrapSentHeadersAndDetailsOnce() async {
    if (_sentBootstrapDone) return;

    final status = ref.read(statusProvider.notifier);
    final messagesService = ref.read(smartschoolMessagesProvider.notifier);
    final syncRepository = ref.read(smartschoolSyncRepositoryProvider);

    try {
      final sentHeaders = await messagesService.getHeaders(
        boxType: SmartschoolBoxType.sent,
      );

      await syncRepository.syncHeaders(sentHeaders, mailbox: 'sent');

      int detailSynced = 0;
      for (final header in sentHeaders) {
        try {
          final details = await messagesService.getMessage(header.id);
          if (details.isEmpty) continue;
          await syncRepository.syncDetail(details.first);
          detailSynced++;
        } catch (_) {
          // Best-effort detail enrichment per sent item.
        }
      }

      _sentBootstrapDone = true;
      status.add(
        StatusEntryType.info,
        'Sent bootstrap: ${sentHeaders.length} headers synced · $detailSynced details enriched.',
      );
    } catch (error) {
      status.add(StatusEntryType.warning, 'Sent bootstrap failed: $error');
    }
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

    // Persist all headers from every thread to the local database.
    final allHeaders = threads.expand((t) => t.messages).toList();
    try {
      final persisted = await ref
          .read(smartschoolSyncRepositoryProvider)
          .syncHeaders(allHeaders);
      status.add(
        StatusEntryType.info,
        'Inbox: ${allHeaders.length} headers fetched · $persisted new/updated persisted.',
      );
    } catch (error) {
      status.add(
        StatusEntryType.warning,
        'Local threaded inbox sync failed: $error',
      );
    }

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
