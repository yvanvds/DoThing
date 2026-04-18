import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../controllers/office365_settings_controller.dart';
import '../database/app_database.dart';
import 'office365/office365_mail_service.dart';

/// Backfills avatar URLs for existing contacts and fetches Outlook profile
/// photos from Microsoft Graph.
///
/// All operations are non-fatal: errors are swallowed so avatar sync never
/// blocks message or contact sync.
class AvatarSyncService {
  AvatarSyncService({required AppDatabase db, required Ref ref})
      : _db = db,
        _ref = ref;

  final AppDatabase _db;
  final Ref _ref;

  static const _kGraphBase = 'https://graph.microsoft.com/v1.0';

  /// Fire-and-forget: backfill Smartschool avatars and fetch any pending
  /// Outlook photos. Returns immediately; work runs in the background.
  void scheduleSync() {
    unawaited(_backfillSmartschoolAvatars());
    unawaited(_fetchOutlookAvatars());
  }

  // ── Smartschool backfill ───────────────────────────────────────────────────

  Future<void> _backfillSmartschoolAvatars() async {
    try {
      final pairs = await _db.contactsDao.findSmartschoolAvatarsFromMessages();
      for (final (identityId, avatarUrl) in pairs) {
        await _db.contactsDao.updateIdentityAvatarUrl(identityId, avatarUrl);
      }
    } catch (_) {}
  }

  // ── Outlook photo fetch ────────────────────────────────────────────────────

  Future<void> _fetchOutlookAvatars() async {
    try {
      final settings = await _ref.read(office365SettingsProvider.future);
      if (!settings.hasToken) return;

      // Derive tenant domain from the signed-in account email.
      // Only attempt photo fetch for senders on the same domain.
      final accountEmail = settings.accountEmail.trim().toLowerCase();
      final atIndex = accountEmail.indexOf('@');
      if (atIndex < 0) return;
      final tenantDomain = accountEmail.substring(atIndex + 1);
      if (tenantDomain.isEmpty) return;

      final identities =
          await _db.contactsDao.findOutlookIdentitiesNeedingAvatarFetch();
      if (identities.isEmpty) return;

      String token;
      try {
        token =
            await _ref.read(office365MailServiceProvider).ensureValidAccessToken();
      } catch (_) {
        return;
      }

      final cacheDir = await _avatarCacheDir();

      for (final identity in identities) {
        final email = identity.externalId.trim().toLowerCase();
        final emailAtIndex = email.indexOf('@');
        if (emailAtIndex < 0) {
          // Not a valid email — skip and mark so we don't retry.
          await _db.contactsDao.markOutlookAvatarChecked(identity.id);
          continue;
        }

        final senderDomain = email.substring(emailAtIndex + 1);
        if (senderDomain != tenantDomain) {
          // External sender — no Graph user in our tenant.
          await _db.contactsDao.markOutlookAvatarChecked(identity.id);
          continue;
        }

        await _fetchAndCachePhoto(
          token: token,
          identityId: identity.id,
          email: email,
          cacheDir: cacheDir,
        );
      }
    } catch (_) {}
  }

  Future<void> _fetchAndCachePhoto({
    required String token,
    required int identityId,
    required String email,
    required Directory cacheDir,
  }) async {
    final encodedEmail = Uri.encodeComponent(email);
    final uri = Uri.parse('$_kGraphBase/users/$encodedEmail/photo/\$value');
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>(
          <int>[],
          (acc, chunk) => acc..addAll(chunk),
        );
        if (bytes.isNotEmpty) {
          final hash = sha256
              .convert(utf8.encode(email))
              .toString()
              .substring(0, 32);
          final file = File(
            '${cacheDir.path}${Platform.pathSeparator}$hash.jpg',
          );
          await file.writeAsBytes(bytes);
          await _db.contactsDao.markOutlookAvatarChecked(
            identityId,
            filePath: file.path,
          );
          return;
        }
        // 200 but empty body: treat as no photo.
        await _db.contactsDao.markOutlookAvatarChecked(identityId);
        return;
      }

      await response.drain<void>();

      if (response.statusCode >= 400 && response.statusCode < 500) {
        // 4xx: user has no photo or is not resolvable — do not retry.
        await _db.contactsDao.markOutlookAvatarChecked(identityId);
      }
      // 5xx or other: leave state null so we retry next startup.
    } on SocketException catch (_) {
      // Network error: leave state null so we retry next startup.
    } catch (_) {
      // Unexpected error: mark to avoid a crash loop.
      await _db.contactsDao.markOutlookAvatarChecked(identityId);
    } finally {
      client.close(force: true);
    }
  }

  // ── Cache directory ────────────────────────────────────────────────────────

  static Future<Directory> _avatarCacheDir() async {
    final appData = Platform.environment['APPDATA'];
    final basePath =
        appData != null && appData.isNotEmpty
            ? '$appData${Platform.pathSeparator}DoThing'
            : (await getApplicationSupportDirectory()).path;
    final dir = Directory(
      '$basePath${Platform.pathSeparator}avatars',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
