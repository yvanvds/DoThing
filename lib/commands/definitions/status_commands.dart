import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/smartschool_inbox_controller.dart';
import '../../controllers/status_controller.dart';
import '../../services/smartschool/smartschool_auth_controller.dart';
import '../app_command.dart';

/// Commands that interact with the status terminal.
List<AppCommand> statusCommands() => [
  AppCommand(
    id: 'clearStatus',
    label: 'Clear Status',
    description: 'Clear all status terminal messages',
    icon: Icons.clear_all,
    execute: (ref) async {
      ref.read(statusProvider.notifier).clear();
    },
  ),
  AppCommand(
    id: 'restartConnection',
    label: 'Restart Smartschool Connection',
    description: 'Reconnect to Smartschool and refresh inbox headers',
    icon: Icons.wifi_protected_setup,
    execute: (ref) async {
      final status = ref.read(statusProvider.notifier);
      final auth = ref.read(smartschoolAuthProvider.notifier);

      status.add(StatusEntryType.info, 'Restarting Smartschool connection…');

      await auth.disconnect();
      await auth.connect();

      final authState = ref.read(smartschoolAuthProvider);
      final connected =
          authState is AsyncData<SmartschoolConnectionState> &&
          authState.value == SmartschoolConnectionState.connected;

      if (!connected) {
        status.add(
          StatusEntryType.error,
          'Smartschool connection restart failed.',
        );
        return;
      }

      final headers = await ref
          .read(smartschoolInboxProvider.notifier)
          .refreshInboxAndGetHeaders(showLoading: false);
      status.add(
        StatusEntryType.success,
        'Smartschool connection restarted. Refreshed ${headers.length} inbox headers.',
      );
    },
  ),
];
