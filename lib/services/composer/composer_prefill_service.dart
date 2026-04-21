import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';

import '../../controllers/composer_controller.dart';
import '../../controllers/composer_visibility_controller.dart';
import '../../controllers/smartschool_settings_controller.dart';
import '../../models/ai/reply_quote_summary.dart';
import '../../models/draft_message.dart';
import '../../models/smartschool_message.dart';
import '../../models/recipients/recipient_chip.dart';
import '../../models/recipients/recipient_chip_source.dart';
import '../../models/recipients/recipient_endpoint.dart';
import '../../models/recipients/recipient_endpoint_kind.dart';
import '../../models/recipients/recipient_endpoint_label.dart';
import '../../providers/database_provider.dart';
import 'ai_reply_quote_service.dart';
import '../office365/office365_mail_service.dart';
import '../smartschool/smartschool_messages_controller.dart';
import '../smartschool/smartschool_selected_message_controller.dart';

enum ComposerPrefillAction { reply, replyAll, forward }

class ComposerPrefillCancellationToken {
  bool _isCanceled = false;

  bool get isCanceled => _isCanceled;

  void cancel() {
    _isCanceled = true;
  }
}

class ComposerPrefillCanceledException implements Exception {
  const ComposerPrefillCanceledException();

  @override
  String toString() => 'Composer prefill was canceled.';
}

class ComposerPrefillService {
  ComposerPrefillService(this.ref);

  final Ref ref;

  Future<void> applyFromSelected(
    ComposerPrefillAction action, {
    ComposerPrefillCancellationToken? cancellationToken,
    String? replyBody,
  }) async {
    _throwIfCanceled(cancellationToken);

    final selected = ref.read(smartschoolSelectedMessageProvider);
    if (selected == null) {
      throw StateError('Select a message first.');
    }

    final draft = await _buildDraft(
      selected,
      action,
      cancellationToken: cancellationToken,
      replyBody: replyBody,
    );
    _throwIfCanceled(cancellationToken);

    // Re-open the composer so header/body editors are recreated with the
    // newly prefilled draft values.
    final visibility = ref.read(composerVisibilityProvider.notifier);
    visibility.close();
    _throwIfCanceled(cancellationToken);
    ref.read(composerProvider.notifier).replace(draft);
    visibility.open();
  }

  Future<DraftMessage> _buildDraft(
    MessageHeader header,
    ComposerPrefillAction action, {
    ComposerPrefillCancellationToken? cancellationToken,
    String? replyBody,
  }) async {
    _throwIfCanceled(cancellationToken);

    if (header.source == 'outlook') {
      return _buildOutlookDraft(
        header,
        action,
        cancellationToken: cancellationToken,
        replyBody: replyBody,
      );
    }
    return _buildSmartschoolDraft(
      header,
      action,
      cancellationToken: cancellationToken,
      replyBody: replyBody,
    );
  }

