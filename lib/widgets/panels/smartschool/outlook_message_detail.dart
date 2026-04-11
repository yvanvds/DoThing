import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_all/webview_all.dart';

import '../../../controllers/status_controller.dart';
import '../../../providers/database_provider.dart';
import '../../../services/office365_mail_service.dart';
import '../../../services/smartschool_messages_service.dart';

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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to load Outlook detail: ${snapshot.error}',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          );
        }

        final payload = snapshot.data;
        if (payload == null) {
          return const Center(
            child: Text('Outlook message not found in local database.'),
          );
        }

        final row = payload.row;
        final sender = payload.participants
            .where((participant) => participant.role == 'sender')
            .map((participant) => participant.displayNameSnapshot)
            .cast<String>()
            .firstWhere(
              (value) => value.trim().isNotEmpty,
              orElse: () => widget.header.from,
            );

        final bodyRaw = row.bodyRaw?.trim() ?? '';
        final bodyText = row.bodyText?.trim() ?? '';
        final bodyFormat = (row.bodyFormat ?? '').toLowerCase();
        final hasHtml = bodyRaw.isNotEmpty && bodyFormat.contains('html');
        final plainBody = bodyText.isNotEmpty
            ? bodyText
            : (bodyRaw.isNotEmpty
                  ? bodyRaw
                  : '(No body available yet. Click refresh.)');

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                        : () => _refreshFromOutlook(row.id),
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
              ),
              const SizedBox(height: 12),
              Text(row.subject, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'From: $sender',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Received: ${_formatDate(row.receivedAt)}',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (payload.attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: payload.attachments.map((attachment) {
                      final visual = _attachmentVisual(attachment, colorScheme);
                      final isDownloading = _downloadingAttachmentIds.contains(
                        attachment.id,
                      );
                      final isDownloaded = (attachment.localPath ?? '')
                          .trim()
                          .isNotEmpty;
                      final icon = isDownloading
                          ? null
                          : isDownloaded
                          ? Icons.open_in_new
                          : Icons.download_outlined;

                      return ActionChip(
                        onPressed: isDownloading
                            ? null
                            : () => _openOrDownloadAttachment(
                                context,
                                row.id,
                                attachment,
                              ),
                        avatar: isDownloading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: visual.tint.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Icon(
                                    icon ?? visual.icon,
                                    size: 14,
                                    color: visual.tint,
                                  ),
                                ),
                              ),
                        label: Text(
                          attachment.filename,
                          overflow: TextOverflow.ellipsis,
                        ),
                        tooltip: isDownloaded
                            ? 'Open attachment'
                            : 'Download attachment',
                      );
                    }).toList(),
                  ),
                ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surface,
                  ),
                  child: hasHtml
                      ? _OutlookHtmlBodyView(html: bodyRaw)
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              plainBody,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
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

class _OutlookHtmlBodyView extends StatefulWidget {
  const _OutlookHtmlBodyView({required this.html});

  final String html;

  @override
  State<_OutlookHtmlBodyView> createState() => _OutlookHtmlBodyViewState();
}

class _OutlookHtmlBodyViewState extends State<_OutlookHtmlBodyView> {
  late final WebViewController _controller;
  Object? _webViewError;

  static String _wrapHtml(String body) =>
      '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <style>
    body {
      font-family: sans-serif;
      font-size: 14px;
      color: #212121;
      background: #ffffff;
      margin: 12px;
      padding: 0;
      word-wrap: break-word;
      user-select: text;
      -webkit-user-select: text;
    }
    a { color: #1565C0; }
    img { max-width: 100%; height: auto; }
    table { border-collapse: collapse; max-width: 100%; }
    td, th { padding: 4px 8px; vertical-align: top; }
  </style>
  <script>
    document.addEventListener('click', function(e) {
      var el = e.target;
      while (el && el.tagName !== 'A') { el = el.parentElement; }
      if (el && el.href && (el.href.startsWith('http://') || el.href.startsWith('https://'))) {
        e.preventDefault();
        LinkHandler.postMessage(el.href);
      }
    });
  </script>
</head>
<body>$body</body>
</html>''';

  static String _plainText(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'</(p|div|li|tr|h[1-6])>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  Future<void> _loadHtml(String html) async {
    try {
      await _controller.loadHtmlString(_wrapHtml(html));
      if (!mounted || _webViewError == null) return;
      setState(() {
        _webViewError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _webViewError = error;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'LinkHandler',
        onMessageReceived: (msg) {
          final uri = Uri.tryParse(msg.message);
          if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
            unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
          }
        },
      );
    unawaited(_loadHtml(widget.html));
  }

  @override
  void didUpdateWidget(covariant _OutlookHtmlBodyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      unawaited(_loadHtml(widget.html));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_webViewError != null) {
      final colorScheme = Theme.of(context).colorScheme;
      final fallbackBody = _plainText(widget.html);
      return Container(
        color: colorScheme.surface,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Embedded message view is unavailable on this Windows session. Showing a plain-text fallback instead.\n$_webViewError',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  fallbackBody.isEmpty ? widget.html : fallbackBody,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return WebViewWidget(controller: _controller);
  }
}
