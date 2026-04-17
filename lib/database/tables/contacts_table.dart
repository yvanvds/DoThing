import 'package:drift/drift.dart';

/// Canonical person/entity record independent of message source.
///
/// A contact is the unified identity behind any number of source-specific
/// identities (Smartschool user, Outlook address, etc.).
class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
