import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_smartschool/flutter_smartschool.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'smartschool_tools.dart';

final _logger = Logger('smartschool_mcp.mcp_server');

class SmartschoolMcpServer {
  late SmartschoolClient _client;
  late SmartschoolTools _tools;
  int _messageId = 0;

  SmartschoolMcpServer();

  /// Main event loop: read JSON from stdin, process, write response to stdout.
  Future<void> run() async {
    _logger.info('Initializing SmartSchool client...');

    try {
      _client = await _initializeSmartschoolClient();
      _tools = SmartschoolTools(_client);
      _logger.info('SmartSchool client initialized successfully');
    } catch (e, st) {
      _logger.severe('Failed to initialize SmartSchool client', e, st);
      rethrow;
    }

    // Read and process JSON-RPC messages from stdin
    try {
      await for (final line
          in stdin.transform(Utf8Decoder()).transform(const LineSplitter())) {
        if (line.isEmpty) continue;

        try {
          final request = jsonDecode(line) as Map<String, dynamic>;
          final response = await _handleRequest(request);
          stdout.writeln(jsonEncode(response));
        } catch (e, st) {
          _logger.warning('Error processing request: $e\n$st');
          // Send error response
          final errorResponse = {
            'jsonrpc': '2.0',
            'id': _messageId++,
            'error': {
              'code': -32603,
              'message': 'Internal error',
              'data': {'error': e.toString()},
            },
          };
          stdout.writeln(jsonEncode(errorResponse));
        }
      }
    } finally {
      await _client.clearCookies();
      _logger.info('stdin closed, shutting down');
    }
  }

  /// Initialize SmartschoolClient from credentials.yml
  Future<SmartschoolClient> _initializeSmartschoolClient() async {
    // Look for credentials.yml in the parent directory
    final parentDir = Directory('..').path;
    final credentialsFile = File('$parentDir/credentials.yml');

    if (!credentialsFile.existsSync()) {
      throw Exception(
        'credentials.yml not found at ${credentialsFile.absolute.path}',
      );
    }

    final yamlContent = credentialsFile.readAsStringSync();
    final yaml = loadYaml(yamlContent) as Map;

    final username = yaml['username'] as String?;
    final password = yaml['password'] as String?;
    final mainUrl = yaml['main_url'] as String?;
    final mfa = yaml['mfa'] as String?;

    if (username == null || password == null || mainUrl == null) {
      throw Exception('Missing required credentials in credentials.yml');
    }

    final credentials = AppCredentials(
      username: username,
      password: password,
      mainUrl: mainUrl,
      mfa: mfa,
    );

    return SmartschoolClient.create(credentials);
  }

  /// Handle an incoming JSON-RPC request
  Future<Map<String, dynamic>> _handleRequest(
    Map<String, dynamic> request,
  ) async {
    final id = request['id'];
    final method = request['method'] as String?;

    _messageId = (id is int) ? id + 1 : _messageId + 1;

    if (method == null) {
      return _errorResponse(id, -32600, 'Invalid Request');
    }

    try {
      return await _dispatchMethod(method, request, id);
    } catch (e, st) {
      _logger.warning('Error handling method $method', e, st);
      return _errorResponse(id, -32603, 'Internal error: ${e.toString()}');
    }
  }

  /// Dispatch to the appropriate handler
  Future<Map<String, dynamic>> _dispatchMethod(
    String method,
    Map<String, dynamic> request,
    dynamic id,
  ) async {
    switch (method) {
      case 'initialize':
        return _handleInitialize(id);

      case 'tools/list':
        return _handleListTools(id);

      case 'tools/call':
        final params = request['params'] as Map<String, dynamic>?;
        return _handleCallTool(params, id);

      default:
        return _errorResponse(id, -32601, 'Method not found: $method');
    }
  }

  /// Handle the initialize request
  Map<String, dynamic> _handleInitialize(dynamic id) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'protocolVersion': '2024-11-05',
        'capabilities': {'tools': {}},
        'serverInfo': {'name': 'smartschool-researcher', 'version': '0.1.0'},
      },
    };
  }

  /// List available tools
  Map<String, dynamic> _handleListTools(dynamic id) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {'tools': _tools.getAvailableTools()},
    };
  }

  /// Call a specific tool
  Future<Map<String, dynamic>> _handleCallTool(
    Map<String, dynamic>? params,
    dynamic id,
  ) async {
    if (params == null) {
      return _errorResponse(id, -32602, 'Missing params');
    }

    final toolName = params['name'] as String?;
    final toolParams = params['arguments'] as Map<String, dynamic>? ?? {};

    if (toolName == null) {
      return _errorResponse(id, -32602, 'Missing tool name');
    }

    try {
      final result = await _tools.callTool(toolName, toolParams);
      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': {
          'content': [
            {'type': 'text', 'text': result},
          ],
        },
      };
    } catch (e) {
      return _errorResponse(
        id,
        -32603,
        'Tool execution failed: ${e.toString()}',
      );
    }
  }

  /// Create an error response
  Map<String, dynamic> _errorResponse(dynamic id, int code, String message) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': code, 'message': message},
    };
  }
}

/// Wrapper to read lines from stdin
extension on Stream<String> {
  // Helper for line splitting
}
