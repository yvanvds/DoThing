import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/office365_settings_controller.dart';
import '../../controllers/status_controller.dart';
import '../../models/office365_settings.dart';
import '../../providers/database_provider.dart';
import '../../services/office365/office365_mail_service.dart';
import '../../services/office365/office365_polling_controller.dart';

class Office365Section extends ConsumerStatefulWidget {
  const Office365Section({super.key});

  @override
  ConsumerState<Office365Section> createState() => _Office365SectionState();
}

class _Office365SectionState extends ConsumerState<Office365Section> {
  final _tenantCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _scopesCtrl = TextEditingController();

  Timer? _debounce;
  bool _initialised = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromProvider());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tenantCtrl.dispose();
    _clientCtrl.dispose();
    _portCtrl.dispose();
    _scopesCtrl.dispose();
    super.dispose();
  }

  void _syncFromProvider() {
    if (_initialised) return;

    final asyncSettings = ref.read(office365SettingsProvider);
    asyncSettings.whenData((settings) {
      _tenantCtrl.text = settings.tenantId;
      _clientCtrl.text = settings.clientId;
      _portCtrl.text = settings.redirectPort.toString();
      _scopesCtrl.text = settings.scopes;
      _initialised = true;
    });
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    final current = await ref.read(office365SettingsProvider.future);
    final port = int.tryParse(_portCtrl.text.trim()) ?? current.redirectPort;

    await ref
        .read(office365SettingsProvider.notifier)
        .updateSettings(
          current.copyWith(
            tenantId: _tenantCtrl.text.trim(),
            clientId: _clientCtrl.text.trim(),
            redirectPort: port,
            scopes: _scopesCtrl.text.trim(),
          ),
        );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      await _save();
      await action();
    } catch (error) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, 'Office 365 action failed: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSettings = ref.watch(office365SettingsProvider);
    final syncStateAsync = ref.watch(office365InboxSyncStateProvider);
    if (!_initialised) {
      asyncSettings.whenData((_) => _syncFromProvider());
    }

    return asyncSettings.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Text('Error loading settings: $error'),
      data: (settings) => _Office365Form(
        tenantCtrl: _tenantCtrl,
        clientCtrl: _clientCtrl,
        portCtrl: _portCtrl,
        scopesCtrl: _scopesCtrl,
        settings: settings,
        syncStateAsync: syncStateAsync,
        busy: _busy,
        onFieldChanged: _scheduleSave,
        onSignIn: () => _runAction(
          () => ref.read(office365MailServiceProvider).authenticate(),
        ),
        onFetchLatest: () => _runAction(() async {
          await ref
              .read(office365MailServiceProvider)
              .fetchLatestInboxMessage();
        }),
        onSignOut: () => _runAction(
          () => ref.read(office365MailServiceProvider).disconnect(),
        ),
      ),
    );
  }
}

class _Office365Form extends StatelessWidget {
  const _Office365Form({
    required this.tenantCtrl,
    required this.clientCtrl,
    required this.portCtrl,
    required this.scopesCtrl,
    required this.settings,
    required this.syncStateAsync,
    required this.busy,
    required this.onFieldChanged,
    required this.onSignIn,
    required this.onFetchLatest,
    required this.onSignOut,
  });

  final TextEditingController tenantCtrl;
  final TextEditingController clientCtrl;
  final TextEditingController portCtrl;
  final TextEditingController scopesCtrl;
  final Office365Settings settings;
  final AsyncValue<SyncStateData?> syncStateAsync;
  final bool busy;
  final VoidCallback onFieldChanged;
  final VoidCallback onSignIn;
  final VoidCallback onFetchLatest;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final connected = settings.hasToken;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Authenticate a school Microsoft account and fetch the latest inbox mail for onboarding.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 14),
        _LabeledField(
          controller: tenantCtrl,
          label: 'Tenant ID',
          hint: 'common or your tenant GUID',
          icon: Icons.apartment_outlined,
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          controller: clientCtrl,
          label: 'Client ID',
          hint: 'Azure app registration client ID',
          icon: Icons.badge_outlined,
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          controller: portCtrl,
          label: 'Redirect Port',
          hint: '3141',
          icon: Icons.http_outlined,
          keyboardType: TextInputType.number,
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          controller: scopesCtrl,
          label: 'Scopes',
          hint: 'offline_access openid profile Mail.Read',
          icon: Icons.security_outlined,
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            FilledButton.icon(
              onPressed: busy ? null : onSignIn,
              icon: const Icon(Icons.login_outlined),
              label: Text(busy ? 'Working...' : 'Sign in'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: busy || !connected ? null : onFetchLatest,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Fetch latest mail'),
            ),
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: busy || !connected ? null : onSignOut,
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Disconnect'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _connectionText(),
            style: TextStyle(
              fontSize: 12,
              color: connected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: connected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildSyncStatus(context, colorScheme),
        ),
      ],
    );
  }

  String _connectionText() {
    if (!settings.hasToken) {
      return 'Not connected';
    }

    final accountLabel = _accountLabel();
    return 'Connected as $accountLabel';
  }

  String _accountLabel() {
    if (settings.accountDisplayName.isNotEmpty) {
      return settings.accountDisplayName;
    }
    if (settings.accountEmail.isNotEmpty) {
      return settings.accountEmail;
    }
    return 'unknown account';
  }

  Widget _buildSyncStatus(BuildContext context, ColorScheme colorScheme) {
    return syncStateAsync.when(
      loading: () => Text(
        'Sync status: loading...',
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      error: (error, _) => Text(
        'Sync status unavailable: $error',
        style: TextStyle(fontSize: 12, color: colorScheme.error),
      ),
      data: (syncState) => _buildSyncStatusContent(syncState, colorScheme),
    );
  }

  Widget _buildSyncStatusContent(
    SyncStateData? syncState,
    ColorScheme colorScheme,
  ) {
    if (syncState == null || syncState.lastSuccessAt == null) {
      return Text(
        'Last Outlook sync: not yet completed',
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      );
    }

    final successText = _formatDateTime(syncState.lastSuccessAt!);
    final hasErrorText = (syncState.lastError ?? '').trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last Outlook sync: $successText',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        if (syncState.failureCount > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Recent failures: ${syncState.failureCount}',
            style: TextStyle(fontSize: 12, color: colorScheme.error),
          ),
          if (hasErrorText)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                syncState.lastError!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: colorScheme.error),
              ),
            ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

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
            keyboardType: keyboardType,
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
            ),
          ),
        ),
      ],
    );
  }
}
