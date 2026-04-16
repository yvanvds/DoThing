import 'dart:async';

import 'package:flutter_chat_core/flutter_chat_core.dart' as chat;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/chat_controller.dart';
import '../../controllers/status_controller.dart';
import '../../models/ai/ai_chat_models.dart';
import '../../providers/database_provider.dart';
import '../../services/ai/ai_chat_transport.dart';
import '../../services/ai/openai_chat_service.dart';
import 'ai_settings_controller.dart';

class AiChatUiState {
  const AiChatUiState({
    required this.conversationId,
    this.streamingState = AiStreamingState.idle,
    this.isBusy = false,
    this.lastError,
    this.lastFailedPrompt,
    this.activeAssistantMessageId,
  });

  final String conversationId;
  final AiStreamingState streamingState;
  final bool isBusy;
  final AiErrorState? lastError;
  final String? lastFailedPrompt;
  final String? activeAssistantMessageId;

  bool get canCancel =>
      streamingState == AiStreamingState.waiting ||
      streamingState == AiStreamingState.active;

  bool get canRetry =>
      lastFailedPrompt != null &&
      lastFailedPrompt!.trim().isNotEmpty &&
      !canCancel;

  AiChatUiState copyWith({
    AiStreamingState? streamingState,
    bool? isBusy,
    AiErrorState? lastError,
    bool clearError = false,
    String? lastFailedPrompt,
    bool clearFailedPrompt = false,
    String? activeAssistantMessageId,
    bool clearActiveAssistantMessageId = false,
  }) {
    return AiChatUiState(
      conversationId: conversationId,
      streamingState: streamingState ?? this.streamingState,
      isBusy: isBusy ?? this.isBusy,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastFailedPrompt: clearFailedPrompt
          ? null
          : (lastFailedPrompt ?? this.lastFailedPrompt),
      activeAssistantMessageId: clearActiveAssistantMessageId
          ? null
          : (activeAssistantMessageId ?? this.activeAssistantMessageId),
    );
  }
}

class AiChatController extends AsyncNotifier<AiChatUiState> {
  StreamSubscription<AiStreamEvent>? _streamSubscription;
  String _streamingBuffer = '';
  String? _activeAssistantId;
  String? _activePrompt;
  chat.Message? _activeAssistantUiMessage;
  int _idSequence = 0;

  @override
  Future<AiChatUiState> build() async {
    final repository = ref.read(aiChatRepositoryProvider);
    await repository.deleteEmptyConversations();
    final conversationId = await repository.createConversation();

    final chatController = ref.read(chatControllerProvider);
    await chatController.setMessages(const <chat.Message>[], animated: false);

    ref.onDispose(_cancelActiveStream);

    return AiChatUiState(conversationId: conversationId);
  }

