import 'package:command_palette/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/context_panel_controller.dart';
import '../settings/settings_page.dart';
import 'panels/smartschool/smartschool_messages_panel.dart';

class ContextPanel extends ConsumerWidget {
  const ContextPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(contextPanelProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ContextPaletteBar(),
          Expanded(child: _buildContent(view, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildContent(ContextView view, ColorScheme colorScheme) {
    return switch (view) {
      ContextView.empty => Center(
        child: Text(
          'Context Panel',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
        ),
      ),
      ContextView.settings => const SettingsPage(),
      ContextView.messages => const MessagesPanel(),
    };
  }
}

class _ContextPaletteBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => CommandPalette.of(context).open(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 15, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Command Palette  (Ctrl+Shift+P)',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