  Future<DraftMessage> _buildSmartschoolDraft(
    MessageHeader header,
    ComposerPrefillAction action, {
    ComposerPrefillCancellationToken? cancellationToken,
    String? replyBody,
  }) async {
    _throwIfCanceled(cancellationToken);

    final messages = ref.read(smartschoolMessagesProvider.notifier);
    final detailList = await messages.getMessage(
      header.id,
      boxType: _smartschoolBoxTypeForHeader(header),
      reportStatus: false,
    );
    final detail = detailList.isEmpty ? null : detailList.first;

    final subjectBase = (detail?.subject ?? header.subject).trim();
    final senderName = (detail?.from ?? header.from).trim();
    final sentAt = (detail?.sendDate ?? detail?.date ?? header.date).trim();

    final senderChip = detail == null
        ? _smartschoolChipFromName(senderName)
        : _smartschoolChipForSender(detail, senderName);
    final to = <RecipientChip>[];
    final cc = <RecipientChip>[];
    final bcc = <RecipientChip>[];

    if (action == ComposerPrefillAction.reply ||
        action == ComposerPrefillAction.replyAll) {
      if (senderChip != null) {
        to.add(senderChip);
      }
    }

    if (action == ComposerPrefillAction.replyAll && detail != null) {
      if (detail.replyAllToRecipients.isNotEmpty ||
          detail.replyAllCcRecipients.isNotEmpty) {
        to.addAll(
          detail.replyAllToRecipients
              .map(_smartschoolChipFromRecipient)
              .whereType<RecipientChip>(),
        );
        cc.addAll(
          detail.replyAllCcRecipients
              .map(_smartschoolChipFromRecipient)
              .whereType<RecipientChip>(),
        );
      } else {
        to.addAll(
          detail.receivers
              .map((recipient) => recipient.displayName)
              .map(_smartschoolChipFromName)
              .whereType<RecipientChip>()
              .where((chip) => chip.dedupeKey != senderChip?.dedupeKey),
        );
        cc.addAll(
          detail.ccReceivers
              .map((recipient) => recipient.displayName)
              .map(_smartschoolChipFromName)
              .whereType<RecipientChip>()
              .where((chip) => chip.dedupeKey != senderChip?.dedupeKey),
        );
      }
    }

    final attachmentNames = action == ComposerPrefillAction.forward
        ? await _smartschoolAttachmentNames(header.id)
        : const <String>[];

    final originalHtml = detail?.body ?? '';
    final plainBody = _toPlainText(originalHtml);
    final smartschoolBaseUrl = await _smartschoolBaseUrl();

    return DraftMessage(
      toRecipients: _dedupe(to),
      ccRecipients: _dedupe(cc),
      bccRecipients: _dedupe(bcc),
      subject: _prefixedSubject(subjectBase, action),
      body: await _buildPrefillDelta(
        action: action,
        from: senderName,
        date: sentAt,
        subject: subjectBase,
        originalHtml: originalHtml,
        fallbackPlainBody: plainBody,
        attachmentNames: attachmentNames,
        smartschoolBaseUrl: smartschoolBaseUrl,
        cancellationToken: cancellationToken,
        replyBody: replyBody,
      ),
    );
  }

  Future<DraftMessage> _buildOutlookDraft(
    MessageHeader header,
    ComposerPrefillAction action, {
    ComposerPrefillCancellationToken? cancellationToken,
    String? replyBody,
  }) async {
    _throwIfCanceled(cancellationToken);

    final db = ref.read(appDatabaseProvider);
    Message? local = await db.messagesDao.getMessageById(header.id);
    if (local == null || local.source != 'outlook') {
      local = await db.messagesDao.findMessage(
        source: 'outlook',
        externalId: header.id.toString(),
      );
    }

    if (local == null) {
      throw StateError('Could not resolve the selected Outlook message.');
    }

    // Refresh once so to/cc/bcc participants and attachments are available.
    await ref.read(office365MailServiceProvider).refreshMessageDetail(local.id);

    final resolved = await db.messagesDao.getMessageById(local.id) ?? local;
    final participants = await db.messagesDao.getParticipantsWithIdentity(
      resolved.id,
    );
    final attachments = await db.attachmentsDao.getAttachmentsForMessage(
      resolved.id,
    );

    final sender = participants.where((p) => p.role == 'sender').firstOrNull;
    final senderName =
        (sender != null && sender.displayName.isNotEmpty
                ? sender.displayName
                : header.from)
            .trim();
    final senderAddress = (sender != null && sender.externalId.contains('@'))
        ? sender.externalId
        : null;

    final senderChip = _emailChip(name: senderName, email: senderAddress);

    final to = <RecipientChip>[];
    final cc = <RecipientChip>[];
    final bcc = <RecipientChip>[];

    final sentMailbox = resolved.mailbox.toLowerCase() == 'sent';

    if (action == ComposerPrefillAction.reply ||
        action == ComposerPrefillAction.replyAll) {
      if (sentMailbox) {
        to.addAll(_chipsForRole(participants, 'to'));
        if (to.isEmpty) {
          to.addAll(_chipsForRole(participants, 'cc'));
        }
      } else if (senderChip != null) {
        to.add(senderChip);
      }
    }

    if (action == ComposerPrefillAction.replyAll) {
      cc.addAll(_chipsForRole(participants, 'to'));
      cc.addAll(_chipsForRole(participants, 'cc'));
      if (senderChip != null) {
        cc.removeWhere((chip) => chip.dedupeKey == senderChip.dedupeKey);
      }
      for (final primary in to) {
        cc.removeWhere((chip) => chip.dedupeKey == primary.dedupeKey);
      }
    }

    final attachmentNames = action == ComposerPrefillAction.forward
        ? attachments
              .map((a) => a.filename.trim())
              .where((n) => n.isNotEmpty)
              .toList()
        : const <String>[];

    // Body is no longer stored in DB (fetched on demand by cache controller).
    const originalHtml = '';
    const plainBody = '';

    return DraftMessage(
      toRecipients: _dedupe(to),
      ccRecipients: _dedupe(cc),
      bccRecipients: _dedupe(bcc),
      subject: _prefixedSubject(resolved.subject.trim(), action),
      body: await _buildPrefillDelta(
        action: action,
        from: senderName,
        date: resolved.receivedAt.toIso8601String(),
        subject: resolved.subject,
        originalHtml: originalHtml,
        fallbackPlainBody: plainBody,
        attachmentNames: attachmentNames,
        cancellationToken: cancellationToken,
        replyBody: replyBody,
      ),
    );
  }

