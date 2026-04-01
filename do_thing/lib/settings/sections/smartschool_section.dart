import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/smartschool_settings_controller.dart';
import '../../models/smartschool_settings.dart';

class SmartschoolSection extends ConsumerStatefulWidget {
  const SmartschoolSection({super.key});

  @override
  ConsumerState<SmartschoolSection> createState() => _SmartschoolSectionState();
}

class _SmartschoolSectionState extends ConsumerState<SmartschoolSection> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();

  bool _passwordVisible = false;
  bool _initialised = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Populate fields once the provider has loaded its value.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromProvider());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _urlCtrl.dispose();
    _birthdayCtrl.dispose();
    super.dispose();
  }

  void _syncFromProvider() {
    if (_initialised) return;
    final asyncSettings = ref.read(smartschoolSettingsProvider);
    asyncSettings.whenData((settings) {
      _usernameCtrl.text = settings.username;
      _passwordCtrl.text = settings.password;
      _urlCtrl.text = settings.url;
      _birthdayCtrl.text = settings.birthday;
      _initialised = true;
    });
  }

  void _schedSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _save);
  }

  Future<void> _save() async {
    await ref
        .read(smartschoolSettingsProvider.notifier)
        .updateSettings(
          SmartschoolSettings(
            username: _usernameCtrl.text.trim(),
            password: _passwordCtrl.text,
            url: _urlCtrl.text.trim(),
            birthday: _birthdayCtrl.text.trim(),
          ),
        );
  }

  Future<void> _pickDate() async {
    // Parse existing value so the picker opens on it.
    DateTime initial = DateTime.now();
    try {
      if (_birthdayCtrl.text.isNotEmpty) {
        initial = DateTime.parse(_birthdayCtrl.text);
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Select birthday',
    );

    if (picked != null && mounted) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      setState(() => _birthdayCtrl.text = formatted);
      _schedSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not yet initialised and the provider just loaded, populate fields.
    final asyncSettings = ref.watch(smartschoolSettingsProvider);
    if (!_initialised) {
      asyncSettings.whenData((_) => _syncFromProvider());
    }

    return asyncSettings.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => Text('Error loading settings: $e'),
      data: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsField(
            controller: _usernameCtrl,
            label: 'Username',
            hint: 'Your Smartschool username',
            icon: Icons.person_outline,
            onChanged: (_) => _schedSave(),
          ),
          const SizedBox(height: 14),
          _SettingsField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: 'Your Smartschool password',
            icon: Icons.lock_outline,
            obscureText: !_passwordVisible,
            onChanged: (_) => _schedSave(),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
              tooltip: _passwordVisible ? 'Hide password' : 'Show password',
            ),
          ),
          const SizedBox(height: 14),
          _SettingsField(
            controller: _urlCtrl,
            label: 'School URL',
            hint: 'https://yourschool.smartschool.be',
            icon: Icons.link_outlined,
            onChanged: (_) => _schedSave(),
          ),
          const SizedBox(height: 14),
          _SettingsField(
            controller: _birthdayCtrl,
            label: 'Birthday',
            hint: 'YYYY-MM-DD',
            icon: Icons.cake_outlined,
            onChanged: (_) => _schedSave(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              onPressed: _pickDate,
              tooltip: 'Pick date',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable labelled text field
// ---------------------------------------------------------------------------

class _SettingsField extends StatelessWidget {
  const _SettingsField({
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
          width: 120,
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
