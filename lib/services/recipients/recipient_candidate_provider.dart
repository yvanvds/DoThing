import '../../models/recipients/recipient_person_candidate.dart';

abstract class RecipientCandidateProvider {
  Future<List<RecipientPersonCandidate>> search(String query, {int limit = 25});
}
