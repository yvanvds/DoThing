import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/office365_settings.dart';

class Office365SettingsController extends AsyncNotifier<Office365Settings> {
  static const _appFolderName = 'DoThing';
  static const _settingsFileName = 'office365_settings.json';

  @override
  Future<Office365Settings> build() async {
    try {
      final file = await _getSettingsFile();
      if (!await file.exists()) return const Office365Settings();

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const Office365Settings();

      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return const Office365Settings();

      return Office365Settings(
        tenantId: data['tenantId'] as String? ?? '',
        clientId: data['clientId'] as String? ?? '',
        redirectPort: (data['redirectPort'] as num?)?.toInt() ?? 3141,
        scopes:
            data['scopes'] as String? ??
            'offline_access openid profile Mail.Read',
        authState: Office365AuthState(
          accessToken: data['accessToken'] as String? ?? '',
          refreshToken: data['refreshToken'] as String? ?? '',
          expiresAtIso: data['expiresAtIso'] as String? ?? '',
          accountEmail: data['accountEmail'] as String? ?? '',
          accountDisplayName: data['accountDisplayName'] as String? ?? '',
        ),
      );
    } catch (_) {
      return const Office365Settings();
    }
  }

  Future<void> updateSettings(Office365Settings settings) async {
    state = AsyncData(settings);

    try {
      final file = await _getSettingsFile();
      final payload = jsonEncode({
        'tenantId': settings.tenantId,
        'clientId': settings.clientId,
        'redirectPort': settings.redirectPort,
        'scopes': settings.scopes,
        'accessToken': settings.accessToken,
        'refreshToken': settings.refreshToken,
        'expiresAtIso': settings.expiresAtIso,
        'accountEmail': settings.accountEmail,
        'accountDisplayName': settings.accountDisplayName,
      });
      await file.writeAsString(payload, flush: true);
    } catch (_) {}
  }

  Future<void> clearAuthState() async {
    final current = state.asData?.value ?? const Office365Settings();
    await updateSettings(
      current.copyWith(authState: const Office365AuthState()),
    );
  }

  Future<File> _getSettingsFile() async {
    final appData = Platform.environment['APPDATA'];
    final basePath = (appData != null && appData.isNotEmpty)
        ? appData
        : Directory.current.path;

    final settingsDir = Directory(
      '$basePath${Platform.pathSeparator}$_appFolderName',
    );
    await settingsDir.create(recursive: true);

    return File(
      '${settingsDir.path}${Platform.pathSeparator}$_settingsFileName',
    );
  }
}

final office365SettingsProvider =
    AsyncNotifierProvider<Office365SettingsController, Office365Settings>(
      Office365SettingsController.new,
    );
