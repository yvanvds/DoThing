import 'package:do_thing/models/office365_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Office365AuthState', () {
    test('hasToken is false when accessToken is empty', () {
      const state = Office365AuthState();
      expect(state.hasToken, isFalse);
    });

    test('hasToken is false when accessToken is whitespace only', () {
      const state = Office365AuthState(accessToken: '   ');
      expect(state.hasToken, isFalse);
    });

    test('hasToken is true when accessToken is present', () {
      const state = Office365AuthState(accessToken: 'tok');
      expect(state.hasToken, isTrue);
    });

    test('expiresAt returns null for empty expiresAtIso', () {
      const state = Office365AuthState();
      expect(state.expiresAt, isNull);
    });

    test('expiresAt returns null for invalid ISO string', () {
      const state = Office365AuthState(expiresAtIso: 'not-a-date');
      expect(state.expiresAt, isNull);
    });

    test('expiresAt parses valid ISO8601 string', () {
      const state = Office365AuthState(
        expiresAtIso: '2026-01-15T12:00:00.000Z',
      );
      expect(state.expiresAt, DateTime.utc(2026, 1, 15, 12));
    });

    test('copyWith updates only specified fields', () {
      const original = Office365AuthState(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtIso: '2026-01-01T00:00:00Z',
        accountEmail: 'e@e.com',
        accountDisplayName: 'E',
      );

      final updated = original.copyWith(accessToken: 'new-token');
      expect(updated.accessToken, 'new-token');
      expect(updated.refreshToken, 'r');
      expect(updated.accountEmail, 'e@e.com');
    });
  });

  group('Office365Settings', () {
    test('default constructor provides expected defaults', () {
      const settings = Office365Settings();
      expect(settings.tenantId, '');
      expect(settings.clientId, '');
      expect(settings.redirectPort, 3141);
      expect(settings.hasToken, isFalse);
    });

    test('delegating getters forward to authState', () {
      const auth = Office365AuthState(
        accessToken: 'tok',
        refreshToken: 'ref',
        expiresAtIso: '2026-06-01T00:00:00Z',
        accountEmail: 'user@work.com',
        accountDisplayName: 'User',
      );
      const settings = Office365Settings(authState: auth);

      expect(settings.accessToken, 'tok');
      expect(settings.refreshToken, 'ref');
      expect(settings.accountEmail, 'user@work.com');
      expect(settings.accountDisplayName, 'User');
      expect(settings.hasToken, isTrue);
      expect(settings.expiresAt, isNotNull);
    });

    test('copyWith replaces only specified fields', () {
      const original = Office365Settings(
        tenantId: 't1',
        clientId: 'c1',
        redirectPort: 8080,
      );

      final updated = original.copyWith(clientId: 'c2');
      expect(updated.tenantId, 't1');
      expect(updated.clientId, 'c2');
      expect(updated.redirectPort, 8080);
    });
  });
}
