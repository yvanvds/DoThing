import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handler signature for commands. Receives a [Ref] so it can
/// interact with any Riverpod provider (controllers, services, etc.).
typedef CommandHandler = Future<void> Function(Ref ref);

/// A single application command.
///
/// Commands are the shared unit of work between the command palette,
/// sidebar buttons, keyboard shortcuts, and any other invoker.
class AppCommand {
  const AppCommand({
    required this.id,
    required this.label,
    required this.execute,
    this.description = '',
    this.icon,
  });

  /// Unique identifier used to invoke this command (e.g. `'openSettings'`).
  final String id;

  /// Human-readable label shown in the command palette and tooltips.
  final String label;

  /// Optional longer description.
  final String description;

  /// Optional icon for sidebar buttons and palette entries.
  final IconData? icon;

  /// The work this command performs.
  final CommandHandler execute;
}
