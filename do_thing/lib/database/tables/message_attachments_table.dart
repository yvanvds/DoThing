import 'package:drift/drift.dart';

import 'messages_table.dart';

/// Metadata and local cache bookkeeping for message attachments.
///
/// File bytes are stored on disk at [localPath]; this table only tracks
/// metadata and the download lifecycle.
///
/// [downloadStatus] lifecycle: none → queued → downloading → downloaded | failed
class MessageAttachments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get messageId =>
      integer().references(Messages, #id, onDelete: KeyAction.cascade)();

  /// Provider name, e.g. 'smartschool'.
  TextColumn get source => text()();

  /// Provider-assigned attachment identifier, if available.
  TextColumn get externalId => text().nullable()();

  /// Original filename as provided by the remote source.
  TextColumn get filename => text()();

  TextColumn get mimeType => text().nullable()();

  IntColumn get sizeBytes => integer().nullable()();

  /// True for inline/embedded attachments (e.g. inline images).
  BoolColumn get isInline => boolean().withDefault(const Constant(false))();

  /// Download lifecycle state.
  ///
  /// Values: 'none', 'queued', 'downloading', 'downloaded', 'failed'
  TextColumn get downloadStatus => text().withDefault(const Constant('none'))();

  /// Absolute path to the locally cached file, if downloaded.
  TextColumn get localPath => text().nullable()();

  /// SHA-256 hex digest of the local file, populated after download.
  TextColumn get localSha256 => text().nullable()();

  DateTimeColumn get downloadedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
