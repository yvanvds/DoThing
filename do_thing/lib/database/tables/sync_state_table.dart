import 'package:drift/drift.dart';

/// Tracks polling/sync health and position per (source, scope) pair.
///
/// Examples of (source, scope):
///  - ('smartschool', 'inbox')
///  - ('gmail', 'inbox')
///
/// [remoteCursor] stores any cursor/delta token the remote provider exposes.
/// For polling-only sources like Smartschool this remains null.
///
/// [highWaterExternalId] and [highWaterReceivedAt] provide fallback position
/// markers for sources without explicit cursors.
class SyncState extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Provider name, e.g. 'smartschool'.
  TextColumn get source => text()();

  /// Functional scope within the provider, e.g. 'inbox', 'sent'.
  TextColumn get scope => text()();

  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get lastSuccessAt => dateTime().nullable()();

  /// Opaque cursor/delta token from the remote provider, if supported.
  TextColumn get remoteCursor => text().nullable()();

  /// Timestamp of the highest received_at seen in the last successful sync.
  DateTimeColumn get highWaterReceivedAt => dateTime().nullable()();

  /// External ID of the newest message seen in the last successful sync.
  TextColumn get highWaterExternalId => text().nullable()();

  /// Serialized error from the last failed attempt.
  TextColumn get lastError => text().nullable()();

  IntColumn get failureCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {source, scope},
  ];
}
