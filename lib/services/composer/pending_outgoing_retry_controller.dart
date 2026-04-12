import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pending_outgoing_retry_service.dart';

class PendingOutgoingRetryController extends Notifier<int> {
  Timer? _timer;
  bool _started = false;
  bool _running = false;

  @override
  int build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
      _started = false;
      _running = false;
    });
    return 0;
  }

  void ensureStarted() {
    if (_started) {
      return;
    }
    _started = true;

    Future<void>.microtask(() => _runOnce(isStartup: true));
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _runOnce(isStartup: false);
    });
  }

  Future<void> runNowForTesting() => _runOnce(isStartup: false);

  Future<void> _runOnce({required bool isStartup}) async {
    if (_running) {
      return;
    }

    _running = true;
    try {
      await ref
          .read(pendingOutgoingRetryServiceProvider)
          .processDueMessages(isStartup: isStartup);
    } finally {
      _running = false;
      state = state + 1;
    }
  }
}

final pendingOutgoingRetryProvider =
    NotifierProvider<PendingOutgoingRetryController, int>(
      PendingOutgoingRetryController.new,
    );
