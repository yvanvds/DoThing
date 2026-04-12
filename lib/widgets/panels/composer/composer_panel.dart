import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/composer_controller.dart';
import '../../../controllers/composer_visibility_controller.dart';
import '../../../controllers/status_controller.dart';
import '../../../services/composer/composer_message_sender.dart';
import 'composer_body.dart';
import 'composer_header.dart';

/// Root composer panel — shown in the detail pane when composing a message.
///
/// Lays out [ComposerHeader] (address fields), [ComposerBody] (rich text
/// editor), and an action row with Cancel and Send.
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

class _ActionRow extends ConsumerStatefulWidget {
  const _ActionRow({required this.onCancel});

  final VoidCallback onCancel;

  @override
  ConsumerState<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends ConsumerState<_ActionRow> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(composerProvider);
    final hasAnyRecipient =
        draft.toRecipients.isNotEmpty ||
        draft.ccRecipients.isNotEmpty ||
        draft.bccRecipients.isNotEmpty;
    final hasSubject = draft.subject.trim().isNotEmpty;
    final canSend = !_sending && hasAnyRecipient && hasSubject;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _sending ? null : widget.onCancel,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: canSend ? _send : null,
            icon: const Icon(Icons.send_outlined, size: 16),
            label: Text(_sending ? 'Sending...' : 'Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    if (_sending) {
      return;
    }

    setState(() => _sending = true);
    try {
      final draft = ref.read(composerProvider);
      await ref.read(composerMessageSenderProvider).send(draft);
      ref.read(composerVisibilityProvider.notifier).close();
      ref.read(composerProvider.notifier).reset();
    } catch (error) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, 'Failed to send message: $error');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}
