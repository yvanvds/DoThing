import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/smartschool_message.dart';
import '../providers/database_provider.dart';
import 'status_controller.dart';
import '../services/smartschool/smartschool_auth_controller.dart';
import '../services/smartschool/smartschool_messages_controller.dart';
import '../services/smartschool/smartschool_polling_controller.dart';

enum SmartschoolRelatedItemType { message }

class SmartschoolRelatedItem {
  const SmartschoolRelatedItem({
    required this.type,
    required this.activityAt,
    required this.messageHeader,
  });

  final SmartschoolRelatedItemType type;
  final DateTime activityAt;
  final MessageHeader messageHeader;
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
  bool _sentHeadersBootstrapDone = false;

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

  Future<int> refreshUnreadFromLocal({bool showLoading = true}) async {
    if (showLoading) {
      state = const AsyncLoading();
    }

    try {
      final db = ref.read(appDatabaseProvider);
      final summaries = await db.messagesDao.getInboxContactSummaries();
      final unread = summaries.fold<int>(
        0,
        (sum, item) => sum + item.unreadCount,
      );
      state = AsyncData(unread);
      return unread;
    } catch (_) {
      if (showLoading) {
        state = const AsyncData(0);
      }
      return 0;
    }
  }

  /// Refresh inbox and return latest headers.
  ///
  /// When [showLoading] is false, keeps the current state visible while
  /// refreshing in the background.
  Future<List<MessageHeader>> refreshInboxAndGetHeaders({
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
      final contacts = await loadContactInboxesFromLocal();

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

  Future<List<SmartschoolContactInbox>> loadContactInboxesFromLocal() async {
    final db = ref.read(appDatabaseProvider);
    final summaries = await db.messagesDao.getInboxContactSummaries();

    final contacts = <SmartschoolContactInbox>[];
    for (final summary in summaries) {
      final headers = await db.messagesDao.getInboxHeadersForContact(
        summary.contactId,
        onlySelfSentToSelf: false,
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
    return contacts;
  }

  Future<List<MessageHeader>> _fetchInboxHeaders() async {
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

    await _bootstrapSentHeadersOnce();

    // Persist headers and remove stale local rows.
    final syncRepo = ref.read(smartschoolSyncRepositoryProvider);
    List<MessageHeader> newlyInserted = const [];
    try {
      newlyInserted = await syncRepo.syncHeaders(headers);
      final activeIds = headers.map((h) => h.id.toString()).toSet();
      final removed = await syncRepo.deleteStaleHeaders(
        mailbox: 'inbox',
        activeIds: activeIds,
      );
      final removedSuffix = removed > 0 ? ' · $removed removed' : '';
      status.add(
        StatusEntryType.info,
        'Smartschool inbox sync: ${headers.length} headers scanned · ${newlyInserted.length} new/updated$removedSuffix.',
      );
    } catch (error) {
      status.add(StatusEntryType.warning, 'Local inbox sync failed: $error');
    }

    // Eagerly fetch full detail for newly inserted messages to resolve identities.
    await _syncDetailForHeaders(
      newlyInserted,
      status,
      syncRepo,
      boxType: SmartschoolBoxType.inbox,
    );

    // Backfill avatars for any contacts without one (fire-and-forget).
    ref.read(avatarSyncServiceProvider).scheduleSync();

    // Initialize polling with the seen message IDs
    final messageIds = headers.map((h) => h.id).toList();
    ref
        .read(smartschoolPollingProvider.notifier)
        .initializeWithSeenIds(messageIds);

    return headers;
  }

  Future<void> _bootstrapSentHeadersOnce() async {
    if (_sentHeadersBootstrapDone) return;

    final status = ref.read(statusProvider.notifier);
    final messagesService = ref.read(smartschoolMessagesProvider.notifier);
    final syncRepository = ref.read(smartschoolSyncRepositoryProvider);

    try {
      final sentHeaders = await messagesService.getHeaders(
        boxType: SmartschoolBoxType.sent,
      );

      final newlySent = await syncRepository.syncHeaders(
        sentHeaders,
        mailbox: 'sent',
      );
      final activeSentIds = sentHeaders.map((h) => h.id.toString()).toSet();
      final removed = await syncRepository.deleteStaleHeaders(
        mailbox: 'sent',
        activeIds: activeSentIds,
      );
      final removedSuffix = removed > 0 ? ' · $removed removed' : '';

      _sentHeadersBootstrapDone = true;
      status.add(
        StatusEntryType.info,
        'Smartschool sent sync: ${sentHeaders.length} headers scanned · ${newlySent.length} new/updated$removedSuffix.',
      );

      await _syncDetailForHeaders(
        newlySent,
        status,
        syncRepository,
        boxType: SmartschoolBoxType.sent,
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

    // Persist all headers from every thread and remove stale local rows.
    final allHeaders = threads.expand((t) => t.messages).toList();
    final syncRepo = ref.read(smartschoolSyncRepositoryProvider);
    List<MessageHeader> newlyInsertedThreads = const [];
    try {
      newlyInsertedThreads = await syncRepo.syncHeaders(allHeaders);
      final activeIds = allHeaders.map((h) => h.id.toString()).toSet();
      final removed = await syncRepo.deleteStaleHeaders(
        mailbox: 'inbox',
        activeIds: activeIds,
      );
      final removedSuffix = removed > 0 ? ' · $removed removed' : '';
      status.add(
        StatusEntryType.info,
        'Smartschool inbox thread sync: ${allHeaders.length} headers scanned · ${newlyInsertedThreads.length} new/updated$removedSuffix.',
      );
    } catch (error) {
      status.add(
        StatusEntryType.warning,
        'Local threaded inbox sync failed: $error',
      );
    }

    await _syncDetailForHeaders(
      newlyInsertedThreads,
      status,
      syncRepo,
      boxType: SmartschoolBoxType.inbox,
    );

    // Initialize polling with all seen message IDs across threads
    final messageIds = threads
        .expand((t) => t.messages.map((m) => m.id))
        .toList();
    ref
        .read(smartschoolPollingProvider.notifier)
        .initializeWithSeenIds(messageIds);

    return threads;
  }

  Future<void> _syncDetailForHeaders(
    List<MessageHeader> headers,
    StatusController status,
    SmartschoolSyncRepository syncRepo, {
    required SmartschoolBoxType boxType,
  }) async {
    if (headers.isEmpty) return;
    final mc = ref.read(smartschoolMessagesProvider.notifier);
    final label = boxType == SmartschoolBoxType.sent ? 'sent' : 'inbox';
    status.add(
      StatusEntryType.info,
      'Fetching detail for ${headers.length} new $label messages…',
    );

    int noDetail = 0;
    int failed = 0;

    for (final header in headers) {
      try {
        final details = await mc.getMessage(
          header.id,
          boxType: boxType,
          reportStatus: false,
        );
        if (details.isEmpty) {
          if (boxType == SmartschoolBoxType.sent) {
            await syncRepo.discardMessage(header.id);
            status.add(
              StatusEntryType.info,
              '[$label] "${header.subject}": self-sent, discarded.',
            );
          } else {
            noDetail++;
            status.add(
              StatusEntryType.warning,
              '[$label] "${header.subject}": no detail returned.',
            );
          }
        } else {
          final result = await syncRepo.syncDetail(details.first);
          final senderMark = result.senderResolved ? '✓' : '✗';
          final toSummary = result.toNames.isEmpty
              ? 'no recipients'
              : '${result.toNames.take(3).map((n) => n.isEmpty ? '?' : n).join(', ')}'
                    '${result.toNames.length > 3 ? ' +${result.toNames.length - 3}' : ''}'
                    ' (${result.toResolved}/${result.toNames.length} resolved)';
          status.add(
            result.toResolved < result.toNames.length
                ? StatusEntryType.warning
                : StatusEntryType.info,
            '[$label] "${header.subject}": sender=${result.senderName} $senderMark · to: $toSummary.',
          );
        }
      } catch (e) {
        failed++;
        status.add(
          StatusEntryType.warning,
          '[$label] "${header.subject}": failed — $e.',
        );
      }
    }

    final summaryParts = <String>[
      if (noDetail > 0) '$noDetail no detail',
      if (failed > 0) '$failed failed',
    ];
    status.add(
      summaryParts.isEmpty ? StatusEntryType.info : StatusEntryType.warning,
      'Detail sync $label complete'
      '${summaryParts.isEmpty ? '' : ': ${summaryParts.join(' · ')}'}.',
    );
  }

  int _unreadCountFromHeaders(List<MessageHeader> headers) {
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
