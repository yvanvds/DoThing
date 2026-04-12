import 'package:drift/drift.dart';

/// Queue of outbound message payloads that still need to be delivered.
///
/// Each row stores a serialized draft payload plus retry metadata so failed
/// sends can be retried later without losing the original recipients/body.
class PendingOutgoingMessages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Serialized draft payload ready to be reconstructed for retry.
  TextColumn get payloadJson => text()();

  /// Convenience copy for debugging / quick inspection.
  TextColumn get subject => text().withDefault(const Constant(''))();

  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// Earliest timestamp when this row should be retried again.
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
