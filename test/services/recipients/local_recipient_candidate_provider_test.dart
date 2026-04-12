import 'package:do_thing/database/app_database.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_kind.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_label.dart';
import 'package:do_thing/services/recipients/local_recipient_candidate_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalRecipientCandidateProvider', () {
    test('returns empty when query is blank', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final provider = LocalRecipientCandidateProvider(db);
      final result = await provider.search('   ');

      expect(result, isEmpty);
    });

    test(
      'builds candidates from contacts with endpoint mapping and dedupe',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final jan = await db.contactsDao.insertStubContact(
          displayName: 'Jan Peeters',
        );
        final peter = await db.contactsDao.insertStubContact(
          displayName: 'Peter Parker',
        );

        await db
            .into(db.contactIdentities)
            .insert(
              ContactIdentitiesCompanion.insert(
                contactId: jan.id,
                source: 'smartschool',
                externalId: 'ss-jan',
                displayNameSnapshot: const Value('Jan Peeters'),
                lastSeenAt: DateTime.now(),
              ),
            );
        await db
            .into(db.contactIdentities)
            .insert(
              ContactIdentitiesCompanion.insert(
                contactId: jan.id,
                source: 'outlook',
                externalId: 'JAN@SCHOOL.BE',
                displayNameSnapshot: const Value('Jan Peeters'),
                lastSeenAt: DateTime.now(),
              ),
            );
        await db
            .into(db.contactIdentities)
            .insert(
              ContactIdentitiesCompanion.insert(
                contactId: jan.id,
                source: 'office365',
                externalId: 'JAN@SCHOOL.BE',
                displayNameSnapshot: const Value('Jan Peeters'),
                lastSeenAt: DateTime.now(),
              ),
            );
        await db
            .into(db.contactIdentities)
            .insert(
              ContactIdentitiesCompanion.insert(
                contactId: jan.id,
                source: 'gmail',
                externalId: 'jan.private@gmail.com',
                displayNameSnapshot: const Value('Jan Peeters'),
                lastSeenAt: DateTime.now(),
              ),
            );

        // Matches query through identity only; display name does not contain "jan".
        await db
            .into(db.contactIdentities)
            .insert(
              ContactIdentitiesCompanion.insert(
                contactId: peter.id,
                source: 'outlook',
                externalId: 'jan.alias@work.com',
                displayNameSnapshot: const Value('Peter Parker'),
                lastSeenAt: DateTime.now(),
              ),
            );

        final provider = LocalRecipientCandidateProvider(db);
        final result = await provider.search('jan');

        final janCandidate = result.firstWhere(
          (item) => item.contactId == jan.id,
        );
        expect(janCandidate.relevanceScore, 150);

        final smartschoolEndpoints = janCandidate.endpoints
            .where((e) => e.kind == RecipientEndpointKind.smartschool)
            .toList(growable: false);
        expect(smartschoolEndpoints, hasLength(1));
        expect(smartschoolEndpoints.first.value, 'ss-jan');
        expect(
          smartschoolEndpoints.first.label,
          RecipientEndpointLabel.smartschool,
        );

        final workEmailEndpoints = janCandidate.endpoints
            .where(
              (e) =>
                  e.kind == RecipientEndpointKind.email &&
                  e.value == 'jan@school.be',
            )
            .toList(growable: false);
        // outlook + office365 duplicate should collapse into one endpoint.
        expect(workEmailEndpoints, hasLength(1));
        expect(workEmailEndpoints.first.label, RecipientEndpointLabel.work);

        final privateEmailEndpoints = janCandidate.endpoints
            .where((e) => e.value == 'jan.private@gmail.com')
            .toList(growable: false);
        expect(privateEmailEndpoints, hasLength(1));
        expect(
          privateEmailEndpoints.first.label,
          RecipientEndpointLabel.private,
        );

        final peterCandidate = result.firstWhere(
          (item) => item.contactId == peter.id,
        );
        expect(peterCandidate.relevanceScore, 80);
      },
    );

    test(
      'includes recent email addresses and ignores non-email addresses',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final now = DateTime.parse('2026-04-12T12:00:00Z');

        final recentMessageId = await db.messagesDao.insertMessage(
          MessagesCompanion.insert(
            source: 'smartschool',
            externalId: 'recent-1',
            mailbox: 'inbox',
            receivedAt: now,
          ),
        );

        await db.messagesDao.replaceParticipants(recentMessageId, [
          MessageParticipantsCompanion.insert(
            messageId: recentMessageId,
            role: 'to',
            displayNameSnapshot: 'Recent Person',
            addressSnapshot: const Value('Recent@Example.com'),
          ),
          MessageParticipantsCompanion.insert(
            messageId: recentMessageId,
            role: 'cc',
            displayNameSnapshot: 'No Mail',
            addressSnapshot: const Value('not-an-email'),
          ),
        ]);

        final provider = LocalRecipientCandidateProvider(db);
        final result = await provider.search('recent');

        final recent = result.where(
          (c) => c.identityKeys.contains('recent:recent@example.com'),
        );
        expect(recent, hasLength(1));
        final candidate = recent.single;
        expect(candidate.relevanceScore, 30);
        expect(candidate.endpoints.single.value, 'recent@example.com');
        expect(candidate.endpoints.single.kind, RecipientEndpointKind.email);
      },
    );
  });
}
