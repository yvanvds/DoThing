import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/executor/tool_call.dart';
import '../../agent/tools/tool_descriptor.dart';
import '../../models/ai/ai_chat_models.dart';
import 'ai_chat_transport.dart';

final aiChatTransportProvider = Provider<AiChatTransport>(
  (ref) => OpenAiChatTransport(),
);

class OpenAiChatTransport implements AiChatTransport {
  static const _requestTimeout = Duration(seconds: 60);

  @override
  Stream<AiStreamEvent> streamCompletion({
    required String apiKey,
    required String baseUrl,
    required AiCompletionRequest request,
  }) async* {
    final uri = Uri.parse('${_normalizeBaseUrl(baseUrl)}/v1/chat/completions');
    final payload = <String, Object?>{
      'model': request.model,
      'stream': request.stream,
      'messages': request.messages
          .map(_serializeMessage)
          .toList(growable: false),
      if (request.jsonObjectResponse)
        'response_format': {'type': 'json_object'},
      if (request.tools.isNotEmpty)
        'tools': request.tools.map(_serializeTool).toList(growable: false),
    };

    HttpClient? client;
    HttpClientRequest? httpRequest;

    try {
      client = HttpClient();
      httpRequest = await client.postUrl(uri).timeout(_requestTimeout);
      _applyHeaders(httpRequest, apiKey);
      httpRequest.add(utf8.encode(jsonEncode(payload)));
      final response = await httpRequest.close().timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final responseBody = await utf8.decoder.bind(response).join();
        yield AiStreamEvent.error(
          AiErrorState(
            code: 'http_${response.statusCode}',
            message: _extractErrorMessage(responseBody),
            retryable: response.statusCode >= 500,
          ),
        );
        return;
      }

      if (!request.stream) {
        final responseBody = await utf8.decoder.bind(response).join();
        final root = jsonDecode(responseBody);
        if (root is! Map<String, dynamic>) {
          yield const AiStreamEvent.error(
            AiErrorState(
              code: 'invalid_response',
              message: 'Invalid provider response payload.',
            ),
          );
          return;
        }

        final choices = root['choices'];
        final firstChoice = choices is List && choices.isNotEmpty
            ? choices.first as Map<String, dynamic>?
            : null;
        final content = firstChoice?['message'] as Map<String, dynamic>?;
        final text = (content?['content'] as String?) ?? '';
        if (text.isNotEmpty) {
          yield AiStreamEvent.delta(text);
        }

        final toolCallsRaw = content?['tool_calls'];
        if (toolCallsRaw is List) {
          for (final raw in toolCallsRaw) {
            final parsed = _parseWholeToolCall(raw);
            if (parsed != null) {
              yield AiStreamEvent.toolCall(parsed);
            }
          }
        }

        yield const AiStreamEvent.done();
        return;
      }

      final toolCallBuilders = <int, _ToolCallBuilder>{};

      final lines = response
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final rawLine in lines) {
        final event = _parseSseEventLine(rawLine);
        if (event == null) {
          continue;
        }

        if (event == '[DONE]') {
          yield* _flushToolCalls(toolCallBuilders);
          yield const AiStreamEvent.done();
          break;
        }

        final decoded = jsonDecode(event);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }

        final choices = decoded['choices'];
        if (choices is! List || choices.isEmpty) {
          continue;
        }

        final firstChoice = choices.first;
        if (firstChoice is! Map<String, dynamic>) {
          continue;
        }

        final delta = firstChoice['delta'];
        if (delta is Map<String, dynamic>) {
          final token = delta['content'];
          if (token is String && token.isNotEmpty) {
            yield AiStreamEvent.delta(token);
          }

          final toolCallsDelta = delta['tool_calls'];
          if (toolCallsDelta is List) {
            for (final chunk in toolCallsDelta) {
              _accumulateToolCall(toolCallBuilders, chunk);
            }
          }
        }

