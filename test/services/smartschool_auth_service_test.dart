import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_thing/controllers/smartschool_settings_controller.dart';
import 'package:do_thing/controllers/status_controller.dart';
import 'package:do_thing/models/smartschool_settings.dart';
import 'package:do_thing/services/smartschool_auth_service.dart';

class _FakeSettingsController extends SmartschoolSettingsController {
  _FakeSettingsController(this._settings);

  final SmartschoolSettings _settings;

  @override
  Future<SmartschoolSettings> build() async => _settings;
}

void main() {
  group('SmartschoolAuthController', () {
    test(
      'connect reports incomplete settings and stays disconnected',
      () async {
        final container = ProviderContainer(
          overrides: [
            smartschoolSettingsProvider.overrideWith(
              () => _FakeSettingsController(const SmartschoolSettings()),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(smartschoolAuthProvider.notifier);
        await notifier.connect();

        final authState = container.read(smartschoolAuthProvider);
        expect(
          authState.maybeWhen(data: (value) => value, orElse: () => null),
          SmartschoolConnectionState.disconnected,
        );

        final statusEntries = container.read(statusProvider);
        expect(
          statusEntries.any(
            (entry) =>
                entry.type == StatusEntryType.error &&
                entry.message.contains('settings are incomplete'),
          ),
          isTrue,
        );
      },
    );

    test('connect maps invalid URL format to friendly error', () async {
      final container = ProviderContainer(
        overrides: [
          smartschoolSettingsProvider.overrideWith(
            () => _FakeSettingsController(
              const SmartschoolSettings(
                username: 'u',
                password: 'p',
                mfaSecret: 'm',
                url: 'https://',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(smartschoolAuthProvider.notifier);
      await notifier.connect();

      final authState = container.read(smartschoolAuthProvider);
      expect(
        authState.maybeWhen(data: (value) => value, orElse: () => null),
        SmartschoolConnectionState.disconnected,
      );

      final statusEntries = container.read(statusProvider);
      expect(
        statusEntries.any(
          (entry) =>
              entry.type == StatusEntryType.error &&
              entry.message.contains('invalid school URL format'),
        ),
        isTrue,
      );
    });

    test('disconnect sets disconnected and appends status entry', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(smartschoolAuthProvider.notifier);
      await notifier.disconnect();

      expect(
        container
            .read(smartschoolAuthProvider)
            .maybeWhen(data: (value) => value, orElse: () => null),
        SmartschoolConnectionState.disconnected,
      );

      final statusEntries = container.read(statusProvider);
      expect(
        statusEntries.any(
          (entry) =>
              entry.type == StatusEntryType.info &&
              entry.message == 'Disconnected from Smartschool.',
        ),
        isTrue,
      );
    });
  });
}
