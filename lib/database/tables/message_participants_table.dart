import 'package:drift/drift.dart';

import 'messages_table.dart';
import 'contact_identities_table.dart';

/// Minimal link table connecting a [Messages] row to resolved identities.
///
/// A row is only inserted once the participant's stable provider identity is
/// known. Messages with no resolved participants do not appear in
/// contact-grouped inbox views — this is intentional.
///
/// Display names are NOT stored here; always read from [ContactIdentities].
class MessageParticipants extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get messageId =>
      integer().references(Messages, #id, onDelete: KeyAction.cascade)();

  /// The resolved identity for this participant. Never null.
  IntColumn get contactIdentityId =>
      integer().references(
        ContactIdentities,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Role in this message: 'sender', 'to', 'cc', 'bcc'.
  TextColumn get role => text()();
}
