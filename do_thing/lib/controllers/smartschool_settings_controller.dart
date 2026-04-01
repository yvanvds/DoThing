import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/smartschool_settings.dart';

/// Persists Smartschool settings to a JSON file in Windows AppData.
///
/// Usage from anywhere:
///   final settings = ref.watch(smartschoolSettingsProvider).valueOrNull;
///   ref.read(smartschoolSettingsProvider.notifier).updateSettings(settings.copyWith(username: 'x'));
class SmartschoolSettingsController extends AsyncNotifier<SmartschoolSettings> {
  static const _appFolderName = 'DoThing';
  static const _settingsFileName = 'smartschool_settings.json';

  @override
  Future<SmartschoolSettings> build() async {
    try {
      final file = await _getSettingsFile();
      if (!await file.exists()) {
        return const SmartschoolSettings();
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const SmartschoolSettings();
      }

      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) {
        return const SmartschoolSettings();
      }

      return SmartschoolSettings(
        username: data['username'] as String? ?? '',
        password: data['password'] as String? ?? '',
        url: data['url'] as String? ?? '',
        birthday: data['birthday'] as String? ?? '',
      );
    } catch (_) {
      return const SmartschoolSettings();
    }
  }

  /// Updates state and immediately persists all fields to disk.
  Future<void> updateSettings(SmartschoolSettings settings) async {
    // Optimistic update so the UI reacts instantly.
    state = AsyncData(settings);

    try {
      final file = await _getSettingsFile();
      final payload = jsonEncode({
        'username': settings.username,
        'password': settings.password,
        'url': settings.url,
        'birthday': settings.birthday,
      });
      await file.writeAsString(payload, flush: true);
    } catch (_) {}
  }

  Future<File> _getSettingsFile() async {
    final appData = Platform.environment['APPDATA'];
    final basePath =
        (appData != null && appData.isNotEmpty)
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

final smartschoolSettingsProvider =
    AsyncNotifierProvider<SmartschoolSettingsController, SmartschoolSettings>(
      SmartschoolSettingsController.new,
    );
