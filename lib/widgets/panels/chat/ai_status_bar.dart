part of 'chat_view.dart';

class _AiStatusBar extends StatelessWidget {
  const _AiStatusBar({
    required this.aiState,
    required this.onCancel,
    required this.onRetry,
  });

  final AsyncValue<AiChatUiState> aiState;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = aiState.asData?.value;

    final label = switch (state?.streamingState) {
      AiStreamingState.waiting => 'Waiting for AI response...',
      AiStreamingState.active => 'AI is streaming...',
      AiStreamingState.completed => 'Last response completed.',
      AiStreamingState.canceled => 'Response canceled.',
      AiStreamingState.failed =>
        state?.lastError?.message ?? 'Response failed.',
      _ => 'Ready',
    };

    final color = switch (state?.streamingState) {
      AiStreamingState.failed => colorScheme.error,
      AiStreamingState.active => colorScheme.primary,
      AiStreamingState.waiting => colorScheme.primary,
      _ => colorScheme.onSurfaceVariant,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_outlined, size: 16),
            label: const Text('Retry'),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.stop_circle_outlined, size: 16),
            label: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
