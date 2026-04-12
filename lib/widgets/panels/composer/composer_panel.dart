import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/composer_controller.dart';
import '../../../controllers/composer_visibility_controller.dart';
import 'composer_body.dart';
import 'composer_header.dart';

/// Root composer panel — shown in the detail pane when composing a message.
///
/// Lays out [ComposerHeader] (address fields), [ComposerBody] (rich text
/// editor), and an action row with Cancel and a placeholder Send button.
class ComposerPanel extends ConsumerWidget {
  const ComposerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // FocusTraversalGroup creates a traversal boundary so Tab cycles through
    // To → CC → BCC → Subject → editor without escaping to the message list.
    return FocusTraversalGroup(
      child: Column(
        children: [
          _ComposerTitleBar(colorScheme: colorScheme),
          const Divider(height: 1),
          const ComposerHeader(),
          const Divider(height: 1),
          const Expanded(child: ComposerBody()),
          const Divider(height: 1),
          _ActionRow(
            onCancel: () {
              ref.read(composerVisibilityProvider.notifier).close();
              ref.read(composerProvider.notifier).reset();
            },
          ),
        ],
      ),
    );
  }
}

class _ComposerTitleBar extends StatelessWidget {
  const _ComposerTitleBar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'New message',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: onCancel, child: const Text('Cancel')),
          const SizedBox(width: 8),
          FilledButton.icon(
            // TODO: inject MessageSender and enable when To + Subject are valid
            onPressed: null,
            icon: const Icon(Icons.send_outlined, size: 16),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