        final finishReason = firstChoice['finish_reason'];
        if (finishReason is String && finishReason.isNotEmpty) {
          yield* _flushToolCalls(toolCallBuilders);
          yield const AiStreamEvent.done();
          break;
        }
      }
    } on TimeoutException {
      yield const AiStreamEvent.error(
        AiErrorState(
          code: 'timeout',
          message: 'Request timed out while contacting OpenAI.',
          retryable: true,
        ),
      );
    } on SocketException catch (e) {
      yield AiStreamEvent.error(
        AiErrorState(
          code: 'network_error',
          message: 'Network error: ${e.message}',
          retryable: true,
        ),
      );
    } catch (e) {
      yield AiStreamEvent.error(
        AiErrorState(
          code: 'unexpected_error',
          message: 'Unexpected OpenAI error: $e',
          retryable: true,
        ),
      );
    } finally {
      httpRequest?.abort();
      client?.close(force: true);
    }
  }

  @override
  Future<void> testConnection({
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {
    final uri = Uri.parse('${_normalizeBaseUrl(baseUrl)}/v1/models');
    final client = HttpClient();

    try {
      final request = await client.getUrl(uri).timeout(_requestTimeout);
      _applyHeaders(request, apiKey);

      final response = await request.close().timeout(_requestTimeout);
      final body = await utf8.decoder.bind(response).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(_extractErrorMessage(body));
      }

      if (model.trim().isNotEmpty && !body.contains(model)) {
        throw StateError(
          'Authenticated, but model "$model" was not found in your account list.',
        );
      }
    } finally {
      client.close(force: true);
    }
  }

  Map<String, Object?> _serializeMessage(AiChatMessageModel message) {
    switch (message.role) {
      case AiMessageRole.tool:
        return <String, Object?>{
          'role': 'tool',
          'tool_call_id': message.toolCallId ?? '',
          'content': message.content,
        };
      case AiMessageRole.assistant:
        final calls = message.toolCalls;
        if (calls != null && calls.isNotEmpty) {
          return <String, Object?>{
            'role': 'assistant',
            'content': message.content,
            'tool_calls': calls
                .map(
                  (c) => <String, Object?>{
                    'id': c.id,
                    'type': 'function',
                    'function': <String, Object?>{
                      'name': c.toolName,
                      'arguments': jsonEncode(c.arguments),
                    },
                  },
                )
                .toList(growable: false),
          };
        }
        return <String, Object?>{
          'role': 'assistant',
          'content': message.content,
        };
      case AiMessageRole.system:
        return <String, Object?>{'role': 'system', 'content': message.content};
      case AiMessageRole.user:
        return <String, Object?>{'role': 'user', 'content': message.content};
    }
  }

  Map<String, Object?> _serializeTool(ToolDescriptor tool) {
    return <String, Object?>{
      'type': 'function',
      'function': <String, Object?>{
        'name': tool.name,
        'description': tool.description,
        'parameters': tool.arguments.jsonSchema,
      },
    };
  }

  void _accumulateToolCall(
    Map<int, _ToolCallBuilder> builders,
    Object? chunk,
  ) {
    if (chunk is! Map<String, dynamic>) return;
    final index = chunk['index'];
    if (index is! int) return;

    final builder = builders.putIfAbsent(index, _ToolCallBuilder.new);

    final id = chunk['id'];
    if (id is String && id.isNotEmpty) {
      builder.id = id;
    }

    final function = chunk['function'];
    if (function is Map<String, dynamic>) {
      final name = function['name'];
      if (name is String && name.isNotEmpty) {
        builder.name = name;
      }
      final argsDelta = function['arguments'];
      if (argsDelta is String) {
        builder.argumentsBuffer.write(argsDelta);
      }
    }
  }

  Stream<AiStreamEvent> _flushToolCalls(
    Map<int, _ToolCallBuilder> builders,
  ) async* {
    if (builders.isEmpty) return;
    final indices = builders.keys.toList()..sort();
    for (final i in indices) {
      final call = builders[i]!.build();
      if (call != null) {
        yield AiStreamEvent.toolCall(call);
      }
    }
    builders.clear();
  }

  ToolCall? _parseWholeToolCall(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'];
    final function = raw['function'];
    if (id is! String || function is! Map<String, dynamic>) return null;
    final name = function['name'];
    if (name is! String || name.isEmpty) return null;
    final argsRaw = function['arguments'];
    final args = _decodeToolArguments(argsRaw is String ? argsRaw : '');
    return ToolCall(id: id, toolName: name, arguments: args);
  }

  String? _parseSseEventLine(String rawLine) {
    final line = rawLine.trim();
    if (!line.startsWith('data:')) {
      return null;
    }

    final data = line.substring(5).trim();
    if (data.isEmpty) {
      return null;
    }

    return data;
  }

  static String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message;
          }
        }
      }
    } catch (_) {}

    return body.trim().isEmpty ? 'OpenAI request failed.' : body;
  }

  static void _applyHeaders(HttpClientRequest request, String apiKey) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}

Map<String, Object?> _decodeToolArguments(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const <String, Object?>{};
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      return Map<String, Object?>.from(decoded);
    }
  } catch (_) {}
  return const <String, Object?>{};
}

class _ToolCallBuilder {
  String? id;
  String? name;
  final StringBuffer argumentsBuffer = StringBuffer();

  ToolCall? build() {
    final resolvedId = id;
    final resolvedName = name;
    if (resolvedId == null || resolvedName == null || resolvedName.isEmpty) {
      return null;
    }
    return ToolCall(
      id: resolvedId,
      toolName: resolvedName,
      arguments: _decodeToolArguments(argumentsBuffer.toString()),
    );
  }
}
