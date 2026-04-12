import 'dart:convert';

import '../../models/draft_message.dart';
import '../../models/recipients/recipient_chip.dart';
import '../../models/recipients/recipient_chip_source.dart';
import '../../models/recipients/recipient_endpoint.dart';
import '../../models/recipients/recipient_endpoint_kind.dart';
import '../../models/recipients/recipient_endpoint_label.dart';

class QueuedDraftCodec {
  static String encode(DraftMessage draft) {
    return jsonEncode({
      'toRecipients': _encodeRecipients(draft.toRecipients),
      'ccRecipients': _encodeRecipients(draft.ccRecipients),
      'bccRecipients': _encodeRecipients(draft.bccRecipients),
      'subject': draft.subject,
      'body': draft.body,
    });
  }

  static DraftMessage decode(String payloadJson) {
    final decoded = jsonDecode(payloadJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Queued draft payload must be a JSON object.',
      );
    }

    return DraftMessage(
      toRecipients: _decodeRecipients(decoded['toRecipients']),
      ccRecipients: _decodeRecipients(decoded['ccRecipients']),
      bccRecipients: _decodeRecipients(decoded['bccRecipients']),
      subject: decoded['subject'] as String? ?? '',
      body: _decodeBody(decoded['body']),
    );
  }

  static List<Map<String, dynamic>> _encodeRecipients(
    List<RecipientChip> recipients,
  ) {
    return recipients
        .map(
          (chip) => {
            'displayName': chip.displayName,
            'source': chip.source.name,
            'sourceContactId': chip.sourceContactId,
            'sourceIdentityKey': chip.sourceIdentityKey,
            'autoSelectedPreferred': chip.autoSelectedPreferred,
            'endpoint': {
              'kind': chip.endpoint.kind.name,
              'value': chip.endpoint.value,
              'label': chip.endpoint.label.name,
              'externalId': chip.endpoint.externalId,
            },
          },
        )
        .toList(growable: false);
  }

  static List<RecipientChip> _decodeRecipients(Object? raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((entry) {
          final map = Map<String, dynamic>.from(entry.cast<String, dynamic>());
          final endpointMap = Map<String, dynamic>.from(
            (map['endpoint'] as Map?)?.cast<String, dynamic>() ?? const {},
          );

          return RecipientChip(
            displayName: map['displayName'] as String? ?? '',
            endpoint: RecipientEndpoint(
              kind: RecipientEndpointKind.values.byName(
                endpointMap['kind'] as String? ??
                    RecipientEndpointKind.email.name,
              ),
              value: endpointMap['value'] as String? ?? '',
              label: RecipientEndpointLabel.values.byName(
                endpointMap['label'] as String? ??
                    RecipientEndpointLabel.other.name,
              ),
              externalId: endpointMap['externalId'] as String?,
            ),
            source: RecipientChipSource.values.byName(
              map['source'] as String? ?? RecipientChipSource.manual.name,
            ),
            sourceContactId: map['sourceContactId'] as int?,
            sourceIdentityKey: map['sourceIdentityKey'] as String?,
            autoSelectedPreferred:
                map['autoSelectedPreferred'] as bool? ?? false,
          );
        })
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _decodeBody(Object? raw) {
    if (raw is! List) {
      return const [
        {'insert': '\n'},
      ];
    }

    return raw
        .whereType<Map>()
        .map(
          (entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()),
        )
        .toList(growable: false);
  }
}
