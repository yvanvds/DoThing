import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:highlight/highlight.dart' as highlight;
import 'package:url_launcher/url_launcher.dart';

import '../controllers/ai/ai_chat_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/ai/ai_chat_models.dart';

class ChatView extends ConsumerWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatController = ref.watch(chatControllerProvider);
    final aiState = ref.watch(aiChatControllerProvider);
    final aiStateData = aiState.asData?.value;

    return Column(
      children: [
        _AiStatusBar(
          aiState: aiState,
          onCancel: aiStateData?.canCancel == true
              ? () => ref
                    .read(aiChatControllerProvider.notifier)
                    .cancelCurrentResponse()
              : null,
          onRetry: aiStateData?.canRetry == true
              ? () => ref
                    .read(aiChatControllerProvider.notifier)
                    .retryLastFailed()
              : null,
        ),
        Expanded(
          child: SelectionArea(
            child: Chat(
              currentUserId: currentUserId,
              chatController: chatController,
              resolveUser: resolveUser,
              onMessageSend: (text) => _handleSend(text, ref),
              theme: ChatTheme.fromThemeData(Theme.of(context)),
              builders: Builders(
                textMessageBuilder:
                    (
                      context,
                      message,
                      index, {
                      required isSentByMe,
                      groupStatus,
                    }) {
                      if (isSentByMe) {
                        return SimpleTextMessage(
                          message: message,
                          index: index,
                        );
                      }

                      return _MarkdownTextMessage(message: message);
                    },
                composerBuilder: (context) => const Composer(sendOnEnter: true),
              ),
              timeFormat: DateFormat(''),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSend(String text, WidgetRef ref) {
    ref.read(aiChatControllerProvider.notifier).sendUserMessage(text);
  }
}

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

class _InlineCodeBuilder extends MarkdownElementBuilder {
  _InlineCodeBuilder(this._theme, this._highlighter);

  final ThemeData _theme;
  final _CodeSyntaxHighlighter _highlighter;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    dynamic element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent as String;
    final isBlock = code.contains('\n');

    if (isBlock) {
      final lang =
          ((element.attributes as Map<dynamic, dynamic>?)?['class']
                      as String? ??
                  '')
              .replaceFirst('language-', '');

      if (lang == 'svg') {
        return _SvgCodeBlock(
          code: code.trimRight(),
          theme: _theme,
          highlighter: _highlighter,
        );
      }

      return _CodeBlock(
        code: code.trimRight(),
        theme: _theme,
        highlighter: _highlighter,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          style: parentStyle,
          children: [_highlighter.format(code)],
        ),
      ),
    );
  }
}

class _SvgCodeBlock extends StatefulWidget {
  const _SvgCodeBlock({
    required this.code,
    required this.theme,
    required this.highlighter,
  });

  final String code;
  final ThemeData theme;
  final _CodeSyntaxHighlighter highlighter;

  @override
  State<_SvgCodeBlock> createState() => _SvgCodeBlockState();
}

class _SvgCodeBlockState extends State<_SvgCodeBlock> {
  bool _showCode = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.theme.colorScheme;

    final svgPreview = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: Container(
        color: colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.all(12),
        child: SvgPicture.string(widget.code, fit: BoxFit.contain),
      ),
    );

    final toolbar = Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          _CopyButton(data: widget.code, tooltip: 'Copy SVG'),
          const SizedBox(width: 4),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
            onPressed: () => setState(() => _showCode = !_showCode),
            icon: Icon(
              _showCode ? Icons.visibility_off_outlined : Icons.code_outlined,
              size: 14,
            ),
            label: Text(
              _showCode ? 'Hide code' : 'Show code',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          svgPreview,
          toolbar,
          if (_showCode)
            _CodeBlock(
              code: widget.code,
              theme: widget.theme,
              highlighter: widget.highlighter,
            ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatefulWidget {
  const _CodeBlock({
    required this.code,
    required this.theme,
    required this.highlighter,
  });

  final String code;
  final ThemeData theme;
  final _CodeSyntaxHighlighter highlighter;

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 34, 12, 12),
          child: RichText(text: widget.highlighter.format(widget.code)),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: _CopyButton(data: widget.code, tooltip: 'Copy code'),
        ),
      ],
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.data, this.tooltip, this.label});

  final String data;
  final String? tooltip;
  final String? label;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final icon = _copied ? Icons.check : Icons.content_copy_outlined;

    final Widget iconWidget = Icon(icon, size: 13, color: color);
    final Widget content = widget.label != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(width: 4),
              Text(
                widget.label!,
                style: TextStyle(fontSize: 11, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        : iconWidget;

    return Tooltip(
      message: widget.tooltip ?? 'Copy',
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          _doCopy();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: content,
        ),
      ),
    );
  }

  Future<void> _doCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.data));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }
}

class _CodeSyntaxHighlighter extends SyntaxHighlighter {
  _CodeSyntaxHighlighter(ThemeData theme)
    : _baseStyle = theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'Consolas',
        color: theme.colorScheme.onSurface,
      ),
      _styles = {
        'keyword': TextStyle(color: theme.colorScheme.primary),
        'built_in': TextStyle(color: theme.colorScheme.tertiary),
        'type': TextStyle(color: theme.colorScheme.tertiary),
        'literal': TextStyle(color: theme.colorScheme.secondary),
        'number': TextStyle(color: theme.colorScheme.secondary),
        'string': TextStyle(color: Colors.green.shade700),
        'subst': TextStyle(color: theme.colorScheme.onSurface),
        'comment': TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        'title': TextStyle(color: theme.colorScheme.primary),
        'params': TextStyle(color: theme.colorScheme.onSurface),
      };

  final TextStyle? _baseStyle;
  final Map<String, TextStyle> _styles;

  @override
  TextSpan format(String source) {
    try {
      final result = highlight.highlight.parse(source, autoDetection: true);
      return TextSpan(
        style: _baseStyle,
        children: _convert(result.nodes ?? const <highlight.Node>[]),
      );
    } catch (_) {
      return TextSpan(style: _baseStyle, text: source);
    }
  }

  List<TextSpan> _convert(List<highlight.Node> nodes) {
    final spans = <TextSpan>[];

    for (final node in nodes) {
      final className = node.className;
      if (node.value != null) {
        final style = className == null ? null : _styles[className];
        spans.add(TextSpan(text: node.value, style: style));
      }

      final children = node.children;
      if (children != null && children.isNotEmpty) {
        spans.add(
          TextSpan(
            style: className == null ? null : _styles[className],
            children: _convert(children),
          ),
        );
      }
    }

    return spans;
  }
}

class _AiStatusBar extends StatelessWidget {
  const _AiStatusBar({
    required this.aiState,
    required this.onCancel,
    required this.onRetry,
  });

  final AsyncValue<AiChatUiState> aiState;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = aiState.asData?.value;

    final label = switch (state?.streamingState) {
      AiStreamingState.waiting => 'Waiting for AI response...',
      AiStreamingState.active => 'AI is streaming...',
      AiStreamingState.completed => 'Last response completed.',
      AiStreamingState.canceled => 'Response canceled.',
      AiStreamingState.failed =>
        state?.lastError?.message ?? 'Response failed.',
      _ => 'Ready',
    };

    final color = switch (state?.streamingState) {
      AiStreamingState.failed => colorScheme.error,
      AiStreamingState.active => colorScheme.primary,
      AiStreamingState.waiting => colorScheme.primary,
      _ => colorScheme.onSurfaceVariant,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_outlined, size: 16),
            label: const Text('Retry'),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.stop_circle_outlined, size: 16),
            label: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
