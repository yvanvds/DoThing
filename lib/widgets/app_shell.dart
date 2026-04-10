import 'package:command_palette/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../commands/command_bus.dart';
import 'chat_view.dart';
import 'context_panel.dart';
import 'sidebar.dart';
import 'status_terminal.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _horizontalController = MultiSplitViewController(
    areas: [Area(size: 300, min: 150), Area(flex: 1, min: 200)],
  );

  final _verticalController = MultiSplitViewController(
    areas: [Area(flex: 1, min: 100), Area(size: 150, min: 60)],
  );

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bus = ref.read(commandBusProvider);

    // Build palette actions from the shared command registry.
    final paletteActions = bus.all
        .map(
          (cmd) => CommandPaletteAction.single(
            label: cmd.label,
            description: cmd.description,
            leading: cmd.icon != null ? Icon(cmd.icon, size: 16) : null,
            onSelect: () => bus.run(cmd.id),
          ),
        )
        .toList();

    return CommandPalette(
      actions: paletteActions,
      child: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: MultiSplitView(
              axis: Axis.horizontal,
              controller: _horizontalController,
              builder: (context, area) {
                final index = _horizontalController.areas.indexOf(area);
                if (index == 0) return const ChatView();
                return MultiSplitView(
                  axis: Axis.vertical,
                  controller: _verticalController,
                  builder: (context, area) {
                    final idx = _verticalController.areas.indexOf(area);
                    if (idx == 0) return const ContextPanel();
                    return const StatusTerminal();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
