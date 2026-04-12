import 'recipient_chip_source.dart';
import 'recipient_endpoint.dart';

class RecipientPersonCandidate {
  const RecipientPersonCandidate({
    required this.displayName,
    required this.endpoints,
    required this.source,
    this.contactId,
    this.identityKeys = const {},
    this.emails = const {},
    this.relevanceScore = 0,
  });

  final String displayName;
  final List<RecipientEndpoint> endpoints;
  final RecipientChipSource source;
  final int? contactId;

  /// Strong merge keys only (contact id, provider ids, known mappings).
  final Set<String> identityKeys;

  /// Normalized emails used for conservative merge when identity keys are absent.
  final Set<String> emails;

  final int relevanceScore;

  RecipientPersonCandidate copyWith({
    String? displayName,
    List<RecipientEndpoint>? endpoints,
    RecipientChipSource? source,
    int? contactId,
    Set<String>? identityKeys,
    Set<String>? emails,
    int? relevanceScore,
  }) {
    return RecipientPersonCandidate(
      displayName: displayName ?? this.displayName,
      endpoints: endpoints ?? this.endpoints,
      source: source ?? this.source,
      contactId: contactId ?? this.contactId,
      identityKeys: identityKeys ?? this.identityKeys,
      emails: emails ?? this.emails,
      relevanceScore: relevanceScore ?? this.relevanceScore,
    );
  }
}