  List<RecipientChip> _chipsForRole(
    List<ParticipantIdentity> participants,
    String role,
  ) {
    return participants
        .where((p) => p.role == role)
        .map(
          (p) => _emailChip(
            name: p.displayName,
            email: p.externalId.contains('@') ? p.externalId : null,
          ),
        )
        .whereType<RecipientChip>()
        .toList(growable: false);
  }

  RecipientChip? _smartschoolChipFromName(String rawName) {
    final name = rawName.trim();
    if (name.isEmpty) return null;

    return RecipientChip(
      displayName: name,
      endpoint: RecipientEndpoint(
        kind: RecipientEndpointKind.smartschool,
        value: name,
        label: RecipientEndpointLabel.smartschool,
      ),
      source: RecipientChipSource.smartschoolRemote,
    );
  }

  RecipientChip? _smartschoolChipFromRecipient(
    SmartschoolMessageRecipient recipient,
  ) {
    final name = recipient.displayName.trim();
    if (name.isEmpty) return null;

    return RecipientChip(
      displayName: name,
      endpoint: RecipientEndpoint(
        kind: RecipientEndpointKind.smartschool,
        value: recipient.userId?.toString() ?? name,
        label: RecipientEndpointLabel.smartschool,
        externalId: recipient.ssId?.toString(),
      ),
      source: RecipientChipSource.smartschoolRemote,
      sourceIdentityKey: recipient.userId != null
          ? 'user:${recipient.userId}'
          : null,
    );
  }

  RecipientChip? _smartschoolChipForSender(
    SmartschoolMessageDetail detail,
    String senderName,
  ) {
    final normalizedSender = senderName.trim().toLowerCase();
    if (normalizedSender.isNotEmpty) {
      for (final recipient in detail.replyAllToRecipients) {
        if (recipient.displayName.trim().toLowerCase() == normalizedSender) {
          return _smartschoolChipFromRecipient(recipient);
        }
      }
    }
    return _smartschoolChipFromName(senderName);
  }

  SmartschoolBoxType _smartschoolBoxTypeForHeader(MessageHeader header) {
    switch (header.realBox.trim().toLowerCase()) {
      case 'draft':
        return SmartschoolBoxType.draft;
      case 'scheduled':
        return SmartschoolBoxType.scheduled;
      case 'sent':
        return SmartschoolBoxType.sent;
      case 'trash':
        return SmartschoolBoxType.trash;
      case 'inbox':
      default:
        return SmartschoolBoxType.inbox;
    }
  }

  RecipientChip? _emailChip({required String name, String? email}) {
    final normalizedEmail = (email ?? '').trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return null;
    }

    final displayName = name.trim().isEmpty ? normalizedEmail : name.trim();

