import 'package:drift/drift.dart';

import 'messages_table.dart';
import 'contacts_table.dart';
import 'contact_identities_table.dart';

/// Links a [Messages] row to one or more [Contacts] with a specific role.
///
/// A message must never store sender/recipient information as direct columns;
/// all participant data lives here.
///
/// [displayNameSnapshot] and [addressSnapshot] preserve the display state at
/// ingest time, so the message history is not retroactively affected when a
/// contact's profile changes.
class MessageParticipants extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get messageId =>
      integer().references(Messages, #id, onDelete: KeyAction.cascade)();

  /// May be null for stub/unresolved participants.
  IntColumn get contactId => integer()
      .references(Contacts, #id, onDelete: KeyAction.setNull)
      .nullable()();

  /// The specific identity this participant was resolved from.
  IntColumn get contactIdentityId => integer()
      .references(ContactIdentities, #id, onDelete: KeyAction.setNull)
      .nullable()();

  /// Role in this message: 'sender', 'to', 'cc', 'bcc'.
  TextColumn get role => text()();

  /// Position within the role group (0-based).
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// Display name as it appeared when the message was ingested.
  TextColumn get displayNameSnapshot => text()();

  /// Email address or other identifier snapshot.
  TextColumn get addressSnapshot => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
