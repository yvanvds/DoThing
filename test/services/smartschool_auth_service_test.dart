import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smartschool/flutter_smartschool.dart';
import 'package:do_thing/controllers/smartschool_settings_controller.dart';
import 'package:do_thing/controllers/status_controller.dart';
import 'package:do_thing/models/smartschool_settings.dart';
import 'package:do_thing/services/smartschool/smartschool_auth_controller.dart';
import 'package:do_thing/services/smartschool/smartschool_bridge.dart';

class _FakeSettingsController extends SmartschoolSettingsController {
  _FakeSettingsController(this._settings);

  final SmartschoolSettings _settings;

  @override
  Future<SmartschoolSettings> build() async => _settings;
}

class _RetryingAuthController extends SmartschoolAuthController {
  _RetryingAuthController({required this.failuresBeforeSuccess});

  final int failuresBeforeSuccess;
  int attempts = 0;

  @override
  Future<SmartschoolConnectionState> build() async =>
      SmartschoolConnectionState.disconnected;

  @override
  Future<SmartschoolBridge> createBridge({
    required String username,
    required String password,
    required String mainUrl,
    String? mfa,
  }) async {
    attempts++;
    if (attempts <= failuresBeforeSuccess) {
      throw Exception('ConnectionError: temporary network issue');
    }
    return SmartschoolBridge.forTesting(
      session: _NoopSessionApi(),
      messages: _NoopMessagesApi(),
    );
  }
}

class _NoopSessionApi implements SmartschoolSessionApi {
  @override
  Future<void> clearCookies() async {}

  @override
  Future<void> ensureAuthenticated() async {}
}

class _NoopMessagesApi implements SmartschoolMessagesApi {
  @override
  Future<void> markRead(int messageId) async {}

  @override
  Future<void> markUnread(int messageId) async {}

  @override
  Future<void> moveToArchive(List<int> messageIds) async {}

  @override
  Future<void> moveToTrash(int messageId) async {}

  @override
  Future<void> setLabel(int messageId, MessageLabel label) async {}

  @override
  Future<List<ShortMessage>> getHeaders({
    required BoxType boxType,
    required List<int> alreadySeenIds,
  }) async {
    return const [];
  }

  @override
  Future<FullMessage?> getMessage(
    int messageId, {
    required BoxType boxType,
    required bool includeAllRecipients,
  }) async {
    return null;
  }

  @override
  Future<(List<MessageSearchUser>, List<MessageSearchUser>)>
  getReplyAllRecipients(int messageId, {required BoxType boxType}) async {
    return (<MessageSearchUser>[], <MessageSearchUser>[]);
  }

  @override
  Future<List<dynamic>> getAttachments(int messageId) async {
    return const [];
  }

  @override
  Future<(List<MessageSearchUser>, List<MessageSearchUser>)>
  getSentMessageRecipients(int messageId) async {
    return (<MessageSearchUser>[], <MessageSearchUser>[]);
  }

  @override
  Future<(List<MessageSearchUser>, List<MessageSearchGroup>)>
  searchRecipientsForCompose(String query) async {
    return (<MessageSearchUser>[], <MessageSearchGroup>[]);
  }

  @override
  Future<void> sendMessage({
    required List<MessageSearchUser> to,
    List<MessageSearchUser> cc = const [],
    List<MessageSearchUser> bcc = const [],
    required String subject,
    required String bodyHtml,
  }) async {}
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

    test('connect retries and succeeds before max attempts', () async {
      final retryingAuth = _RetryingAuthController(failuresBeforeSuccess: 2);
      final container = ProviderContainer(
        overrides: [
          smartschoolSettingsProvider.overrideWith(
            () => _FakeSettingsController(
              const SmartschoolSettings(
                username: 'u',
                password: 'p',
                mfaSecret: 'm',
                url: 'school.example.com',
              ),
            ),
          ),
          smartschoolAuthProvider.overrideWith(() => retryingAuth),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(smartschoolAuthProvider.notifier);
      await notifier.connect();

      expect(retryingAuth.attempts, 3);
      expect(
        container
            .read(smartschoolAuthProvider)
            .maybeWhen(data: (value) => value, orElse: () => null),
        SmartschoolConnectionState.connected,
      );
    });

    test('connect gives up after max retry attempts', () async {
      final retryingAuth = _RetryingAuthController(failuresBeforeSuccess: 10);
      final container = ProviderContainer(
        overrides: [
          smartschoolSettingsProvider.overrideWith(
            () => _FakeSettingsController(
              const SmartschoolSettings(
                username: 'u',
                password: 'p',
                mfaSecret: 'm',
                url: 'school.example.com',
              ),
            ),
          ),
          smartschoolAuthProvider.overrideWith(() => retryingAuth),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(smartschoolAuthProvider.notifier);
      await notifier.connect();

      expect(retryingAuth.attempts, 5);
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
              entry.type == StatusEntryType.error &&
              entry.message.contains('after 5 attempts'),
        ),
        isTrue,
      );
    });
  });
}
