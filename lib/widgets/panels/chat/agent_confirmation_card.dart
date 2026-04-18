import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../agent/confirmation/pending_confirmation.dart';
import '../../../agent/orchestrator/agent_orchestrator_controller.dart';
import '../../../agent/tools/tool_risk_tier.dart';

/// Sidecar card rendered above the chat transcript whenever the agent
/// executor has paused on a privileged tool call. Confirm resumes the
/// executor with the staged arguments; Cancel injects a canceled tool
/// result so the model can abandon or propose an alternative.
class AgentConfirmationCard extends ConsumerWidget {
  const AgentConfirmationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
      agentOrchestratorControllerProvider.select((s) => s.pending),
    );
    if (pending == null) {
      return const SizedBox.shrink();
    }
    return _AgentConfirmationCardBody(pending: pending);
  }
}

class _AgentConfirmationCardBody extends ConsumerWidget {
  const _AgentConfirmationCardBody({required this.pending});

  final PendingConfirmation pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final riskColor = _riskColor(pending.risk, colorScheme);

    final orchestrator = ref.read(
      agentOrchestratorControllerProvider.notifier,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(color: riskColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: riskColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pending.humanPreview,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _RiskBadge(risk: pending.risk, color: riskColor),
            ],
          ),
          if ((pending.reason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              pending.reason!.trim(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _ArgumentsBlock(arguments: pending.arguments),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => orchestrator.cancelPending(pending.id),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => orchestrator.confirmPending(pending.id),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Confirm'),
                style: FilledButton.styleFrom(backgroundColor: riskColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _riskColor(ToolRiskTier risk, ColorScheme scheme) {
    switch (risk) {
      case ToolRiskTier.read:
      case ToolRiskTier.prepare:
        return scheme.primary;
      case ToolRiskTier.commit:
        return scheme.tertiary;
      case ToolRiskTier.privileged:
        return scheme.error;
    }
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.risk, required this.color});

  final ToolRiskTier risk;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        risk.name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ArgumentsBlock extends StatelessWidget {
  const _ArgumentsBlock({required this.arguments});

  final Map<String, Object?> arguments;

  @override
  Widget build(BuildContext context) {
    if (arguments.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    const encoder = JsonEncoder.withIndent('  ');
    final pretty = encoder.convert(arguments);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        pretty,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          fontSize: 11.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
