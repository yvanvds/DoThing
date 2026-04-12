import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/status_controller.dart';
import '../../../providers/database_provider.dart';
import '../../../services/office365/office365_mail_service.dart';
import '../../../services/smartschool/smartschool_messages_controller.dart';
import 'widgets/message_html_body_view.dart';

class OutlookMessageDetailView extends ConsumerStatefulWidget {
  const OutlookMessageDetailView({required this.header, super.key});

  final SmartschoolMessageHeader header;

  @override
  ConsumerState<OutlookMessageDetailView> createState() =>
      _OutlookMessageDetailViewState();
}

class _OutlookMessageDetailViewState
    extends ConsumerState<OutlookMessageDetailView> {
  bool _refreshing = false;
  final Set<int> _downloadingAttachmentIds = <int>{};

  Future<_OutlookDetailPayload?> _load() async {
    final db = ref.read(appDatabaseProvider);
    final status = ref.read(statusProvider.notifier);

    Message? row = await db.messagesDao.getMessageById(widget.header.id);
    if (row == null || row.source != 'outlook') {
      row = await db.messagesDao.findMessage(
        source: 'outlook',
        externalId: widget.header.id.toString(),
      );
    }

    if (row == null) return null;

    var resolvedRow = row;
    var downloadedFromServer = false;

    final hasUnresolvedCid = (resolvedRow.bodyRaw ?? '').toLowerCase().contains(
      'cid:',
    );
    final hasFullBody =
        resolvedRow.detailFetchedAt != null ||
        (resolvedRow.bodyFormat?.toLowerCase().contains('html') ?? false);
    if (!hasFullBody || hasUnresolvedCid) {
      try {
        await ref
            .read(office365MailServiceProvider)
            .refreshMessageDetail(resolvedRow.id);
        resolvedRow =
            await db.messagesDao.getMessageById(resolvedRow.id) ?? resolvedRow;
        downloadedFromServer = true;
      } catch (_) {}
    }

    status.add(
      StatusEntryType.info,
      downloadedFromServer
          ? 'Outlook detail downloaded from Microsoft Graph (message ${resolvedRow.id}).'
          : 'Outlook detail loaded from local database (message ${resolvedRow.id}).',
    );

    final participants = await db.messagesDao.getParticipants(resolvedRow.id);
    final attachments = await db.attachmentsDao.getAttachmentsForMessage(
      resolvedRow.id,
    );
    return _OutlookDetailPayload(
      row: resolvedRow,
      participants: participants,
      attachments: attachments,
    );
  }

  Future<void> _refreshFromOutlook(int localMessageId) async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    try {
      await ref
          .read(office365MailServiceProvider)
          .refreshMessageDetail(localMessageId);
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _openOrDownloadAttachment(
    BuildContext context,
    int messageId,
    MessageAttachment attachment,
  ) async {
    if (_downloadingAttachmentIds.contains(attachment.id)) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _downloadingAttachmentIds.add(attachment.id);
    });

    try {
      File file;
      final cachedPath = attachment.localPath?.trim() ?? '';
      if (cachedPath.isNotEmpty) {
        final existing = File(cachedPath);
        if (await existing.exists()) {
          file = existing;
        } else {
          file = await ref
              .read(office365MailServiceProvider)
              .downloadAttachment(
                localMessageId: messageId,
                attachment: attachment,
              );
        }
      } else {
        file = await ref
            .read(office365MailServiceProvider)
            .downloadAttachment(
              localMessageId: messageId,
              attachment: attachment,
            );
      }

      final uri = Uri.file(file.path);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              opened
                  ? 'Opened ${attachment.filename}'
                  : 'Downloaded ${attachment.filename} to ${file.path}',
            ),
          ),
        );
      }
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to download attachment: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingAttachmentIds.remove(attachment.id);
        });
      }
    }
  }

  _OutlookAttachmentVisual _attachmentVisual(
    MessageAttachment attachment,
    ColorScheme colorScheme,
  ) {
    final fileName = attachment.filename.toLowerCase();
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex >= 0 ? fileName.substring(dotIndex + 1) : '';

    switch (extension) {
      case 'pdf':
        return _OutlookAttachmentVisual(
          icon: Icons.picture_as_pdf_rounded,
          tint: Colors.red.shade600,
        );
      case 'doc':
      case 'docx':
      case 'odt':
      case 'rtf':
        return _OutlookAttachmentVisual(
          icon: Icons.description_rounded,
          tint: Colors.blue.shade700,
        );
      case 'xls':
      case 'xlsx':
      case 'csv':
      case 'ods':
        return _OutlookAttachmentVisual(
          icon: Icons.table_chart_rounded,
          tint: Colors.green.shade700,
        );
      case 'ppt':
      case 'pptx':
      case 'odp':
        return _OutlookAttachmentVisual(
          icon: Icons.slideshow_rounded,
          tint: Colors.orange.shade700,
        );
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return _OutlookAttachmentVisual(
          icon: Icons.image_rounded,
          tint: Colors.purple.shade500,
        );
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return _OutlookAttachmentVisual(
          icon: Icons.archive_rounded,
          tint: Colors.brown.shade600,
        );
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
        return _OutlookAttachmentVisual(
          icon: Icons.audio_file_rounded,
          tint: Colors.teal.shade600,
        );
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return _OutlookAttachmentVisual(
          icon: Icons.movie_rounded,
          tint: Colors.deepPurple.shade400,
        );
      case 'txt':
      case 'md':
      case 'log':
        return _OutlookAttachmentVisual(
          icon: Icons.notes_rounded,
          tint: Colors.blueGrey.shade600,
        );
      case 'dart':
      case 'py':
      case 'js':
      case 'ts':
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
      case 'html':
      case 'css':
        return _OutlookAttachmentVisual(
          icon: Icons.code_rounded,
          tint: colorScheme.primary,
        );
      default:
        return _OutlookAttachmentVisual(
          icon: Icons.insert_drive_file_rounded,
          tint: colorScheme.primary,
        );
    }
  }

  Future<void> _dumpOutlookDebugInfo(_OutlookDetailPayload payload) async {
    final db = ref.read(appDatabaseProvider);
    final row = payload.row;

    final contactIds = payload.participants
        .map((p) => p.contactId)
        .whereType<int>()
        .toSet();

    final contacts = <int, Contact>{};
    final identitiesByContact = <int, List<ContactIdentity>>{};
    for (final cId in contactIds) {
      final contact = await db.contactsDao.getContactById(cId);
      if (contact != null) contacts[cId] = contact;
      identitiesByContact[cId] = await (db.select(
        db.contactIdentities,
      )..where((t) => t.contactId.equals(cId))).get();
    }

    final bodyRaw = row.bodyRaw ?? '';
    final buf = StringBuffer()
      ..writeln('========== Outlook Message Debug ==========')
      ..writeln('--- DB Message Row ---')
      ..writeln(
        jsonEncode({
          'id': row.id,
          'source': row.source,
          'externalId': row.externalId,
          'mailbox': row.mailbox,
          'subject': row.subject,
          'isRead': row.isRead,
          'isArchived': row.isArchived,
          'isDeleted': row.isDeleted,
          'hasAttachments': row.hasAttachments,
          'sentAt': row.sentAt?.toIso8601String(),
          'receivedAt': row.receivedAt.toIso8601String(),
          'detailFetchedAt': row.detailFetchedAt?.toIso8601String(),
          'bodyFormat': row.bodyFormat,
          'rawHeaderJson': row.rawHeaderJson,
          'rawDetailJson': row.rawDetailJson,
          'body_length': bodyRaw.length,
          'body_preview': bodyRaw.length > 300
              ? bodyRaw.substring(0, 300)
              : bodyRaw,
        }),
      )
      ..writeln('--- Participants (${payload.participants.length}) ---');

    for (final p in payload.participants) {
      buf.writeln(
        jsonEncode({
          'id': p.id,
          'messageId': p.messageId,
          'contactId': p.contactId,
          'contactIdentityId': p.contactIdentityId,
          'role': p.role,
          'position': p.position,
          'displayNameSnapshot': p.displayNameSnapshot,
          'addressSnapshot': p.addressSnapshot,
        }),
      );
    }

    for (final cId in contactIds) {
      final contact = contacts[cId];
      final identities = identitiesByContact[cId] ?? [];
      buf
        ..writeln('--- Contact $cId ---')
        ..writeln(
          jsonEncode(
            contact != null
                ? {
                    'id': contact.id,
                    'displayName': contact.displayName,
                    'primaryAvatarUrl': contact.primaryAvatarUrl,
                    'kind': contact.kind,
                    'isStub': contact.isStub,
                    'createdAt': contact.createdAt.toIso8601String(),
                    'updatedAt': contact.updatedAt.toIso8601String(),
                  }
                : {'error': 'contact not found'},
          ),
        )
        ..writeln('  Identities (${identities.length}):');
      for (final identity in identities) {
        buf
          ..write('  ')
          ..writeln(
            jsonEncode({
              'id': identity.id,
              'source': identity.source,
              'externalId': identity.externalId,
              'displayNameSnapshot': identity.displayNameSnapshot,
              'avatarUrlSnapshot': identity.avatarUrlSnapshot,
              'lastSeenAt': identity.lastSeenAt.toIso8601String(),
              'rawPayloadJson': identity.rawPayloadJson,
            }),
          );
      }
    }

    buf.writeln('==========================================');
    debugPrint(buf.toString());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<_OutlookDetailPayload?>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error, colorScheme);
        }

        final payload = snapshot.data;
        if (payload == null) {
          return _buildMissingState();
        }

        return _buildLoadedState(context, payload, colorScheme);
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(Object? error, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Failed to load Outlook detail: $error',
          style: TextStyle(color: colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildMissingState() {
    return const Center(
      child: Text('Outlook message not found in local database.'),
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    _OutlookDetailPayload payload,
    ColorScheme colorScheme,
  ) {
    final row = payload.row;
    final body = _messageBody(row);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(payload, row.id, colorScheme),
          const SizedBox(height: 12),
          Text(row.subject, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'From: ${_senderName(payload)}',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Received: ${_formatDate(row.receivedAt)}',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (payload.attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildAttachmentWrap(
                context,
                payload,
                row.id,
                colorScheme,
              ),
            ),
          Expanded(child: _buildBodyPanel(body, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    _OutlookDetailPayload payload,
    int localMessageId,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Outlook',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _refreshing
              ? null
              : () => _refreshFromOutlook(localMessageId),
          icon: _refreshing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 16),
          label: Text(_refreshing ? 'Refreshing...' : 'Refresh'),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.bug_report_outlined, size: 18),
          tooltip: 'Dump debug info to console',
          visualDensity: VisualDensity.compact,
          onPressed: () => unawaited(_dumpOutlookDebugInfo(payload)),
        ),
      ],
    );
  }

  String _senderName(_OutlookDetailPayload payload) {
    return payload.participants
        .where((participant) => participant.role == 'sender')
        .map((participant) => participant.displayNameSnapshot)
        .cast<String>()
        .firstWhere(
          (value) => value.trim().isNotEmpty,
          orElse: () => widget.header.from,
        );
  }

  _MessageBodyState _messageBody(Message row) {
    final bodyRaw = row.bodyRaw?.trim() ?? '';
    final bodyText = row.bodyText?.trim() ?? '';
    final bodyFormat = (row.bodyFormat ?? '').toLowerCase();
    final hasHtml = bodyRaw.isNotEmpty && bodyFormat.contains('html');
    final plainBody = _resolvePlainBody(bodyText: bodyText, bodyRaw: bodyRaw);

    return _MessageBodyState(
      bodyRaw: bodyRaw,
      plainBody: plainBody,
      hasHtml: hasHtml,
    );
  }

  Widget _buildAttachmentWrap(
    BuildContext context,
    _OutlookDetailPayload payload,
    int localMessageId,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: payload.attachments
          .map(
            (attachment) => _buildAttachmentChip(
              context,
              attachment,
              localMessageId,
              colorScheme,
            ),
          )
          .toList(),
    );
  }

  Widget _buildAttachmentChip(
    BuildContext context,
    MessageAttachment attachment,
    int localMessageId,
    ColorScheme colorScheme,
  ) {
    final visual = _attachmentVisual(attachment, colorScheme);
    final isDownloading = _downloadingAttachmentIds.contains(attachment.id);
    final isDownloaded = (attachment.localPath ?? '').trim().isNotEmpty;
    final icon = _attachmentActionIcon(
      isDownloading: isDownloading,
      isDownloaded: isDownloaded,
    );

    return ActionChip(
      onPressed: isDownloading
          ? null
          : () =>
                _openOrDownloadAttachment(context, localMessageId, attachment),
      avatar: isDownloading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: visual.tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(icon ?? visual.icon, size: 14, color: visual.tint),
              ),
            ),
      label: Text(attachment.filename, overflow: TextOverflow.ellipsis),
      tooltip: isDownloaded ? 'Open attachment' : 'Download attachment',
    );
  }

  String _resolvePlainBody({
    required String bodyText,
    required String bodyRaw,
  }) {
    if (bodyText.isNotEmpty) {
      return bodyText;
    }
    if (bodyRaw.isNotEmpty) {
      return bodyRaw;
    }
    return '(No body available yet. Click refresh.)';
  }

  IconData? _attachmentActionIcon({
    required bool isDownloading,
    required bool isDownloaded,
  }) {
    if (isDownloading) {
      return null;
    }
    if (isDownloaded) {
      return Icons.open_in_new;
    }
    return Icons.download_outlined;
  }

  Widget _buildBodyPanel(_MessageBodyState body, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surface,
      ),
      child: body.hasHtml
          ? MessageHtmlBodyView(html: body.bodyRaw)
          : Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: SelectableText(
                  body.plainBody,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime value) {
    String two(int v) => v.toString().padLeft(2, '0');
    final local = value.toLocal();
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _OutlookDetailPayload {
  const _OutlookDetailPayload({
    required this.row,
    required this.participants,
    required this.attachments,
  });

  final Message row;
  final List<MessageParticipant> participants;
  final List<MessageAttachment> attachments;
}

class _OutlookAttachmentVisual {
  const _OutlookAttachmentVisual({required this.icon, required this.tint});

  final IconData icon;
  final Color tint;
}

class _MessageBodyState {
  const _MessageBodyState({
    required this.bodyRaw,
    required this.plainBody,
    required this.hasHtml,
  });

  final String bodyRaw;
  final String plainBody;
  final bool hasHtml;
}
