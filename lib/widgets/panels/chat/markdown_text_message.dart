part of 'chat_view.dart';

class _MarkdownTextMessage extends StatelessWidget {
  const _MarkdownTextMessage({required this.message});

  final TextMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final syntaxHighlighter = _CodeSyntaxHighlighter(theme);
    final safeMarkdown = _sanitizeMarkdown(message.text);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: colorScheme.surfaceContainer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MarkdownBody(
              data: safeMarkdown,
              onTapLink: (text, href, title) => _openLink(href),
              syntaxHighlighter: syntaxHighlighter,
              builders: {'code': _InlineCodeBuilder(theme, syntaxHighlighter)},
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: theme.textTheme.bodyMedium,
                code: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'Consolas',
                  color: colorScheme.onSurface,
                ),
                codeblockDecoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                blockquoteDecoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  border: Border(
                    left: BorderSide(color: colorScheme.outline, width: 3),
                  ),
                ),
                blockquotePadding: const EdgeInsets.all(10),
                listIndent: 14,
                listBulletPadding: const EdgeInsets.only(right: 4),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CopyButton(data: message.text, tooltip: 'Copy reply'),
                if (kDebugMode)
                  ...([
                    const SizedBox(width: 6),
                    _CopyButton(
                      data: message.id,
                      tooltip: message.id,
                      label: message.id,
                    ),
                  ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _sanitizeMarkdown(String input) {
    final fenceCount = RegExp(
      r'(^|\n)```',
      multiLine: true,
    ).allMatches(input).length;

    if (fenceCount.isEven) {
      return input;
    }

    return '$input\n```';
  }

  Future<void> _openLink(String? href) async {
    if (href == null || href.isEmpty) return;

    final rawUri = Uri.tryParse(href);
    final uri = (rawUri != null && rawUri.hasScheme)
        ? rawUri
        : Uri.tryParse('https://$href');
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
