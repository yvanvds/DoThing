import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/status_controller.dart';

String _formatTime(DateTime timestamp) {
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final second = timestamp.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}

class StatusTerminal extends ConsumerStatefulWidget {
  const StatusTerminal({super.key});

  @override
  ConsumerState<StatusTerminal> createState() => _StatusTerminalState();
}

class _StatusTerminalState extends ConsumerState<StatusTerminal> {
  final _scrollController = ScrollController();
  int _lastEntryCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(statusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (entries.length > _lastEntryCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    _lastEntryCount = entries.length;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TerminalHeader(),
          Expanded(
            child: SelectionArea(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return _TerminalLine(entry: entries[index]);
                },
              ),
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
        '',
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
          SizedBox(
            width: 20,
            child: SelectableText(
              '$prefix',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: color,
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: SelectableText(
              '${_formatTime(entry.timestamp)} ',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
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
