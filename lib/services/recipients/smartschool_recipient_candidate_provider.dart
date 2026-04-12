import '../../models/recipients/recipient_person_candidate.dart';
import 'recipient_candidate_provider.dart';

/// Remote Smartschool lookup provider.
///
/// This is intentionally a no-op for now; wiring to the actual Smartschool
/// user search endpoint will be added when backend support is finalized.
class SmartschoolRecipientCandidateProvider
    implements RecipientCandidateProvider {
  @override
  Future<List<RecipientPersonCandidate>> search(
    String query, {
    int limit = 25,
  }) async {
    return const [];
  }
}
