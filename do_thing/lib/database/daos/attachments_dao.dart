import 'package:drift/drift.dart';

import '../app_database.dart';

part 'attachments_dao.g.dart';

@DriftAccessor(tables: [MessageAttachments])
class AttachmentsDao extends DatabaseAccessor<AppDatabase>
    with _$AttachmentsDaoMixin {
  AttachmentsDao(super.db);

  /// Upsert attachment metadata for a message.
  Future<void> upsertAttachments(List<MessageAttachmentsCompanion> rows) async {
    await batch((b) => b.insertAllOnConflictUpdate(messageAttachments, rows));
  }

  Future<List<MessageAttachment>> getAttachmentsForMessage(int messageId) =>
      (select(
        messageAttachments,
      )..where((t) => t.messageId.equals(messageId))).get();

  Stream<List<MessageAttachment>> watchAttachmentsForMessage(int messageId) =>
      (select(
        messageAttachments,
      )..where((t) => t.messageId.equals(messageId))).watch();

  /// Mark an attachment as downloaded with its local path and checksum.
  Future<void> markDownloaded({
    required int id,
    required String localPath,
    required String sha256,
  }) async {
    await (update(messageAttachments)..where((t) => t.id.equals(id))).write(
      MessageAttachmentsCompanion(
        downloadStatus: const Value('downloaded'),
        localPath: Value(localPath),
        localSha256: Value(sha256),
        downloadedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markDownloadFailed(int id) async {
    await (update(messageAttachments)..where((t) => t.id.equals(id))).write(
      MessageAttachmentsCompanion(
        downloadStatus: const Value('failed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
