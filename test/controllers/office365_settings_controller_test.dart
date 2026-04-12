import 'dart:io';

import 'package:do_thing/controllers/office365_settings_controller.dart';
import 'package:do_thing/models/office365_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('office365_settings_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  ProviderContainer makeContainer() {
    final notifier = Office365SettingsController()
      ..setStorageDirectory(tempDir);
    final container = ProviderContainer(
      overrides: [office365SettingsProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('build returns defaults when no file exists', () async {
    final container = makeContainer();
    final settings = await container.read(office365SettingsProvider.future);
    expect(settings.tenantId, '');
    expect(settings.clientId, '');
    expect(settings.redirectPort, 3141);
    expect(settings.hasToken, isFalse);
  });

  test('updateSettings persists all fields and can be read back', () async {
    final container = makeContainer();
    await container.read(office365SettingsProvider.future);

    const initial = Office365Settings(
      tenantId: 'tenant-1',
      clientId: 'client-2',
      redirectPort: 9000,
    );
    await container
        .read(office365SettingsProvider.notifier)
        .updateSettings(initial);

    final notifier2 = Office365SettingsController()
      ..setStorageDirectory(tempDir);
    final container2 = ProviderContainer(
      overrides: [office365SettingsProvider.overrideWith(() => notifier2)],
    );
    addTearDown(container2.dispose);

    final loaded = await container2.read(office365SettingsProvider.future);
    expect(loaded.tenantId, 'tenant-1');
    expect(loaded.clientId, 'client-2');
    expect(loaded.redirectPort, 9000);
  });

  test('clearAuthState resets tokens while keeping other fields', () async {
    final container = makeContainer();
    await container.read(office365SettingsProvider.future);

    await container
        .read(office365SettingsProvider.notifier)
        .updateSettings(
          const Office365Settings(
            tenantId: 'tid',
            authState: Office365AuthState(
              accessToken: 'tok',
              refreshToken: 'ref',
            ),
          ),
        );

    await container.read(office365SettingsProvider.notifier).clearAuthState();

    final cleared = await container.read(office365SettingsProvider.future);
    expect(cleared.tenantId, 'tid');
    expect(cleared.accessToken, '');
    expect(cleared.refreshToken, '');
    expect(cleared.hasToken, isFalse);
  });

  test('build returns defaults for corrupt JSON', () async {
    await File(
      '${tempDir.path}${Platform.pathSeparator}office365_settings.json',
    ).writeAsString('{bad json');

    final container = makeContainer();
    final settings = await container.read(office365SettingsProvider.future);
    expect(settings.tenantId, '');
  });

  test('build returns defaults for empty file', () async {
    await File(
      '${tempDir.path}${Platform.pathSeparator}office365_settings.json',
    ).writeAsString('  ');

    final container = makeContainer();
    final settings = await container.read(office365SettingsProvider.future);
    expect(settings.clientId, '');
  });
}
