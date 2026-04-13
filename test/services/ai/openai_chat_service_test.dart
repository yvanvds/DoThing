import 'dart:convert';
import 'dart:io';

import 'package:do_thing/models/ai/ai_chat_models.dart';
import 'package:do_thing/services/ai/ai_chat_transport.dart';
import 'package:do_thing/services/ai/openai_chat_service.dart';
import 'package:flutter_test/flutter_test.dart';

AiCompletionRequest _request({required bool stream}) {
  return AiCompletionRequest(
    model: 'gpt-test',
    stream: stream,
    messages: [
      AiChatMessageModel(
        id: 'm1',
        conversationId: 'c1',
        role: AiMessageRole.user,
        content: 'Hello',
        createdAt: DateTime.parse('2026-04-13T12:00:00Z'),
      ),
    ],
  );
}

void main() {
  group('OpenAiChatTransport', () {
    test('returns delta then done for non-streaming responses', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((request) async {
        if (request.method == 'POST' &&
            request.uri.path == '/v1/chat/completions') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Hello back'},
                },
              ],
            }),
          );
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final transport = OpenAiChatTransport();
      final events = await transport
          .streamCompletion(
            apiKey: 'key',
            baseUrl: 'http://127.0.0.1:${server.port}/',
            request: _request(stream: false),
          )
          .toList();

      expect(events, hasLength(2));
      expect(events.first.delta, 'Hello back');
      expect(events.last.done, isTrue);
    });

    test('parses streamed SSE deltas and terminates on done', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((request) async {
        if (request.method == 'POST' &&
            request.uri.path == '/v1/chat/completions') {
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          request.response.write(
            'data: {"choices":[{"delta":{"content":"Hel"}}]}\n\n',
          );
          request.response.write(
            'data: {"choices":[{"delta":{"content":"lo"}}]}\n\n',
          );
          request.response.write('data: [DONE]\n\n');
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final transport = OpenAiChatTransport();
      final events = await transport
          .streamCompletion(
            apiKey: 'key',
            baseUrl: 'http://127.0.0.1:${server.port}',
            request: _request(stream: true),
          )
          .toList();

      expect(
        events.map((event) => event.delta).where((delta) => delta.isNotEmpty),
        ['Hel', 'lo'],
      );
      expect(events.last.done, isTrue);
    });

    test('returns provider error details for non-2xx responses', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((request) async {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'error': {'message': 'Invalid API key'},
          }),
        );
        await request.response.close();
      });

      final transport = OpenAiChatTransport();
      final events = await transport
          .streamCompletion(
            apiKey: 'bad-key',
            baseUrl: 'http://127.0.0.1:${server.port}',
            request: _request(stream: false),
          )
          .toList();

      expect(events, hasLength(1));
      expect(events.single.error?.code, 'http_401');
      expect(events.single.error?.message, 'Invalid API key');
      expect(events.single.error?.retryable, isFalse);
    });
  });
}
