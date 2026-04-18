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

  /// Look up an existing identity by display name (case-insensitive).
  ///
  /// Used as a fallback for sent messages where recipients are returned by the
  /// API as display-name strings only (no stable userId/ssId). Returns the
  /// first match found for the given source, or null if unknown.
  Future<ContactIdentity?> findIdentityByDisplayName({
    required String source,
    required String displayName,
  }) async {
    final normalized = displayName.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final rows = await customSelect(
      '''
      SELECT * FROM contact_identities
      WHERE source = ? AND LOWER(TRIM(display_name)) = ?
      LIMIT 1
      ''',
      variables: [Variable<String>(source), Variable<String>(normalized)],
      readsFrom: {contactIdentities},
    ).get();
    if (rows.isEmpty) return null;
    return ContactIdentity(
      id: rows.first.read<int>('id'),
      contactId: rows.first.read<int>('contact_id'),
      source: rows.first.read<String>('source'),
      externalId: rows.first.read<String>('external_id'),
      displayName: rows.first.read<String?>('display_name'),
      avatarUrl: rows.first.read<String?>('avatar_url'),
      lastSeenAt: rows.first.read<DateTime>('last_seen_at'),
      updatedAt: rows.first.read<DateTime>('updated_at'),
      avatarFetchState: rows.first.read<String?>('avatar_fetch_state'),
    );
  }

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

  // ── Avatar backfill helpers ─────────────────────────────────────────────────

  /// For each Smartschool identity that has no avatar_url, find the best
  /// sender_avatar_url from messages where that identity was the sender.
  ///
  /// Returns (identityId, bestAvatarUrl) pairs. Real (non-initials) URLs are
  /// preferred over placeholder initials URLs. Only identities that actually
  /// have at least one message with a sender_avatar_url are returned.
  Future<List<(int, String)>> findSmartschoolAvatarsFromMessages() async {
    final rows = await customSelect(
      '''
      SELECT
        mp.contact_identity_id,
        COALESCE(
          MAX(CASE
            WHEN m.sender_avatar_url NOT LIKE '%/initials_%'
            THEN m.sender_avatar_url
            ELSE NULL
          END),
          MAX(m.sender_avatar_url)
        ) AS best_avatar
      FROM message_participants mp
      JOIN messages m ON m.id = mp.message_id
      WHERE
        mp.role = 'sender'
        AND m.source = 'smartschool'
        AND m.sender_avatar_url IS NOT NULL
        AND TRIM(m.sender_avatar_url) <> ''
        AND mp.contact_identity_id IN (
          SELECT id FROM contact_identities
          WHERE source = 'smartschool'
            AND (avatar_url IS NULL OR TRIM(avatar_url) = '')
        )
      GROUP BY mp.contact_identity_id
      HAVING best_avatar IS NOT NULL
      ''',
      variables: [],
      readsFrom: {
        contactIdentities,
        attachedDatabase.messageParticipants,
        attachedDatabase.messages,
      },
    ).get();

    return rows
        .map(
          (r) => (
            r.read<int>('contact_identity_id'),
            r.read<String>('best_avatar'),
          ),
        )
        .toList();
  }

  /// Outlook identities for which a Graph photo fetch has not been attempted.
  ///
  /// Uses raw SQL because [avatarFetchState] was added after the last
  /// build_runner run; the generated companion does not have it yet.
  Future<List<({int id, String externalId})>>
  findOutlookIdentitiesNeedingAvatarFetch() async {
    final rows = await customSelect(
      '''
      SELECT id, external_id
      FROM contact_identities
      WHERE source = 'outlook'
        AND avatar_url IS NULL
        AND avatar_fetch_state IS NULL
      ''',
      variables: [],
      readsFrom: {contactIdentities},
    ).get();
    return rows
        .map(
          (r) => (
            id: r.read<int>('id'),
            externalId: r.read<String>('external_id'),
          ),
        )
        .toList();
  }

  /// Write a confirmed avatar URL for a Smartschool identity.
  Future<void> updateIdentityAvatarUrl(int identityId, String url) =>
      customStatement(
        'UPDATE contact_identities SET avatar_url = ? WHERE id = ?',
        [url, identityId],
      );

  /// Record the result of an Outlook Graph photo fetch.
  ///
  /// [filePath] set → photo saved locally, written to avatar_url.
  /// [filePath] null → no photo; avatar_fetch_state set to 'none' (do not retry).
  Future<void> markOutlookAvatarChecked(int identityId, {String? filePath}) {
    if (filePath != null) {
      return customStatement(
        'UPDATE contact_identities SET avatar_url = ? WHERE id = ?',
        [filePath, identityId],
      );
    }
    return customStatement(
      "UPDATE contact_identities SET avatar_url = NULL, avatar_fetch_state = 'none' WHERE id = ?",
      [identityId],
    );
  }
}
