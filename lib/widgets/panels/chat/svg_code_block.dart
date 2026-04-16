part of 'chat_view.dart';

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
