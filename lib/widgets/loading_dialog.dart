import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/busy_status_controller.dart';
import '../services/busy_status_message_catalog.dart';

/// A non-dismissible loading dialog that displays the app logo and rotating
/// status messages during initial app polling.
class LoadingDialog extends ConsumerWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageIndex = ref.watch(busyStatusMessageProvider);
    final message = BusyStatusMessageCatalog.genericPhrases[messageIndex];

    return GestureDetector(
      onTap: () {}, // Block all taps
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Image.asset(
                'assets/background.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),
              // Circular progress indicator
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 40),
              // Rotating status message
              SizedBox(
                width: 400,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
