import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/status_controller.dart';
import '../models/smartschool_message.dart';
export '../models/smartschool_message.dart' show SmartschoolMessageHeader;
import '../providers/database_provider.dart';
import 'smartschool_auth_service.dart';
import 'smartschool_bridge.dart';

/// Convenience Riverpod wrapper that exposes Smartschool message operations.
///
/// All methods require an active connection via [smartschoolAuthProvider].
///
/// ```dart
/// final svc = ref.read(smartschoolMessagesProvider.notifier);
/// final headers = await svc.getHeaders();
/// final thread  = await svc.getMessage(headers.first.id);
/// ```
class SmartschoolMessagesController extends Notifier<void> {
  @override
  void build() {}

  SmartschoolBridge get _bridge =>
      ref.read(smartschoolAuthProvider.notifier).bridge;

  /// Fetch message headers for the given [boxType].
  ///
  /// Pass [alreadySeenIds] to only receive new (unseen) messages.
  Future<List<SmartschoolMessageHeader>> getHeaders({
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    List<int> alreadySeenIds = const [],
  }) async {
    final headers = await _bridge.getMessageHeaders(
      boxType: boxType,
      alreadySeenIds: alreadySeenIds,
    );
    if (headers.isNotEmpty) {
      final msg = headers.length == 1 ? 'message' : 'messages';
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.success, 'Retrieved ${headers.length} $msg.');
    }
    return headers;
  }

  /// Fetch message headers grouped into conversation threads.
  ///
  /// Each thread groups messages with the same normalised subject.
  Future<List<SmartschoolMessageThread>> getThreadedHeaders({
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    List<int> alreadySeenIds = const [],
  }) async {
    final threads = await _bridge.getThreadedHeaders(
      boxType: boxType,
      alreadySeenIds: alreadySeenIds,
    );
    if (threads.isNotEmpty) {
      final count = threads.fold<int>(0, (s, t) => s + t.messageCount);
      final msg = count == 1 ? 'message' : 'messages';
      final tMsg = threads.length == 1 ? 'thread' : 'threads';
      ref
          .read(statusProvider.notifier)
          .add(
            StatusEntryType.success,
            'Retrieved $count $msg in ${threads.length} $tMsg.',
          );
    }
    return threads;
  }

  /// Fetch the full message thread for [messageId].
  Future<List<SmartschoolMessageDetail>> getMessage(int messageId) async {
    final message = await _bridge.getMessage(messageId);
    if (message.isNotEmpty) {
      ref
          .read(statusProvider.notifier)
          .add(
            StatusEntryType.success,
            'Loaded message: ${message.first.subject}',
          );
    }
    return message;
  }

  /// List attachment metadata for [messageId] (without file bytes).
  Future<List<SmartschoolAttachment>> listAttachments(int messageId) =>
      _bridge.listAttachments(messageId);

  /// Download a single attachment by [attachmentIndex] for [messageId].
  Future<SmartschoolAttachment> downloadAttachment(
    int messageId,
    int attachmentIndex,
  ) => _bridge.downloadAttachment(messageId, attachmentIndex);

  /// Mark a message as unread.
  Future<void> markUnread(int messageId) async {
    await _bridge.markUnread(messageId);
    ref
        .read(statusProvider.notifier)
        .add(StatusEntryType.info, 'Message marked as unread.');
  }

  /// Mark a message as read.
  ///
  /// Smartschool exposes this implicitly through "show message".
  /// Triggering message fetch ensures backend read state is updated.
  Future<void> markRead(int messageId) async {
    await _bridge.getMessage(messageId);
  }

  /// Set a label / flag colour on a message.
  Future<void> setLabel(int messageId, SmartschoolMessageLabel label) async {
    await _bridge.setLabel(messageId, label);
    ref
        .read(statusProvider.notifier)
        .add(StatusEntryType.info, 'Message labeled: ${label.name}.');
  }

  /// Archive a message (or list of message IDs).
  Future<void> archive(dynamic messageId) async {
    await _bridge.archive(messageId);
    final count = messageId is List ? messageId.length : 1;
    final msg = count == 1 ? 'message' : 'messages';
    ref
        .read(statusProvider.notifier)
        .add(StatusEntryType.success, 'Archived $count $msg.');
  }

  /// Move a message to the trash.
  Future<void> trash(int messageId) async {
    await _bridge.trash(messageId);
    ref
        .read(statusProvider.notifier)
        .add(StatusEntryType.success, 'Message moved to trash.');
  }
}

/// Provides Smartschool message operations.
final smartschoolMessagesProvider =
    NotifierProvider<SmartschoolMessagesController, void>(
      SmartschoolMessagesController.new,
    );

