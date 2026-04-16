part of 'chat_view.dart';

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
