import 'package:drift/drift.dart';

/// Persistent metadata record for a single message from any provider.
///
/// Deduplication is enforced by the unique constraint on (source, externalId).
///
/// Body content is NOT stored here — it is fetched on demand from the remote
/// provider and held in the in-memory cache only.
///
/// Sender/recipient information lives in [MessageParticipants], not here.
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Provider name, e.g. 'smartschool'.
  TextColumn get source => text()();

  /// ID of the message as assigned by the remote provider.
  TextColumn get externalId => text()();

  /// Mailbox/folder name, e.g. 'inbox', 'sent', 'trash'.
  TextColumn get mailbox => text()();

  TextColumn get subject => text().withDefault(const Constant(''))();

  /// Sender's avatar URL captured at header-sync time.
  TextColumn get senderAvatarUrl => text().nullable()();

  /// When the message was received / first stored.
  DateTimeColumn get receivedAt => dateTime()();

  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get hasAttachments => boolean().withDefault(const Constant(false))();

  /// Hash of mutable header fields used to detect remote updates.
  TextColumn get headerFingerprint => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {source, externalId},
  ];
}
