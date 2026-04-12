import '../../models/recipients/recipient_endpoint.dart';
import '../../models/recipients/recipient_endpoint_kind.dart';
import '../../models/recipients/recipient_endpoint_label.dart';
import '../../models/recipients/recipient_person_candidate.dart';
import '../../models/recipients/recipient_person_suggestion.dart';

class RecipientCandidateRanker {
  List<RecipientPersonSuggestion> rank(
    List<RecipientPersonCandidate> candidates,
  ) {
    final suggestions = candidates
        .map(_toSuggestion)
        .where((suggestion) => suggestion.endpoints.isNotEmpty)
        .toList();

    suggestions.sort((a, b) {
      final byScore = b.relevanceScore.compareTo(a.relevanceScore);
      if (byScore != 0) return byScore;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return suggestions;
  }

  RecipientPersonSuggestion _toSuggestion(RecipientPersonCandidate candidate) {
    final endpoints = [...candidate.endpoints]..sort(_compareEndpoints);
    final preferred = endpoints.first;

    final requiresDisambiguation = _requiresDisambiguation(endpoints);

    return RecipientPersonSuggestion(
      displayName: candidate.displayName,
      endpoints: endpoints,
      preferredEndpoint: preferred,
      requiresDisambiguation: requiresDisambiguation,
      source: candidate.source,
      relevanceScore: candidate.relevanceScore,
      contactId: candidate.contactId,
      identityKeys: candidate.identityKeys,
    );
  }

  int _compareEndpoints(RecipientEndpoint a, RecipientEndpoint b) {
    final priorityA = _endpointPriority(a);
    final priorityB = _endpointPriority(b);
    if (priorityA != priorityB) return priorityA.compareTo(priorityB);
    return a.value.toLowerCase().compareTo(b.value.toLowerCase());
  }

  int _endpointPriority(RecipientEndpoint endpoint) {
    if (endpoint.kind == RecipientEndpointKind.smartschool) return 0;

    switch (endpoint.label) {
      case RecipientEndpointLabel.work:
      case RecipientEndpointLabel.school:
        return 1;
      case RecipientEndpointLabel.private:
        return 2;
      case RecipientEndpointLabel.other:
      case RecipientEndpointLabel.smartschool:
        return 3;
    }
  }

  bool _requiresDisambiguation(List<RecipientEndpoint> endpoints) {
    if (endpoints.length <= 1) return false;

    final top = _endpointPriority(endpoints[0]);
    final second = _endpointPriority(endpoints[1]);

    // If both options have the same endpoint class, let the user choose.
    if (top == second) return true;

    // Smartschool + email generally has a clear default.
    if (endpoints[0].kind == RecipientEndpointKind.smartschool &&
        endpoints[1].kind == RecipientEndpointKind.email) {
      return false;
    }

    return second - top <= 1;
  }
}
