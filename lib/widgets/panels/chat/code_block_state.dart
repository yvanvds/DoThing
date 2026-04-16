part of 'chat_view.dart';

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
