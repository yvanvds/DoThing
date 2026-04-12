import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/ai/ai_settings_controller.dart';
import '../../controllers/status_controller.dart';
import '../../models/ai/ai_settings.dart';

class AiSection extends ConsumerStatefulWidget {
  const AiSection({super.key});

  @override
  ConsumerState<AiSection> createState() => _AiSectionState();
}

class _AiSectionState extends ConsumerState<AiSection> {
  final _modelCtrl = TextEditingController();
  final _baseUrlCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  Timer? _debounce;
  bool _initialised = false;
  bool _keyVisible = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromProvider());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _modelCtrl.dispose();
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  void _syncFromProvider() {
    if (_initialised) {
      return;
    }

    final asyncSettings = ref.read(aiSettingsProvider);
    asyncSettings.whenData((settings) {
      _modelCtrl.text = settings.model;
      _baseUrlCtrl.text = settings.baseUrl;
      _initialised = true;
    });
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _save);
  }

  Future<void> _save() async {
    final current = await ref.read(aiSettingsProvider.future);
    await ref
        .read(aiSettingsProvider.notifier)
        .updateSettings(
          current.copyWith(
            model: _modelCtrl.text.trim(),
            baseUrl: _baseUrlCtrl.text.trim(),
          ),
        );
  }

  Future<void> _saveApiKey() async {
    setState(() => _busy = true);
    try {
      await ref.read(aiSettingsProvider.notifier).saveApiKey(_apiKeyCtrl.text);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved securely on this device.')),
      );
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.success, 'AI API key stored securely.');
      _apiKeyCtrl.clear();
    } catch (error) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, 'Failed to save API key: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() => _busy = true);
    try {
      await _save();
      await ref.read(aiSettingsProvider.notifier).testConnection();
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.success, 'AI connection test succeeded.');
    } catch (error) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, 'AI connection test failed: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSettings = ref.watch(aiSettingsProvider);

    if (!_initialised) {
      asyncSettings.whenData((_) => _syncFromProvider());
    }

    return asyncSettings.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Text('Error loading AI settings: $error'),
      data: (settings) => _AiSectionForm(
        settings: settings,
        modelCtrl: _modelCtrl,
        baseUrlCtrl: _baseUrlCtrl,
        apiKeyCtrl: _apiKeyCtrl,
        keyVisible: _keyVisible,
        busy: _busy,
        onProviderChanged: (value) async {
          final provider = value ?? AiProvider.openai;
          await ref
              .read(aiSettingsProvider.notifier)
              .updateSettings(settings.copyWith(provider: provider));
        },
        onStreamingChanged: (value) async {
          await ref
              .read(aiSettingsProvider.notifier)
              .updateSettings(settings.copyWith(streamingEnabled: value));
        },
        onFieldChanged: _scheduleSave,
        onToggleKeyVisible: () => setState(() => _keyVisible = !_keyVisible),
        onSaveApiKey: _saveApiKey,
        onClearApiKey: () async {
          await ref.read(aiSettingsProvider.notifier).saveApiKey('');
        },
        onTestConnection: _testConnection,
      ),
    );
  }
}

class _AiSectionForm extends StatelessWidget {
  const _AiSectionForm({
    required this.settings,
    required this.modelCtrl,
    required this.baseUrlCtrl,
    required this.apiKeyCtrl,
    required this.keyVisible,
    required this.busy,
    required this.onProviderChanged,
    required this.onStreamingChanged,
    required this.onFieldChanged,
    required this.onToggleKeyVisible,
    required this.onSaveApiKey,
    required this.onClearApiKey,
    required this.onTestConnection,
  });

  final AiSettings settings;
  final TextEditingController modelCtrl;
  final TextEditingController baseUrlCtrl;
  final TextEditingController apiKeyCtrl;
  final bool keyVisible;
  final bool busy;
  final ValueChanged<AiProvider?> onProviderChanged;
  final ValueChanged<bool> onStreamingChanged;
  final VoidCallback onFieldChanged;
  final VoidCallback onToggleKeyVisible;
  final VoidCallback onSaveApiKey;
  final VoidCallback onClearApiKey;
  final VoidCallback onTestConnection;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connect your own OpenAI account. The app stores your API key securely on this machine.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            SizedBox(
              width: 200,
              child: Row(
                children: [
                  Icon(
                    Icons.hub_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Provider',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DropdownButtonFormField<AiProvider>(
                isExpanded: true,
                initialValue: settings.provider,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AiProvider.openai,
                    child: Text('OpenAI'),
                  ),
                ],
                onChanged: busy ? null : onProviderChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LabeledField(
          controller: modelCtrl,
          label: 'Model',
          hint: 'gpt-4.1-mini',
          icon: Icons.memory_outlined,
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          controller: baseUrlCtrl,
          label: 'Base URL',
          hint: 'https://api.openai.com',
          icon: Icons.link_outlined,
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          controller: apiKeyCtrl,
          label: 'API key',
          hint: 'sk-...',
          icon: Icons.key_outlined,
          obscureText: !keyVisible,
          onChanged: (_) {},
          suffixIcon: IconButton(
            icon: Icon(
              keyVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
            ),
            onPressed: onToggleKeyVisible,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.icon(
              onPressed: busy ? null : onSaveApiKey,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save key'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: busy || !settings.hasApiKey ? null : onClearApiKey,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear key'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                settings.hasApiKey
                    ? 'Key stored securely'
                    : 'No key stored yet',
                style: TextStyle(
                  fontSize: 12,
                  color: settings.hasApiKey
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Streaming replies'),
          subtitle: const Text('Show assistant output progressively in chat'),
          value: settings.streamingEnabled,
          onChanged: busy ? null : onStreamingChanged,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: busy ? null : onTestConnection,
              icon: const Icon(Icons.network_check_outlined),
              label: Text(busy ? 'Testing...' : 'Test connection'),
            ),
          ],
        ),
        if (settings.hasRecentTest) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              settings.lastTestMessage ?? 'No test result.',
              style: TextStyle(
                fontSize: 12,
                color: (settings.lastTestSuccessful ?? false)
                    ? Colors.green.shade500
                    : colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
