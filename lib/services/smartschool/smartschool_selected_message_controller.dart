import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/smartschool_message.dart';

/// Tracks which message header is currently selected in the panel.
///
/// Null means no message is selected.
class _SelectedMessageController extends Notifier<SmartschoolMessageHeader?> {
  @override
  SmartschoolMessageHeader? build() => null;

  void select(SmartschoolMessageHeader? header) {
    state = header;
  }
}

final smartschoolSelectedMessageProvider =
    NotifierProvider<_SelectedMessageController, SmartschoolMessageHeader?>(
      _SelectedMessageController.new,
    );
