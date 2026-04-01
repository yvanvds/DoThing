import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/status_controller.dart';

class StatusTerminal extends ConsumerWidget {
  const StatusTerminal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(statusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TerminalHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                return _TerminalLine(entry: entries[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: const Row(
        children: [
          Icon(Icons.terminal, size: 14),
          SizedBox(width: 6),
          Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TerminalLine extends StatelessWidget {
  const _TerminalLine({required this.entry});

  final StatusEntry entry;

  @override
  Widget build(BuildContext context) {
    final (color, prefix) = switch (entry.type) {
      StatusEntryType.info => (
        Theme.of(context).colorScheme.onSurfaceVariant,
        '>',
      ),
      StatusEntryType.success => (Colors.green.shade400, '✔'),
      StatusEntryType.warning => (Colors.orange.shade400, '!'),
      StatusEntryType.error => (Colors.red.shade400, '✖'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$prefix ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: color,
            ),
          ),
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
