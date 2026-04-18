import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_all/webview_all.dart';

typedef HtmlPreprocessor = String Function(String html);

class MessageHtmlBodyView extends StatefulWidget {
  const MessageHtmlBodyView({
    required this.html,
    this.preprocessHtml,
    super.key,
  });

  final String html;
  final HtmlPreprocessor? preprocessHtml;

  @override
  State<MessageHtmlBodyView> createState() => _MessageHtmlBodyViewState();
}

class _MessageHtmlBodyViewState extends State<MessageHtmlBodyView> {
  late final WebViewController _controller;
  Object? _webViewError;

  String _processedHtml() {
    return widget.preprocessHtml?.call(widget.html) ?? widget.html;
  }

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
    unawaited(_loadHtml(_processedHtml()));
  }

  @override
  void didUpdateWidget(covariant MessageHtmlBodyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html ||
        oldWidget.preprocessHtml != widget.preprocessHtml) {
      unawaited(_loadHtml(_processedHtml()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_webViewError != null) {
      final colorScheme = Theme.of(context).colorScheme;
      final source = _processedHtml();
      final fallbackBody = _plainText(source);
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
                  fallbackBody.isEmpty ? source : fallbackBody,
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
