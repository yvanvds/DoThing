import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_command.dart';
import 'command_registry.dart';

/// Provides the single [CommandBus] instance to the widget tree.
final commandBusProvider = Provider<CommandBus>((ref) {
  final commands = buildCommandRegistry();
  return CommandBus(ref, {for (final cmd in commands) cmd.id: cmd});
});

/// Executes [AppCommand]s by id.
///
/// Obtained via [commandBusProvider]. Both the command palette and
/// sidebar buttons call [run] with the same command id, ensuring a
/// single source of truth for every action.
class CommandBus {
  CommandBus(this._ref, this._commands);

  final Ref _ref;
  final Map<String, AppCommand> _commands;

  /// Look up a command by [id]. Returns `null` when not found.
  AppCommand? command(String id) => _commands[id];

  /// All registered commands (useful for building the palette).
  List<AppCommand> get all => _commands.values.toList(growable: false);

  /// Execute the command identified by [id].
  Future<void> run(String id) async {
    final cmd = _commands[id];
    if (cmd == null) return;
    await cmd.execute(_ref);
  }
}
