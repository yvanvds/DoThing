import '../../models/recipients/recipient_person_candidate.dart';
import 'recipient_candidate_provider.dart';

/// Remote Office365 / Outlook directory lookup provider.
///
/// This is intentionally a no-op for now; wiring to Graph directory search
/// will be added when the permissions and endpoint contract are finalized.
class Office365RecipientCandidateProvider
    implements RecipientCandidateProvider {
  @override
  Future<List<RecipientPersonCandidate>> search(
    String query, {
    int limit = 25,
  }) async {
    return const [];
  }
}