    return RecipientChip(
      displayName: displayName,
      endpoint: RecipientEndpoint(
        kind: RecipientEndpointKind.email,
        value: normalizedEmail,
        label: RecipientEndpointLabel.work,
        externalId: normalizedEmail,
      ),
      source: RecipientChipSource.office365Remote,
    );
  }

  Future<List<String>> _smartschoolAttachmentNames(int messageId) async {
    final attachments = await ref
        .read(smartschoolMessagesProvider.notifier)
        .listAttachments(messageId);
    return attachments
        .map((attachment) => attachment.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  List<RecipientChip> _dedupe(List<RecipientChip> chips) {
    final seen = <String>{};
    final unique = <RecipientChip>[];
    for (final chip in chips) {
      if (seen.add(chip.dedupeKey)) {
        unique.add(chip);
      }
    }
    return unique;
  }

  String _prefixedSubject(String subject, ComposerPrefillAction action) {
    final normalized = subject.trim();
    return switch (action) {
      ComposerPrefillAction.reply ||
      ComposerPrefillAction.replyAll => _prefixIfMissing(normalized, 'Re:'),
      ComposerPrefillAction.forward => _prefixIfMissing(normalized, 'Fwd:'),
    };
  }

  String _prefixIfMissing(String subject, String prefix) {
    if (subject.isEmpty) {
      return '$prefix (no subject)';
    }

    final lc = subject.toLowerCase();
    if (lc.startsWith('${prefix.toLowerCase()} ')) {
      return subject;
    }
    return '$prefix $subject';
  }

  Future<List<Map<String, dynamic>>> _buildPrefillDelta({
    required ComposerPrefillAction action,
    required String from,
    required String date,
    required String subject,
    required String originalHtml,
    required String fallbackPlainBody,
    required List<String> attachmentNames,
    String smartschoolBaseUrl = '',
    ComposerPrefillCancellationToken? cancellationToken,
    String? replyBody,
  }) async {
    _throwIfCanceled(cancellationToken);

    final sender = from.trim().isEmpty ? 'Unknown sender' : from.trim();
    final sentDate = _formatReadableDate(date);
    final cleanSubject = subject.trim().isEmpty
        ? '(no subject)'
        : subject.trim();
    final ops = <Map<String, dynamic>>[];

    final authoredBody = replyBody?.trim() ?? '';
    if (authoredBody.isNotEmpty) {
      for (final line in authoredBody.split('\n')) {
        if (line.isNotEmpty) {
          ops.add({'insert': line});
        }
        ops.add({'insert': '\n'});
      }
    }

    void addText(String text, {Map<String, dynamic>? attributes}) {
      if (text.isEmpty) {
        return;
      }
      final op = <String, dynamic>{'insert': text};
      if (attributes != null && attributes.isNotEmpty) {
        op['attributes'] = attributes;
      }
      ops.add(op);
    }

    void addNewLine({Map<String, dynamic>? attributes}) {
      addText('\n', attributes: attributes);
    }

    void addLine(String text, {Map<String, dynamic>? lineAttributes}) {
      addText(text);
      addNewLine(attributes: lineAttributes);
    }

    if (action == ComposerPrefillAction.forward) {
      addNewLine();
      addLine('---------- Forwarded message ----------');
      addLine('From: $sender');
      addLine('Date: $sentDate');
      addLine('Subject: $cleanSubject');

      if (attachmentNames.isNotEmpty) {
        addLine('Attachments:');
        for (final name in attachmentNames) {
          addLine('- $name');
        }
      }

      addNewLine();
      ops.addAll(
        _htmlToDelta(
          originalHtml,
          quoteBlock: false,
          fallbackPlainText: fallbackPlainBody,
          smartschoolBaseUrl: smartschoolBaseUrl,
        ),
      );

      return _ensureTrailingNewline(ops);
    }

    addNewLine();
    addNewLine();
    final aiQuote = await ref
        .read(aiReplyQuoteServiceProvider)
        .summarizeReplyQuote(
          from: sender,
          date: sentDate,
          subject: cleanSubject,
          fallbackPlainText: fallbackPlainBody,
          originalHtml: originalHtml,
          smartschoolBaseUrl: smartschoolBaseUrl,
          isCanceled: () => cancellationToken?.isCanceled ?? false,
        );
    _throwIfCanceled(cancellationToken);

    if (aiQuote != null) {
      addLine('$sender replied. This is the take-away so far:');
      addNewLine();
      ops.addAll(_replyQuoteSummaryToDelta(aiQuote));
      return _ensureTrailingNewline(ops);
    }

    addLine('On $sentDate, $sender wrote:');
    addNewLine();

    ops.addAll(
      _htmlToDelta(
        originalHtml,
        quoteBlock: true,
        fallbackPlainText: fallbackPlainBody,
        smartschoolBaseUrl: smartschoolBaseUrl,
      ),
    );

    return _ensureTrailingNewline(ops);
  }

  void _throwIfCanceled(ComposerPrefillCancellationToken? token) {
    if (token?.isCanceled ?? false) {
      throw const ComposerPrefillCanceledException();
    }
  }

  List<Map<String, dynamic>> _replyQuoteSummaryToDelta(
    ReplyQuoteSummary summary,
  ) {
    final ops = <Map<String, dynamic>>[];

    void addQuotedLine(
      String text, {
      bool boldEntireLine = false,
      bool boldPrefixBeforeColon = false,
    }) {
      final trimmed = text.trim();
      if (trimmed.isNotEmpty) {
        if (boldEntireLine) {
          ops.add({
            'insert': trimmed,
            'attributes': <String, dynamic>{'bold': true},
          });
        } else if (boldPrefixBeforeColon) {
          final idx = trimmed.indexOf(':');
          if (idx > 0 && idx <= 40) {
            final prefix = trimmed.substring(0, idx + 1);
            final remainder = trimmed.substring(idx + 1).trimLeft();
            ops.add({
              'insert': prefix,
              'attributes': <String, dynamic>{'bold': true},
            });
            if (remainder.isNotEmpty) {
              ops.add({'insert': ' $remainder'});
            }
          } else {
            ops.add({'insert': trimmed});
          }
        } else {
          ops.add({'insert': trimmed});
        }
      }
      ops.add({
        'insert': '\n',
        'attributes': <String, dynamic>{'blockquote': true},
      });
    }

    for (final line in summary.effectiveSummaryLines) {
      addQuotedLine(line, boldPrefixBeforeColon: true);
    }

    if (summary.actionItems.isNotEmpty) {
      addQuotedLine('Action items:', boldEntireLine: true);
      for (final item in summary.actionItems) {
        addQuotedLine('- $item');
      }
    }

    if (summary.carryOverContext.trim().isNotEmpty) {
      addQuotedLine(
        'Thread context: ${summary.carryOverContext.trim()}',
        boldPrefixBeforeColon: true,
      );
    }

    if (summary.links.isNotEmpty) {
      addQuotedLine('Relevant links:', boldEntireLine: true);
      for (final link in summary.links) {
        final url = (link['url'] ?? '').trim();
        final label = (link['label'] ?? '').trim();
        if (url.isEmpty) {
          continue;
        }
        ops.add({'insert': '- '});
        if (label.isNotEmpty && label != url) {
          ops.add({'insert': '$label: '});
        }
        ops.add({
          'insert': url,
          'attributes': <String, dynamic>{'link': url},
        });
        ops.add({
          'insert': '\n',
          'attributes': <String, dynamic>{'blockquote': true},
        });
      }
    }

    if (summary.images.isNotEmpty) {
      addQuotedLine('Relevant images:', boldEntireLine: true);
      for (final image in summary.images) {
        final url = (image['url'] ?? '').trim();
        final label = (image['label'] ?? '').trim();
        if (url.isEmpty) {
          continue;
        }
        ops.add({
          'insert': <String, dynamic>{'image': url},
        });
        ops.add({
          'insert': '\n',
          'attributes': <String, dynamic>{'blockquote': true},
        });
        if (label.isNotEmpty) {
          addQuotedLine(label);
        }
      }
    }

    return ops;
  }

  List<Map<String, dynamic>> _htmlToDelta(
    String rawHtml, {
    required bool quoteBlock,
    required String fallbackPlainText,
    String smartschoolBaseUrl = '',
  }) {
    final html = rawHtml.trim();
    if (html.isEmpty) {
      return _plainTextToDelta(fallbackPlainText, quoteBlock: quoteBlock);
    }

    final converter = HtmlToDelta();
    final normalizedHtml = _normalizeHtmlForDeltaConversion(html);
    final delta = converter.convert(normalizedHtml);
    final convertedRaw = delta
        .toJson()
        .map((raw) => Map<String, dynamic>.from(raw))
        .toList(growable: false);
    final converted = _sanitizeUnsupportedEmbeds(
      convertedRaw,
      quoteBlock: quoteBlock,
      smartschoolBaseUrl: smartschoolBaseUrl,
    );

    if (converted.isEmpty) {
      return _plainTextToDelta(fallbackPlainText, quoteBlock: quoteBlock);
    }

    if (!quoteBlock) {
      return _ensureTrailingNewline(converted);
    }

    return _ensureTrailingNewline(_applyBlockquoteToOps(converted));
  }

  String _normalizeHtmlForDeltaConversion(String html) {
    return html
        .replaceAll(
          RegExp(r'<\s*/?\s*(tbody|thead|tfoot)\b[^>]*>', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'<\s*table\b[^>]*>', caseSensitive: false), '<div>')
        .replaceAll(
          RegExp(r'<\s*/\s*table\s*>', caseSensitive: false),
          '</div><br />',
        )
        .replaceAll(RegExp(r'<\s*tr\b[^>]*>', caseSensitive: false), '<div>')
        .replaceAll(
          RegExp(r'<\s*/\s*tr\s*>', caseSensitive: false),
          '</div><br />',
        )
        .replaceAll(RegExp(r'<\s*td\b[^>]*>', caseSensitive: false), '<div>')
        .replaceAll(RegExp(r'<\s*/\s*td\s*>', caseSensitive: false), '</div>');
  }

  /// Adds `blockquote: true` to every line-ending newline in [ops].
  ///
  /// [HtmlToDelta] often embeds `\n` inside text insert strings (for `<p>` /
  /// `<div>` elements) instead of emitting a standalone `\n` op.  Only
  /// `<blockquote>` HTML elements produce standalone `\n` ops that already
  /// carry `blockquote: true`.  This method splits every text op at its `\n`
  /// characters so that all line terminators receive the blockquote attribute.
  List<Map<String, dynamic>> _applyBlockquoteToOps(
    List<Map<String, dynamic>> ops,
  ) {
    final result = <Map<String, dynamic>>[];

    for (final op in ops) {
      final insert = op['insert'];

      // Non-string inserts (embeds) and strings without newlines pass through.
      if (insert is! String || !insert.contains('\n')) {
        result.add(op);
        continue;
      }

      // Split at every \n.  Each text segment keeps the original inline
      // attributes; each newline gets blockquote (only block-level format).
      final attrs = op['attributes'] as Map?;
      final parts = insert.split('\n');

      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (part.isNotEmpty) {
          final textOp = <String, dynamic>{'insert': part};
          if (attrs != null && attrs.isNotEmpty) {
            textOp['attributes'] = Map<String, dynamic>.from(attrs);
          }
          result.add(textOp);
        }
        // Emit a blockquote newline between every pair of segments.
        if (i < parts.length - 1) {
          final newlineAttrs = <String, dynamic>{
            ..._lineAttributesForNewline(insert == '\n' ? attrs : null),
            'blockquote': true,
          };
          result.add({'insert': '\n', 'attributes': newlineAttrs});
        }
      }
    }

    return result;
  }

  Map<String, dynamic> _lineAttributesForNewline(Map? attrs) {
    if (attrs == null || attrs.isEmpty) {
      return const <String, dynamic>{};
    }

    const lineAttributeKeys = <String>{
      'align',
      'blockquote',
      'code-block',
      'direction',
      'header',
      'indent',
      'list',
    };

    final filtered = <String, dynamic>{};
    for (final entry in attrs.entries) {
      final key = entry.key.toString();
      if (lineAttributeKeys.contains(key)) {
        filtered[key] = entry.value;
      }
    }
    return filtered;
  }

  List<Map<String, dynamic>> _sanitizeUnsupportedEmbeds(
    List<Map<String, dynamic>> ops, {
    required bool quoteBlock,
    required String smartschoolBaseUrl,
  }) {
    final sanitized = <Map<String, dynamic>>[];

    for (final op in ops) {
      final insert = op['insert'];
      if (insert is String) {
        sanitized.add(op);
        continue;
      }

      if (insert is Map) {
        final normalizedEmbed = _normalizeEmbedInsert(
          insert,
          smartschoolBaseUrl: smartschoolBaseUrl,
        );
        if (normalizedEmbed != null) {
          sanitized.add({...op, 'insert': normalizedEmbed});
          continue;
        }

        final embedText = _embedFallbackText(insert);
        if (embedText.isNotEmpty) {
          sanitized.add({'insert': embedText});
          sanitized.add({
            'insert': '\n',
            if (quoteBlock) 'attributes': <String, dynamic>{'blockquote': true},
          });
        }
        continue;
      }

      // Unknown operation payload; drop it to keep the editor stable.
    }

    return sanitized;
  }

  Map<String, dynamic>? _normalizeEmbedInsert(
    Map<dynamic, dynamic> insert, {
    required String smartschoolBaseUrl,
  }) {
    if (insert.containsKey('image')) {
      final source = _resolveSmartschoolImageUrl(
        (insert['image'] ?? '').toString().trim(),
        smartschoolBaseUrl,
      );
      if (source.isEmpty) {
        return null;
      }
      return <String, dynamic>{'image': source};
    }

    if (insert.containsKey('video')) {
      final source = (insert['video'] ?? '').toString().trim();
      if (source.isEmpty) {
        return null;
      }
      return <String, dynamic>{'video': source};
    }

    return null;
  }

  String _embedFallbackText(Map<dynamic, dynamic> insert) {
    if (insert.containsKey('formula')) {
      final source = (insert['formula'] ?? '').toString().trim();
      return source.isEmpty ? '[Formula]' : '[Formula] $source';
    }

    final kind = insert.keys.isNotEmpty
        ? insert.keys.first.toString()
        : 'Embed';
    return '[$kind]';
  }

  Future<String> _smartschoolBaseUrl() async {
    try {
      final settings = await ref.read(smartschoolSettingsProvider.future);
      return _normalizeBaseUrl(settings.url);
    } catch (_) {
      return '';
    }
  }

  String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final parsed = Uri.tryParse(withScheme);
    if (parsed == null || parsed.host.isEmpty) {
      return '';
    }

    return Uri(
      scheme: parsed.scheme.isEmpty ? 'https' : parsed.scheme,
      host: parsed.host,
    ).toString();
  }

  String _resolveSmartschoolImageUrl(String source, String smartschoolBaseUrl) {
    final value = source.trim();
    if (value.isEmpty) {
      return value;
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }

    if (value.startsWith('/public/')) {
      if (smartschoolBaseUrl.isEmpty) {
        return value;
      }
      return '$smartschoolBaseUrl$value';
    }

    return value;
  }

  List<Map<String, dynamic>> _ensureTrailingNewline(
    List<Map<String, dynamic>> ops,
  ) {
    if (ops.isEmpty) {
      return const [
        {'insert': '\n'},
      ];
    }

    final last = ops.last['insert'];
    if (last is String && last.endsWith('\n')) {
      return ops;
    }

    return [
      ...ops,
      {'insert': '\n'},
    ];
  }

  List<Map<String, dynamic>> _plainTextToDelta(
    String text, {
    bool quoteBlock = false,
  }) {
    final source = text.trim();
    if (source.isEmpty) {
      return const [
        {'insert': '\n'},
      ];
    }

    final lines = source.split('\n');
    final ops = <Map<String, dynamic>>[];
    for (final line in lines) {
      if (line.isNotEmpty) {
        ops.add({'insert': line});
      }
      ops.add({
        'insert': '\n',
        if (quoteBlock) 'attributes': <String, dynamic>{'blockquote': true},
      });
    }

    return ops;
  }

  String _toPlainText(String raw) {
    if (raw.trim().isEmpty) {
      return '';
    }

    final withBreaks = raw
        .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(
            r'</\s*(p|div|h[1-6]|blockquote|tr)\s*>',
            caseSensitive: false,
          ),
          '\n',
        )
        .replaceAll(RegExp(r'<\s*li[^>]*>', caseSensitive: false), '\n- ')
        .replaceAll(RegExp(r'</\s*li\s*>', caseSensitive: false), '\n');

    final decoded = withBreaks
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    final lines = decoded
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trimRight())
        .toList(growable: false);

    final compacted = <String>[];
    var previousBlank = false;
    for (final line in lines) {
      final isBlank = line.trim().isEmpty;
      if (isBlank) {
        if (!previousBlank) {
          compacted.add('');
        }
        previousBlank = true;
      } else {
        compacted.add(line.trimLeft());
        previousBlank = false;
      }
    }

    while (compacted.isNotEmpty && compacted.first.isEmpty) {
      compacted.removeAt(0);
    }
    while (compacted.isNotEmpty && compacted.last.isEmpty) {
      compacted.removeLast();
    }

    return compacted.join('\n');
  }

  String _formatReadableDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return 'Unknown date';
    }

    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      return text;
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[parsed.month - 1];
    final day = parsed.day.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');

    return '$day $month ${parsed.year} $hour:$minute';
  }
}

final composerPrefillServiceProvider = Provider<ComposerPrefillService>(
  ComposerPrefillService.new,
);
