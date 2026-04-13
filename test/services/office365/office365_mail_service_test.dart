import 'dart:convert';
import 'dart:io';

import 'package:do_thing/controllers/office365_settings_controller.dart';
import 'package:do_thing/models/office365_settings.dart';
import 'package:do_thing/providers/database_provider.dart';
import 'package:do_thing/services/office365/office365_mail_service.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _office365TestServiceProvider = Provider<Office365MailService>(
  (ref) => throw UnimplementedError(),
);

class _FakeOffice365SettingsController extends Office365SettingsController {
  _FakeOffice365SettingsController(this._settings);

  final Office365Settings _settings;

  @override
  Future<Office365Settings> build() async => _settings;
}

Future<int> _insertOutlookMessage(
  AppDatabase db, {
  required String externalId,
  bool isRead = false,
}) {
  return db.messagesDao.insertMessage(
    MessagesCompanion.insert(
      source: 'outlook',
      externalId: externalId,
      mailbox: 'inbox',
      subject: const Value('Outlook message'),
      receivedAt: DateTime.parse('2026-04-13T10:00:00Z'),
      isRead: Value(isRead),
    ),
  );
}

Future<MessageAttachment> _insertAttachment(
  AppDatabase db, {
  required int messageId,
  required String externalId,
  String filename = 'attachment.txt',
}) async {
  await db
      .into(db.messageAttachments)
      .insert(
        MessageAttachmentsCompanion.insert(
          messageId: messageId,
          source: 'outlook',
          externalId: Value(externalId),
          filename: filename,
        ),
      );

  return (await db.attachmentsDao.getAttachmentsForMessage(messageId)).single;
}

Office365Settings _settingsWithToken() {
  return const Office365Settings(
    tenantId: 'tenant-id',
    clientId: 'client-id',
    authState: Office365AuthState(
      accessToken: 'token-123',
      expiresAtIso: '2999-01-01T00:00:00Z',
    ),
  );
}

void main() {
  group('Office365MailService', () {
    test(
      'downloadAttachment stores file and marks attachment downloaded',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final messageId = await _insertOutlookMessage(db, externalId: 'msg-1');
        final attachment = await _insertAttachment(
          db,
          messageId: messageId,
          externalId: 'att-1',
        );

        final tempDir = await Directory.systemTemp.createTemp(
          'office365_download_',
        );
        addTearDown(() async {
          if (tempDir.existsSync()) {
            await tempDir.delete(recursive: true);
          }
        });

        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);
        server.listen((request) async {
          if (request.method == 'GET' &&
              request.uri.path == '/v1.0/me/messages/msg-1/attachments/att-1') {
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode({
                'id': 'att-1',
                'name': 'server-file.txt',
                'contentBytes': base64Encode(utf8.encode('hello outlook')),
              }),
            );
            await request.response.close();
            return;
          }

          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        });

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            office365SettingsProvider.overrideWith(
              () => _FakeOffice365SettingsController(_settingsWithToken()),
            ),
            _office365TestServiceProvider.overrideWith(
              (ref) => Office365MailService(
                ref,
                graphApiBaseUri: Uri.parse(
                  'http://127.0.0.1:${server.port}/v1.0',
                ),
                saveDownloadedFile: (fileName, bytes) async {
                  final file = File(
                    '${tempDir.path}${Platform.pathSeparator}$fileName',
                  );
                  await file.writeAsBytes(bytes, flush: true);
                  return file;
                },
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(_office365TestServiceProvider);
        final file = await service.downloadAttachment(
          localMessageId: messageId,
          attachment: attachment,
        );

        expect(await file.readAsString(), 'hello outlook');

        final updated = (await db.attachmentsDao.getAttachmentsForMessage(
          messageId,
        )).single;
        expect(updated.downloadStatus, 'downloaded');
        expect(updated.localPath, file.path);
        expect(updated.localSha256, isNotEmpty);
      },
    );

    test(
      'downloadAttachment marks attachment failed when payload has no bytes',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final messageId = await _insertOutlookMessage(db, externalId: 'msg-2');
        final attachment = await _insertAttachment(
          db,
          messageId: messageId,
          externalId: 'att-2',
        );

        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);
        server.listen((request) async {
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({'id': 'att-2', 'name': 'broken.txt'}),
          );
          await request.response.close();
        });

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            office365SettingsProvider.overrideWith(
              () => _FakeOffice365SettingsController(_settingsWithToken()),
            ),
            _office365TestServiceProvider.overrideWith(
              (ref) => Office365MailService(
                ref,
                graphApiBaseUri: Uri.parse(
                  'http://127.0.0.1:${server.port}/v1.0',
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(_office365TestServiceProvider);

        await expectLater(
          () => service.downloadAttachment(
            localMessageId: messageId,
            attachment: attachment,
          ),
          throwsA(isA<StateError>()),
        );

        final updated = (await db.attachmentsDao.getAttachmentsForMessage(
          messageId,
        )).single;
        expect(updated.downloadStatus, 'failed');
        expect(updated.localPath, isNull);
      },
    );

    test('markMessageRead sends PATCH and updates the local message', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final messageId = await _insertOutlookMessage(
        db,
        externalId: 'msg-read-1',
        isRead: false,
      );

      String? receivedBody;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((request) async {
        if (request.method == 'PATCH' &&
            request.uri.path == '/v1.0/me/messages/msg-read-1') {
          receivedBody = await utf8.decoder.bind(request).join();
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          office365SettingsProvider.overrideWith(
            () => _FakeOffice365SettingsController(_settingsWithToken()),
          ),
          _office365TestServiceProvider.overrideWith(
            (ref) => Office365MailService(
              ref,
              graphApiBaseUri: Uri.parse(
                'http://127.0.0.1:${server.port}/v1.0',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(_office365TestServiceProvider)
          .markMessageRead(messageId);

      expect(receivedBody, '{"isRead":true}');
      final updated = await db.messagesDao.getMessageById(messageId);
      expect(updated?.isRead, isTrue);
    });
  });
}
