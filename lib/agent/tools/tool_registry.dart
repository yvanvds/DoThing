import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capabilities/capability_domain.dart';
import 'definitions/composer_tools.dart';
import 'definitions/focus_tools.dart';
import 'definitions/mailbox_tools.dart';
import 'definitions/navigation_tools.dart';
import 'tool_descriptor.dart';
import 'tool_risk_tier.dart';

/// Thrown at [ToolRegistry] construction when a [ToolDescriptor] violates
/// a structural invariant (duplicate name, risk above the domain's
/// ceiling). These represent code-level bugs, not runtime input errors.
class ToolRegistryConfigurationError extends StateError {
  ToolRegistryConfigurationError(super.message);
}

/// In-memory lookup of the agent's [ToolDescriptor]s.
///
/// Mirrors the existing [CommandBus] lookup pattern for [AppCommand]s.
/// The registry is assembled once at app start and shared via
/// [toolRegistryProvider]; domain activation is a pure
/// `Set<CapabilityDomain>` → `List<ToolDescriptor>` function.
class ToolRegistry {
  ToolRegistry(Iterable<ToolDescriptor> tools)
    : _byName = <String, ToolDescriptor>{} {
    for (final tool in tools) {
      if (_byName.containsKey(tool.name)) {
        throw ToolRegistryConfigurationError(
          'Duplicate tool name "${tool.name}" in registry.',
        );
      }
      final ceiling = capabilityDomainRiskCeiling[tool.domain];
      if (ceiling == null) {
        throw ToolRegistryConfigurationError(
          'Domain ${tool.domain} has no risk ceiling configured.',
        );
      }
      if (tool.risk.index > ceiling.index) {
        throw ToolRegistryConfigurationError(
          'Tool "${tool.name}" has risk ${tool.risk.name} which exceeds '
          'the ${tool.domain.name} domain ceiling (${ceiling.name}).',
        );
      }
      _byName[tool.name] = tool;
    }
  }

  final Map<String, ToolDescriptor> _byName;

  /// All registered tools, in insertion order.
  List<ToolDescriptor> get all => _byName.values.toList(growable: false);

  /// Subset of tools whose [ToolDescriptor.domain] is in [domains].
  /// Returns a new list; callers may iterate freely.
  List<ToolDescriptor> forDomains(Set<CapabilityDomain> domains) {
    if (domains.isEmpty) return const [];
    return _byName.values
        .where((tool) => domains.contains(tool.domain))
        .toList(growable: false);
  }

  /// Look up a tool by the model-facing [name]. Returns `null` when no
  /// such tool is registered.
  ToolDescriptor? byName(String name) => _byName[name];

  /// True when this registry contains any tool whose risk matches [tier].
  bool hasRisk(ToolRiskTier tier) =>
      _byName.values.any((tool) => tool.risk == tier);
}

/// Builds the default [ToolRegistry] from the feature-based definition
/// files under `agent/tools/definitions/`.
///
/// New tool sets should be added here once their definitions file is
/// created, mirroring how [buildCommandRegistry] aggregates commands.
List<ToolDescriptor> buildToolRegistry() => [
  ...mailboxTools(),
  ...navigationTools(),
  ...composerTools(),
  ...focusTools(),
];

/// Provides the app-wide [ToolRegistry].
final toolRegistryProvider = Provider<ToolRegistry>((ref) {
  return ToolRegistry(buildToolRegistry());
});
