import 'app_command.dart';
import 'definitions/composer_commands.dart';
import 'definitions/navigation_commands.dart';
import 'definitions/status_commands.dart';

/// Builds the full list of commands from all feature-based definition files.
///
/// To add new commands, create a file under `definitions/` that returns
/// a `List<AppCommand>`, then spread it here.
List<AppCommand> buildCommandRegistry() => [
  ...navigationCommands(),
  ...statusCommands(),
  ...composerCommands(),
];
