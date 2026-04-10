// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_dao.dart';

// ignore_for_file: type=lint
mixin _$MessagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $MessagesTable get messages => attachedDatabase.messages;
  $ContactsTable get contacts => attachedDatabase.contacts;
  $ContactIdentitiesTable get contactIdentities =>
      attachedDatabase.contactIdentities;
  $MessageParticipantsTable get messageParticipants =>
      attachedDatabase.messageParticipants;
  MessagesDaoManager get managers => MessagesDaoManager(this);
}

class MessagesDaoManager {
  final _$MessagesDaoMixin _db;
  MessagesDaoManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db.attachedDatabase, _db.messages);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
  $$ContactIdentitiesTableTableManager get contactIdentities =>
      $$ContactIdentitiesTableTableManager(
        _db.attachedDatabase,
        _db.contactIdentities,
      );
  $$MessageParticipantsTableTableManager get messageParticipants =>
      $$MessageParticipantsTableTableManager(
        _db.attachedDatabase,
        _db.messageParticipants,
      );
}
