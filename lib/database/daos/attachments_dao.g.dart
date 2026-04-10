// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachments_dao.dart';

// ignore_for_file: type=lint
mixin _$AttachmentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $MessagesTable get messages => attachedDatabase.messages;
  $MessageAttachmentsTable get messageAttachments =>
      attachedDatabase.messageAttachments;
  AttachmentsDaoManager get managers => AttachmentsDaoManager(this);
}

class AttachmentsDaoManager {
  final _$AttachmentsDaoMixin _db;
  AttachmentsDaoManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db.attachedDatabase, _db.messages);
  $$MessageAttachmentsTableTableManager get messageAttachments =>
      $$MessageAttachmentsTableTableManager(
        _db.attachedDatabase,
        _db.messageAttachments,
      );
}
