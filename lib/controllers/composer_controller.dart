import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/draft_message.dart';

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
  DraftMessage build() => const DraftMessage();

  void updateTo(List<String> to) => state = state.copyWith(to: to);
  void updateCc(List<String> cc) => state = state.copyWith(cc: cc);
  void updateBcc(List<String> bcc) => state = state.copyWith(bcc: bcc);
  void updateSubject(String subject) =>
      state = state.copyWith(subject: subject);
  void updateBody(List<Map<String, dynamic>> body) =>
      state = state.copyWith(body: body);

  /// Resets the draft to a blank state.
  void reset() => state = const DraftMessage();
}
