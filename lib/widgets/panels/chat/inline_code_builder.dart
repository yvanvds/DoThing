part of 'chat_view.dart';

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
