// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_dao.dart';

// ignore_for_file: type=lint
mixin _$SearchDaoMixin on DatabaseAccessor<AppDatabase> {
  $MessagesTable get messages => attachedDatabase.messages;
  SearchDaoManager get managers => SearchDaoManager(this);
}

class SearchDaoManager {
  final _$SearchDaoMixin _db;
  SearchDaoManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db.attachedDatabase, _db.messages);
}
