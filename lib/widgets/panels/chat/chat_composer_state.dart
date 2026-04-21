part of 'chat_view.dart';

class _ChatComposerState extends ConsumerState<_ChatComposer> {
  final _key = GlobalKey();
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  late final ValueNotifier<bool> _hasTextNotifier;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _hasTextNotifier = ValueNotifier(false);
    _textController.addListener(_handleTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  @override
  void dispose() {
    _textController.removeListener(_handleTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    _hasTextNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final focusedItem = ref.watch(focusedItemMetadataProvider);
    final attachment = ref.watch(chatComposerAttachmentProvider);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        key: _key,
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachment != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: _AttachedFocusedItemChip(
                  metadata: attachment,
                  onClear: () => ref
                      .read(chatComposerAttachmentProvider.notifier)
                      .clear(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: focusedItem == null
                        ? 'Nothing focused to attach'
                        : 'Attach focused ${focusedItem.type.name}: '
                              '${focusedItem.title}',
                    onPressed: focusedItem == null
                        ? null
                        : () => ref
                              .read(chatComposerAttachmentProvider.notifier)
                              .attach(focusedItem),
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        isDense: true,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHigh.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: _hasTextNotifier,
                    builder: (context, hasText, _) {
                      return IconButton(
                        tooltip: 'Send',
                        onPressed: hasText ? _submit : null,
                        icon: const Icon(Icons.send),
                      );
                    },
                  ),
                ],
              ),
            ),
            _ChatQuickActionsRow(
              selectedPreset: widget.selectedPreset,
              complexModel: widget.complexModel,
              defaultModel: widget.defaultModel,
              cheapModel: widget.cheapModel,
              onPresetChanged: widget.onPresetChanged,
              onNewChat: widget.onNewChat,
            ),
            SizedBox(height: bottomSafeArea),
          ],
        ),
      ),
    );
  }

  void _handleTextChanged() {
    _hasTextNotifier.value = _textController.text.trim().isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _textController.clear();
    _measureHeight();
  }

  void _measureHeight() {
    if (!mounted) return;

    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    provider.Provider.of<ComposerHeightNotifier>(
      context,
      listen: false,
    ).setHeight(renderBox.size.height - bottomSafeArea);
  }
}
