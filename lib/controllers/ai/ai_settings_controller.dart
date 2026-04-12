import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/ai/ai_settings.dart';
import '../../services/ai/openai_chat_service.dart';

class AiSettingsController extends AsyncNotifier<AiSettings> {
  static const _appFolderName = 'DoThing';
  static const _settingsFileName = 'ai_settings.json';
  static const _apiKeyStorageKey = 'do_thing.ai.openai_api_key';

  Directory? _storageDirectory;
  FlutterSecureStorage? _storage;

  @visibleForTesting
  void setStorageDirectory(Directory dir) => _storageDirectory = dir;

  @visibleForTesting
  void setSecureStorage(FlutterSecureStorage storage) => _storage = storage;

  @override
  Future<AiSettings> build() async {
    try {
      final file = await _getSettingsFile();
      final hasApiKey = await _hasApiKey();
      if (!await file.exists()) {
        return AiSettings(hasApiKey: hasApiKey);
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return AiSettings(hasApiKey: hasApiKey);
      }

      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) {
        return AiSettings(hasApiKey: hasApiKey);
      }

      final settings = AiSettings.fromJson(data);
      return settings.copyWith(hasApiKey: hasApiKey);
    } catch (_) {
      final hasApiKey = await _hasApiKey();
      return AiSettings(hasApiKey: hasApiKey);
    }
  }

  Future<void> updateSettings(AiSettings settings) async {
    state = AsyncData(settings);

    try {
      final file = await _getSettingsFile();
      await file.writeAsString(jsonEncode(settings.toJson()), flush: true);
    } catch (_) {}
  }

  Future<void> saveApiKey(String apiKey) async {
    final sanitized = apiKey.trim();
    final storage = _storage ?? const FlutterSecureStorage();

    if (sanitized.isEmpty) {
      await storage.delete(key: _apiKeyStorageKey);
      final current = state.asData?.value ?? const AiSettings();
      await updateSettings(current.copyWith(hasApiKey: false));
      return;
    }

    await storage.write(key: _apiKeyStorageKey, value: sanitized);
    final current = state.asData?.value ?? const AiSettings();
    await updateSettings(current.copyWith(hasApiKey: true));
  }

  Future<String?> readApiKey() async {
    final storage = _storage ?? const FlutterSecureStorage();
    final value = await storage.read(key: _apiKeyStorageKey);
    return value?.trim().isNotEmpty == true ? value?.trim() : null;
  }

  Future<bool> _hasApiKey() async {
    final key = await readApiKey();
    return key != null && key.isNotEmpty;
  }

  Future<void> testConnection() async {
    final current = state.asData?.value ?? const AiSettings();
    final apiKey = await readApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      await updateSettings(
        current.copyWith(
          lastTestAtIso: DateTime.now().toIso8601String(),
          lastTestSuccessful: false,
          lastTestMessage: 'No API key saved.',
        ),
      );
      throw StateError('No API key saved.');
    }

    final transport = ref.read(aiChatTransportProvider);
    try {
      await transport.testConnection(
        apiKey: apiKey,
        baseUrl: current.baseUrl,
        model: current.model,
      );
      await updateSettings(
        current.copyWith(
          lastTestAtIso: DateTime.now().toIso8601String(),
          lastTestSuccessful: true,
          lastTestMessage: 'OpenAI connection successful.',
        ),
      );
    } catch (e) {
      await updateSettings(
        current.copyWith(
          lastTestAtIso: DateTime.now().toIso8601String(),
          lastTestSuccessful: false,
          lastTestMessage: 'Connection failed: $e',
        ),
      );
      rethrow;
    }
  }

  Future<File> _getSettingsFile() async {
    final settingsDir =
        _storageDirectory ??
        () {
          final appData = Platform.environment['APPDATA'];
          final basePath = (appData != null && appData.isNotEmpty)
              ? appData
              : Directory.current.path;
          return Directory('$basePath${Platform.pathSeparator}$_appFolderName');
        }();
    await settingsDir.create(recursive: true);

    return File(
      '${settingsDir.path}${Platform.pathSeparator}$_settingsFileName',
    );
  }
}

final aiSettingsProvider =
    AsyncNotifierProvider<AiSettingsController, AiSettings>(
      AiSettingsController.new,
    );