/// In-memory cache of fetched full messages by ID.
///
/// Stores results to avoid re-fetching the same message on multiple clicks.
/// Cache is cleared when the app restarts (in-memory, not persistent).
class SmartschoolMessageCacheController
    extends Notifier<Map<int, SmartschoolMessageDetail>> {
  @override
  Map<int, SmartschoolMessageDetail> build() => {};

  /// Get a cached message, fetching if not present.
  ///
  /// If [messageId] is already in cache, returns immediately.
  /// Otherwise fetches from Smartschool, caches the result, and persists it
  /// to the local database.
  Future<SmartschoolMessageDetail> getOrFetch(
    int messageId,
    SmartschoolBridge bridge, {
    SmartschoolSyncRepository? syncRepository,
  }) async {
    if (state.containsKey(messageId)) {
      return state[messageId]!;
    }

    AppDatabase? db;
    try {
      db = ref.read(appDatabaseProvider);
    } catch (_) {
      db = null;
    }

    if (db != null) {
      final local = await db.messagesDao.findMessage(
        source: 'smartschool',
        externalId: messageId.toString(),
      );
      if (_hasPersistedFullDetail(local)) {
        final localDetail = _detailFromLocalRow(local!, messageId);
        state = {...state, messageId: localDetail};
        return localDetail;
      }
    }

    final messages = await bridge.getMessage(messageId);
    if (messages.isEmpty) {
      throw StateError('No message detail returned for ID $messageId');
    }

    final detail = messages.first;
    state = {...state, messageId: detail};

    var repository = syncRepository;
    if (repository == null) {
      try {
        repository = ref.read(smartschoolSyncRepositoryProvider);
      } catch (_) {
        repository = null;
      }
    }

    // Persist detail to local database (non-fatal if it fails).
    if (repository != null) {
      try {
        await repository.syncDetail(detail);
      } catch (_) {}
    }

    return detail;
  }

  bool _hasPersistedFullDetail(Message? row) {
    if (row == null) return false;
    if (row.detailFetchedAt == null) return false;

    final raw = row.bodyRaw?.trim() ?? '';
    final text = row.bodyText?.trim() ?? '';
    return raw.isNotEmpty || text.isNotEmpty;
  }

  SmartschoolMessageDetail _detailFromLocalRow(Message row, int messageId) {
    Map<String, dynamic>? rawDetail;
    final rawJson = row.rawDetailJson;
    if (rawJson != null && rawJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          rawDetail = decoded;
        }
      } catch (_) {}
    }

    return SmartschoolMessageDetail(
      id: messageId,
      from: (rawDetail?['from'] as String?) ?? '',
      subject: (rawDetail?['subject'] as String?) ?? row.subject,
      body: row.bodyRaw ?? row.bodyText ?? '',
      date: (rawDetail?['date'] as String?) ?? row.receivedAt.toIso8601String(),
      to: rawDetail?['to'] as String?,
      status: (rawDetail?['status'] as int?) ?? (row.isRead ? 1 : 0),
      attachment:
          (rawDetail?['attachment'] as int?) ?? (row.hasAttachments ? 1 : 0),
      unread: (rawDetail?['unread'] as bool?) ?? !row.isRead,
      label: rawDetail?['label'] as bool?,
      receivers: rawDetail?['receivers'],
      ccReceivers: rawDetail?['ccreceivers'],
      bccReceivers: rawDetail?['bccreceivers'],
      senderPicture: rawDetail?['sender_picture'] as String?,
      fromTeam: rawDetail?['from_team'] as int?,
      totalNrOtherToReceivers:
          rawDetail?['total_nr_other_to_reciviers'] as int?,
      totalNrOtherCcReceivers:
          rawDetail?['total_nr_other_cc_receivers'] as int?,
      totalNrOtherBccReceivers:
          rawDetail?['total_nr_other_bcc_receivers'] as int?,
      canReply: rawDetail?['can_reply'] as bool?,
      hasReply: rawDetail?['has_reply'] as bool?,
      hasForward: rawDetail?['has_forward'] as bool?,
      sendDate: rawDetail?['send_date'] as String?,
    );
  }

  /// Clear the cache.
  void clear() => state = {};
}

/// Provides the message cache.
final smartschoolMessageCacheProvider =
    NotifierProvider<
      SmartschoolMessageCacheController,
      Map<int, SmartschoolMessageDetail>
    >(SmartschoolMessageCacheController.new);

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
        if (persisted > 0) {
          ref
              .read(statusProvider.notifier)
              .add(
                StatusEntryType.info,
                'Poll: ${allMessages.length} headers fetched · $persisted new/updated persisted.',
              );
        }
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

/// Tracks which message header is currently selected in the panel.
///
/// Null means no message is selected.
class _SelectedMessageController extends Notifier<SmartschoolMessageHeader?> {
  @override
  SmartschoolMessageHeader? build() => null;

  void select(SmartschoolMessageHeader? header) {
    state = header;
  }
}

final smartschoolSelectedMessageProvider =
    NotifierProvider<_SelectedMessageController, SmartschoolMessageHeader?>(
      _SelectedMessageController.new,
    );
