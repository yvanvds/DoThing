import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/smartschool_settings_controller.dart';
import '../../controllers/status_controller.dart';
import 'smartschool_bridge.dart';

/// High-level connection / authentication state.
enum SmartschoolConnectionState { disconnected, initializing, connected }

/// Manages the full Python engine lifecycle and Smartschool authentication.
///
/// ```dart
/// // Watch connection state
/// final state = ref.watch(smartschoolAuthProvider);
///
/// // Connect (init engine + login)
/// await ref.read(smartschoolAuthProvider.notifier).connect();
///
/// // Access the bridge for message operations
/// final bridge = ref.read(smartschoolAuthProvider.notifier).bridge;
///
/// // Disconnect
/// await ref.read(smartschoolAuthProvider.notifier).disconnect();
/// ```
class SmartschoolAuthController
    extends AsyncNotifier<SmartschoolConnectionState> {
  static const int _maxLoginAttempts = 5;
  static const Duration _retryDelay = Duration(seconds: 3);

  SmartschoolBridge? _bridge;
  int _loginAttemptCounter = 0;

  @override
  Future<SmartschoolConnectionState> build() async =>
      SmartschoolConnectionState.disconnected;

  /// The live bridge to the Python process. Throws if not connected.
  SmartschoolBridge get bridge {
    if (_bridge == null) {
      throw StateError('Not connected to Smartschool.');
    }
    return _bridge!;
  }

  /// Initializes an authenticated Smartschool session.
  Future<void> connect() async {
    final status = ref.read(statusProvider.notifier);
    final settings = await ref.read(smartschoolSettingsProvider.future);

    if (settings.username.isEmpty ||
        settings.url.isEmpty ||
        settings.password.isEmpty) {
      status.add(
        StatusEntryType.error,
        'Smartschool settings are incomplete – configure them first.',
      );
      return;
    }

    final existingBridge = _bridge;
    if (existingBridge != null) {
      status.add(
        StatusEntryType.info,
        'Checking existing Smartschool session…',
      );
      final stillAuthenticated = await existingBridge.ping();
      if (stillAuthenticated) {
        state = const AsyncData(SmartschoolConnectionState.connected);
        status.add(
          StatusEntryType.info,
          'Reused existing Smartschool session.',
        );
        return;
      }

      status.add(
        StatusEntryType.warning,
        'Stored Smartschool session expired. Performing a fresh login…',
      );
      existingBridge.dispose();
      _bridge = null;
    } else {
      status.add(
        StatusEntryType.info,
        'No active Smartschool session. Performing a fresh login…',
      );
    }

    state = const AsyncData(SmartschoolConnectionState.initializing);
    String normalizedUrl;
    try {
      normalizedUrl = _normalizeMainUrl(settings.url);
    } catch (error) {
      status.add(StatusEntryType.error, _friendlyAuthError(error));
      state = const AsyncData(SmartschoolConnectionState.disconnected);
      return;
    }

    final attemptStartedAt = DateTime.now();
    Object? lastError;

    for (var attempt = 1; attempt <= _maxLoginAttempts; attempt++) {
      final attemptNumber = ++_loginAttemptCounter;
      try {
        status.add(
          StatusEntryType.info,
          'Connecting to Smartschool at $normalizedUrl (attempt $attempt/$_maxLoginAttempts)…',
        );

        _bridge = await createBridge(
          username: settings.username,
          password: settings.password,
          mainUrl: normalizedUrl,
          mfa: settings.mfaSecret,
        );

        final elapsed = DateTime.now().difference(attemptStartedAt);
        status.add(
          StatusEntryType.success,
          'Logged in to Smartschool on attempt #$attemptNumber after ${elapsed.inMilliseconds} ms.',
        );
        state = const AsyncData(SmartschoolConnectionState.connected);

        try {
          final user = await _bridge!.getCurrentUser();
          final current = await ref.read(smartschoolSettingsProvider.future);
          await ref
              .read(smartschoolSettingsProvider.notifier)
              .updateSettings(
                current.copyWith(
                  userDisplayName: user.displayName,
                  userAvatarUrl: user.avatarUrl,
                ),
              );
        } catch (_) {
          // Non-fatal: tile falls back to 'Me' if this fails.
        }

        return;
      } catch (error) {
        lastError = error;
        if (attempt < _maxLoginAttempts) {
          status.add(
            StatusEntryType.warning,
            'Smartschool login attempt $attempt/$_maxLoginAttempts failed. Retrying in ${_retryDelay.inSeconds} seconds…',
          );
          await Future<void>.delayed(_retryDelay);
        }
      }
    }

    final elapsed = DateTime.now().difference(attemptStartedAt);
    status.add(
      StatusEntryType.error,
      '${_friendlyAuthError(lastError ?? 'Unknown error')} (after $_maxLoginAttempts attempts, ${elapsed.inMilliseconds} ms)',
    );
    state = const AsyncData(SmartschoolConnectionState.disconnected);
  }

  Future<SmartschoolBridge> createBridge({
    required String username,
    required String password,
    required String mainUrl,
    String? mfa,
  }) {
    return SmartschoolBridge.connect(
      username: username,
      password: password,
      mainUrl: mainUrl,
      mfa: mfa,
    );
  }

  String _friendlyAuthError(Object error) {
    final text = error.toString();

    if (text.contains('ConnectionError') ||
        text.contains('getaddrinfo failed')) {
      return 'Connection failed: unable to reach Smartschool host. Check school URL and internet connection.';
    }

    if (text.contains('ParseError') && text.contains('no element found')) {
      return 'Connection failed: Smartschool returned invalid/empty data. Credentials, MFA, or URL may be incorrect.';
    }

    if (text.contains('FormatException')) {
      return 'Connection failed: invalid school URL format.';
    }

    return 'Connection failed: $error';
  }

  String _normalizeMainUrl(String raw) {
    final input = raw.trim();
    if (input.isEmpty) {
      throw const FormatException('School URL is empty.');
    }

    final uri = input.contains('://')
        ? Uri.tryParse(input)
        : Uri.tryParse('https://$input');

    final host = uri?.host.trim() ?? '';
    if (host.isEmpty) {
      throw FormatException('Invalid school URL: "$raw"');
    }

    return host;
  }

  /// Log out and tear down the Python bridge process.
  Future<void> disconnect() async {
    final status = ref.read(statusProvider.notifier);

    try {
      if (_bridge != null) {
        await _bridge!.logout();
      }
    } catch (_) {
      // Best-effort logout.
    }

    _bridge?.dispose();
    _bridge = null;

    state = const AsyncData(SmartschoolConnectionState.disconnected);
    status.add(StatusEntryType.info, 'Disconnected from Smartschool.');
  }
}

/// Provides the Smartschool connection state and auth controller.
final smartschoolAuthProvider =
    AsyncNotifierProvider<
      SmartschoolAuthController,
      SmartschoolConnectionState
    >(SmartschoolAuthController.new);
