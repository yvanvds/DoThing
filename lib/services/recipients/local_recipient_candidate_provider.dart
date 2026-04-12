import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/recipients/recipient_chip_source.dart';
import '../../models/recipients/recipient_endpoint.dart';
import '../../models/recipients/recipient_endpoint_kind.dart';
import '../../models/recipients/recipient_endpoint_label.dart';
import '../../models/recipients/recipient_person_candidate.dart';
import 'recipient_candidate_provider.dart';

class LocalRecipientCandidateProvider implements RecipientCandidateProvider {
  LocalRecipientCandidateProvider(this._db);

  final AppDatabase _db;

  @override
  Future<List<RecipientPersonCandidate>> search(
    String query, {
    int limit = 25,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final contactCandidates = await _searchContactCandidates(q, limit: limit);
    final recentCandidates = await _searchRecentAddressCandidates(
      q,
      limit: (limit / 2).clamp(5, 25).toInt(),
    );

    return [...contactCandidates, ...recentCandidates];
  }

  Future<List<RecipientPersonCandidate>> _searchContactCandidates(
    String query, {
    required int limit,
  }) async {
    final pattern = '%${query.toLowerCase()}%';

    final rows = await _db
        .customSelect(
          '''
      SELECT
        c.id AS contact_id,
        c.display_name AS contact_display_name,
        ci.source AS identity_source,
        ci.external_id AS identity_external_id,
        ci.display_name_snapshot AS identity_display_name
      FROM contacts c
      LEFT JOIN contact_identities ci ON ci.contact_id = c.id
      WHERE
        LOWER(c.display_name) LIKE ? OR
        LOWER(COALESCE(ci.display_name_snapshot, '')) LIKE ? OR
        LOWER(COALESCE(ci.external_id, '')) LIKE ?
      ORDER BY c.updated_at DESC
      LIMIT ?
      ''',
          variables: [
            Variable<String>(pattern),
            Variable<String>(pattern),
            Variable<String>(pattern),
            Variable<int>(limit),
          ],
          readsFrom: {_db.contacts, _db.contactIdentities},
        )
        .get();

    final byContactId = <int, _LocalCandidateAccumulator>{};

    for (final row in rows) {
      final contactId = row.read<int>('contact_id');
      final contactDisplayName = row.read<String>('contact_display_name');

      final acc = byContactId.putIfAbsent(
        contactId,
        () => _LocalCandidateAccumulator(
          displayName: contactDisplayName,
          contactId: contactId,
        ),
      );

      final source = row.readNullable<String>('identity_source')?.trim() ?? '';
      final externalId =
          row.readNullable<String>('identity_external_id')?.trim() ?? '';

      if (source.isEmpty || externalId.isEmpty) continue;

      final endpoint = _endpointFromIdentity(source, externalId);
      if (endpoint == null) continue;

      acc.endpoints[endpoint.dedupeKey] = endpoint;
      acc.identityKeys.add('identity:${source.toLowerCase()}:$externalId');
      if (endpoint.value.contains('@')) {
        acc.emails.add(endpoint.value.toLowerCase());
      }
    }

    return byContactId.values
        .map((acc) => acc.toCandidate(query: query))
        .where((candidate) => candidate.endpoints.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<RecipientPersonCandidate>> _searchRecentAddressCandidates(
    String query, {
    required int limit,
  }) async {
    final pattern = '%${query.toLowerCase()}%';
    final rows = await _db
        .customSelect(
          '''
      SELECT
        LOWER(TRIM(mp.address_snapshot)) AS address,
        MAX(COALESCE(mp.display_name_snapshot, mp.address_snapshot)) AS display_name,
        MAX(COALESCE(m.received_at, m.sent_at)) AS latest_seen_at
      FROM message_participants mp
      INNER JOIN messages m ON m.id = mp.message_id
      WHERE
        mp.address_snapshot IS NOT NULL AND
        TRIM(mp.address_snapshot) <> '' AND
        LOWER(mp.address_snapshot) LIKE ?
      GROUP BY LOWER(TRIM(mp.address_snapshot))
      ORDER BY latest_seen_at DESC
      LIMIT ?
      ''',
          variables: [Variable<String>(pattern), Variable<int>(limit)],
          readsFrom: {_db.messageParticipants, _db.messages},
        )
        .get();

    return rows
        .map((row) {
          final address = row.read<String>('address');
          if (!address.contains('@')) return null;

          final displayName =
              row.readNullable<String>('display_name') ?? address;
          return RecipientPersonCandidate(
            displayName: displayName,
            endpoints: [
              RecipientEndpoint(
                kind: RecipientEndpointKind.email,
                value: address,
                label: RecipientEndpointLabel.other,
              ),
            ],
            source: RecipientChipSource.local,
            identityKeys: {'recent:$address'},
            emails: {address},
            relevanceScore: 30,
          );
        })
        .whereType<RecipientPersonCandidate>()
        .toList(growable: false);
  }

  RecipientEndpoint? _endpointFromIdentity(String source, String externalId) {
    final normalizedSource = source.toLowerCase();

    if (normalizedSource == 'smartschool') {
      return RecipientEndpoint(
        kind: RecipientEndpointKind.smartschool,
        value: externalId,
        label: RecipientEndpointLabel.smartschool,
        externalId: externalId,
      );
    }

    if (!externalId.contains('@')) return null;

    final label = switch (normalizedSource) {
      'outlook' || 'office365' => RecipientEndpointLabel.work,
      'gmail' => RecipientEndpointLabel.private,
      _ => RecipientEndpointLabel.other,
    };

    return RecipientEndpoint(
      kind: RecipientEndpointKind.email,
      value: externalId.toLowerCase(),
      label: label,
      externalId: externalId,
    );
  }
}

class _LocalCandidateAccumulator {
  _LocalCandidateAccumulator({
    required this.displayName,
    required this.contactId,
  });

  final String displayName;
  final int contactId;
  final Map<String, RecipientEndpoint> endpoints = {};
  final Set<String> identityKeys = {};
  final Set<String> emails = {};

  RecipientPersonCandidate toCandidate({required String query}) {
    final lowerName = displayName.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final score = lowerName.startsWith(lowerQuery)
        ? 150
        : (lowerName.contains(lowerQuery) ? 120 : 80);

    return RecipientPersonCandidate(
      displayName: displayName,
      endpoints: endpoints.values.toList(growable: false),
      source: RecipientChipSource.local,
      contactId: contactId,
      identityKeys: {...identityKeys, 'contact:$contactId'},
      emails: emails,
      relevanceScore: score,
    );
  }
}