  Future<void> sendUserMessage(
    String text, {
    AiRequestContext? context,
    String? modelOverride,
  }) async {
    final prompt = text.trim();
    if (prompt.isEmpty) {
      return;
    }

    if (_streamSubscription != null) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.warning, 'A response is already streaming.');
      return;
    }

    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final settings = await ref.read(aiSettingsProvider.future);
    final resolvedModel = modelOverride?.trim().isNotEmpty == true
        ? modelOverride!.trim()
        : settings.model;
    final apiKey = await ref.read(aiSettingsProvider.notifier).readApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      final error = const AiErrorState(
        code: 'missing_api_key',
        message: 'OpenAI API key is missing in settings.',
      );
      state = AsyncData(
        current.copyWith(
          streamingState: AiStreamingState.failed,
          isBusy: false,
          lastError: error,
          lastFailedPrompt: prompt,
        ),
      );
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, error.message);
      return;
    }

    final repository = ref.read(aiChatRepositoryProvider);
    final conversationId = current.conversationId;

    final hasMessages = await repository.hasMessages(conversationId);
    if (!hasMessages) {
      await repository.updateConversationTitle(
        conversationId,
        _conversationTitleFromPrompt(prompt),
      );
    }

    final userMessage = AiChatMessageModel(
      id: _nextId('u'),
      conversationId: conversationId,
      role: AiMessageRole.user,
      content: prompt,
      createdAt: DateTime.now(),
      status: AiMessageStatus.completed,
      requestContext: context,
    );
    await repository.upsertMessage(userMessage);

    final userUi = _toUiMessage(userMessage);
    await ref.read(chatControllerProvider).insertMessage(userUi);

    final assistantMessage = AiChatMessageModel(
      id: _nextId('a'),
      conversationId: conversationId,
      role: AiMessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      status: AiMessageStatus.waiting,
      parentMessageId: userMessage.id,
    );
    await repository.upsertMessage(assistantMessage);

    final assistantUi = _toUiMessage(assistantMessage);
    await ref.read(chatControllerProvider).insertMessage(assistantUi);

    _activeAssistantId = assistantMessage.id;
    _activePrompt = prompt;
    _activeAssistantUiMessage = assistantUi;
    _streamingBuffer = '';

    state = AsyncData(
      current.copyWith(
        streamingState: AiStreamingState.waiting,
        isBusy: true,
        clearError: true,
        clearFailedPrompt: true,
        activeAssistantMessageId: assistantMessage.id,
      ),
    );

    final history = await repository.listMessages(conversationId);
    final requestMessages = history
        .where(
          (m) =>
              m.status != AiMessageStatus.failed &&
              m.status != AiMessageStatus.canceled &&
              m.content.trim().isNotEmpty,
        )
        .toList(growable: false);

    final transport = ref.read(aiChatTransportProvider);
    final stream = transport.streamCompletion(
      apiKey: apiKey,
      baseUrl: settings.baseUrl,
      request: AiCompletionRequest(
        model: resolvedModel,
        stream: settings.streamingEnabled,
        messages: requestMessages,
        context: context,
      ),
    );

    _streamSubscription = stream.listen(
      (event) => _handleStreamEvent(event, conversationId),
      onError: (error, _) {
        _markFailed(
          conversationId,
          prompt,
          AiErrorState(
            code: 'stream_error',
            message: 'Streaming failed: $error',
            retryable: true,
          ),
        );
      },
      onDone: () {
        _streamSubscription = null;
      },
      cancelOnError: true,
    );
  }

  Future<void> retryLastFailed() async {
    final current = state.asData?.value;
    final failedPrompt = current?.lastFailedPrompt?.trim();
    if (failedPrompt == null || failedPrompt.isEmpty) {
      return;
    }
    await sendUserMessage(failedPrompt);
  }

  Future<void> startNewConversation() async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    await _cancelStreamForConversationSwitch();

    final repository = ref.read(aiChatRepositoryProvider);
    await _pruneIfEmpty(current.conversationId);
    final conversationId = await repository.createConversation();
    await _openConversation(conversationId);

    ref
        .read(statusProvider.notifier)
        .add(StatusEntryType.success, 'Started a new conversation.');
  }

  Future<void> openConversation(String conversationId) async {
    final current = state.asData?.value;
    if (current == null || current.conversationId == conversationId) {
      return;
    }

    await _cancelStreamForConversationSwitch();
    await _pruneIfEmpty(current.conversationId);
    await _openConversation(conversationId);
  }

  Future<void> deleteConversation(String conversationId) async {
    final repository = ref.read(aiChatRepositoryProvider);
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    await _cancelStreamForConversationSwitch();
    await repository.deleteConversation(conversationId);

    if (current.conversationId == conversationId) {
      final nextConversationId = await repository.createConversation();
      await _openConversation(nextConversationId);
    }

    ref
        .read(statusProvider.notifier)
        .add(StatusEntryType.success, 'Conversation deleted.');
  }

  Future<void> cancelCurrentResponse() async {
    await _cancelActiveStream();
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final assistantId = _activeAssistantId;
    if (assistantId == null) {
      return;
    }

    final repository = ref.read(aiChatRepositoryProvider);
    await repository.updateMessageState(
      id: assistantId,
      content: _streamingBuffer,
      status: AiMessageStatus.canceled,
    );

    state = AsyncData(
      current.copyWith(
        streamingState: AiStreamingState.canceled,
        isBusy: false,
        clearActiveAssistantMessageId: true,
      ),
    );

    ref
        .read(statusProvider.notifier)
        .add(StatusEntryType.warning, 'AI response canceled.');

    _activeAssistantId = null;
    _activePrompt = null;
    _activeAssistantUiMessage = null;
  }

  Future<void> _handleStreamEvent(
    AiStreamEvent event,
    String conversationId,
  ) async {
    if (event.error != null) {
      await _markFailed(conversationId, _activePrompt ?? '', event.error!);
      return;
    }

    final current = state.asData?.value;
    if (current == null || _activeAssistantId == null) {
      return;
    }

    if (!event.done && event.delta.isNotEmpty) {
      _streamingBuffer += event.delta;
      await _upsertAssistantProgress(
        conversationId: conversationId,
        status: AiMessageStatus.streaming,
      );

      state = AsyncData(
        current.copyWith(
          streamingState: AiStreamingState.active,
          isBusy: true,
          clearError: true,
        ),
      );
      return;
    }

    if (event.done) {
      await _upsertAssistantProgress(
        conversationId: conversationId,
        status: AiMessageStatus.completed,
        providerMessageId: event.providerMessageId,
      );

      state = AsyncData(
        current.copyWith(
          streamingState: AiStreamingState.completed,
          isBusy: false,
          clearError: true,
          clearActiveAssistantMessageId: true,
        ),
      );

      _activeAssistantId = null;
      _activePrompt = null;
      _activeAssistantUiMessage = null;
      _streamSubscription = null;
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.success, 'AI response complete.');
    }
  }

  Future<void> _upsertAssistantProgress({
    required String conversationId,
    required AiMessageStatus status,
    String? providerMessageId,
  }) async {
    final assistantId = _activeAssistantId;
    final oldUi = _activeAssistantUiMessage;
    if (assistantId == null || oldUi == null) {
      return;
    }

    final repository = ref.read(aiChatRepositoryProvider);
    await repository.updateMessageState(
      id: assistantId,
      content: _streamingBuffer,
      status: status,
      providerMessageId: providerMessageId,
    );

    final newUi = chat.Message.text(
      id: assistantId,
      authorId: systemUserId,
      createdAt: oldUi.createdAt,
      text: _streamingBuffer,
    );

    await ref.read(chatControllerProvider).updateMessage(oldUi, newUi);
    _activeAssistantUiMessage = newUi;
  }

  Future<void> _markFailed(
    String conversationId,
    String failedPrompt,
    AiErrorState error,
  ) async {
    final current = state.asData?.value;
    final assistantId = _activeAssistantId;

    if (assistantId != null) {
      await ref
          .read(aiChatRepositoryProvider)
          .updateMessageState(
            id: assistantId,
            content: _streamingBuffer,
            status: AiMessageStatus.failed,
            error: error,
          );
    }

    await _cancelActiveStream();

    if (current != null) {
      final retryPrompt = failedPrompt.trim().isNotEmpty
          ? failedPrompt
          : (current.lastFailedPrompt ?? failedPrompt);

      state = AsyncData(
        current.copyWith(
          streamingState: AiStreamingState.failed,
          isBusy: false,
          lastError: error,
          lastFailedPrompt: retryPrompt,
          clearActiveAssistantMessageId: true,
        ),
      );
    }

    ref
        .read(statusProvider.notifier)
        .add(StatusEntryType.error, 'AI request failed: ${error.message}');

    _activeAssistantId = null;
    _activePrompt = null;
    _activeAssistantUiMessage = null;
  }

  Future<void> _cancelActiveStream() async {
    final sub = _streamSubscription;
    _streamSubscription = null;
    if (sub != null) {
      await sub.cancel();
    }
  }

  Future<void> _cancelStreamForConversationSwitch() async {
    if (_activeAssistantId != null) {
      await cancelCurrentResponse();
      return;
    }

    await _cancelActiveStream();
  }

  Future<void> _pruneIfEmpty(String conversationId) async {
    final repository = ref.read(aiChatRepositoryProvider);
    final isEmpty = !await repository.hasMessages(conversationId);
    if (isEmpty) {
      await repository.deleteConversation(conversationId);
    }
  }

  Future<void> _openConversation(String conversationId) async {
    final repository = ref.read(aiChatRepositoryProvider);
    final messages = await repository.listMessages(conversationId);
    final uiMessages = messages.map(_toUiMessage).toList(growable: false);

    await ref
        .read(chatControllerProvider)
        .setMessages(uiMessages, animated: false);

    final current = state.asData?.value;
    if (current == null) {
      state = AsyncData(AiChatUiState(conversationId: conversationId));
      return;
    }

    state = AsyncData(
      AiChatUiState(
        conversationId: conversationId,
        streamingState: AiStreamingState.idle,
        isBusy: false,
      ),
    );
  }

  String _conversationTitleFromPrompt(String prompt) {
    final compact = prompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return 'New chat';
    }

    if (compact.length <= 48) {
      return compact;
    }

    return '${compact.substring(0, 45)}...';
  }

  chat.Message _toUiMessage(AiChatMessageModel message) {
    final authorId = switch (message.role) {
      AiMessageRole.system => systemUserId,
      AiMessageRole.user => currentUserId,
      AiMessageRole.assistant => systemUserId,
    };

    return chat.Message.text(
      id: message.id,
      authorId: authorId,
      createdAt: message.createdAt,
      text: message.content,
    );
  }

  String _nextId(String prefix) {
    _idSequence++;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_idSequence';
  }
}

final aiChatControllerProvider =
    AsyncNotifierProvider<AiChatController, AiChatUiState>(
      AiChatController.new,
    );
