import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_all/webview_all.dart';

import '../../../models/smartschool_message.dart';
import '../../../providers/database_provider.dart';
import '../../../services/smartschool_messages_service.dart';
import '../../../services/smartschool_auth_service.dart';

/// Displays the full detail of a selected Smartschool message.
///
/// Fetches from cache if available, otherwise retrieves from the bridge.
/// Displays sender, subject, body, and recipient info.
class SmartschoolMessageDetailView extends ConsumerWidget {
  const SmartschoolMessageDetailView({required this.header, super.key});

  final SmartschoolMessageHeader header;

  Future<_MessageDetailPayload> _loadPayload(
    WidgetRef ref,
    SmartschoolAuthController authNotifier,
  ) async {
    final syncRepo = ref.read(smartschoolSyncRepositoryProvider);
    final detail = await ref
        .read(smartschoolMessageCacheProvider.notifier)
        .getOrFetch(header.id, authNotifier.bridge, syncRepository: syncRepo);
    final attachments = await ref
        .read(smartschoolMessagesProvider.notifier)
        .listAttachments(header.id);
    // Persist attachment metadata to the local database.
    try {
      await syncRepo.syncAttachments(header.id, attachments);
    } catch (_) {}
    return _MessageDetailPayload(detail: detail, attachments: attachments);
  }

