import 'dart:async';
import 'dart:convert';

import 'package:py_engine_desktop/py_engine_desktop.dart';

import '../models/smartschool_message.dart';

/// Low-level JSON-line protocol bridge to the Python smartschool process.
///
/// Each command is a JSON object sent on a single line to the process's stdin.
/// Each response is a JSON object received on a single line from stdout.
class SmartschoolBridge {
  SmartschoolBridge(this._script) {
    _stdoutSub = _script.stdout.listen(_onStdout);
    _stderrSub = _script.stderr.listen(_onStderr);

    // Handle unexpected process termination.
    _script.exitCode.then(_onProcessExit);
  }

  final PythonScript _script;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;

  int _nextId = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final List<String> _stderrLog = [];

  /// Stderr output collected from the Python process (for debugging).
  List<String> get stderrLog => List.unmodifiable(_stderrLog);

  // ---------------------------------------------------------------------------
  // Internal protocol handling
  // ---------------------------------------------------------------------------

  void _onStdout(String line) {
    if (line.trim().isEmpty) return;
    try {
      final data = jsonDecode(line) as Map<String, dynamic>;
      final id = data['id'] as int?;
      if (id != null && _pending.containsKey(id)) {
        _pending.remove(id)!.complete(data);
      }
    } catch (_) {
      // Non-JSON output – treat as debug noise.
      _stderrLog.add('[stdout] $line');
    }
  }

  void _onStderr(String line) {
    _stderrLog.add(line);
  }

  void _onProcessExit(int code) {
    final error = SmartschoolBridgeException(
      'Python process exited with code $code',
    );
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pending.clear();
  }

  /// Send a command and wait for the matching response.
  Future<Map<String, dynamic>> send(
    String action, [
    Map<String, dynamic> params = const {},
  ]) {
    final id = ++_nextId;
    final command = <String, dynamic>{'action': action, 'id': id, ...params};
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _script.process.stdin.writeln(jsonEncode(command));
    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('Bridge timed out for action "$action"');
      },
    );
  }

  /// Validate the response – throws on error.
  Map<String, dynamic> _check(Map<String, dynamic> response) {
    if (response.containsKey('error')) {
      final errorType = response['error_type'] ?? 'PythonError';
      throw SmartschoolBridgeException('$errorType: ${response['error']}');
    }
    return response;
  }

  // ---------------------------------------------------------------------------
  // Typed commands
  // ---------------------------------------------------------------------------

  /// Verify the bridge process is alive.
  Future<bool> ping() async {
    final res = await send('ping');
    return res['pong'] == true;
  }

  /// Verify that required Python packages are importable.
  Future<List<String>> checkPackages() async {
    final res = _check(await send('check_packages'));
    return List<String>.from(res['missing'] ?? []);
  }

  /// Authenticate with Smartschool using direct credentials.
  Future<void> login({
    required String username,
    required String password,
    required String url,
    String mfa = '',
  }) async {
    _check(
      await send('login', {
        'username': username,
        'password': password,
        'url': url,
        'mfa': mfa,
      }),
    );
  }

  /// Clear the Python-side session.
  Future<void> logout() async {
    _check(await send('logout'));
  }

  /// Check whether the Python session holds an active login.
  Future<bool> isAuthenticated() async {
    final res = _check(await send('is_authenticated'));
    return res['authenticated'] as bool? ?? false;
  }

  /// Fetch message headers for the given [boxType].
  Future<List<SmartschoolMessageHeader>> getMessageHeaders({
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    List<int> alreadySeenIds = const [],
  }) async {
    final res = _check(
      await send('get_message_headers', {
        'box_type': boxType.value,
        if (alreadySeenIds.isNotEmpty) 'already_seen_ids': alreadySeenIds,
      }),
    );
    final list = res['headers'] as List<dynamic>? ?? [];
    return list
        .cast<Map<String, dynamic>>()
        .map(SmartschoolMessageHeader.fromJson)
        .toList();
  }

  /// Fetch message headers grouped into conversation threads.
  Future<List<SmartschoolMessageThread>> getThreadedHeaders({
    SmartschoolBoxType boxType = SmartschoolBoxType.inbox,
    List<int> alreadySeenIds = const [],
  }) async {
    final res = _check(
      await send('get_threaded_headers', {
        'box_type': boxType.value,
        if (alreadySeenIds.isNotEmpty) 'already_seen_ids': alreadySeenIds,
      }),
    );
    final list = res['threads'] as List<dynamic>? ?? [];
    return list
        .cast<Map<String, dynamic>>()
        .map(SmartschoolMessageThread.fromJson)
        .toList();
  }

  /// Fetch the full message thread for [messageId].
  Future<List<SmartschoolMessageDetail>> getMessage(int messageId) async {
    final res = _check(await send('get_message', {'message_id': messageId}));
    final list = res['messages'] as List<dynamic>? ?? [];
    return list
        .cast<Map<String, dynamic>>()
        .map(SmartschoolMessageDetail.fromJson)
        .toList();
  }

  /// Download all attachments for [messageId].
  Future<List<SmartschoolAttachment>> getAttachments(int messageId) async {
    final res = _check(
      await send('get_attachments', {'message_id': messageId}),
    );
    final list = res['attachments'] as List<dynamic>? ?? [];
    return list
        .cast<Map<String, dynamic>>()
        .map(SmartschoolAttachment.fromJson)
        .toList();
  }

  /// Mark a message as unread.
  Future<void> markUnread(int messageId) async {
    _check(await send('mark_unread', {'message_id': messageId}));
  }

  /// Set a label / flag colour on a message.
  Future<void> setLabel(int messageId, SmartschoolMessageLabel label) async {
    _check(
      await send('set_label', {'message_id': messageId, 'label': label.value}),
    );
  }

  /// Move a message (or list of IDs) to the archive.
  Future<void> archive(dynamic messageId) async {
    _check(await send('archive', {'message_id': messageId}));
  }

  /// Move a message to the trash.
  Future<void> trash(int messageId) async {
    _check(await send('trash', {'message_id': messageId}));
  }

  /// Shut down the Python process.
  void dispose() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _script.stop();
  }
}

/// Exception thrown when the Python bridge returns an error.
class SmartschoolBridgeException implements Exception {
  SmartschoolBridgeException(this.message);
  final String message;

  @override
  String toString() => 'SmartschoolBridgeException: $message';
}
