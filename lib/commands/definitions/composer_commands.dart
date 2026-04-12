import 'package:flutter/material.dart';

import '../../controllers/composer_controller.dart';
import '../../controllers/composer_visibility_controller.dart';
import '../../controllers/context_panel_controller.dart';
import '../app_command.dart';

/// Commands related to the message composer.
List<AppCommand> composerCommands() => [
  AppCommand(
    id: 'newMessage',
    label: 'New message',
    description: 'Open the message composer',
    icon: Icons.edit_outlined,
    execute: (ref) async {
      ref.read(contextPanelProvider.notifier).show(ContextView.messages);
      ref.read(composerProvider.notifier).reset();
      ref.read(composerVisibilityProvider.notifier).open();
    },
  ),
];
