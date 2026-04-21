import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/app_initialization_controller.dart';
import '../controllers/busy_status_controller.dart';
import '../controllers/context_panel_controller.dart';
import '../services/busy_status_message_catalog.dart';

/// A non-dismissible loading dialog that displays the app logo and rotating
/// status messages during initial app polling.
class LoadingDialog extends ConsumerWidget {
  const LoadingDialog({super.key});

  void _cancelInitialization(WidgetRef ref) {
    ref.read(appInitializationOverrideProvider.notifier).dismiss();
    ref.read(contextPanelProvider.notifier).show(ContextView.settings);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageIndex = ref.watch(busyStatusMessageProvider);
    final message = BusyStatusMessageCatalog.genericPhrases[messageIndex];

    return GestureDetector(
      onTap: () {}, // Block all taps
      child: Material(
        color: Colors.black87,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/background.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 40),
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'If setup is incomplete or your connection is unavailable, you can close this screen and review settings.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => _cancelInitialization(ref),
                      icon: const Icon(Icons.close_outlined),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
