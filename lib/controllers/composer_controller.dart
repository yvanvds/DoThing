import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/draft_message.dart';
import '../models/recipients/recipient_chip.dart';

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

  void updateSubject(String subject) =>
      state = state.copyWith(subject: subject);
  void updateBody(List<Map<String, dynamic>> body) =>
      state = state.copyWith(body: body);

  /// Resets the draft to a blank state.
  void reset() => state = DraftMessage();
}
