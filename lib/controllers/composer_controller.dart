import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/draft_message.dart';
import '../models/recipients/recipient_chip.dart';
import '../models/recipients/recipient_chip_source.dart';
import '../models/recipients/recipient_endpoint.dart';
import '../models/recipients/recipient_endpoint_kind.dart';
import '../models/recipients/recipient_endpoint_label.dart';

/// Manages the state of the message currently being composed.
final composerProvider = NotifierProvider<ComposerController, DraftMessage>(
  ComposerController.new,
);

/// Controls the in-progress [DraftMessage] in the composer.
///
/// Each update method returns a new immutable [DraftMessage]; the previous
/// draft is discarded. Persistence is out of scope for this phase.
class ComposerController extends Notifier<DraftMessage> {
  @override
  DraftMessage build() => DraftMessage();

  void updateToRecipients(List<RecipientChip> toRecipients) =>
      state = state.copyWith(toRecipients: toRecipients);

  void updateCcRecipients(List<RecipientChip> ccRecipients) =>
      state = state.copyWith(ccRecipients: ccRecipients);

  void updateBccRecipients(List<RecipientChip> bccRecipients) =>
      state = state.copyWith(bccRecipients: bccRecipients);

  /// Legacy compatibility for older call sites that still pass raw addresses.
  void updateTo(List<String> to) =>
      state = state.copyWith(toRecipients: _manualEmailChips(to));

  /// Legacy compatibility for older call sites that still pass raw addresses.
  void updateCc(List<String> cc) =>
      state = state.copyWith(ccRecipients: _manualEmailChips(cc));

  /// Legacy compatibility for older call sites that still pass raw addresses.
  void updateBcc(List<String> bcc) =>
      state = state.copyWith(bccRecipients: _manualEmailChips(bcc));

  void updateSubject(String subject) =>
      state = state.copyWith(subject: subject);
  void updateBody(List<Map<String, dynamic>> body) =>
      state = state.copyWith(body: body);

  /// Resets the draft to a blank state.
  void reset() => state = DraftMessage();

  List<RecipientChip> _manualEmailChips(List<String> values) {
    return values
        .map((raw) => raw.trim())
        .where((value) => value.isNotEmpty)
        .map(
          (value) => RecipientChip(
            displayName: value,
            endpoint: RecipientEndpoint(
              kind: RecipientEndpointKind.email,
              value: value.toLowerCase(),
              label: RecipientEndpointLabel.other,
            ),
            source: RecipientChipSource.manual,
            autoSelectedPreferred: false,
          ),
        )
        .toList(growable: false);
  }
}
