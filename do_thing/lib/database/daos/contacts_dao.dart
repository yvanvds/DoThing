import 'package:drift/drift.dart';

import '../app_database.dart';

part 'contacts_dao.g.dart';

@DriftAccessor(tables: [Contacts, ContactIdentities])
class ContactsDao extends DatabaseAccessor<AppDatabase>
    with _$ContactsDaoMixin {
  ContactsDao(super.db);

  // ── Contacts ────────────────────────────────────────────────────────────

  Future<Contact> insertStubContact({
    required String displayName,
    String? avatarUrl,
    String? kind,
  }) async {
    final id = await into(contacts).insert(
      ContactsCompanion.insert(
        displayName: displayName,
        primaryAvatarUrl: Value(avatarUrl),
        kind: Value(kind),
        isStub: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return (select(contacts)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> enrichContact(
    int contactId, {
    required String displayName,
    String? avatarUrl,
    String? kind,
  }) async {
    await (update(contacts)..where((t) => t.id.equals(contactId))).write(
      ContactsCompanion(
        displayName: Value(displayName),
        primaryAvatarUrl: Value(avatarUrl),
        kind: Value(kind),
        isStub: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<Contact?> getContactById(int id) =>
      (select(contacts)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ── ContactIdentities ───────────────────────────────────────────────────

  /// Returns the existing identity, or null if not found.
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
  /// If the identity does not exist a new stub contact is created and linked.
  /// Returns the resolved [contactId].
  Future<int> upsertIdentity({
    required String source,
    required String externalId,
    required String displayName,
    String? avatarUrl,
    String? rawPayloadJson,
  }) async {
    final existing = await findIdentity(source: source, externalId: externalId);

    if (existing != null) {
      // Update snapshot fields and lastSeenAt.
      await (update(
        contactIdentities,
      )..where((t) => t.id.equals(existing.id))).write(
        ContactIdentitiesCompanion(
          displayNameSnapshot: Value(displayName),
          avatarUrlSnapshot: Value(avatarUrl),
          rawPayloadJson: Value(rawPayloadJson),
          lastSeenAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return existing.contactId;
    }

    // No identity yet → create stub contact first.
    final contact = await insertStubContact(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );

    await into(contactIdentities).insert(
      ContactIdentitiesCompanion.insert(
        contactId: contact.id,
        source: source,
        externalId: externalId,
        displayNameSnapshot: Value(displayName),
        avatarUrlSnapshot: Value(avatarUrl),
        rawPayloadJson: Value(rawPayloadJson),
        lastSeenAt: DateTime.now(),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return contact.id;
  }

  Stream<List<ContactIdentity>> watchIdentitiesForContact(int contactId) =>
      (select(
        contactIdentities,
      )..where((t) => t.contactId.equals(contactId))).watch();
}
