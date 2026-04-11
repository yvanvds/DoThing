import 'package:command_palette/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _paletteAnchorKey = GlobalKey();

  final _horizontalController = MultiSplitViewController(
    areas: [Area(size: 300, min: 150), Area(flex: 1, min: 200)],
  );

  final _verticalController = MultiSplitViewController(
    areas: [Area(flex: 1, min: 100), Area(size: 150, min: 60)],
  );

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalShortcut);
  }

  bool _handleGlobalShortcut(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    if (event.logicalKey != LogicalKeyboardKey.keyP) {
      return false;
    }

    final keyboard = HardwareKeyboard.instance;
    final hasPlatformModifier =
        keyboard.isControlPressed || keyboard.isMetaPressed;

    if (!hasPlatformModifier || !keyboard.isShiftPressed) {
      return false;
    }

    final paletteContext = _paletteAnchorKey.currentContext;
    if (paletteContext == null) {
      return false;
    }

    CommandPalette.of(paletteContext).open();
    return true;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalShortcut);
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bus = ref.read(commandBusProvider);
    final viewport = MediaQuery.sizeOf(context);
    final chatWidth = _horizontalController.areas.first.size ?? 300;
    final minPaletteWidth = 320.0;

    final rawPaletteLeft = Sidebar.width + chatWidth;
    final maxPaletteLeft = (viewport.width - minPaletteWidth).clamp(
      0.0,
      viewport.width,
    );
    final paletteLeft = rawPaletteLeft.clamp(0.0, maxPaletteLeft);
    final paletteWidth = (viewport.width - paletteLeft).clamp(
      minPaletteWidth,
      viewport.width,
    );

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
      config: CommandPaletteConfig(
        // Keep the modal visually attached to the right panel's palette bar.
        top: 0,
        left: paletteLeft,
        width: paletteWidth,
        height: viewport.height,
        openKeySet: SingleActivator(LogicalKeyboardKey.f24),
        style: const CommandPaletteStyle(
          commandPaletteBarrierColor: Colors.transparent,
        ),
      ),
      actions: paletteActions,
      child: KeyedSubtree(
        key: _paletteAnchorKey,
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
      ),
    );
  }
}
