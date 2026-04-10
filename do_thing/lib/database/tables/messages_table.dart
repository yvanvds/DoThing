import 'package:drift/drift.dart';

/// Persistent record for a single message from any provider.
///
/// Deduplication is enforced by the unique constraint on (source, externalId).
///
/// The body is stored in two forms:
///  - [bodyRaw]  : the original payload from the provider (HTML or plain text).
///  - [bodyText] : a stripped/normalized plain-text version used for FTS and AI.
///
/// Sender and recipient information is stored in [MessageParticipants],
/// NOT as direct columns here.
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Provider name, always 'smartschool' for now.
  TextColumn get source => text()();

  /// ID of the message as assigned by the remote provider.
  TextColumn get externalId => text()();

  /// Mailbox/folder name, e.g. 'inbox', 'sent', 'trash'.
  TextColumn get mailbox => text()();

  TextColumn get subject => text().withDefault(const Constant(''))();

  /// Original body as received (typically HTML).
  TextColumn get bodyRaw => text().nullable()();

  /// Normalized plain-text body for FTS and AI processing.
  TextColumn get bodyText => text().nullable()();

  /// Format of [bodyRaw], e.g. 'html' or 'plain'.
  TextColumn get bodyFormat => text().nullable()();

  /// When the message was sent (may differ from server receive time).
  DateTimeColumn get sentAt => dateTime().nullable()();

  /// When we first received / stored this message.
  DateTimeColumn get receivedAt => dateTime()();

  /// Timestamp from the remote provider, used for update detection.
  DateTimeColumn get remoteUpdatedAt => dateTime().nullable()();

  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get hasAttachments =>
      boolean().withDefault(const Constant(false))();

  /// When the full body detail was last fetched and stored.
  DateTimeColumn get detailFetchedAt => dateTime().nullable()();

  /// Hash of header fields used to detect remote updates without deep comparison.
  TextColumn get headerFingerprint => text().nullable()();

  /// Raw header JSON snapshot for debugging / re-processing.
  TextColumn get rawHeaderJson => text().nullable()();

  /// Raw detail JSON snapshot for debugging / re-processing.
  TextColumn get rawDetailJson => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {source, externalId},
  ];
}
