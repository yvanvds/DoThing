import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';

class SystemNotificationService {
  static bool _setupAttempted = false;

  static Future<void> initialize() async {
    if (_setupAttempted) return;
    _setupAttempted = true;

    try {
      await localNotifier.setup(appName: 'DoThing');
    } catch (_) {
      // Non-fatal. Notifications will be skipped if setup fails.
    }
  }

  Future<void> showSmartschoolMessageReceived({
    required String subject,
    required String sender,
  }) async {
    await initialize();

    final trimmedSubject = subject.trim();
    final trimmedSender = sender.trim();
    final title = trimmedSubject.isEmpty
        ? 'New Smartschool message'
        : trimmedSubject;
    final body = trimmedSender.isEmpty ? 'Smartschool' : trimmedSender;

    try {
      final notification = LocalNotification(title: title, body: body);
      await notification.show();
    } catch (_) {
      // Non-fatal. Ignore notification delivery failures.
    }
  }
}

final systemNotificationServiceProvider = Provider<SystemNotificationService>(
  (ref) => SystemNotificationService(),
);
