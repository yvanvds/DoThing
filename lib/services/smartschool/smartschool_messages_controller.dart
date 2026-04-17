import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../controllers/status_controller.dart';
import '../../models/smartschool_message.dart';
export '../../models/smartschool_message.dart' show SmartschoolMessageHeader;
import 'smartschool_auth_controller.dart';
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
  Future<List<SmartschoolMessageDetail>> getMessage(
    int messageId, {
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    bool reportStatus = true,
  }) async {
    final message = await _bridge.getMessage(messageId, boxType: boxType);
    if (reportStatus && message.isNotEmpty) {
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
  Future<void> markRead(int messageId) async {
    await _bridge.markRead(messageId);
  }

  Future<void> startEventDrivenInboxDetection({
    required Iterable<int> seenIds,
    required FutureOr<void> Function(List<SmartschoolMessageHeader>)
    onNewHeaders,
    void Function(Object error)? onError,
  }) async {
    await _bridge.startInboxEventDrivenDetection(
      seenIds: seenIds,
      onNewHeaders: onNewHeaders,
      onError: onError,
    );
  }

  Future<void> stopEventDrivenInboxDetection() async {
    await _bridge.stopInboxEventDrivenDetection();
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
