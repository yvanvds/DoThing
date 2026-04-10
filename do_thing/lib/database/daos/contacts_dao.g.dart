// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contacts_dao.dart';

// ignore_for_file: type=lint
mixin _$ContactsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ContactsTable get contacts => attachedDatabase.contacts;
  $ContactIdentitiesTable get contactIdentities =>
      attachedDatabase.contactIdentities;
  ContactsDaoManager get managers => ContactsDaoManager(this);
}

class ContactsDaoManager {
  final _$ContactsDaoMixin _db;
  ContactsDaoManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
  $$ContactIdentitiesTableTableManager get contactIdentities =>
      $$ContactIdentitiesTableTableManager(
        _db.attachedDatabase,
        _db.contactIdentities,
      );
}
