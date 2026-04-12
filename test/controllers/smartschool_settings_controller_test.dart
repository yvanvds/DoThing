import 'dart:io';

import 'package:do_thing/controllers/smartschool_settings_controller.dart';
import 'package:do_thing/models/smartschool_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('smartschool_settings_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  ProviderContainer makeContainer() {
    final notifier = SmartschoolSettingsController()
      ..setStorageDirectory(tempDir);
    final container = ProviderContainer(
      overrides: [smartschoolSettingsProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('build returns defaults when no file exists', () async {
    final container = makeContainer();
    final settings = await container.read(smartschoolSettingsProvider.future);
    expect(settings, isA<SmartschoolSettings>());
    expect(settings.username, '');
    expect(settings.url, '');
  });

  test('updateSettings persists and can be read back', () async {
    final container = makeContainer();
    await container.read(smartschoolSettingsProvider.future);

    await container
        .read(smartschoolSettingsProvider.notifier)
        .updateSettings(
          const SmartschoolSettings(
            username: 'stef',
            password: 'pass123',
            url: 'https://school.smartschool.be',
          ),
        );

    // Create a fresh container that reads the same directory.
    final notifier2 = SmartschoolSettingsController()
      ..setStorageDirectory(tempDir);
    final container2 = ProviderContainer(
      overrides: [smartschoolSettingsProvider.overrideWith(() => notifier2)],
    );
    addTearDown(container2.dispose);

    final loaded = await container2.read(smartschoolSettingsProvider.future);
    expect(loaded.username, 'stef');
    expect(loaded.url, 'https://school.smartschool.be');
    expect(loaded.password, 'pass123');
  });

  test('build returns defaults for corrupt/invalid JSON', () async {
    await File(
      '${tempDir.path}${Platform.pathSeparator}smartschool_settings.json',
    ).writeAsString('not json {{{');

    final container = makeContainer();
    final settings = await container.read(smartschoolSettingsProvider.future);
    expect(settings.username, '');
  });

  test('build returns defaults for empty JSON file', () async {
    await File(
      '${tempDir.path}${Platform.pathSeparator}smartschool_settings.json',
    ).writeAsString('   ');

    final container = makeContainer();
    final settings = await container.read(smartschoolSettingsProvider.future);
    expect(settings.username, '');
  });
}
