import 'package:flutter/material.dart';

import '../../controllers/status_controller.dart';
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
];
