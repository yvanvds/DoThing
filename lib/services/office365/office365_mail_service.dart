import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/office365_settings_controller.dart';
import '../../controllers/status_controller.dart';
import '../../models/office365_settings.dart';
import '../../providers/database_provider.dart';
import '../downloads_file_store.dart';
import 'outlook_models.dart';

const _kOffice365Source = 'outlook';
const _kMicrosoftLoginHost = 'login.microsoftonline.com';
const _kOutlookBodyContentTypeHeader = 'outlook.body-content-type="html"';
const _kOutlookMessageNotFound = 'Outlook message not found in local database.';

class _InboxDeltaStart {
  const _InboxDeltaStart({required this.nextUrl, required this.isFullRefresh});

  final String nextUrl;
  final bool isFullRefresh;
}

class _InboxSyncProgress {
  _InboxSyncProgress({required bool isFullRefresh})
    : scannedExternalIds = isFullRefresh ? <String>{} : null;

  final Set<String>? scannedExternalIds;
  int newCount = 0;
  int scannedCount = 0;
  int removedCount = 0;
  DateTime? latestReceivedAt;
  String? latestExternalId;
  String? deltaCursor;

  void trackMessage(OutlookLatestMessage message) {
    scannedCount++;
    scannedExternalIds?.add(message.id);

    if (latestReceivedAt == null ||
        message.receivedAt.isAfter(latestReceivedAt!)) {
      latestReceivedAt = message.receivedAt;
      latestExternalId = message.id;
    }
  }

  OutlookSyncResult toResult() {
    return OutlookSyncResult(
      scannedCount: scannedCount,
      newCount: newCount,
      removedCount: removedCount,
    );
  }
}

class Office365MailService {
  Office365MailService(this.ref);

  final Ref ref;

  Future<void> markMessageRead(int localMessageId) =>
      _setMessageReadState(localMessageId: localMessageId, isRead: true);

  Future<void> markMessageUnread(int localMessageId) =>
      _setMessageReadState(localMessageId: localMessageId, isRead: false);

