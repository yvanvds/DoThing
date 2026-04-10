import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_thing/commands/command_bus.dart';
import 'package:do_thing/controllers/context_panel_controller.dart';
import 'package:do_thing/controllers/status_controller.dart';

void main() {
  group('CommandBus', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('returns null for unknown command and run is no-op', () async {
      final bus = container.read(commandBusProvider);

      expect(bus.command('doesNotExist'), isNull);
      await expectLater(bus.run('doesNotExist'), completes);
    });

    test('openSettings command updates context panel', () async {
      final bus = container.read(commandBusProvider);

      expect(container.read(contextPanelProvider), ContextView.empty);
      await bus.run('openSettings');
      expect(container.read(contextPanelProvider), ContextView.settings);
    });

    test('clearStatus command clears status entries', () async {
      final bus = container.read(commandBusProvider);

      container.read(statusProvider.notifier).add(StatusEntryType.info, 'temp');
      expect(container.read(statusProvider).length, greaterThan(1));

      await bus.run('clearStatus');

      expect(container.read(statusProvider), isEmpty);
    });
  });
}
