import 'package:do_thing/services/office365/office365_mail_service.dart';
import 'package:do_thing/models/office365_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Office365MailServiceUtils', () {
    test('normalizedScopes adds required scopes and deduplicates values', () {
      final scopes = Office365MailServiceUtils.normalizedScopes(
        'Mail.Read User.Read Mail.Read',
      ).split(' ');

      expect(scopes.contains('Mail.Read'), isTrue);
      expect(scopes.contains('offline_access'), isTrue);
      expect(scopes.contains('openid'), isTrue);
      expect(scopes.contains('profile'), isTrue);
      expect(scopes.where((scope) => scope == 'Mail.Read').length, 1);
    });

    test('pkceChallenge is deterministic for known verifier', () {
      const verifier = 'abc123xyz';
      final challenge = Office365MailServiceUtils.pkceChallenge(verifier);

      expect(challenge, 'YENl-hFG0X6BqkHvcu8DsHpdPC5Ez6b5uBdgZ3nsyuY');
    });

    test('toPlainText keeps non-html body unchanged', () {
      const raw = 'Line 1\nLine 2';
      final plain = Office365MailServiceUtils.toPlainText(
        raw,
        bodyFormat: 'text',
      );

      expect(plain, raw);
    });

    test('toPlainText strips html and decodes common entities', () {
      const raw = '<p>Hello&nbsp;<b>world</b>&amp;team&lt;x&gt;</p>';
      final plain = Office365MailServiceUtils.toPlainText(
        raw,
        bodyFormat: 'html',
      );

      expect(plain, 'Hello world &team<x>');
    });

    test('formEncode escapes keys and values', () {
      final encoded = Office365MailServiceUtils.formEncode({
        'client id': 'abc 123',
        'redirect_uri': 'http://127.0.0.1/callback?x=1',
      });

      expect(
        encoded,
        'client+id=abc+123&redirect_uri=http%3A%2F%2F127.0.0.1%2Fcallback%3Fx%3D1',
      );
    });

    test('validateSettings accepts valid settings', () {
      const settings = Office365Settings(
        tenantId: 'tenant',
        clientId: 'client',
        redirectPort: 8080,
      );

      expect(
        () => Office365MailServiceUtils.validateSettings(settings),
        returnsNormally,
      );
    });

    test('validateSettings rejects missing tenant id', () {
      const settings = Office365Settings(
        tenantId: '  ',
        clientId: 'client',
        redirectPort: 8080,
      );

      expect(
        () => Office365MailServiceUtils.validateSettings(settings),
        throwsA(isA<StateError>()),
      );
    });

    test('validateSettings rejects missing client id', () {
      const settings = Office365Settings(
        tenantId: 'tenant',
        clientId: ' ',
        redirectPort: 8080,
      );

      expect(
        () => Office365MailServiceUtils.validateSettings(settings),
        throwsA(isA<StateError>()),
      );
    });

    test('validateSettings rejects invalid redirect port', () {
      const settings = Office365Settings(
        tenantId: 'tenant',
        clientId: 'client',
        redirectPort: 0,
      );

      expect(
        () => Office365MailServiceUtils.validateSettings(settings),
        throwsA(isA<StateError>()),
      );
    });
  });
}
