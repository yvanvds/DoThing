import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../commands/command_bus.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  static const double width = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bus = ref.read(commandBusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _SidebarIcon(
            icon: Icons.chat_bubble_outline,
            tooltip: 'Chat',
            onTap: () => bus.run('openChat'),
          ),
          _SidebarIcon(
            icon: Icons.folder_outlined,
            tooltip: 'Files',
            onTap: () {},
          ),
          _SidebarIcon(icon: Icons.search, tooltip: 'Search', onTap: () {}),
          _SidebarIcon(
            icon: Icons.extension_outlined,
            tooltip: 'Extensions',
            onTap: () {},
          ),
          const Spacer(),
          _SidebarIcon(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onTap: () => bus.run('openSettings'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}
