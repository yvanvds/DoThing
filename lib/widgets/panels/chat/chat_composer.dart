part of 'chat_view.dart';

class _ChatComposer extends ConsumerStatefulWidget {
  const _ChatComposer({
    required this.selectedPreset,
    required this.complexModel,
    required this.defaultModel,
    required this.cheapModel,
    required this.onPresetChanged,
    required this.onNewChat,
    required this.onSend,
  });

  final _ChatModelPreset selectedPreset;
  final String complexModel;
  final String defaultModel;
  final String cheapModel;
  final ValueChanged<_ChatModelPreset> onPresetChanged;
  final VoidCallback onNewChat;
  final ValueChanged<String> onSend;

  @override
  ConsumerState<_ChatComposer> createState() => _ChatComposerState();
}
