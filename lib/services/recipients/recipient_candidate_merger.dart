import '../../models/recipients/recipient_chip_source.dart';
import '../../models/recipients/recipient_endpoint.dart';
import '../../models/recipients/recipient_person_candidate.dart';

class RecipientCandidateMerger {
  List<RecipientPersonCandidate> merge(List<RecipientPersonCandidate> input) {
    final groups = <_MergeGroup>[];

    for (final candidate in input) {
      final normalized = _normalize(candidate);
      final matchIndex = groups.indexWhere(
        (group) => group.matches(normalized),
      );
      if (matchIndex == -1) {
        groups.add(_MergeGroup.fromCandidate(normalized));
      } else {
        groups[matchIndex].merge(normalized);
      }
    }

    return groups.map((group) => group.toCandidate()).toList(growable: false);
  }

  RecipientPersonCandidate _normalize(RecipientPersonCandidate candidate) {
    final endpoints = <String, RecipientEndpoint>{
      for (final endpoint in candidate.endpoints) endpoint.dedupeKey: endpoint,
    };

    final normalizedEmails = {
      ...candidate.emails.map((email) => email.trim().toLowerCase()),
      ...candidate.endpoints
          .where((endpoint) => endpoint.value.contains('@'))
          .map((endpoint) => endpoint.value.trim().toLowerCase()),
    };

    final identityKeys = {
      ...candidate.identityKeys.map((key) => key.trim().toLowerCase()),
      if (candidate.contactId != null) 'contact:${candidate.contactId}',
    };

    return candidate.copyWith(
      endpoints: endpoints.values.toList(growable: false),
      identityKeys: identityKeys,
      emails: normalizedEmails,
    );
  }
}

class _MergeGroup {
  _MergeGroup({
    required this.displayName,
    required this.source,
    required this.contactId,
    required this.identityKeys,
    required this.emails,
    required this.endpoints,
    required this.relevanceScore,
  });

  factory _MergeGroup.fromCandidate(RecipientPersonCandidate candidate) {
    return _MergeGroup(
      displayName: candidate.displayName,
      source: candidate.source,
      contactId: candidate.contactId,
      identityKeys: {...candidate.identityKeys},
      emails: {...candidate.emails},
      endpoints: {
        for (final endpoint in candidate.endpoints)
          endpoint.dedupeKey: endpoint,
      },
      relevanceScore: candidate.relevanceScore,
    );
  }

  String displayName;
  RecipientChipSource source;
  int? contactId;
  final Set<String> identityKeys;
  final Set<String> emails;
  final Map<String, RecipientEndpoint> endpoints;
  int relevanceScore;

  bool matches(RecipientPersonCandidate candidate) {
    if (identityKeys.isNotEmpty && candidate.identityKeys.isNotEmpty) {
      final shared = identityKeys.intersection(candidate.identityKeys);
      if (shared.isNotEmpty) return true;
    }

    if (emails.isNotEmpty && candidate.emails.isNotEmpty) {
      final sharedEmails = emails.intersection(candidate.emails);
      if (sharedEmails.isNotEmpty) return true;
    }

    return false;
  }

  void merge(RecipientPersonCandidate other) {
    identityKeys.addAll(other.identityKeys);
    emails.addAll(other.emails);
    for (final endpoint in other.endpoints) {
      endpoints.putIfAbsent(endpoint.dedupeKey, () => endpoint);
    }

    if (other.relevanceScore > relevanceScore) {
      relevanceScore = other.relevanceScore;
      displayName = other.displayName;
      source = other.source;
    }
    contactId ??= other.contactId;
  }

  RecipientPersonCandidate toCandidate() {
    return RecipientPersonCandidate(
      displayName: displayName,
      endpoints: endpoints.values.toList(growable: false),
      source: source,
      contactId: contactId,
      identityKeys: identityKeys,
      emails: emails,
      relevanceScore: relevanceScore,
    );
  }
}
