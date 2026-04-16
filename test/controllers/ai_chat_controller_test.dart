import 'dart:async';

import 'package:do_thing/controllers/ai/ai_chat_controller.dart';
import 'package:do_thing/controllers/ai/ai_settings_controller.dart';
import 'package:do_thing/controllers/status_controller.dart';
import 'package:do_thing/models/ai/ai_chat_models.dart';
import 'package:do_thing/models/ai/ai_settings.dart';
import 'package:do_thing/providers/database_provider.dart';
import 'package:do_thing/services/ai/ai_chat_transport.dart';
import 'package:do_thing/services/ai/openai_chat_service.dart';
import 'package:drift/drift.dart' show Value;
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

    test('sendUserMessage uses modelOverride when provided', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final transport = _FakeAiTransport(
        onStreamCompletion: (_) => Stream.fromIterable([
          const AiStreamEvent.delta('ok'),
          const AiStreamEvent.done(providerMessageId: 'provider-override'),
        ]),
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          aiSettingsProvider.overrideWith(
            () => _FakeAiSettingsController(
              settings: const AiSettings(
                hasApiKey: true,
                complexModel: 'gpt-5.4',
              ),
              apiKey: 'token-override',
            ),
          ),
          aiChatTransportProvider.overrideWithValue(transport),
        ],
      );
      addTearDown(container.dispose);

      await container.read(aiChatControllerProvider.future);
      await container
          .read(aiChatControllerProvider.notifier)
          .sendUserMessage('Use cheap model', modelOverride: 'gpt-5.4-nano');
      await _flushAsyncWork();

      expect(transport.requests, hasLength(1));
      expect(transport.requests.single.model, 'gpt-5.4-nano');
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
        expect(initial.conversationId, startsWith('conv-'));
        expect(state.streamingState, AiStreamingState.completed);
        expect(state.isBusy, isFalse);

        final messages = await AiChatRepository(
          db,
        ).listMessages(initial.conversationId);
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

    test('startNewConversation creates a new active session', () async {
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
              settings: const AiSettings(hasApiKey: true),
              apiKey: 'token-2',
            ),
          ),
          aiChatTransportProvider.overrideWithValue(transport),
        ],
      );
      addTearDown(container.dispose);

      final initialState = await container.read(
        aiChatControllerProvider.future,
      );

      await container
          .read(aiChatControllerProvider.notifier)
          .startNewConversation();

      final nextState = container.read(aiChatControllerProvider).requireValue;
      expect(nextState.conversationId, isNot(initialState.conversationId));

      // The old (empty) conversation is pruned on switch, so only the new one survives.
      final conversations = await AiChatRepository(db).listConversations();
      expect(conversations, hasLength(1));
      expect(conversations.first.id, nextState.conversationId);
    });

    test('deleteConversation keeps an active conversation available', () async {
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
              settings: const AiSettings(hasApiKey: true),
              apiKey: 'token-2',
            ),
          ),
          aiChatTransportProvider.overrideWithValue(transport),
        ],
      );
      addTearDown(container.dispose);

      final initialState = await container.read(
        aiChatControllerProvider.future,
      );
      final initialConversationId = initialState.conversationId;

      await container
          .read(aiChatControllerProvider.notifier)
          .deleteConversation(initialConversationId);

      final nextState = container.read(aiChatControllerProvider).requireValue;
      expect(nextState.conversationId, isNot(initialConversationId));

      final conversations = await AiChatRepository(db).listConversations();
      expect(conversations, hasLength(1));
      expect(conversations.single.id, nextState.conversationId);
    });

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

      final conversationId = container
          .read(aiChatControllerProvider)
          .requireValue
          .conversationId;
      final messages = await AiChatRepository(db).listMessages(conversationId);
      expect(messages, hasLength(2));
      expect(messages.last.status, AiMessageStatus.canceled);
      expect(messages.last.content, 'partial');
      expect(
        container.read(statusProvider).last.message,
        'AI response canceled.',
      );
    });

    test('build() removes pre-existing empty conversations on startup', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // Pre-populate with two empty conversations (simulating previous restarts).
      final repo = AiChatRepository(db);
      await repo.createConversation(title: 'Orphan 1');
      await repo.createConversation(title: 'Orphan 2');

      final transport = _FakeAiTransport(
        onStreamCompletion: (_) => const Stream.empty(),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          aiSettingsProvider.overrideWith(
            () => _FakeAiSettingsController(
              settings: const AiSettings(hasApiKey: true),
              apiKey: 'token-x',
            ),
          ),
          aiChatTransportProvider.overrideWithValue(transport),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(aiChatControllerProvider.future);

      final conversations = await repo.listConversations();
      // Only the fresh conversation created by build() should remain.
      expect(conversations, hasLength(1));
      expect(conversations.single.id, state.conversationId);
    });

    test('openConversation prunes the current empty conversation', () async {
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
              settings: const AiSettings(hasApiKey: true),
              apiKey: 'token-x',
            ),
          ),
          aiChatTransportProvider.overrideWithValue(transport),
        ],
      );
      addTearDown(container.dispose);

      // Start: one empty conversation (the initial one).
      final initialState = await container.read(
        aiChatControllerProvider.future,
      );
      final emptyId = initialState.conversationId;

      // Seed a second conversation with a known distinct ID and a message.
      const secondId = 'conv-test-has-content';
      final repo = AiChatRepository(db);
      await db.aiChatDao.upsertConversation(
        AiConversationsCompanion(
          id: const Value(secondId),
          title: const Value('Has content'),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await repo.upsertMessage(
        AiChatMessageModel(
          id: 'msg-seed',
          conversationId: secondId,
          role: AiMessageRole.user,
          content: 'Seed message',
          createdAt: DateTime.now(),
          status: AiMessageStatus.completed,
        ),
      );

      // Open the second conversation — the empty initial one should be pruned.
      await container
          .read(aiChatControllerProvider.notifier)
          .openConversation(secondId);

      final nextState = container.read(aiChatControllerProvider).requireValue;
      expect(nextState.conversationId, secondId);

      final conversations = await repo.listConversations();
      expect(conversations.any((c) => c.id == emptyId), isFalse);
      expect(conversations.any((c) => c.id == secondId), isTrue);
    });

    test('sendUserMessage sets title from first message content', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final transport = _FakeAiTransport(
        onStreamCompletion: (_) => Stream.fromIterable([
          const AiStreamEvent.delta('Sure!'),
          const AiStreamEvent.done(providerMessageId: 'p2'),
        ]),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          aiSettingsProvider.overrideWith(
            () => _FakeAiSettingsController(
              settings: const AiSettings(hasApiKey: true),
              apiKey: 'token-x',
            ),
          ),
          aiChatTransportProvider.overrideWithValue(transport),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(aiChatControllerProvider.future);
      await container
          .read(aiChatControllerProvider.notifier)
          .sendUserMessage('Tell me about Dart');
      await _flushAsyncWork();

      final conversations = await AiChatRepository(db).listConversations();
      final conv = conversations.singleWhere(
        (c) => c.id == initial.conversationId,
      );
      expect(conv.title, 'Tell me about Dart');
    });

    test(
      'sendUserMessage does not overwrite title on second message',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        int callCount = 0;
        final transport = _FakeAiTransport(
          onStreamCompletion: (_) {
            callCount++;
            return Stream.fromIterable([
              AiStreamEvent.delta('Reply $callCount'),
              const AiStreamEvent.done(providerMessageId: 'px'),
            ]);
          },
        );
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            aiSettingsProvider.overrideWith(
              () => _FakeAiSettingsController(
                settings: const AiSettings(hasApiKey: true),
                apiKey: 'token-x',
              ),
            ),
            aiChatTransportProvider.overrideWithValue(transport),
          ],
        );
        addTearDown(container.dispose);

        final initial = await container.read(aiChatControllerProvider.future);
        final notifier = container.read(aiChatControllerProvider.notifier);

        await notifier.sendUserMessage('First prompt');
        await _flushAsyncWork();
        await notifier.sendUserMessage('Second prompt — different');
        await _flushAsyncWork();

        final conversations = await AiChatRepository(db).listConversations();
        final conv = conversations.singleWhere(
          (c) => c.id == initial.conversationId,
        );
        // Title must reflect the first message, not the second.
        expect(conv.title, 'First prompt');
      },
    );
  });
}
