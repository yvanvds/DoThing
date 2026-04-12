import 'recipient_chip_source.dart';
import 'recipient_endpoint.dart';

class RecipientPersonSuggestion {
  const RecipientPersonSuggestion({
    required this.displayName,
    required this.endpoints,
    required this.preferredEndpoint,
    required this.requiresDisambiguation,
    required this.source,
    required this.relevanceScore,
    this.contactId,
    this.identityKeys = const {},
  });

  final String displayName;
  final List<RecipientEndpoint> endpoints;
  final RecipientEndpoint preferredEndpoint;
  final bool requiresDisambiguation;
  final RecipientChipSource source;
  final int relevanceScore;
  final int? contactId;
  final Set<String> identityKeys;
}