  Future<void> archiveMessage(int localMessageId) async {
    final local = await _requireOutlookLocalMessage(localMessageId);
    final token = await _ensureValidAccessToken();
    final encodedId = Uri.encodeComponent(local.externalId);

    await _postJson(
      Uri.parse('https://graph.microsoft.com/v1.0/me/messages/$encodedId/move'),
      headers: {'Authorization': 'Bearer $token'},
      body: {'destinationId': 'archive'},
    );

    final db = ref.read(appDatabaseProvider);
    await db.messagesDao.updateMessageById(
      local.id,
      MessagesCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteMessage(int localMessageId) async {
    final local = await _requireOutlookLocalMessage(localMessageId);
    final token = await _ensureValidAccessToken();
    final encodedId = Uri.encodeComponent(local.externalId);

    await _sendWithoutResponseBody(
      method: 'DELETE',
      uri: Uri.parse('https://graph.microsoft.com/v1.0/me/messages/$encodedId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final db = ref.read(appDatabaseProvider);
    await db.messagesDao.updateMessageById(
      local.id,
      MessagesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> authenticate() async {
    final settings = await ref.read(office365SettingsProvider.future);
    _validateSettings(settings);

    final verifier = _randomUrlSafe(64);
    final challenge = _pkceChallenge(verifier);
    final state = _randomUrlSafe(32);

    final redirectUri = Uri.parse(
      'http://127.0.0.1:${settings.redirectPort}/office365/callback',
    );

    final authUri = Uri.https(
      _kMicrosoftLoginHost,
      '/${settings.tenantId.trim()}/oauth2/v2.0/authorize',
      {
        'client_id': settings.clientId.trim(),
        'response_type': 'code',
        'redirect_uri': redirectUri.toString(),
        'response_mode': 'query',
        'scope': _normalizedScopes(settings.scopes),
        'state': state,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      },
    );

    ref
        .read(statusProvider.notifier)
        .add(StatusEntryType.info, 'Opening Microsoft sign-in in browser...');

    HttpServer? server;
    try {
      server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        settings.redirectPort,
      );

      final callbackFuture = _waitForOAuthCallback(server);

      final launched = await launchUrl(
        authUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Could not open browser for Microsoft sign-in.');
      }

      final callback = await callbackFuture.timeout(const Duration(minutes: 5));
      final callbackState = callback['state'] ?? '';
      if (callbackState != state) {
        throw StateError('OAuth state mismatch. Please try signing in again.');
      }

      final code = callback['code'] ?? '';
      if (code.trim().isEmpty) {
        final oauthError = callback['error'] ?? 'authorization_failed';
        final errorDescription = callback['error_description'] ?? '';
        final detail = errorDescription.isEmpty
            ? oauthError
            : '$oauthError: $errorDescription';
        throw StateError('Microsoft sign-in failed: $detail');
      }

      final tokenData = await _exchangeAuthorizationCode(
        settings: settings,
        code: code,
        codeVerifier: verifier,
        redirectUri: redirectUri.toString(),
      );

      await _storeTokens(settings: settings, tokenData: tokenData);

      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.success, 'Office 365 account connected.');
    } finally {
      await server?.close(force: true);
    }
  }

  Future<OutlookLatestMessage?> fetchLatestInboxMessage() async {
    final messages = await fetchLatestInboxMessages(limit: 1);
    final latest = messages.isEmpty ? null : messages.first;
    if (latest == null) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.info, 'No Outlook inbox messages found.');
      return null;
    }

    ref
        .read(statusProvider.notifier)
        .add(
          StatusEntryType.success,
          'Fetched latest Outlook mail: ${latest.subject}',
        );
    return latest;
  }

  Future<List<OutlookLatestMessage>> fetchLatestInboxMessages({
    int limit = 50,
  }) async {
    final token = await _ensureValidAccessToken();
    final payload = await _fetchInboxPayload(token: token, top: limit);
    final values = payload['value'];
    if (values is! List || values.isEmpty) return const [];

    final results = <OutlookLatestMessage>[];
    for (final entry in values) {
      if (entry is! Map<String, dynamic>) continue;
      final parsed = _parseLatestMessage(entry);
      if (parsed == null) continue;

      await _persistInboxMessage(parsed);
      results.add(parsed);
    }

    return results;
  }

  Future<int> syncLatestInboxMessages({bool silentWhenNotReady = true}) async {
    final result = await syncInboxDelta(silentWhenNotReady: silentWhenNotReady);
    return result.newCount;
  }

  Future<OutlookSyncResult> syncInboxDelta({
    bool silentWhenNotReady = true,
  }) async {
    try {
      final token = await _ensureValidAccessToken();
      final db = ref.read(appDatabaseProvider);

      await _markInboxSyncAttempt(db);
      final currentState = await db.syncStateDao.getState(
        source: _kOffice365Source,
        scope: 'inbox',
      );
      final syncStart = _buildInboxDeltaStart(currentState);
      final progress = await _syncInboxDeltaPages(
        token: token,
        nextUrl: syncStart.nextUrl,
        isFullRefresh: syncStart.isFullRefresh,
      );

      progress.removedCount += await _reconcileFullRefreshInbox(
        db: db,
        isFullRefresh: syncStart.isFullRefresh,
        scannedExternalIds: progress.scannedExternalIds,
      );
      await _markInboxSyncSuccess(
        db: db,
        currentState: currentState,
        progress: progress,
      );

      return progress.toResult();
    } catch (error) {
      if (silentWhenNotReady) {
        return const OutlookSyncResult(
          scannedCount: 0,
          newCount: 0,
          removedCount: 0,
        );
      }

      final db = ref.read(appDatabaseProvider);
      await db.syncStateDao.markFailure(
        source: _kOffice365Source,
        scope: 'inbox',
        error: '$error',
      );
      rethrow;
    }
  }

  Future<void> _markInboxSyncAttempt(AppDatabase db) {
    return db.syncStateDao.markAttempt(
      source: _kOffice365Source,
      scope: 'inbox',
    );
  }

  _InboxDeltaStart _buildInboxDeltaStart(SyncStateData? currentState) {
    final remoteCursor = currentState?.remoteCursor?.trim();
    final isFullRefresh = remoteCursor == null || remoteCursor.isEmpty;
    return _InboxDeltaStart(
      nextUrl: isFullRefresh ? _deltaSeedUrl() : remoteCursor,
      isFullRefresh: isFullRefresh,
    );
  }

  Future<_InboxSyncProgress> _syncInboxDeltaPages({
    required String token,
    required String nextUrl,
    required bool isFullRefresh,
  }) async {
    final progress = _InboxSyncProgress(isFullRefresh: isFullRefresh);
    var currentUrl = nextUrl;

    while (currentUrl.isNotEmpty) {
      final payload = await _fetchInboxDeltaPage(
        token: token,
        nextUrl: currentUrl,
      );
      await _processInboxDeltaPayload(payload, progress);
      currentUrl = _nextInboxDeltaUrl(payload);
    }

    return progress;
  }

  Future<Map<String, dynamic>> _fetchInboxDeltaPage({
    required String token,
    required String nextUrl,
  }) {
    return _getJson(
      Uri.parse(nextUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Prefer': _kOutlookBodyContentTypeHeader,
      },
    );
  }

  Future<void> _processInboxDeltaPayload(
    Map<String, dynamic> payload,
    _InboxSyncProgress progress,
  ) async {
    final values = payload['value'];
    if (values is List) {
      for (final entry in values.whereType<Map<String, dynamic>>()) {
        await _processInboxDeltaEntry(entry, progress);
      }
    }

    final deltaLink = payload['@odata.deltaLink'] as String?;
    if (deltaLink != null && deltaLink.trim().isNotEmpty) {
      progress.deltaCursor = deltaLink;
    }
  }

  Future<void> _processInboxDeltaEntry(
    Map<String, dynamic> entry,
    _InboxSyncProgress progress,
  ) async {
    final removedId = _removedInboxEntryId(entry);
    if (removedId != null) {
      await _markMessageDeletedByExternalId(removedId);
      progress.removedCount++;
      return;
    }

    final parsed = _parseLatestMessage(entry);
    if (parsed == null) return;

    progress.trackMessage(parsed);
    final existed = await _messageExists(externalId: parsed.id);
    await _persistInboxMessage(parsed);
    if (!existed) {
      progress.newCount++;
    }
  }

  String? _removedInboxEntryId(Map<String, dynamic> entry) {
    if (!entry.containsKey('@removed')) {
      return null;
    }

    final removedId = (entry['id'] as String?)?.trim();
    if (removedId == null || removedId.isEmpty) {
      return null;
    }
    return removedId;
  }

  String _nextInboxDeltaUrl(Map<String, dynamic> payload) {
    final nextLink = (payload['@odata.nextLink'] as String?)?.trim();
    return nextLink == null || nextLink.isEmpty ? '' : nextLink;
  }

  Future<int> _reconcileFullRefreshInbox({
    required AppDatabase db,
    required bool isFullRefresh,
    required Set<String>? scannedExternalIds,
  }) async {
    if (!isFullRefresh || scannedExternalIds == null) {
      return 0;
    }

    return db.messagesDao.deleteStaleMessages(
      source: _kOffice365Source,
      mailbox: 'inbox',
      activeExternalIds: scannedExternalIds,
    );
  }

  Future<void> _markInboxSyncSuccess({
    required AppDatabase db,
    required SyncStateData? currentState,
    required _InboxSyncProgress progress,
  }) {
    return db.syncStateDao.markSuccess(
      source: _kOffice365Source,
      scope: 'inbox',
      remoteCursor: progress.deltaCursor ?? currentState?.remoteCursor,
      highWaterExternalId: progress.latestExternalId,
      highWaterReceivedAt: progress.latestReceivedAt,
    );
  }

  Future<void> disconnect() async {
    await ref.read(office365SettingsProvider.notifier).clearAuthState();
    ref
        .read(statusProvider.notifier)
        .add(StatusEntryType.info, 'Office 365 authentication cleared.');
  }

  Future<void> refreshMessageDetail(int localMessageId) async {
    final db = ref.read(appDatabaseProvider);
    final local = await db.messagesDao.getMessageById(localMessageId);
    if (local == null || local.source != _kOffice365Source) {
      throw StateError(_kOutlookMessageNotFound);
    }

    final token = await _ensureValidAccessToken();
    final encodedId = Uri.encodeComponent(local.externalId);
    final uri = Uri.parse(
      'https://graph.microsoft.com/v1.0/me/messages/$encodedId'
      r'?$select=id,subject,body,bodyPreview,isRead,hasAttachments,from,receivedDateTime'
      r'&$expand=attachments',
    );

    final payload = await _getJson(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Prefer': _kOutlookBodyContentTypeHeader,
      },
    );

    final bodyData = payload['body'] as Map<String, dynamic>? ?? const {};
    final bodyRaw = bodyData['content'] as String? ?? '';
    final bodyFormat = ((bodyData['contentType'] as String?) ?? 'text')
        .toLowerCase();
    final attachmentPayloads = _extractAttachmentPayloads(payload);
    final resolvedBodyRaw = _replaceInlineCidUrls(bodyRaw, attachmentPayloads);
    final bodyText = _toPlainText(resolvedBodyRaw, bodyFormat: bodyFormat);

    final receivedAt =
        DateTime.tryParse(payload['receivedDateTime'] as String? ?? '') ??
        local.receivedAt;
    final subject = payload['subject'] as String? ?? local.subject;
    final isRead = payload['isRead'] as bool? ?? local.isRead;
    final hasAttachments =
        payload['hasAttachments'] as bool? ?? local.hasAttachments;

    await db.messagesDao.updateMessageById(
      local.id,
      MessagesCompanion(
        subject: Value(subject),
        receivedAt: Value(receivedAt),
        isRead: Value(isRead),
        hasAttachments: Value(hasAttachments),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await db.messagesDao.updateMessageDetail(
      id: local.id,
      bodyRaw: resolvedBodyRaw,
      bodyText: bodyText,
      bodyFormat: bodyFormat,
      rawDetailJson: jsonEncode(payload),
    );

    final attachmentRows = _buildAttachmentRows(
      messageId: local.id,
      attachments: attachmentPayloads,
    );
    await db.attachmentsDao.replaceAttachmentsForMessage(
      local.id,
      attachmentRows,
    );

    final sender = payload['from'] as Map<String, dynamic>? ?? const {};
    final senderData =
        sender['emailAddress'] as Map<String, dynamic>? ?? const {};
    final senderName = senderData['name'] as String? ?? 'Unknown sender';
    final senderAddress = (senderData['address'] as String? ?? '')
        .trim()
        .toLowerCase();

    int? senderContactId;
    if (senderAddress.isNotEmpty) {
      senderContactId = await db.contactsDao.upsertIdentity(
        source: _kOffice365Source,
        externalId: senderAddress,
        displayName: senderName,
      );
    }

    await db.messagesDao.replaceParticipants(local.id, [
      MessageParticipantsCompanion.insert(
        messageId: local.id,
        role: 'sender',
        displayNameSnapshot: senderName,
        contactId: Value(senderContactId),
        addressSnapshot: Value(senderAddress.isEmpty ? null : senderAddress),
      ),
    ]);

    ref
        .read(statusProvider.notifier)
        .add(StatusEntryType.success, 'Outlook detail refreshed from server.');
  }

  Future<File> downloadAttachment({
    required int localMessageId,
    required MessageAttachment attachment,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final local = await db.messagesDao.getMessageById(localMessageId);
    if (local == null || local.source != _kOffice365Source) {
      throw StateError(_kOutlookMessageNotFound);
    }

    if (attachment.localPath != null &&
        attachment.localPath!.trim().isNotEmpty) {
      final existing = File(attachment.localPath!.trim());
      if (await existing.exists()) {
        return existing;
      }
    }

    final externalAttachmentId = attachment.externalId?.trim();
    if (externalAttachmentId == null || externalAttachmentId.isEmpty) {
      throw StateError('Attachment id is missing for this Outlook attachment.');
    }

    final token = await _ensureValidAccessToken();
    final encodedMessageId = Uri.encodeComponent(local.externalId);
    final encodedAttachmentId = Uri.encodeComponent(externalAttachmentId);
    final uri = Uri.parse(
      'https://graph.microsoft.com/v1.0/me/messages/$encodedMessageId/attachments/$encodedAttachmentId'
      '?\$select=id,name,contentType,size,isInline,contentId,contentBytes',
    );

    try {
      final payload = await _getJson(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final base64 = (payload['contentBytes'] as String? ?? '').trim();
      if (base64.isEmpty) {
        throw StateError(
          'Attachment payload does not contain downloadable bytes.',
        );
      }

      final bytes = base64Decode(base64);
      final filename = (payload['name'] as String? ?? attachment.filename)
          .trim();
      final file = await DownloadsFileStore.saveToDownloads(
        filename.isEmpty ? attachment.filename : filename,
        bytes,
      );

      final checksum = sha256.convert(bytes).toString();
      await db.attachmentsDao.markDownloaded(
        id: attachment.id,
        localPath: file.path,
        sha256: checksum,
      );
      return file;
    } catch (_) {
      await db.attachmentsDao.markDownloadFailed(attachment.id);
      rethrow;
    }
  }

  Future<void> _setMessageReadState({
    required int localMessageId,
    required bool isRead,
  }) async {
    final local = await _requireOutlookLocalMessage(localMessageId);
    final token = await _ensureValidAccessToken();
    final encodedId = Uri.encodeComponent(local.externalId);

    await _sendWithoutResponseBody(
      method: 'PATCH',
      uri: Uri.parse('https://graph.microsoft.com/v1.0/me/messages/$encodedId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: {'isRead': isRead},
    );

    final db = ref.read(appDatabaseProvider);
    await db.messagesDao.updateMessageById(
      local.id,
      MessagesCompanion(
        isRead: Value(isRead),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<Message> _requireOutlookLocalMessage(int localMessageId) async {
    final db = ref.read(appDatabaseProvider);
    final local = await db.messagesDao.getMessageById(localMessageId);
    if (local == null || local.source != _kOffice365Source) {
      throw StateError(_kOutlookMessageNotFound);
    }
    return local;
  }

  Future<void> _persistInboxMessage(OutlookLatestMessage latest) async {
    final db = ref.read(appDatabaseProvider);

    final existing = await db.messagesDao.findMessage(
      source: _kOffice365Source,
      externalId: latest.id,
    );

    final fullBody = latest.body.raw?.trim() ?? '';
    final hasFullBody = fullBody.isNotEmpty;
    final effectiveBodyRaw = hasFullBody ? fullBody : latest.body.preview;
    final effectiveBodyFormat = hasFullBody
        ? (latest.body.format ?? 'html')
        : 'plain';
    final effectiveBodyText = _toPlainText(
      effectiveBodyRaw,
      bodyFormat: effectiveBodyFormat,
    );

    final row = MessagesCompanion.insert(
      source: _kOffice365Source,
      externalId: latest.id,
      mailbox: 'inbox',
      subject: Value(latest.subject),
      bodyRaw: Value(effectiveBodyRaw),
      bodyText: Value(effectiveBodyText),
      bodyFormat: Value(effectiveBodyFormat),
      receivedAt: latest.receivedAt,
      isRead: Value(latest.isRead),
      hasAttachments: Value(latest.hasAttachments),
      detailFetchedAt: hasFullBody
          ? Value(DateTime.now())
          : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    final messageId = await db.transaction(() async {
      if (existing == null) {
        return db.messagesDao.insertMessage(row);
      }

      await db.messagesDao.updateMessageById(
        existing.id,
        MessagesCompanion(
          mailbox: const Value('inbox'),
          subject: Value(latest.subject),
          bodyRaw: Value(effectiveBodyRaw),
          bodyText: Value(effectiveBodyText),
          bodyFormat: Value(effectiveBodyFormat),
          receivedAt: Value(latest.receivedAt),
          isRead: Value(latest.isRead),
          hasAttachments: Value(latest.hasAttachments),
          detailFetchedAt: hasFullBody
              ? Value(DateTime.now())
              : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return existing.id;
    });

    int? senderContactId;
    final senderAddress = latest.sender.address.trim().toLowerCase();
    if (senderAddress.isNotEmpty) {
      senderContactId = await db.contactsDao.upsertIdentity(
        source: _kOffice365Source,
        externalId: senderAddress,
        displayName: latest.sender.name,
      );
    }

    await db.messagesDao.replaceParticipants(messageId, [
      MessageParticipantsCompanion.insert(
        messageId: messageId,
        role: 'sender',
        displayNameSnapshot: latest.sender.name,
        contactId: Value(senderContactId),
        addressSnapshot: Value(senderAddress.isEmpty ? null : senderAddress),
      ),
    ]);
  }

  Future<void> _markMessageDeletedByExternalId(String externalId) async {
    final db = ref.read(appDatabaseProvider);
    final existing = await db.messagesDao.findMessage(
      source: _kOffice365Source,
      externalId: externalId,
    );
    if (existing == null) return;

    await db.messagesDao.updateMessageById(
      existing.id,
      MessagesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<bool> _messageExists({required String externalId}) async {
    final db = ref.read(appDatabaseProvider);
    final existing = await db.messagesDao.findMessage(
      source: _kOffice365Source,
      externalId: externalId,
    );
    return existing != null;
  }

  Future<Map<String, dynamic>> _fetchInboxPayload({
    required String token,
    required int top,
  }) {
    final effectiveTop = top <= 0 ? 1 : top;
    final uri = Uri.parse(
      'https://graph.microsoft.com/v1.0/me/messages'
      '?\$top=$effectiveTop&\$orderby=receivedDateTime%20desc'
      '&\$select=id,subject,receivedDateTime,bodyPreview,isRead,hasAttachments,from',
    );

    return _getJson(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Prefer': _kOutlookBodyContentTypeHeader,
      },
    );
  }

  String _deltaSeedUrl() {
    return 'https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messages/delta'
        '?\$select=id,subject,receivedDateTime,bodyPreview,isRead,hasAttachments,from';
  }

  OutlookLatestMessage? _parseLatestMessage(Map<String, dynamic> raw) {
    final sender = raw['from'];
    final senderData = sender is Map<String, dynamic>
        ? (sender['emailAddress'] as Map<String, dynamic>? ?? const {})
        : const <String, dynamic>{};

    final id = raw['id'] as String? ?? '';
    if (id.trim().isEmpty) return null;

    final bodyData = raw['body'] as Map<String, dynamic>?;
    final bodyRaw = bodyData?['content'] as String?;
    final bodyFormat =
        (bodyData?['contentType'] as String?)?.toLowerCase() ??
        (bodyRaw == null ? null : 'html');

    return OutlookLatestMessage(
      id: id,
      subject: raw['subject'] as String? ?? '(no subject)',
      sender: OutlookSenderInfo(
        name: senderData['name'] as String? ?? 'Unknown sender',
        address: senderData['address'] as String? ?? '',
      ),
      receivedAt:
          DateTime.tryParse(raw['receivedDateTime'] as String? ?? '') ??
          DateTime.now(),
      body: OutlookBodyContent(
        preview: raw['bodyPreview'] as String? ?? '',
        raw: bodyRaw,
        format: bodyFormat,
      ),
      isRead: raw['isRead'] as bool? ?? false,
      hasAttachments: raw['hasAttachments'] as bool? ?? false,
    );
  }

  List<Map<String, dynamic>> _extractAttachmentPayloads(
    Map<String, dynamic> payload,
  ) {
    final raw = payload['attachments'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    if (raw is Map<String, dynamic>) {
      final values = raw['value'];
      if (values is List) {
        return values.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }

  String _replaceInlineCidUrls(
    String html,
    List<Map<String, dynamic>> attachments,
  ) {
    var result = html;
    for (final attachment in attachments) {
      final isInline = attachment['isInline'] as bool? ?? false;
      if (!isInline) continue;

      final rawContentId = (attachment['contentId'] as String? ?? '').trim();
      final contentBytes = (attachment['contentBytes'] as String? ?? '').trim();
      if (rawContentId.isEmpty || contentBytes.isEmpty) continue;

      final contentId = rawContentId
          .replaceAll('<', '')
          .replaceAll('>', '')
          .trim();
      if (contentId.isEmpty) continue;

      final mimeType =
          (attachment['contentType'] as String? ?? 'application/octet-stream')
              .trim();
      final dataUri = 'data:$mimeType;base64,$contentBytes';

      final cidRegex = RegExp(
        'cid:<?${RegExp.escape(contentId)}>?',
        caseSensitive: false,
      );
      result = result.replaceAllMapped(cidRegex, (_) => dataUri);
    }

    return result;
  }

  List<MessageAttachmentsCompanion> _buildAttachmentRows({
    required int messageId,
    required List<Map<String, dynamic>> attachments,
  }) {
    return attachments.map((attachment) {
      final externalId = (attachment['id'] as String?)?.trim();
      final filename = (attachment['name'] as String? ?? 'attachment').trim();
      final mimeType = (attachment['contentType'] as String?)?.trim();
      final size = (attachment['size'] as num?)?.toInt();
      final isInline = attachment['isInline'] as bool? ?? false;

      return MessageAttachmentsCompanion.insert(
        messageId: messageId,
        source: _kOffice365Source,
        externalId: Value(
          externalId == null || externalId.isEmpty ? null : externalId,
        ),
        filename: filename.isEmpty ? 'attachment' : filename,
        mimeType: Value(mimeType == null || mimeType.isEmpty ? null : mimeType),
        sizeBytes: Value(size),
        isInline: Value(isInline),
      );
    }).toList();
  }

  Future<String> _ensureValidAccessToken() async {
    final settings = await ref.read(office365SettingsProvider.future);
    _validateSettings(settings);

    final accessToken = settings.accessToken.trim();
    if (accessToken.isEmpty) {
      throw StateError('Office 365 is not signed in yet.');
    }

    final expiresAt = settings.expiresAt;
    final isExpired =
        expiresAt == null ||
        DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 1)));

    if (!isExpired) return accessToken;

    final refreshToken = settings.refreshToken.trim();
    if (refreshToken.isEmpty) {
      throw StateError('Office 365 token expired and no refresh token found.');
    }

    final tokenData = await _exchangeRefreshToken(
      settings: settings,
      refreshToken: refreshToken,
    );

    await _storeTokens(settings: settings, tokenData: tokenData);
    final updated = await ref.read(office365SettingsProvider.future);
    return updated.accessToken;
  }

  Future<Map<String, dynamic>> _exchangeAuthorizationCode({
    required Office365Settings settings,
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) {
    return _postForm(
      Uri.https(
        _kMicrosoftLoginHost,
        '/${settings.tenantId.trim()}/oauth2/v2.0/token',
      ),
      body: {
        'client_id': settings.clientId.trim(),
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'scope': _normalizedScopes(settings.scopes),
        'code_verifier': codeVerifier,
      },
    );
  }

  Future<Map<String, dynamic>> _exchangeRefreshToken({
    required Office365Settings settings,
    required String refreshToken,
  }) {
    return _postForm(
      Uri.https(
        _kMicrosoftLoginHost,
        '/${settings.tenantId.trim()}/oauth2/v2.0/token',
      ),
      body: {
        'client_id': settings.clientId.trim(),
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'scope': _normalizedScopes(settings.scopes),
      },
    );
  }

  Future<void> _storeTokens({
    required Office365Settings settings,
    required Map<String, dynamic> tokenData,
  }) async {
    final accessToken = tokenData['access_token'] as String? ?? '';
    final refreshToken = tokenData['refresh_token'] as String? ?? '';
    final expiresIn = (tokenData['expires_in'] as num?)?.toInt() ?? 3600;

    if (accessToken.trim().isEmpty) {
      throw StateError('Token response did not include access_token.');
    }

    final profile = await _getJson(
      Uri.parse(
        'https://graph.microsoft.com/v1.0/me?%24select=displayName,mail,userPrincipalName',
      ),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final accountEmail =
        (profile['mail'] as String?) ??
        (profile['userPrincipalName'] as String?) ??
        '';
    final accountDisplayName = profile['displayName'] as String? ?? '';

    await ref
        .read(office365SettingsProvider.notifier)
        .updateSettings(
          settings.copyWith(
            authState: settings.authState.copyWith(
              accessToken: accessToken,
              refreshToken: refreshToken.isEmpty
                  ? settings.refreshToken
                  : refreshToken,
              expiresAtIso: DateTime.now()
                  .add(Duration(seconds: expiresIn))
                  .toIso8601String(),
              accountEmail: accountEmail,
              accountDisplayName: accountDisplayName,
            ),
          ),
        );
  }

  Future<Map<String, String>> _waitForOAuthCallback(HttpServer server) {
    final completer = Completer<Map<String, String>>();

    server.listen((request) async {
      final query = request.uri.queryParameters;

      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.html;
      request.response.write(
        '<html><body><h3>Office 365 authentication complete.</h3>'
        '<p>You can close this tab and return to DoThing.</p></body></html>',
      );
      await request.response.close();

      if (!completer.isCompleted) {
        completer.complete(query);
      }
    });

    return completer.future;
  }

  Future<Map<String, dynamic>> _postForm(
    Uri uri, {
    required Map<String, String> body,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
      );
      request.write(_formEncode(body));

      final response = await request.close();
      final raw = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Microsoft token request failed (${response.statusCode}): $raw',
        );
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw StateError('Token response was not valid JSON object.');
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _getJson(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers.forEach(request.headers.set);

      final response = await request.close();
      final raw = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('HTTP ${response.statusCode} calling $uri: $raw');
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw StateError('Response from $uri was not a JSON object.');
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri, {
    Map<String, String> headers = const {},
    Map<String, dynamic> body = const {},
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      headers.forEach(request.headers.set);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));

      final response = await request.close();
      final raw = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('HTTP ${response.statusCode} calling $uri: $raw');
      }

      if (raw.trim().isEmpty) {
        return const {};
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw StateError('Response from $uri was not a JSON object.');
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _sendWithoutResponseBody({
    required String method,
    required Uri uri,
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, uri);
      headers.forEach(request.headers.set);
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final raw = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('HTTP ${response.statusCode} calling $uri: $raw');
      }
    } finally {
      client.close(force: true);
    }
  }

  String _formEncode(Map<String, String> values) => values.entries
      .map(
        (entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
      )
      .join('&');

  void _validateSettings(Office365Settings settings) {
    if (settings.tenantId.trim().isEmpty) {
      throw StateError('Office 365 tenant ID is required.');
    }
    if (settings.clientId.trim().isEmpty) {
      throw StateError('Office 365 client ID is required.');
    }
    if (settings.redirectPort <= 0) {
      throw StateError('Office 365 redirect port must be greater than 0.');
    }
  }

  String _normalizedScopes(String rawScopes) {
    final scopes = rawScopes
        .split(RegExp(r'\s+'))
        .map((scope) => scope.trim())
        .where((scope) => scope.isNotEmpty)
        .toSet();

    scopes.add('offline_access');
    scopes.add('Mail.Read');
    scopes.add('openid');
    scopes.add('profile');

    return scopes.join(' ');
  }

  String _randomUrlSafe(int length) {
    final random = Random.secure();
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final buffer = StringBuffer();

    for (var index = 0; index < length; index++) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }

    return buffer.toString();
  }

  String _pkceChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes).bytes;
    return base64UrlEncode(digest).replaceAll('=', '');
  }

  String _toPlainText(String raw, {required String bodyFormat}) {
    final normalized = bodyFormat.toLowerCase();
    if (!normalized.contains('html')) {
      return raw;
    }

    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

final office365MailServiceProvider = Provider<Office365MailService>(
  Office365MailService.new,
);
