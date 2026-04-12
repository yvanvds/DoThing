import 'recipient_chip_source.dart';
import 'recipient_endpoint.dart';

class RecipientChip {
  const RecipientChip({
    required this.displayName,
    required this.endpoint,
    required this.source,
    this.sourceContactId,
    this.sourceIdentityKey,
    this.autoSelectedPreferred = false,
  });

  final String displayName;
  final RecipientEndpoint endpoint;
  final RecipientChipSource source;
  final int? sourceContactId;
  final String? sourceIdentityKey;
  final bool autoSelectedPreferred;

  String get dedupeKey => endpoint.dedupeKey;

  RecipientChip copyWith({
    String? displayName,
    RecipientEndpoint? endpoint,
    RecipientChipSource? source,
    int? sourceContactId,
    String? sourceIdentityKey,
    bool? autoSelectedPreferred,
  }) {
    return RecipientChip(
      displayName: displayName ?? this.displayName,
      endpoint: endpoint ?? this.endpoint,
      source: source ?? this.source,
      sourceContactId: sourceContactId ?? this.sourceContactId,
      sourceIdentityKey: sourceIdentityKey ?? this.sourceIdentityKey,
      autoSelectedPreferred:
          autoSelectedPreferred ?? this.autoSelectedPreferred,
    );
  }
}
