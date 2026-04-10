import 'package:drift/drift.dart';

import 'contacts_table.dart';

/// Source-specific identity attached to a [Contacts] row.
///
/// A single contact can be known under multiple identities across providers
/// (e.g. the same person has a Smartschool ID, a Gmail address, etc.).
///
/// This table is the deduplication key during ingest: incoming messages are
/// resolved to a contact by (source, externalId).
class ContactIdentities extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get contactId =>
      integer().references(Contacts, #id, onDelete: KeyAction.cascade)();

  /// Provider name, e.g. 'smartschool', 'gmail', 'outlook'.
  TextColumn get source => text()();

  /// ID of the user as supplied by the remote provider.
  TextColumn get externalId => text()();

  /// Display name at the time this identity was last seen.
  TextColumn get displayNameSnapshot => text().nullable()();

  /// Avatar URL at the time this identity was last seen.
  TextColumn get avatarUrlSnapshot => text().nullable()();

  /// Full raw payload as JSON, for future re-processing.
  TextColumn get rawPayloadJson => text().nullable()();

  DateTimeColumn get lastSeenAt => dateTime()();
  DateTimeColumn get lastEnrichedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {source, externalId},
  ];
}
