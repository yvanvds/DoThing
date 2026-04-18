import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/composer_controller.dart';
import '../../../controllers/composer_visibility_controller.dart';
import '../../../controllers/status_controller.dart';
import '../../../providers/database_provider.dart';
import '../../../services/composer/composer_prefill_service.dart';
import '../../../services/office365/office365_mail_service.dart';
import '../../../services/office365/outlook_body_content.dart';
import '../../../services/office365/outlook_message_body_cache_controller.dart';
import '../../../services/smartschool/smartschool_messages_controller.dart';
import '../composer/prefill_summary_progress_dialog.dart';
import 'widgets/message_html_body_view.dart';

class OutlookMessageDetailView extends ConsumerStatefulWidget {
  const OutlookMessageDetailView({required this.header, super.key});

  final MessageHeader header;

  @override
  ConsumerState<OutlookMessageDetailView> createState() =>
      _OutlookMessageDetailViewState();
}

class _OutlookMessageDetailViewState
    extends ConsumerState<OutlookMessageDetailView> {
  bool _refreshing = false;
  final Set<int> _downloadingAttachmentIds = <int>{};
  late Future<_OutlookDetailPayload?> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void didUpdateWidget(covariant OutlookMessageDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.header.id != widget.header.id) {
      setState(() {
        _refreshing = false;
        _downloadingAttachmentIds.clear();
        _loadFuture = _load();
      });
    }
  }

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

    // Always refresh to ensure participants and attachments are up-to-date.
    try {
      await ref
          .read(office365MailServiceProvider)
          .refreshMessageDetail(resolvedRow.id);
      resolvedRow =
          await db.messagesDao.getMessageById(resolvedRow.id) ?? resolvedRow;
      downloadedFromServer = true;
    } catch (_) {}

    status.add(
      StatusEntryType.info,
      downloadedFromServer
          ? 'Outlook detail downloaded from Microsoft Graph (message ${resolvedRow.id}).'
          : 'Outlook detail loaded from local database (message ${resolvedRow.id}).',
    );

    final participants = await db.messagesDao.getParticipantsWithIdentity(
      resolvedRow.id,
    );
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
        // Re-run load so participants/attachments reflect the latest data.
        setState(() => _loadFuture = _load());
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
          'receivedAt': row.receivedAt.toIso8601String(),
        }),
      )
      ..writeln('--- Participants (${payload.participants.length}) ---');

    for (final p in payload.participants) {
      buf.writeln(
        jsonEncode({
          'role': p.role,
          'contactId': p.contactId,
          'displayName': p.displayName,
          'externalId': p.externalId,
          'source': p.source,
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
                    'createdAt': contact.createdAt.toIso8601String(),
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
              'displayName': identity.displayName,
              'avatarUrl': identity.avatarUrl,
              'lastSeenAt': identity.lastSeenAt.toIso8601String(),
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
    final bodyCache = ref.watch(outlookMessageBodyCacheProvider);

    return FutureBuilder<_OutlookDetailPayload?>(
      future: _loadFuture,
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

        return _buildLoadedState(context, payload, colorScheme, bodyCache);
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
    Map<int, OutlookBodyContent> bodyCache,
  ) {
    final row = payload.row;
    final body = _messageBody(bodyCache[row.id]);

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
          const Divider(height: 1),
          _buildNewMessageRow(),
        ],
      ),
    );
  }

  Widget _buildNewMessageRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () {
              ref.read(composerProvider.notifier).reset();
              ref.read(composerVisibilityProvider.notifier).open();
            },
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('New message'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
          IconButton(
            onPressed: () =>
                unawaited(_prefillComposerAction(ComposerPrefillAction.reply)),
            icon: const Icon(Icons.reply_outlined, size: 18),
            tooltip: 'Reply',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: () => unawaited(
              _prefillComposerAction(ComposerPrefillAction.replyAll),
            ),
            icon: const Icon(Icons.reply_all_outlined, size: 18),
            tooltip: 'Reply all',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: () => unawaited(
              _prefillComposerAction(ComposerPrefillAction.forward),
            ),
            icon: const Icon(Icons.forward_outlined, size: 18),
            tooltip: 'Forward',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Future<void> _prefillComposerAction(ComposerPrefillAction action) async {
    try {
      final service = ref.read(composerPrefillServiceProvider);
      final cancellationToken = ComposerPrefillCancellationToken();
      final needsSummaryOverlay =
          action == ComposerPrefillAction.reply ||
          action == ComposerPrefillAction.replyAll;

      if (!needsSummaryOverlay) {
        await service.applyFromSelected(
          action,
          cancellationToken: cancellationToken,
        );
        return;
      }

      final navigator = Navigator.of(context, rootNavigator: true);
      var dialogOpen = true;
      Object? taskError;
      StackTrace? taskStackTrace;
      final done = Completer<void>();

      unawaited(() async {
        try {
          await service.applyFromSelected(
            action,
            cancellationToken: cancellationToken,
          );
        } catch (error, stackTrace) {
          taskError = error;
          taskStackTrace = stackTrace;
        } finally {
          done.complete();
          if (dialogOpen && mounted && navigator.canPop()) {
            navigator.pop(false);
          }
        }
      }());

      final canceled =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return PrefillSummaryProgressDialog(
                onCancel: () {
                  cancellationToken.cancel();
                  Navigator.of(dialogContext, rootNavigator: true).pop(true);
                },
              );
            },
          ) ??
          false;
      dialogOpen = false;

      await done.future;

      if (canceled || taskError is ComposerPrefillCanceledException) {
        ref
            .read(statusProvider.notifier)
            .add(StatusEntryType.info, 'Reply prefill canceled.');
        return;
      }

      if (taskError != null) {
        Error.throwWithStackTrace(taskError!, taskStackTrace!);
      }
    } catch (error) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, 'Could not prefill draft: $error');
    }
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
            .where((p) => p.role == 'sender' && p.displayName.trim().isNotEmpty)
            .map((p) => p.displayName)
            .firstOrNull ??
        widget.header.from;
  }

  _MessageBodyState _messageBody(OutlookBodyContent? content) {
    if (content == null) {
      return const _MessageBodyState(
        bodyRaw: '',
        plainBody:
            '(Body not available — click Refresh to fetch from Outlook.)',
        hasHtml: false,
      );
    }
    final bodyRaw = content.raw?.trim() ?? '';
    final bodyFormat = (content.format ?? '').toLowerCase();
    return _MessageBodyState(
      bodyRaw: bodyRaw,
      plainBody: bodyRaw.isEmpty ? '(No body content.)' : bodyRaw,
      hasHtml: bodyRaw.isNotEmpty && bodyFormat.contains('html'),
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
  final List<ParticipantIdentity> participants;
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
