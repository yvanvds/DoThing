import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../commands/command_bus.dart';
import '../controllers/smartschool_inbox_controller.dart';
import '../services/smartschool_messages_service.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  static const double width = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bus = ref.read(commandBusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(smartschoolPollingProvider, (previous, next) {
      if (next != previous) {
        ref
            .read(smartschoolInboxProvider.notifier)
            .refreshInboxAndGetHeaders(showLoading: false);
      }
    });

    final unreadCountAsync = ref.watch(smartschoolInboxProvider);
    final unreadCount = unreadCountAsync.asData?.value ?? 0;

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
            icon: Icons.mail_outline,
            tooltip: 'Mail',
            onTap: () => bus.run('openMessages'),
            badgeCount: unreadCount,
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
    this.badgeCount,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int? badgeCount;

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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 22),
              if ((badgeCount ?? 0) > 0)
                Positioned(
                  right: -8,
                  top: -6,
                  child: _Badge(count: badgeCount!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = count > 99 ? '99+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onError,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
