import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/smartschool_message.dart';

/// Tracks which message header is currently selected in the panel.
///
/// Null means no message is selected.
class _SelectedMessageController extends Notifier<MessageHeader?> {
  @override
  MessageHeader? build() => null;

  void select(MessageHeader? header) {
    state = header;
  }
}

final smartschoolSelectedMessageProvider =
    NotifierProvider<_SelectedMessageController, MessageHeader?>(
      _SelectedMessageController.new,
    );
