part of 'chat_view.dart';

class _ChatQuickActionsRow extends StatelessWidget {
  const _ChatQuickActionsRow({
    required this.selectedPreset,
    required this.complexModel,
    required this.defaultModel,
    required this.cheapModel,
    required this.onPresetChanged,
    required this.onNewChat,
  });

  final _ChatModelPreset selectedPreset;
  final String complexModel;
  final String defaultModel;
  final String cheapModel;
  final ValueChanged<_ChatModelPreset> onPresetChanged;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
                color: colorScheme.surfaceContainerLowest,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_ChatModelPreset>(
                    value: selectedPreset,
                    isDense: true,
                    onChanged: (value) {
                      if (value != null) {
                        onPresetChanged(value);
                      }
                    },
                    items: _ChatModelPreset.values
                        .map((preset) {
                          return DropdownMenuItem<_ChatModelPreset>(
                            value: preset,
                            child: Text(
                              '${_chatModelPresetLabel(preset)} · ${_modelForPreset(preset)}',
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelMedium,
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              minimumSize: const Size(30, 30),
              padding: const EdgeInsets.all(4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            tooltip: 'Start a new chat',
            onPressed: onNewChat,
            icon: const Icon(Icons.add_comment_outlined, size: 14),
          ),
        ],
      ),
    );
  }

  String _modelForPreset(_ChatModelPreset preset) {
    return switch (preset) {
      _ChatModelPreset.complex => complexModel,
      _ChatModelPreset.defaultModel => defaultModel,
      _ChatModelPreset.cheap => cheapModel,
    };
  }
}
