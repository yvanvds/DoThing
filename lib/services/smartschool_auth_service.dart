import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/smartschool_settings_controller.dart';
import '../controllers/status_controller.dart';
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
  SmartschoolBridge? _bridge;

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

    state = const AsyncData(SmartschoolConnectionState.initializing);

    state = await AsyncValue.guard(() async {
      final normalizedUrl = _normalizeMainUrl(settings.url);

      status.add(StatusEntryType.info, 'Connecting to Smartschool…');
      _bridge = await SmartschoolBridge.connect(
        username: settings.username,
        password: settings.password,
        mainUrl: normalizedUrl,
        mfa: settings.mfaSecret,
      );
      status.add(StatusEntryType.success, 'Logged in to Smartschool.');

      return SmartschoolConnectionState.connected;
    });

    if (state is AsyncError) {
      final asyncError = state as AsyncError<SmartschoolConnectionState>;
      status.add(StatusEntryType.error, _friendlyAuthError(asyncError.error));
      state = const AsyncData(SmartschoolConnectionState.disconnected);
    }
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
