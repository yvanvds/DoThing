import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/ai/ai_settings_controller.dart';
import '../../controllers/status_controller.dart';
import '../../models/ai/ai_settings.dart';
import '../../services/ai/openai_model_catalog.dart';

class AiSection extends ConsumerStatefulWidget {
  const AiSection({super.key});

  @override
  ConsumerState<AiSection> createState() => _AiSectionState();
}

class _AiSectionState extends ConsumerState<AiSection> {
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
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  void _syncFromProvider() {
    if (_initialised) return;
    final asyncSettings = ref.read(aiSettingsProvider);
    asyncSettings.whenData((settings) {
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
        .updateSettings(current.copyWith(baseUrl: _baseUrlCtrl.text.trim()));
  }

  Future<void> _saveModel({
    required String complexModel,
    required String fastModel,
    required String cheapModel,
  }) async {
    final current = await ref.read(aiSettingsProvider.future);
    await ref
        .read(aiSettingsProvider.notifier)
        .updateSettings(
          current.copyWith(
            complexModel: complexModel,
            fastModel: fastModel,
            cheapModel: cheapModel,
          ),
        );
  }

  Future<void> _saveApiKey() async {
    setState(() => _busy = true);
    try {
      await ref.read(aiSettingsProvider.notifier).saveApiKey(_apiKeyCtrl.text);
      if (!mounted) return;
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
      if (mounted) setState(() => _busy = false);
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
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSettings = ref.watch(aiSettingsProvider);
    final availableModels = ref.watch(openAiAvailableModelsProvider);

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
        availableModels: availableModels,
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
        onComplexModelChanged: (modelId) async {
          if (modelId == null) return;
          await _saveModel(
            complexModel: modelId,
            fastModel: settings.fastModel,
            cheapModel: settings.cheapModel,
          );
        },
        onFastModelChanged: (modelId) async {
          if (modelId == null) return;
          await _saveModel(
            complexModel: settings.complexModel,
            fastModel: modelId,
            cheapModel: settings.cheapModel,
          );
        },
        onCheapModelChanged: (modelId) async {
          if (modelId == null) return;
          await _saveModel(
            complexModel: settings.complexModel,
            fastModel: settings.fastModel,
            cheapModel: modelId,
          );
        },
        onStreamingChanged: (value) async {
          await ref
              .read(aiSettingsProvider.notifier)
              .updateSettings(settings.copyWith(streamingEnabled: value));
        },
        onBaseUrlChanged: _scheduleSave,
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
    required this.availableModels,
    required this.baseUrlCtrl,
    required this.apiKeyCtrl,
    required this.keyVisible,
    required this.busy,
    required this.onProviderChanged,
    required this.onComplexModelChanged,
    required this.onFastModelChanged,
    required this.onCheapModelChanged,
    required this.onStreamingChanged,
    required this.onBaseUrlChanged,
    required this.onToggleKeyVisible,
    required this.onSaveApiKey,
    required this.onClearApiKey,
    required this.onTestConnection,
  });

  final AiSettings settings;
  final AsyncValue<List<OpenAiModelInfo>> availableModels;
  final TextEditingController baseUrlCtrl;
  final TextEditingController apiKeyCtrl;
  final bool keyVisible;
  final bool busy;
  final ValueChanged<AiProvider?> onProviderChanged;
  final ValueChanged<String?> onComplexModelChanged;
  final ValueChanged<String?> onFastModelChanged;
  final ValueChanged<String?> onCheapModelChanged;
  final ValueChanged<bool> onStreamingChanged;
  final VoidCallback onBaseUrlChanged;
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
        _LabeledRow(
          label: 'Provider',
          icon: Icons.hub_outlined,
          child: DropdownButtonFormField<AiProvider>(
            isExpanded: true,
            initialValue: settings.provider,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: AiProvider.openai, child: Text('OpenAI')),
            ],
            onChanged: busy ? null : onProviderChanged,
          ),
        ),
        const SizedBox(height: 12),
        _ModelDropdownRow(
          label: 'Complex model',
          icon: Icons.psychology_outlined,
          currentValue: settings.complexModel,
          availableModels: availableModels,
          onChanged: busy ? null : onComplexModelChanged,
        ),
        const SizedBox(height: 12),
        _ModelDropdownRow(
          label: 'Fast model',
          icon: Icons.bolt_outlined,
          currentValue: settings.fastModel,
          availableModels: availableModels,
          onChanged: busy ? null : onFastModelChanged,
        ),
        const SizedBox(height: 12),
        _ModelDropdownRow(
          label: 'Cheap model',
          icon: Icons.savings_outlined,
          currentValue: settings.cheapModel,
          availableModels: availableModels,
          onChanged: busy ? null : onCheapModelChanged,
        ),
        const SizedBox(height: 12),
        _LabeledField(
          controller: baseUrlCtrl,
          label: 'Base URL',
          hint: 'https://api.openai.com',
          icon: Icons.link_outlined,
          onChanged: (_) => onBaseUrlChanged(),
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

class _ModelDropdownRow extends StatelessWidget {
  const _ModelDropdownRow({
    required this.label,
    required this.icon,
    required this.currentValue,
    required this.availableModels,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String currentValue;
  final AsyncValue<List<OpenAiModelInfo>> availableModels;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _LabeledRow(
      label: label,
      icon: icon,
      child: availableModels.when(
        loading: () => _DisabledDropdownField(
          value: currentValue,
          trailing: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, err) => _DisabledDropdownField(
          value: currentValue,
          trailing: const Tooltip(
            message: 'Could not load models list',
            child: Icon(Icons.warning_amber_outlined, size: 16),
          ),
        ),
        data: (models) {
          final items = <DropdownMenuItem<String>>[];
          if (!models.any((m) => m.id == currentValue)) {
            items.add(
              DropdownMenuItem(
                value: currentValue,
                child: Text(
                  '$currentValue (not found)',
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }
          items.addAll(
            models.map(
              (m) => DropdownMenuItem(
                value: m.id,
                child: Text(
                  m.id,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
          return DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: currentValue,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(),
            ),
            items: items,
            onChanged: onChanged,
          );
        },
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

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
        Expanded(child: child),
      ],
    );
  }
}

class _DisabledDropdownField extends StatelessWidget {
  const _DisabledDropdownField({required this.value, this.trailing});

  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: const OutlineInputBorder(),
        suffixIcon: trailing != null
            ? Padding(padding: const EdgeInsets.all(10), child: trailing)
            : null,
      ),
      child: Text(value, style: const TextStyle(fontSize: 13)),
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
    return _LabeledRow(
      label: label,
      icon: icon,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
