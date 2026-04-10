import 'package:drift/drift.dart';

/// Canonical person/entity record independent of message source.
///
/// A contact is the unified identity behind any number of source-specific
/// identities (Smartschool user, Gmail address, Teams user, etc.).
///
/// Rows start as stubs (`isStub = true`) when only partial data is known,
/// and are later enriched via [ContactIdentities].
class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get displayName => text()();

  /// URL to the primary avatar image, if known.
  TextColumn get primaryAvatarUrl => text().nullable()();

  /// Rough entity kind: 'person', 'team', 'system'.
  TextColumn get kind => text().nullable()();

  /// True until at least one enrichment pass has been completed.
  BoolColumn get isStub => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