  Future<void> _handleAttachmentTap(
    BuildContext context,
    WidgetRef ref,
    SmartschoolAttachment attachment,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final downloaded = await ref
          .read(smartschoolMessagesProvider.notifier)
          .downloadAttachment(header.id, attachment.index);

      final encoded = downloaded.contentBase64;
      if (encoded == null || encoded.isEmpty) {
        throw StateError('No content received for attachment.');
      }

      final bytes = base64Decode(encoded);
      final file = await _saveToDownloads(downloaded.name, bytes);

      var opened = false;
      final fileUri = Uri.file(file.path);
      if (await canLaunchUrl(fileUri)) {
        opened = await launchUrl(fileUri, mode: LaunchMode.externalApplication);
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Downloaded and opened ${downloaded.name}'
                : 'Downloaded ${downloaded.name} to Downloads',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to download attachment: $e')),
      );
    }
  }

  Future<File> _saveToDownloads(String fileName, List<int> bytes) async {
    final userProfile = Platform.environment['USERPROFILE'];
    Directory targetDir;
    if (userProfile != null && userProfile.isNotEmpty) {
      final downloads = Directory('$userProfile\\Downloads');
      if (downloads.existsSync()) {
        targetDir = downloads;
      } else {
        targetDir = Directory.current;
      }
    } else {
      targetDir = Directory.current;
    }

    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final uniquePath = _buildUniquePath(targetDir.path, fileName);
    final file = File(uniquePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _buildUniquePath(String directoryPath, String fileName) {
    final safeName = fileName.trim().isEmpty ? 'attachment.bin' : fileName;
    final dotIndex = safeName.lastIndexOf('.');
    final hasExtension = dotIndex > 0 && dotIndex < safeName.length - 1;
    final baseName = hasExtension ? safeName.substring(0, dotIndex) : safeName;
    final extension = hasExtension ? safeName.substring(dotIndex) : '';

    var candidate = '$directoryPath${Platform.pathSeparator}$safeName';
    var counter = 1;
    while (File(candidate).existsSync()) {
      candidate =
          '$directoryPath${Platform.pathSeparator}$baseName ($counter)$extension';
      counter++;
    }
    return candidate;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(smartschoolMessageCacheProvider);
    final authNotifier = ref.read(smartschoolAuthProvider.notifier);

    // Check if already cached
    if (cache.containsKey(header.id)) {
      return FutureBuilder<List<SmartschoolAttachment>>(
        future: ref
            .read(smartschoolMessagesProvider.notifier)
            .listAttachments(header.id),
        builder: (context, attachmentsSnapshot) {
          if (attachmentsSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  'Error loading attachments:\n${attachmentsSnapshot.error}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            );
          }
          final attachments = attachmentsSnapshot.data ?? const [];
          return _buildMessage(context, ref, cache[header.id]!, attachments);
        },
      );
    }

    // Otherwise, fetch message + attachments.
    return FutureBuilder<_MessageDetailPayload>(
      future: _loadPayload(ref, authNotifier),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                'Error loading message:\n${snapshot.error}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No message data'));
        }

        return _buildMessage(
          context,
          ref,
          snapshot.data!.detail,
          snapshot.data!.attachments,
        );
      },
    );
  }

  /// Build the message display.
  Widget _buildMessage(
    BuildContext context,
    WidgetRef ref,
    SmartschoolMessageDetail msg,
    List<SmartschoolAttachment> attachments,
  ) {
    final textTheme = Theme.of(context).textTheme;
    // Prefer the header's fromImage (reliably populated); fall back to
    // senderPicture from the full message if available.
    final avatarUrl = header.fromImage.trim().isNotEmpty
        ? header.fromImage
        : (msg.senderPicture ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large avatar on the far left
              _DetailAvatar(imageUrl: avatarUrl, name: msg.from),
              const SizedBox(width: 12),
              // Subject + meta-box to the right, filling remaining width
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      msg.subject,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMetaBox(context, msg),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _HtmlBodyView(html: msg.body)),
        if (attachments.isNotEmpty) ...[
          const Divider(height: 1),
          _buildAttachmentsRow(context, ref, attachments),
        ],
      ],
    );
  }

  Widget _buildAttachmentsRow(
    BuildContext context,
    WidgetRef ref,
    List<SmartschoolAttachment> attachments,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: colorScheme.surface,
      child: Align(
        alignment: Alignment.centerRight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: attachments.map((attachment) {
              final visual = _attachmentVisual(attachment, colorScheme);
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _handleAttachmentTap(context, ref, attachment),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: visual.tint.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: visual.tint.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            visual.icon,
                            size: 18,
                            color: visual.tint,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                attachment.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _formatAttachmentSize(attachment),
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  _AttachmentVisual _attachmentVisual(
    SmartschoolAttachment attachment,
    ColorScheme colorScheme,
  ) {
    final fileName = attachment.name.toLowerCase();
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex >= 0 ? fileName.substring(dotIndex + 1) : '';

    switch (extension) {
      case 'pdf':
        return _AttachmentVisual(
          Icons.picture_as_pdf_rounded,
          Colors.red.shade600,
        );
      case 'doc':
      case 'docx':
      case 'odt':
      case 'rtf':
        return _AttachmentVisual(
          Icons.description_rounded,
          Colors.blue.shade700,
        );
      case 'xls':
      case 'xlsx':
      case 'csv':
      case 'ods':
        return _AttachmentVisual(
          Icons.table_chart_rounded,
          Colors.green.shade700,
        );
      case 'ppt':
      case 'pptx':
      case 'odp':
        return _AttachmentVisual(
          Icons.slideshow_rounded,
          Colors.orange.shade700,
        );
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return _AttachmentVisual(Icons.image_rounded, Colors.purple.shade500);
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return _AttachmentVisual(Icons.archive_rounded, Colors.brown.shade600);
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
        return _AttachmentVisual(
          Icons.audio_file_rounded,
          Colors.teal.shade600,
        );
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return _AttachmentVisual(
          Icons.movie_rounded,
          Colors.deepPurple.shade400,
        );
      case 'txt':
      case 'md':
      case 'log':
        return _AttachmentVisual(Icons.notes_rounded, Colors.blueGrey.shade600);
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
        return _AttachmentVisual(Icons.code_rounded, colorScheme.primary);
      default:
        return _AttachmentVisual(
          Icons.insert_drive_file_rounded,
          colorScheme.primary,
        );
    }
  }

  String _formatAttachmentSize(SmartschoolAttachment attachment) {
    final sizeLabel = attachment.sizeLabel;
    if (sizeLabel != null && sizeLabel.trim().isNotEmpty) {
      return sizeLabel;
    }

    final bytes = attachment.size;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Sender name/date on the left (intrinsic width), recipients on the right.
  Widget _buildMetaBox(BuildContext context, SmartschoolMessageDetail msg) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final toStr = _formatRecipients(msg.receivers);
    final ccStr = _formatRecipients(msg.ccReceivers);
    final bccStr = _formatRecipients(msg.bccReceivers);
    final hasRight = toStr != null || ccStr != null || bccStr != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sender name + date — only as wide as content
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  msg.from,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  _formatDetailDate(msg.date),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Vertical Divider between sender and recipients
          if (hasRight) ...[
            const SizedBox(width: 12),
            Container(width: 1, height: 32, color: colorScheme.outline),
            const SizedBox(width: 12),
          ],
          // To / CC / BCC column — takes remaining space
          if (hasRight) ...[
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (toStr != null)
                    SelectableText('To: $toStr', style: textTheme.bodySmall),
                  if (ccStr != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: SelectableText(
                        'CC: $ccStr',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                  if (bccStr != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: SelectableText(
                        'BCC: $bccStr',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Format an ISO-8601 date string as "Weekday, Month day hh:mm".
  String _formatDetailDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day} $h:$m';
  }

  /// Convert a dynamic receiver value (List or String) to a comma-separated
  /// string, or null if empty.
  String? _formatRecipients(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final items = value
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      return items.isEmpty ? null : items.join(', ');
    }
    if (value is String) {
      final cleaned = value.trim().replaceAll(RegExp(r'^\[|\]$'), '').trim();
      return cleaned.isEmpty ? null : cleaned;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// WebView-based body renderer
// ---------------------------------------------------------------------------

class _HtmlBodyView extends StatefulWidget {
  const _HtmlBodyView({required this.html});

  final String html;

  @override
  State<_HtmlBodyView> createState() => _HtmlBodyViewState();
}

class _HtmlBodyViewState extends State<_HtmlBodyView> {
  late final WebViewController _controller;

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
    }
    a { color: #1565C0; }
    img { max-width: 100%; height: auto; }
    table { border-collapse: collapse; }
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
      )
      ..loadHtmlString(_wrapHtml(_fixRelativeImageUrls(widget.html)));
  }

  @override
  void didUpdateWidget(_HtmlBodyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _controller.loadHtmlString(_wrapHtml(_fixRelativeImageUrls(widget.html)));
    }
  }

  /// Rewrites Smartschool relative image paths to absolute stream URLs.
  ///
  /// Input:  src="/public/{platform}/Images/{filename}/unique_id/{uid}"
  /// Output: src="https://{platform}.smartschool.be/TinyMCE/Image/stream
  ///              ?platform={platform}&filename={filename}&unique_id={uid}"
  static String _fixRelativeImageUrls(String html) {
    return html.replaceAllMapped(
      RegExp(r'src="(/public/([^/"&]+)/Images/([^/"]+)/unique_id/([^"]+))"'),
      (m) {
        final platform = _htmlDecode(m[2]!);
        final filename = _htmlDecode(m[3]!);
        final uniqueId = _htmlDecode(m[4]!);
        final newUrl =
            'https://$platform.smartschool.be/TinyMCE/Image/stream'
            '?platform=$platform&filename=$filename&unique_id=$uniqueId';
        return 'src="$newUrl"';
      },
    );
  }

  /// Decodes common HTML character entities in a URL attribute value.
  static String _htmlDecode(String input) {
    return input
        .replaceAll('&#43;', '+')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

// ---------------------------------------------------------------------------
// Private avatar widget for the detail view
// ---------------------------------------------------------------------------

class _DetailAvatar extends StatelessWidget {
  const _DetailAvatar({required this.imageUrl, required this.name});

  final String imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();
    if (trimmed.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          trimmed,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _InitialsCircle(name: name),
        ),
      );
    }
    return _InitialsCircle(name: name);
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({required this.name});

  final String name;

  String _initials() {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
    ];
    return CircleAvatar(
      radius: 26,
      backgroundColor: colors[name.hashCode.abs() % colors.length],
      child: Text(
        _initials(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _AttachmentVisual {
  const _AttachmentVisual(this.icon, this.tint);

  final IconData icon;
  final Color tint;
}

class _MessageDetailPayload {
  const _MessageDetailPayload({
    required this.detail,
    required this.attachments,
  });

  final SmartschoolMessageDetail detail;
  final List<SmartschoolAttachment> attachments;
}
