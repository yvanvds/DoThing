import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smartschool/flutter_smartschool.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import '../../controllers/status_controller.dart';
import '../../models/draft_message.dart';
import '../../models/recipients/recipient_chip.dart';
import '../../models/recipients/recipient_endpoint_kind.dart';
import '../../providers/database_provider.dart';
import '../office365/office365_mail_service.dart';
import '../smartschool/smartschool_auth_controller.dart';
import '../smartschool/smartschool_bridge.dart';
import 'queued_draft_codec.dart';

class ComposerMessageSender {
  ComposerMessageSender(this.ref);

  final Ref ref;

  Future<void> send(
    DraftMessage draft, {
    bool queueOnFailure = true,
    bool reportStatus = true,
  }) async {
    final subject = draft.subject.trim();
    if (subject.isEmpty) {
      throw StateError('A subject is required before sending.');
    }

    final hasAnyRecipient =
        draft.toRecipients.isNotEmpty ||
        draft.ccRecipients.isNotEmpty ||
        draft.bccRecipients.isNotEmpty;
    if (!hasAnyRecipient) {
      throw StateError('Add at least one recipient before sending.');
    }

    final batches = _buildBatches(draft);
    if (batches.isEmpty) {
      throw StateError('No supported recipients were found in this draft.');
    }

    final bodyHtml = _deltaToHtml(draft.body);
    var sentBatchCount = 0;
    var queuedBatchCount = 0;
    final errors = <String>[];

    for (final batch in batches) {
      try {
        switch (batch.provider) {
          case RecipientEndpointKind.smartschool:
            await _sendSmartschool(
              to: batch.draft.toRecipients,
              cc: batch.draft.ccRecipients,
              bcc: batch.draft.bccRecipients,
              subject: subject,
              bodyHtml: bodyHtml,
              reportStatus: reportStatus,
            );
          case RecipientEndpointKind.email:
            await _sendOutlook(
              to: batch.draft.toRecipients,
              cc: batch.draft.ccRecipients,
              bcc: batch.draft.bccRecipients,
              subject: subject,
              bodyHtml: bodyHtml,
              reportStatus: reportStatus,
            );
        }
        sentBatchCount++;
      } catch (error) {
        errors.add('${batch.label}: $error');
        if (queueOnFailure) {
          await _queueFailedBatch(batch.draft, error.toString());
          queuedBatchCount++;
        }
      }
    }

    if (errors.isNotEmpty) {
      if (reportStatus) {
        ref
            .read(statusProvider.notifier)
            .add(
              StatusEntryType.warning,
              _failureSummary(
                sentBatchCount: sentBatchCount,
                queuedBatchCount: queuedBatchCount,
              ),
            );
      }
      throw StateError(errors.join(' | '));
    }

    if (reportStatus) {
      final batchWord = sentBatchCount == 1
          ? 'message batch'
          : 'message batches';
      ref
          .read(statusProvider.notifier)
          .add(
            StatusEntryType.success,
            'Message sent ($sentBatchCount $batchWord).',
          );
    }
  }

