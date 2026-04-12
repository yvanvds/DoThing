// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_outgoing_messages_dao.dart';

// ignore_for_file: type=lint
mixin _$PendingOutgoingMessagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PendingOutgoingMessagesTable get pendingOutgoingMessages =>
      attachedDatabase.pendingOutgoingMessages;
  PendingOutgoingMessagesDaoManager get managers =>
      PendingOutgoingMessagesDaoManager(this);
}

class PendingOutgoingMessagesDaoManager {
  final _$PendingOutgoingMessagesDaoMixin _db;
  PendingOutgoingMessagesDaoManager(this._db);
  $$PendingOutgoingMessagesTableTableManager get pendingOutgoingMessages =>
      $$PendingOutgoingMessagesTableTableManager(
        _db.attachedDatabase,
        _db.pendingOutgoingMessages,
      );
}
