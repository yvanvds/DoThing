import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_thing/controllers/app_initialization_controller.dart';
import 'package:do_thing/controllers/context_panel_controller.dart';
import 'package:do_thing/controllers/settings_navigation_controller.dart';
import 'package:do_thing/controllers/status_controller.dart';
import 'package:do_thing/controllers/theme_mode_controller.dart';
import 'package:do_thing/controllers/smartschool_inbox_controller.dart';
import 'package:do_thing/services/office365/office365_polling_controller.dart';

class _FakeSmartschoolInboxController extends SmartschoolInboxController {
  @override
  Future<int> build() async => 0;
}

class _FakeOffice365PollingController extends Office365PollingController {
  @override
  int build() => 0;
}

void main() {
  group('ContextPanelController', () {
    test('builds empty and supports show/reset', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(contextPanelProvider), ContextView.empty);

      container.read(contextPanelProvider.notifier).show(ContextView.messages);
      expect(container.read(contextPanelProvider), ContextView.messages);

      container.read(contextPanelProvider.notifier).reset();
      expect(container.read(contextPanelProvider), ContextView.empty);
    });
  });

  group('StatusController', () {
    test('starts with Ready, adds entries, then clears', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(statusProvider);
      expect(initial, hasLength(1));
      expect(initial.first.type, StatusEntryType.info);
      expect(initial.first.message, 'Ready.');

      container
          .read(statusProvider.notifier)
          .add(StatusEntryType.success, 'Synced');
      final afterAdd = container.read(statusProvider);
      expect(afterAdd, hasLength(2));
      expect(afterAdd.last.type, StatusEntryType.success);
      expect(afterAdd.last.message, 'Synced');

      container.read(statusProvider.notifier).clear();
      expect(container.read(statusProvider), isEmpty);
    });
  });

  group('ThemeModeController', () {
    test('defaults to system and can update mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
      container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });

  group('SettingsNavigationController', () {
    test('navigates to section id and clears', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(settingsNavigationProvider), isNull);
      container
          .read(settingsNavigationProvider.notifier)
          .navigateTo('security');
      expect(container.read(settingsNavigationProvider), 'security');
      container.read(settingsNavigationProvider.notifier).clear();
      expect(container.read(settingsNavigationProvider), isNull);
    });
  });

  group('AppInitializationOverrideController', () {
    test('dismisses startup blocking without requiring sync completion', () {
      final container = ProviderContainer(
        overrides: [
          smartschoolInboxProvider.overrideWith(
            _FakeSmartschoolInboxController.new,
          ),
          smartschoolInitialInboxRetrievalDoneProvider.overrideWith(
            SmartschoolInitialInboxRetrievalDoneController.new,
          ),
          office365PollingProvider.overrideWith(
            _FakeOffice365PollingController.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(appInitializationProvider), isFalse);

      container.read(appInitializationOverrideProvider.notifier).dismiss();

      expect(container.read(appInitializationProvider), isTrue);

      container.read(appInitializationOverrideProvider.notifier).reset();

      expect(container.read(appInitializationProvider), isFalse);
    });
  });
}
