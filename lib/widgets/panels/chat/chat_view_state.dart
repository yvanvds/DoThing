part of 'chat_view.dart';

class _ChatViewState extends ConsumerState<ChatView> {
  @override
  Widget build(BuildContext context) {
    final chatController = ref.watch(chatControllerProvider);
    final aiState = ref.watch(aiChatControllerProvider);
    final aiStateData = aiState.asData?.value;
    final settings =
        ref.watch(aiSettingsProvider).asData?.value ?? const AiSettings();
    final selectedPreset = _chatModelPresetFromStorage(
      settings.chatModelPreset,
    );

    final selectedModel = switch (selectedPreset) {
      _ChatModelPreset.complex => settings.complexModel,
      _ChatModelPreset.defaultModel => settings.fastModel,
      _ChatModelPreset.cheap => settings.cheapModel,
    };

    return Column(
      children: [
        _AiStatusBar(
          aiState: aiState,
          onCancel: aiStateData?.canCancel == true
              ? () => ref
                    .read(aiChatControllerProvider.notifier)
                    .cancelCurrentResponse()
              : null,
          onRetry: aiStateData?.canRetry == true
              ? () => ref
                    .read(aiChatControllerProvider.notifier)
                    .retryLastFailed()
              : null,
        ),
        Expanded(
          child: SelectionArea(
            child: Chat(
              currentUserId: currentUserId,
              chatController: chatController,
              resolveUser: resolveUser,
              onMessageSend: (text) => _handleSend(text, selectedModel),
              theme: ChatTheme.fromThemeData(Theme.of(context)),
              builders: Builders(
                textMessageBuilder:
                    (
                      context,
                      message,
                      index, {
                      required isSentByMe,
                      groupStatus,
                    }) {
                      if (isSentByMe) {
                        return SimpleTextMessage(
                          message: message,
                          index: index,
                        );
                      }

                      return _MarkdownTextMessage(message: message);
                    },
                composerBuilder: (context) {
                  return _ChatComposer(
                    selectedPreset: selectedPreset,
                    complexModel: settings.complexModel,
                    defaultModel: settings.fastModel,
                    cheapModel: settings.cheapModel,
                    onSend: (text) => _handleSend(text, selectedModel),
                    onPresetChanged: (value) {
                      ref
                          .read(aiSettingsProvider.notifier)
                          .updateSettings(
                            settings.copyWith(
                              chatModelPreset: _chatModelPresetToStorage(value),
                            ),
                          );
                    },
                    onNewChat: () {
                      ref
                          .read(aiChatControllerProvider.notifier)
                          .startNewConversation();
                    },
                  );
                },
              ),
              timeFormat: DateFormat(''),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSend(String text, String selectedModel) {
    ref
        .read(aiChatControllerProvider.notifier)
        .sendUserMessage(text, modelOverride: selectedModel);
  }
}
