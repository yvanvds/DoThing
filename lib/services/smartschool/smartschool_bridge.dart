import 'dart:convert';
import 'dart:async';

import 'package:flutter_smartschool/flutter_smartschool.dart';

import '../../models/smartschool_message.dart';
import 'smartschool_bridge_exception.dart';

abstract class SmartschoolSessionApi {
  Future<void> ensureAuthenticated();
  Future<void> clearCookies();
}

abstract class SmartschoolMessagesApi {
  Future<List<ShortMessage>> getHeaders({
    required BoxType boxType,
    required List<int> alreadySeenIds,
  });

  Future<(List<MessageSearchUser>, List<MessageSearchGroup>)>
  searchRecipientsForCompose(String query);

  Future<void> sendMessage({
    required List<MessageSearchUser> to,
    List<MessageSearchUser> cc,
    List<MessageSearchUser> bcc,
    required String subject,
    required String bodyHtml,
  });

  Future<FullMessage?> getMessage(
    int messageId, {
    required BoxType boxType,
    required bool includeAllRecipients,
  });
  Future<(List<MessageSearchUser>, List<MessageSearchUser>)>
  getReplyAllRecipients(int messageId, {required BoxType boxType});
  Future<(List<MessageSearchUser>, List<MessageSearchUser>)>
  getSentMessageRecipients(int messageId);
  Future<List<dynamic>> getAttachments(int messageId);
  Future<void> markRead(int messageId);
  Future<void> markUnread(int messageId);
  Future<void> setLabel(int messageId, MessageLabel label);
  Future<void> moveToArchive(List<int> messageIds);
  Future<void> moveToTrash(int messageId);
}

class _SmartschoolSessionClientAdapter implements SmartschoolSessionApi {
  _SmartschoolSessionClientAdapter(this._client);

  final SmartschoolClient _client;

  @override
  Future<void> ensureAuthenticated() => _client.ensureAuthenticated();

  @override
  Future<void> clearCookies() => _client.clearCookies();
}

class _SmartschoolMessagesServiceAdapter implements SmartschoolMessagesApi {
  _SmartschoolMessagesServiceAdapter(this._service);

  final MessagesService _service;

  @override
  Future<List<ShortMessage>> getHeaders({
    required BoxType boxType,
    required List<int> alreadySeenIds,
  }) => _service.getHeaders(boxType: boxType, alreadySeenIds: alreadySeenIds);

  @override
  Future<(List<MessageSearchUser>, List<MessageSearchGroup>)>
  searchRecipientsForCompose(String query) =>
      _service.searchRecipientsForCompose(query);

  @override
  Future<void> sendMessage({
    required List<MessageSearchUser> to,
    List<MessageSearchUser> cc = const [],
    List<MessageSearchUser> bcc = const [],
    required String subject,
    required String bodyHtml,
  }) => _service.sendMessage(
    SendMessageParams(
      to: to,
      cc: cc,
      bcc: bcc,
      subject: subject,
      bodyHtml: bodyHtml,
    ),
  );

  @override
  Future<FullMessage?> getMessage(
    int messageId, {
    required BoxType boxType,
    required bool includeAllRecipients,
  }) => _service.getMessage(
    messageId,
    boxType: boxType,
    includeAllRecipients: includeAllRecipients,
  );

  @override
  Future<(List<MessageSearchUser>, List<MessageSearchUser>)>
  getReplyAllRecipients(int messageId, {required BoxType boxType}) =>
      _service.getReplyAllRecipients(messageId, boxType: boxType);

  @override
  Future<(List<MessageSearchUser>, List<MessageSearchUser>)>
  getSentMessageRecipients(int messageId) =>
      _service.getSentMessageRecipients(messageId);

  @override
  Future<List<dynamic>> getAttachments(int messageId) =>
      _service.getAttachments(messageId);

  @override
  Future<void> markRead(int messageId) => _service.markRead(messageId);

  @override
  Future<void> markUnread(int messageId) => _service.markUnread(messageId);

  @override
  Future<void> setLabel(int messageId, MessageLabel label) =>
      _service.setLabel(messageId, label);

  @override
  Future<void> moveToArchive(List<int> messageIds) =>
      _service.moveToArchive(messageIds);

  @override
  Future<void> moveToTrash(int messageId) => _service.moveToTrash(messageId);
}

/// Compatibility bridge that adapts `flutter_smartschool` to the app's
/// existing Smartschool DTOs and controller contracts.
class SmartschoolBridge {
  SmartschoolBridge._({
    SmartschoolClient? client,
    required SmartschoolSessionApi session,
    required SmartschoolMessagesApi messages,
    MessagesService? eventMessages,
  }) : _client = client,
       _session = session,
       _messages = messages,
       _eventMessages = eventMessages;

