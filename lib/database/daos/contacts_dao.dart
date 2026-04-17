import 'package:drift/drift.dart';

import '../app_database.dart';

part 'contacts_dao.g.dart';

@DriftAccessor(tables: [Contacts, ContactIdentities])
class ContactsDao extends DatabaseAccessor<AppDatabase>
    with _$ContactsDaoMixin {
  ContactsDao(super.db);

  // ── Contacts ────────────────────────────────────────────────────────────

  /// Insert a new contact row. Returns the full row.
  Future<Contact> insertContact(String displayName) async {
    final id = await into(contacts).insert(
      ContactsCompanion.insert(displayName: displayName),
    );
    return (select(contacts)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<Contact?> getContactById(int id) =>
      (select(contacts)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Find an existing contact by case-insensitive display name, or create one.
  ///
  /// Returns the contact id.
  Future<int> findOrCreateContactByDisplayName(String displayName) async {
    final normalized = displayName.trim().toLowerCase();
    if (normalized.isNotEmpty) {
      final existing = await customSelect(
        'SELECT id FROM contacts WHERE LOWER(TRIM(display_name)) = ? LIMIT 1',
        variables: [Variable<String>(normalized)],
        readsFrom: {contacts},
      ).getSingleOrNull();
      if (existing != null) return existing.read<int>('id');
    }

    final name = displayName.trim().isNotEmpty ? displayName.trim() : 'Unknown';
    return into(contacts).insert(ContactsCompanion.insert(displayName: name));
  }

  // ── ContactIdentities ───────────────────────────────────────────────────

  Future<ContactIdentity?> findIdentity({
    required String source,
    required String externalId,
  }) =>
      (select(contactIdentities)..where(
            (t) => t.source.equals(source) & t.externalId.equals(externalId),
          ))
          .getSingleOrNull();

  /// Upsert a contact identity by (source, externalId).
  ///
  /// [externalId] must be a stable provider-assigned ID (never a display-name
  /// derived key such as 'display:...'). Throws [ArgumentError] otherwise.
  ///
  /// If the identity does not exist, a contact is found or created by display
  /// name and the identity row is inserted.
  ///
  /// Returns the identity row id.
  Future<int> upsertIdentity({
    required String source,
    required String externalId,
    required String displayName,
    String? avatarUrl,
  }) async {
    assert(
      !externalId.startsWith('display:'),
      'externalId must be a stable provider ID, got: $externalId',
    );

    final existing = await findIdentity(source: source, externalId: externalId);

    if (existing != null) {
      await (update(contactIdentities)..where(
            (t) => t.id.equals(existing.id),
          ))
          .write(
        ContactIdentitiesCompanion(
          displayName: Value(displayName),
          avatarUrl: Value(avatarUrl),
          lastSeenAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return existing.id;
    }

    final contactId = await findOrCreateContactByDisplayName(displayName);
    return into(contactIdentities).insert(
      ContactIdentitiesCompanion.insert(
        contactId: contactId,
        source: source,
        externalId: externalId,
        displayName: Value(displayName),
        avatarUrl: Value(avatarUrl),
        lastSeenAt: DateTime.now(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<ContactIdentity>> watchIdentitiesForContact(int contactId) =>
      (select(contactIdentities)..where(
            (t) => t.contactId.equals(contactId),
          ))
          .watch();
}
