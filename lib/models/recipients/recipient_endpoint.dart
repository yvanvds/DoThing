import 'recipient_endpoint_kind.dart';
import 'recipient_endpoint_label.dart';

class RecipientEndpoint {
  const RecipientEndpoint({
    required this.kind,
    required this.value,
    this.label = RecipientEndpointLabel.other,
    this.externalId,
  });

  final RecipientEndpointKind kind;

  /// Deterministic destination value (smartschool user id or email address).
  final String value;

  final RecipientEndpointLabel label;

  /// Optional provider-specific external id for future integrations.
  final String? externalId;

  String get dedupeKey => '${kind.name}:${value.trim().toLowerCase()}';

  String get badgeText {
    switch (label) {
      case RecipientEndpointLabel.smartschool:
        return 'Smartschool';
      case RecipientEndpointLabel.work:
        return 'Work';
      case RecipientEndpointLabel.school:
        return 'School';
      case RecipientEndpointLabel.private:
        return 'Private';
      case RecipientEndpointLabel.other:
        return kind == RecipientEndpointKind.smartschool
            ? 'Smartschool'
            : 'Email';
    }
  }

  RecipientEndpoint copyWith({
    RecipientEndpointKind? kind,
    String? value,
    RecipientEndpointLabel? label,
    String? externalId,
  }) {
    return RecipientEndpoint(
      kind: kind ?? this.kind,
      value: value ?? this.value,
      label: label ?? this.label,
      externalId: externalId ?? this.externalId,
    );
  }
}
