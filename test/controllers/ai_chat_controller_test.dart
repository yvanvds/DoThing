import 'dart:async';

import 'package:do_thing/controllers/ai/ai_chat_controller.dart';
import 'package:do_thing/controllers/ai/ai_settings_controller.dart';
import 'package:do_thing/controllers/status_controller.dart';
import 'package:do_thing/models/ai/ai_chat_models.dart';
import 'package:do_thing/models/ai/ai_settings.dart';
import 'package:do_thing/providers/database_provider.dart';
import 'package:do_thing/services/ai/ai_chat_transport.dart';
import 'package:do_thing/services/ai/openai_chat_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAiSettingsController extends AiSettingsController {
  _FakeAiSettingsController({required this.settings, this.apiKey});

  final AiSettings settings;
  final String? apiKey;

  @override
  Future<AiSettings> build() async => settings;

  @override
  Future<String?> readApiKey() async => apiKey;
}

class _FakeAiTransport implements AiChatTransport {
  _FakeAiTransport({required this.onStreamCompletion});

  final Stream<AiStreamEvent> Function(AiCompletionRequest request)
  onStreamCompletion;
  final List<AiCompletionRequest> requests = [];

  @override
  Stream<AiStreamEvent> streamCompletion({
    required String apiKey,
    required String baseUrl,
    required AiCompletionRequest request,
  }) {
    requests.add(request);
    return onStreamCompletion(request);
  }

  @override
  Future<void> testConnection({
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {}
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('AiChatController', () {
    test('sendUserMessage fails fast when API key is missing', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final transport = _FakeAiTransport(
        onStreamCompletion: (_) => const Stream.empty(),
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          aiSettingsProvider.overrideWith(
            () => _FakeAiSettingsController(
              settings: const AiSettings(hasApiKey: false),
              apiKey: null,
            ),
          ),
          aiChatTransportProvider.overrideWithValue(transport),
        ],
      );
      addTearDown(container.dispose);

      await container.read(aiChatControllerProvider.future);
      await container
          .read(aiChatControllerProvider.notifier)
          .sendUserMessage('Need help');

      final state = container.read(aiChatControllerProvider).requireValue;
      expect(state.streamingState, AiStreamingState.failed);
      expect(state.lastError?.code, 'missing_api_key');
      expect(state.lastFailedPrompt, 'Need help');
      expect(transport.requests, isEmpty);
      expect(
        container.read(statusProvider).last.message,
        'OpenAI API key is missing in settings.',
      );
    });

    test(
      'sendUserMessage persists streamed assistant output and completes',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final transport = _FakeAiTransport(
          onStreamCompletion: (_) => Stream.fromIterable([
            const AiStreamEvent.delta('Hello'),
            const AiStreamEvent.done(providerMessageId: 'provider-1'),
          ]),
        );

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            aiSettingsProvider.overrideWith(
              () => _FakeAiSettingsController(
                settings: const AiSettings(hasApiKey: true),
                apiKey: 'token-1',
              ),
            ),
            aiChatTransportProvider.overrideWithValue(transport),
          ],
        );
        addTearDown(container.dispose);

        final initial = await container.read(aiChatControllerProvider.future);
        await container
            .read(aiChatControllerProvider.notifier)
            .sendUserMessage('Hi AI');
        await _flushAsyncWork();

        final state = container.read(aiChatControllerProvider).requireValue;
        expect(initial.conversationId, 'default');
        expect(state.streamingState, AiStreamingState.completed);
        expect(state.isBusy, isFalse);

        final messages = await AiChatRepository(db).listMessages('default');
        expect(messages, hasLength(2));
        expect(messages.first.role, AiMessageRole.user);
        expect(messages.first.content, 'Hi AI');
        expect(messages.last.role, AiMessageRole.assistant);
        expect(messages.last.content, 'Hello');
        expect(messages.last.status, AiMessageStatus.completed);
        expect(messages.last.providerMessageId, 'provider-1');
        expect(transport.requests.single.messages.single.content, 'Hi AI');
        expect(
          container.read(statusProvider).last.message,
          'AI response complete.',
        );
      },
    );

    test('cancelCurrentResponse marks assistant message canceled', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final streamController = StreamController<AiStreamEvent>();
      addTearDown(streamController.close);

      final transport = _FakeAiTransport(
        onStreamCompletion: (_) => streamController.stream,
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          aiSettingsProvider.overrideWith(
            () => _FakeAiSettingsController(
              settings: const AiSettings(hasApiKey: true),
              apiKey: 'token-2',
            ),
          ),
          aiChatTransportProvider.overrideWithValue(transport),
        ],
      );
      addTearDown(container.dispose);

      await container.read(aiChatControllerProvider.future);
      await container
          .read(aiChatControllerProvider.notifier)
          .sendUserMessage('Stop soon');
      streamController.add(const AiStreamEvent.delta('partial'));
      await _flushAsyncWork();

      await container
          .read(aiChatControllerProvider.notifier)
          .cancelCurrentResponse();

      final state = container.read(aiChatControllerProvider).requireValue;
      expect(state.streamingState, AiStreamingState.canceled);
      expect(state.isBusy, isFalse);

      final messages = await AiChatRepository(db).listMessages('default');
      expect(messages, hasLength(2));
      expect(messages.last.status, AiMessageStatus.canceled);
      expect(messages.last.content, 'partial');
      expect(
        container.read(statusProvider).last.message,
        'AI response canceled.',
      );
    });
  });
}
