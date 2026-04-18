import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capabilities/capability_domain.dart';
import '../executor/tool_result.dart';
import 'tool_argument_schema.dart';
import 'tool_mode.dart';
import 'tool_risk_tier.dart';

/// Signature of a tool's invocation callback. Receives a Riverpod [Ref]
/// so it can reach any controller or service, mirroring the existing
/// [AppCommand]/[CommandBus] pattern.
typedef ToolInvokeHandler =
    Future<ToolResult> Function(Ref ref, Map<String, Object?> arguments);

/// Builds the human-readable preview line for the confirmation card.
typedef ToolHumanPreviewBuilder = String Function(Map<String, Object?> args);

/// Model-facing description of a single tool.
///
/// This is the agent counterpart to [AppCommand]: commands are
/// UI-triggered, tools are model-triggered. They may share an underlying
/// service call, but their metadata serves different audiences — hence
/// a separate type.
class ToolDescriptor {
  const ToolDescriptor({
    required this.name,
    required this.description,
    required this.domain,
    required this.mode,
    required this.risk,
    required this.arguments,
    required this.invoke,
    this.humanPreview,
  });

  /// Stable snake_case identifier sent to the model. Never localize.
  final String name;

  /// Plain-English description of the tool's behavior, shown only to
  /// the model. Keep it terse and imperative.
  final String description;

  final CapabilityDomain domain;
  final ToolMode mode;
  final ToolRiskTier risk;
  final ToolArgumentSchema arguments;
  final ToolInvokeHandler invoke;

  /// Optional builder for the confirmation-card title. Required in
  /// practice for [ToolRiskTier.privileged] tools.
  final ToolHumanPreviewBuilder? humanPreview;
}
