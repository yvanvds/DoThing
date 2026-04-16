part of 'chat_view.dart';

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
