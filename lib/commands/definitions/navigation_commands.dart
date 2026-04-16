import 'package:flutter/material.dart';

import '../../controllers/context_panel_controller.dart';
import '../app_command.dart';

/// Commands related to navigation and panel switching.
List<AppCommand> navigationCommands() => [
  AppCommand(
    id: 'openChat',
    label: 'Open Chat History',
    description: 'Open chat history in the context panel',
    icon: Icons.chat_bubble_outline,
    execute: (ref) async {
      ref.read(contextPanelProvider.notifier).show(ContextView.chatHistory);
    },
  ),
  AppCommand(
    id: 'openSettings',
    label: 'Open Settings',
    description: 'Open the application settings',
    icon: Icons.settings_outlined,
    execute: (ref) async {
      ref.read(contextPanelProvider.notifier).show(ContextView.settings);
    },
  ),
  AppCommand(
    id: 'openMessages',
    label: 'Open Messages',
    description: 'Open messages panel',
    icon: Icons.mail_outline,
    execute: (ref) async {
      ref.read(contextPanelProvider.notifier).show(ContextView.messages);
    },
  ),
];
