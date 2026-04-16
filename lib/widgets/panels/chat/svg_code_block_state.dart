part of 'chat_view.dart';

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
