import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_all/webview_all.dart';

import '../../../models/smartschool_message.dart';
import '../../../services/smartschool_messages_service.dart';
import '../../../services/smartschool_auth_service.dart';

/// Displays the full detail of a selected Smartschool message.
///
/// Fetches from cache if available, otherwise retrieves from the bridge.
/// Displays sender, subject, body, and recipient info.
class SmartschoolMessageDetailView extends ConsumerWidget {
  const SmartschoolMessageDetailView({required this.header, super.key});

  final SmartschoolMessageHeader header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(smartschoolMessageCacheProvider);
    final authNotifier = ref.read(smartschoolAuthProvider.notifier);

    // Check if already cached
    if (cache.containsKey(header.id)) {
      return _buildMessage(context, cache[header.id]!);
    }

    // Otherwise, fetch (with cache check inside)
    return FutureBuilder<SmartschoolMessageDetail>(
      future: ref
          .read(smartschoolMessageCacheProvider.notifier)
          .getOrFetch(header.id, authNotifier.bridge),
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

        return _buildMessage(context, snapshot.data!);
      },
    );
  }

  /// Build the message display.
  Widget _buildMessage(BuildContext context, SmartschoolMessageDetail msg) {
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
      ],
    );
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
</head>
<body>$body</body>
</html>''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Open links externally rather than navigating away
            if (request.url != 'about:blank') {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_wrapHtml(widget.html));
  }

  @override
  void didUpdateWidget(_HtmlBodyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _controller.loadHtmlString(_wrapHtml(widget.html));
    }
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
          errorBuilder: (_, __, ___) => _InitialsCircle(name: name),
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
