part of 'chat_view.dart';

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
