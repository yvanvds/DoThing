import '../../models/recipients/recipient_search_result.dart';
import 'recipient_candidate_merger.dart';
import 'recipient_candidate_provider.dart';
import 'recipient_candidate_ranker.dart';

class RecipientSearchService {
  RecipientSearchService({
    required List<RecipientCandidateProvider> providers,
    RecipientCandidateMerger? merger,
    RecipientCandidateRanker? ranker,
  }) : _providers = providers,
       _merger = merger ?? RecipientCandidateMerger(),
       _ranker = ranker ?? RecipientCandidateRanker();

  final List<RecipientCandidateProvider> _providers;
  final RecipientCandidateMerger _merger;
  final RecipientCandidateRanker _ranker;

  Future<RecipientSearchResult> search(
    String query, {
    int limitPerProvider = 25,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const RecipientSearchResult(people: []);

    final responses = await Future.wait(
      _providers.map(
        (provider) => provider.search(trimmed, limit: limitPerProvider),
      ),
    );

    final merged = _merger.merge(responses.expand((items) => items).toList());
    final ranked = _ranker.rank(merged);

    return RecipientSearchResult(people: ranked);
  }
}
