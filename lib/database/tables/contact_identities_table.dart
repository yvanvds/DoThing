import 'package:drift/drift.dart';

import 'contacts_table.dart';

/// Source-specific identity attached to a [Contacts] row.
///
/// One contact can be known under multiple identities across providers.
///
/// [externalId] must always be a stable provider-assigned ID:
///   - Smartschool: 'user:{userId}' or 'ss:{ssId}' — never a display name.
///   - Outlook: email address or provider object ID.
class ContactIdentities extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get contactId =>
      integer().references(Contacts, #id, onDelete: KeyAction.cascade)();

  /// Provider name, e.g. 'smartschool', 'outlook'.
  TextColumn get source => text()();

  /// Stable provider-assigned ID (never a display-name derived key).
  TextColumn get externalId => text()();

  /// Display name as last seen for this identity.
  TextColumn get displayName => text().nullable()();

  /// Avatar URL as last seen for this identity.
  TextColumn get avatarUrl => text().nullable()();

  DateTimeColumn get lastSeenAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {source, externalId},
  ];
}
