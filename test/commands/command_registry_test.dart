import 'package:flutter_test/flutter_test.dart';
import 'package:do_thing/commands/command_registry.dart';

void main() {
  test('buildCommandRegistry exposes expected command ids', () {
    final commands = buildCommandRegistry();
    final ids = commands.map((c) => c.id).toSet();

    expect(
      ids,
      containsAll({
        'openChat',
        'openSettings',
        'openMessages',
        'clearStatus',
        'newMessage',
      }),
    );
    expect(commands.length, ids.length);
  });
}
