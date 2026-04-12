import 'package:do_thing/services/office365/office365_mail_service.dart';
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
  });
}
