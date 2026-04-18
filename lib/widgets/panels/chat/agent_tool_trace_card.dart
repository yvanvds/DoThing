import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../agent/orchestrator/agent_orchestrator_controller.dart';
import '../../../agent/orchestrator/agent_tool_trace.dart';
import '../../../agent/tools/tool_risk_tier.dart';

/// Compact list of commit/privileged tool invocations executed during
/// the current agent turn, rendered as a sidecar stack above the chat.
///
/// Stays out of the Chat message builder on purpose — traces belong to
/// agent control surfaces, not the transcript text.
class AgentToolTraceList extends ConsumerWidget {
  const AgentToolTraceList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traces = ref.watch(
      agentOrchestratorControllerProvider.select((s) => s.traces),
    );
    if (traces.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final trace in traces) _AgentToolTraceCard(trace: trace),
        ],
      ),
    );
  }
}

class _AgentToolTraceCard extends StatelessWidget {
  const _AgentToolTraceCard({required this.trace});

  final AgentToolTrace trace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _accentColor(trace, colorScheme);
    final icon = _icon(trace);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(
          left: BorderSide(color: accent, width: 3),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trace.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if ((trace.detail ?? '').trim().isNotEmpty)
                  Text(
                    trace.detail!.trim(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _icon(AgentToolTrace trace) {
    if (trace.canceled) return Icons.block;
    if (trace.isError) return Icons.error_outline;
    return Icons.check_circle_outline;
  }

  static Color _accentColor(AgentToolTrace trace, ColorScheme scheme) {
    if (trace.canceled) return scheme.onSurfaceVariant;
    if (trace.isError) return scheme.error;
    return switch (trace.risk) {
      ToolRiskTier.read || ToolRiskTier.prepare => scheme.primary,
      ToolRiskTier.commit => scheme.tertiary,
      ToolRiskTier.privileged => scheme.secondary,
    };
  }
}
