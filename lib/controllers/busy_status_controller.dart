import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/busy_status_message_catalog.dart';

/// Provides the current message index being displayed in the busy status dialog.
final busyStatusMessageProvider = NotifierProvider<BusyStatusController, int>(
  BusyStatusController.new,
);

/// Manages the rotating busy status messages.
///
/// Rotates through messages from [BusyStatusMessageCatalog.genericPhrases]
/// every 3 seconds.
class BusyStatusController extends Notifier<int> {
  Timer? _messageTimer;
  final _random = Random();

  @override
  int build() {
    // Start with a random message
    _startMessageRotation();
    ref.onDispose(() {
      _stopMessageRotation();
    });
    return _random.nextInt(BusyStatusMessageCatalog.genericPhrases.length);
  }

  /// Start rotating messages every 3 seconds.
  void _startMessageRotation() {
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      state = _random.nextInt(BusyStatusMessageCatalog.genericPhrases.length);
    });
  }

  /// Stop the message rotation timer.
  void _stopMessageRotation() {
    _messageTimer?.cancel();
    _messageTimer = null;
  }
}
