import 'package:do_thing/models/recipients/recipient_chip_source.dart';
import 'package:do_thing/models/recipients/recipient_endpoint.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_kind.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_label.dart';
import 'package:do_thing/models/recipients/recipient_person_candidate.dart';
import 'package:do_thing/services/recipients/recipient_candidate_provider.dart';
import 'package:do_thing/services/recipients/recipient_search_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecipientSearchService', () {
    test('merges only on strong identity keys or exact email', () async {
      final service = RecipientSearchService(
        providers: [
          _FakeProvider([
            RecipientPersonCandidate(
              displayName: 'Jan Peeters',
              endpoints: const [
                RecipientEndpoint(
                  kind: RecipientEndpointKind.smartschool,
                  value: 'ss-jan',
                  label: RecipientEndpointLabel.smartschool,
                ),
              ],
              source: RecipientChipSource.local,
              identityKeys: const {'contact:42', 'smartschool:ss-jan'},
              emails: const {'jan.peeters@school.be'},
              relevanceScore: 180,
            ),
            RecipientPersonCandidate(
              displayName: 'Jan Peeters',
              endpoints: const [
                RecipientEndpoint(
                  kind: RecipientEndpointKind.email,
                  value: 'jan.peeters@school.be',
                  label: RecipientEndpointLabel.work,
                ),
              ],
              source: RecipientChipSource.office365Remote,
              identityKeys: const {'office365:user-123'},
              emails: const {'jan.peeters@school.be'},
              relevanceScore: 120,
            ),
          ]),
          _FakeProvider([
            RecipientPersonCandidate(
              displayName: 'Jan Peeters',
              endpoints: const [
                RecipientEndpoint(
                  kind: RecipientEndpointKind.email,
                  value: 'other.jan@example.com',
                  label: RecipientEndpointLabel.private,
                ),
              ],
              source: RecipientChipSource.smartschoolRemote,
              identityKeys: const {'smartschool:someone-else'},
              emails: const {'other.jan@example.com'},
              relevanceScore: 90,
            ),
          ]),
        ],
      );

      final result = await service.search('jan');

      // First two candidates merge by exact email, third stays separate.
      expect(result.people.length, 2);
      expect(result.people.first.endpoints.length, 2);
    });

    test(
      'prefers Smartschool endpoint over email when both are present',
      () async {
        final service = RecipientSearchService(
          providers: [
            _FakeProvider([
              RecipientPersonCandidate(
                displayName: 'Els Demo',
                endpoints: const [
                  RecipientEndpoint(
                    kind: RecipientEndpointKind.email,
                    value: 'els@school.be',
                    label: RecipientEndpointLabel.work,
                  ),
                  RecipientEndpoint(
                    kind: RecipientEndpointKind.smartschool,
                    value: 'ss-els',
                    label: RecipientEndpointLabel.smartschool,
                  ),
                ],
                source: RecipientChipSource.local,
                identityKeys: const {'contact:5'},
                emails: const {'els@school.be'},
                relevanceScore: 100,
              ),
            ]),
          ],
        );

        final result = await service.search('els');

        expect(result.people, hasLength(1));
        expect(
          result.people.first.preferredEndpoint.kind,
          RecipientEndpointKind.smartschool,
        );
      },
    );
  });
}

class _FakeProvider implements RecipientCandidateProvider {
  _FakeProvider(this._results);

  final List<RecipientPersonCandidate> _results;

  @override
  Future<List<RecipientPersonCandidate>> search(
    String query, {
    int limit = 25,
  }) async {
    return _results;
  }
}
