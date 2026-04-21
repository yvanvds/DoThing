import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/focus/focused_item_metadata.dart';

/// Holds the focused item the user has manually pinned to the next chat
/// turn, if any. Decoupled from the focused-item service: setting an
/// attachment is an explicit user intent ("include this specific item"),
/// independent of whatever is currently focused.
///
/// Cleared automatically when the chat controller sends the turn — the
/// attachment is a per-send payload, not a persistent setting.
class ChatComposerAttachmentController
    extends Notifier<FocusedItemMetadata?> {
  @override
  FocusedItemMetadata? build() => null;

  /// Pins [metadata] as the next-turn attachment. Replaces any previous
  /// pin so the composer chip never accumulates stale items.
  void attach(FocusedItemMetadata metadata) {
    state = metadata;
  }

  /// Removes the pin. Called from the chip's close button and after the
  /// chat controller has consumed the attachment.
  void clear() {
    state = null;
  }
}

final chatComposerAttachmentProvider = NotifierProvider<
    ChatComposerAttachmentController,
    FocusedItemMetadata?>(
  ChatComposerAttachmentController.new,
);