  SmartschoolBridge.forTesting({
    required SmartschoolSessionApi session,
    required SmartschoolMessagesApi messages,
  }) : _client = null,
       _session = session,
       _messages = messages,
       _eventMessages = null;

  final SmartschoolClient? _client;
  final SmartschoolSessionApi _session;
  final SmartschoolMessagesApi _messages;
  final MessagesService? _eventMessages;
  final List<String> _stderrLog = [];
  StreamSubscription<MessageCounterUpdate>? _messageCounterSubscription;
  bool _messageCounterBound = false;

  /// Kept for backward compatibility with existing debug UI.
  ///
  /// This bridge no longer runs a Python subprocess, so the list stays empty
  /// unless explicit adapter-level diagnostics are added.
  List<String> get stderrLog => List.unmodifiable(_stderrLog);

  static Future<SmartschoolBridge> connect({
    required String username,
    required String password,
    required String mainUrl,
    String? mfa,
  }) async {
    try {
      final client = await SmartschoolClient.create(
        AppCredentials(
          username: username,
          password: password,
          mainUrl: mainUrl,
          mfa: (mfa != null && mfa.trim().isNotEmpty) ? mfa : null,
        ),
      );
      await client.ensureAuthenticated();
      final messagesService = MessagesService(client);
      return SmartschoolBridge._(
        client: client,
        session: _SmartschoolSessionClientAdapter(client),
        messages: _SmartschoolMessagesServiceAdapter(messagesService),
        eventMessages: MessagesService(client),
      );
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<bool> ping() async {
    try {
      await _session.ensureAuthenticated();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> checkPackages() async => const [];

  Future<void> login({
    required String username,
    required String password,
    required String url,
    String mfa = '',
  }) async {
    try {
      await _session.ensureAuthenticated();
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _session.clearCookies();
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      await _session.ensureAuthenticated();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<SmartschoolMessageHeader>> getMessageHeaders({
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    List<int> alreadySeenIds = const [],
  }) async {
    try {
      final headers = await _messages.getHeaders(
        boxType: _mapBoxType(boxType),
        alreadySeenIds: alreadySeenIds,
      );
      return headers.map(_toHeader).toList();
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<List<SmartschoolMessageThread>> getThreadedHeaders({
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    List<int> alreadySeenIds = const [],
  }) async {
    final headers = await getMessageHeaders(
      boxType: boxType,
      alreadySeenIds: alreadySeenIds,
    );
    if (headers.isEmpty) return const [];

    final grouped = <String, List<SmartschoolMessageHeader>>{};
    for (final header in headers) {
      final key = normalizeSubjectForThreading(header.subject);
      grouped.putIfAbsent(key, () => []).add(header);
    }

    final threads =
        grouped.entries.map((entry) {
          final messages = [...entry.value]
            ..sort(
              (a, b) => parseIsoForSorting(
                b.date,
              ).compareTo(parseIsoForSorting(a.date)),
            );
          final latest = messages.first;
          return SmartschoolMessageThread(
            threadKey: entry.key,
            subject: latest.subject,
            latestDate: latest.date,
            messageCount: messages.length,
            hasUnread: messages.any((m) => m.unread),
            hasReply: messages.any((m) => m.hasReply),
            messages: messages,
          );
        }).toList()..sort(
          (a, b) => parseIsoForSorting(
            b.latestDate,
          ).compareTo(parseIsoForSorting(a.latestDate)),
        );

    return threads;
  }

  Future<List<SmartschoolMessageDetail>> getMessage(
    int messageId, {
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
  }) async {
    try {
      final mappedBoxType = _mapBoxType(boxType);
      final detail = await _messages.getMessage(
        messageId,
        boxType: mappedBoxType,
        includeAllRecipients: true,
      );
      if (detail == null) return const [];
      List<MessageSearchUser> replyAllTo = const [];
      List<MessageSearchUser> replyAllCc = const [];
      if (mappedBoxType == BoxType.sent) {
        try {
          (replyAllTo, replyAllCc) = await _messages.getSentMessageRecipients(
            messageId,
          );
        } catch (_) {}
        // Empty means self-sent; caller will discard the DB row.
        if (replyAllTo.isEmpty && replyAllCc.isEmpty) return const [];
      } else {
        try {
          (replyAllTo, replyAllCc) = await _messages.getReplyAllRecipients(
            messageId,
            boxType: mappedBoxType,
          );
        } catch (_) {}
      }
      return [
        _toDetail(detail, replyAllTo: replyAllTo, replyAllCc: replyAllCc),
      ];
    } on SmartschoolParsingError catch (error) {
      // Log parsing errors for debugging
      _stderrLog.add(
        'SmartschoolBridge: Parsing error for message $messageId: $error',
      );
      // Return empty list - the header will be used as fallback by the UI layer
      return const [];
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<List<SmartschoolAttachment>> listAttachments(int messageId) async {
    try {
      final attachments = await _messages.getAttachments(messageId);
      return attachments
          .map(
            (a) => SmartschoolAttachment(
              index: a.fileId,
              name: a.name,
              size: parseAttachmentSizeBytes(a.size),
              sizeLabel: a.size,
            ),
          )
          .toList();
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<List<MessageSearchUser>> searchRecipientsForCompose(
    String query,
  ) async {
    try {
      final (users, _) = await _messages.searchRecipientsForCompose(query);
      return users;
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<void> sendMessage({
    required List<MessageSearchUser> to,
    List<MessageSearchUser> cc = const [],
    List<MessageSearchUser> bcc = const [],
    required String subject,
    required String bodyHtml,
  }) async {
    try {
      await _messages.sendMessage(
        to: to,
        cc: cc,
        bcc: bcc,
        subject: subject,
        bodyHtml: bodyHtml,
      );
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<SmartschoolAttachment> downloadAttachment(
    int messageId,
    int attachmentIndex,
  ) async {
    try {
      final attachments = await _messages.getAttachments(messageId);
      final selected = attachments.firstWhere(
        (a) => a.fileId == attachmentIndex,
        orElse: () => throw SmartschoolBridgeException(
          'Attachment with fileId $attachmentIndex was not found.',
        ),
      );
      final client = _client;
      if (client == null) {
        throw SmartschoolBridgeException(
          'Attachment download requires a live Smartschool client.',
        );
      }
      final bytes = await selected.download(client);
      return SmartschoolAttachment(
        index: selected.fileId,
        name: selected.name,
        size: parseAttachmentSizeBytes(selected.size),
        sizeLabel: selected.size,
        contentBase64: base64Encode(bytes),
      );
    } catch (error) {
      if (error is SmartschoolBridgeException) rethrow;
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<void> markUnread(int messageId) async {
    try {
      await _messages.markUnread(messageId);
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<void> markRead(int messageId) async {
    try {
      await _messages.markRead(messageId);
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<void> startInboxEventDrivenDetection({
    required Iterable<int> seenIds,
    required FutureOr<void> Function(List<SmartschoolMessageHeader>)
    onNewHeaders,
    void Function(Object error)? onError,
  }) async {
    final eventMessages = _eventMessages;
    final client = _client;
    if (eventMessages == null || client == null) {
      throw SmartschoolBridgeException(
        'Event-driven detection requires a live Smartschool client.',
      );
    }

    try {
      eventMessages.seedIncrementalSeenIds(seenIds, boxType: BoxType.inbox);

      if (!_messageCounterBound) {
        eventMessages.bindNotificationCounterStream(
          client.notificationCounterUpdates,
        );
        _messageCounterBound = true;
      }

      await _messageCounterSubscription?.cancel();
      _messageCounterSubscription = eventMessages.messageCounterUpdates.listen((
        update,
      ) async {
        try {
          final headers = await eventMessages.refreshHeadersOnMessageCounter(
            update,
            boxType: BoxType.inbox,
          );
          if (headers.isEmpty) return;
          await onNewHeaders(headers.map(_toHeader).toList());
        } catch (error) {
          onError?.call(error);
        }
      }, onError: onError);
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<void> stopInboxEventDrivenDetection() async {
    await _messageCounterSubscription?.cancel();
    _messageCounterSubscription = null;
  }

  Future<void> setLabel(int messageId, SmartschoolMessageLabel label) async {
    try {
      await _messages.setLabel(messageId, _mapLabel(label));
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<void> archive(dynamic messageId) async {
    try {
      final ids = switch (messageId) {
        int id => <int>[id],
        List<int> list => list,
        List<dynamic> list => list.whereType<int>().toList(),
        _ => <int>[],
      };
      if (ids.isEmpty) return;
      await _messages.moveToArchive(ids);
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  Future<void> trash(int messageId) async {
    try {
      await _messages.moveToTrash(messageId);
    } catch (error) {
      throw SmartschoolBridgeException(error.toString());
    }
  }

  void dispose() {
    _messageCounterSubscription?.cancel();
    _messageCounterSubscription = null;
    _eventMessages?.dispose();
  }

  BoxType _mapBoxType(SmartschoolBoxType boxType) {
    switch (boxType) {
      case SmartschoolBoxType.inbox:
        return BoxType.inbox;
      case SmartschoolBoxType.draft:
        return BoxType.draft;
      case SmartschoolBoxType.scheduled:
        return BoxType.scheduled;
      case SmartschoolBoxType.sent:
        return BoxType.sent;
      case SmartschoolBoxType.trash:
        return BoxType.trash;
    }
  }

  MessageLabel _mapLabel(SmartschoolMessageLabel label) {
    switch (label) {
      case SmartschoolMessageLabel.noFlag:
        return MessageLabel.noFlag;
      case SmartschoolMessageLabel.greenFlag:
        return MessageLabel.greenFlag;
      case SmartschoolMessageLabel.yellowFlag:
        return MessageLabel.yellowFlag;
      case SmartschoolMessageLabel.redFlag:
        return MessageLabel.redFlag;
      case SmartschoolMessageLabel.blueFlag:
        return MessageLabel.blueFlag;
    }
  }

  SmartschoolMessageHeader _toHeader(ShortMessage m) {
    return SmartschoolMessageHeader(
      id: m.id,
      source: 'smartschool',
      from: m.sender,
      fromImage: m.fromImage,
      subject: m.subject,
      date: m.date.toIso8601String(),
      status: m.status,
      unread: m.unread,
      hasAttachment: m.attachment > 0,
      label: m.coloredFlag > 0,
      deleted: m.deleted,
      allowReply: m.allowReply,
      allowReplyEnabled: m.allowReplyEnabled,
      hasReply: m.hasReply,
      hasForward: m.hasForward,
      realBox: m.realBox,
      sendDate: m.sendDate?.toIso8601String(),
    );
  }

  SmartschoolMessageDetail _toDetail(
    FullMessage m, {
    List<MessageSearchUser> replyAllTo = const [],
    List<MessageSearchUser> replyAllCc = const [],
  }) {
    return SmartschoolMessageDetail(
      id: m.id,
      from: m.sender,
      subject: m.subject,
      body: m.body,
      date: m.date.toIso8601String(),
      to: m.to,
      status: m.status,
      attachment: m.attachment,
      unread: m.unread,
      label: m.coloredFlag > 0,
      receivers: m.receivers.map(_toRecipient).toList(growable: false),
      ccReceivers: m.ccReceivers.map(_toRecipient).toList(growable: false),
      bccReceivers: m.bccReceivers.map(_toRecipient).toList(growable: false),
      replyAllToRecipients: replyAllTo
          .map(_toResolvedRecipient)
          .toList(growable: false),
      replyAllCcRecipients: replyAllCc
          .map(_toResolvedRecipient)
          .toList(growable: false),
      senderPicture: m.senderPicture,
      fromTeam: m.fromTeam,
      totalNrOtherToReceivers: m.totalNrOtherToReceivers,
      totalNrOtherCcReceivers: m.totalNrOtherCcReceivers,
      totalNrOtherBccReceivers: m.totalNrOtherBccReceivers,
      canReply: m.canReply,
      hasReply: m.hasReply,
      hasForward: m.hasForward,
      sendDate: m.sendDate?.toIso8601String(),
    );
  }

  SmartschoolMessageRecipient _toRecipient(String name) {
    final cleaned = name.trim().replaceFirst(RegExp(r'^[+\-]'), '').trim();
    return SmartschoolMessageRecipient(displayName: cleaned);
  }

  SmartschoolMessageRecipient _toResolvedRecipient(MessageSearchUser user) {
    return SmartschoolMessageRecipient(
      displayName: user.displayName.trim(),
      userId: user.userId,
      ssId: user.ssId,
      userLt: user.userLt,
      picture: user.picture,
    );
  }

  static String normalizeSubjectForThreading(String subject) {
    final trimmed = subject.trim();
    if (trimmed.isEmpty) return '(no subject)';
    final stripped = trimmed.replaceFirst(
      RegExp(
        r'^(?:(?:re|fw|fwd|aw|wg)\s*(?:\[\d+\])?\s*:\s*)+',
        caseSensitive: false,
      ),
      '',
    );
    return (stripped.isEmpty ? trimmed : stripped).toLowerCase();
  }

  static DateTime parseIsoForSorting(String value) =>
      DateTime.tryParse(value)?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static int parseAttachmentSizeBytes(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return 0;

    final direct = int.tryParse(input);
    if (direct != null) return direct;

    final match = RegExp(
      r'^([0-9]+(?:\.[0-9]+)?)\s*([kmgt]?b)$',
      caseSensitive: false,
    ).firstMatch(input);
    if (match == null) return 0;

    final value = double.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = (match.group(2) ?? 'b').toLowerCase();
    final multiplier = switch (unit) {
      'kb' => 1024,
      'mb' => 1024 * 1024,
      'gb' => 1024 * 1024 * 1024,
      'tb' => 1024 * 1024 * 1024 * 1024,
      _ => 1,
    };
    return (value * multiplier).round();
  }
}