  Future<void> _sendSmartschool({
    required List<RecipientChip> to,
    required List<RecipientChip> cc,
    required List<RecipientChip> bcc,
    required String subject,
    required String bodyHtml,
    required bool reportStatus,
  }) async {
    final bridge = ref.read(smartschoolAuthProvider.notifier).bridge;
    final queryCache = <String, List<MessageSearchUser>>{};

    final resolvedTo = await _resolveSmartschoolUsers(
      bridge: bridge,
      chips: to,
      queryCache: queryCache,
    );
    final resolvedCc = await _resolveSmartschoolUsers(
      bridge: bridge,
      chips: cc,
      queryCache: queryCache,
    );
    final resolvedBcc = await _resolveSmartschoolUsers(
      bridge: bridge,
      chips: bcc,
      queryCache: queryCache,
    );

    if (reportStatus) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.info, 'Sending Smartschool message...');
    }

    await bridge.sendMessage(
      to: resolvedTo,
      cc: resolvedCc,
      bcc: resolvedBcc,
      subject: subject,
      bodyHtml: bodyHtml,
    );
  }

  Future<void> _sendOutlook({
    required List<RecipientChip> to,
    required List<RecipientChip> cc,
    required List<RecipientChip> bcc,
    required String subject,
    required String bodyHtml,
    required bool reportStatus,
  }) async {
    final office365 = ref.read(office365MailServiceProvider);

    if (reportStatus) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.info, 'Sending Outlook message...');
    }

    await office365.sendMail(
      toRecipients: to
          .map((chip) => chip.endpoint.value)
          .toList(growable: false),
      ccRecipients: cc
          .map((chip) => chip.endpoint.value)
          .toList(growable: false),
      bccRecipients: bcc
          .map((chip) => chip.endpoint.value)
          .toList(growable: false),
      subject: subject,
      bodyHtml: bodyHtml,
    );
  }

  Future<List<MessageSearchUser>> _resolveSmartschoolUsers({
    required SmartschoolBridge bridge,
    required List<RecipientChip> chips,
    required Map<String, List<MessageSearchUser>> queryCache,
  }) async {
    final resolved = <MessageSearchUser>[];
    final usedUserIds = <int>{};

    for (final chip in chips) {
      final user = await _resolveSmartschoolUser(
        bridge: bridge,
        chip: chip,
        queryCache: queryCache,
      );
      if (usedUserIds.add(user.userId)) {
        resolved.add(user);
      }
    }

    return resolved;
  }

  Future<MessageSearchUser> _resolveSmartschoolUser({
    required SmartschoolBridge bridge,
    required RecipientChip chip,
    required Map<String, List<MessageSearchUser>> queryCache,
  }) async {
    final queries = <String>{
      chip.endpoint.externalId?.trim() ?? '',
      chip.endpoint.value.trim(),
      chip.displayName.trim(),
    }..removeWhere((query) => query.isEmpty);

    final candidatesByUserId = <int, MessageSearchUser>{};
    for (final query in queries) {
      final users = await _searchSmartschoolUsers(
        bridge: bridge,
        query: query,
        queryCache: queryCache,
      );
      for (final user in users) {
        candidatesByUserId[user.userId] = user;
      }
    }

    final candidates = candidatesByUserId.values.toList(growable: false);
    final matched = _pickBestSmartschoolUser(
      chip: chip,
      candidates: candidates,
    );
    if (matched != null) {
      return matched;
    }

    throw StateError(
      'Could not resolve Smartschool recipient for "${chip.displayName}".',
    );
  }

  Future<List<MessageSearchUser>> _searchSmartschoolUsers({
    required SmartschoolBridge bridge,
    required String query,
    required Map<String, List<MessageSearchUser>> queryCache,
  }) async {
    final cached = queryCache[query];
    if (cached != null) {
      return cached;
    }

    final users = await bridge.searchRecipientsForCompose(query);
    queryCache[query] = users;
    return users;
  }

  MessageSearchUser? _pickBestSmartschoolUser({
    required RecipientChip chip,
    required List<MessageSearchUser> candidates,
  }) {
    if (candidates.isEmpty) {
      return null;
    }

    final idTokens = <String>{
      chip.endpoint.externalId?.trim() ?? '',
      chip.endpoint.value.trim(),
    }..removeWhere((value) => value.isEmpty);

    final idMatches = candidates
        .where((candidate) {
          final ssId = candidate.ssId.toString();
          final userId = candidate.userId.toString();
          return idTokens.contains(ssId) || idTokens.contains(userId);
        })
        .toList(growable: false);
    if (idMatches.isNotEmpty) {
      return idMatches.first;
    }

    final normalizedName = chip.displayName.trim().toLowerCase();
    if (normalizedName.isNotEmpty) {
      final exactNameMatches = candidates
          .where(
            (candidate) =>
                candidate.displayName.trim().toLowerCase() == normalizedName,
          )
          .toList(growable: false);
      if (exactNameMatches.length == 1) {
        return exactNameMatches.first;
      }
    }

    return null;
  }

  List<RecipientChip> _recipientsOfKind(
    List<RecipientChip> recipients,
    RecipientEndpointKind kind,
  ) {
    final unique = <String>{};
    final filtered = <RecipientChip>[];

    for (final chip in recipients) {
      if (chip.endpoint.kind != kind) {
        continue;
      }
      if (unique.add(chip.dedupeKey)) {
        filtered.add(chip);
      }
    }

    return filtered;
  }

  List<_SendBatch> _buildBatches(DraftMessage draft) {
    final batches = <_SendBatch>[];

    final smartschoolDraft = _draftForKind(
      draft: draft,
      kind: RecipientEndpointKind.smartschool,
    );
    if (_hasRecipients(smartschoolDraft)) {
      batches.add(
        _SendBatch(
          provider: RecipientEndpointKind.smartschool,
          label: 'Smartschool',
          draft: smartschoolDraft,
        ),
      );
    }

    final outlookDraft = _draftForKind(
      draft: draft,
      kind: RecipientEndpointKind.email,
    );
    if (_hasRecipients(outlookDraft)) {
      batches.add(
        _SendBatch(
          provider: RecipientEndpointKind.email,
          label: 'Outlook',
          draft: outlookDraft,
        ),
      );
    }

    return batches;
  }

  DraftMessage _draftForKind({
    required DraftMessage draft,
    required RecipientEndpointKind kind,
  }) {
    return DraftMessage(
      toRecipients: _recipientsOfKind(draft.toRecipients, kind),
      ccRecipients: _recipientsOfKind(draft.ccRecipients, kind),
      bccRecipients: _recipientsOfKind(draft.bccRecipients, kind),
      subject: draft.subject,
      body: draft.body,
    );
  }

  bool _hasRecipients(DraftMessage draft) {
    return draft.toRecipients.isNotEmpty ||
        draft.ccRecipients.isNotEmpty ||
        draft.bccRecipients.isNotEmpty;
  }

  Future<void> _queueFailedBatch(DraftMessage draft, String error) async {
    final now = DateTime.now();
    await ref
        .read(appDatabaseProvider)
        .pendingOutgoingMessagesDao
        .enqueue(
          payloadJson: QueuedDraftCodec.encode(draft),
          subject: draft.subject,
          attemptCount: 1,
          lastAttemptAt: now,
          nextAttemptAt: now.add(const Duration(minutes: 5)),
          lastError: error,
        );
  }

  String _failureSummary({
    required int sentBatchCount,
    required int queuedBatchCount,
  }) {
    if (queuedBatchCount > 0 && sentBatchCount > 0) {
      return 'Message sending partially failed: $sentBatchCount batch sent, $queuedBatchCount queued for retry.';
    }
    if (queuedBatchCount > 0) {
      return 'Message sending failed: $queuedBatchCount batch queued for retry.';
    }
    return 'Message sending failed.';
  }

  String _deltaToHtml(List<Map<String, dynamic>> delta) {
    if (delta.isEmpty) {
      return '<p></p>';
    }

    final converter = QuillDeltaToHtmlConverter(
      delta,
      ConverterOptions.forEmail(),
    );
    final html = converter.convert().trim();
    return html.isEmpty ? '<p></p>' : html;
  }
}

final composerMessageSenderProvider = Provider<ComposerMessageSender>(
  ComposerMessageSender.new,
);

class _SendBatch {
  _SendBatch({
    required this.provider,
    required this.label,
    required this.draft,
  });

  final RecipientEndpointKind provider;
  final String label;
  final DraftMessage draft;
}
