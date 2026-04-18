import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../services/busy_status_message_catalog.dart';

class PrefillSummaryProgressDialog extends StatefulWidget {
  const PrefillSummaryProgressDialog({required this.onCancel, super.key});

  final VoidCallback onCancel;

  @override
  State<PrefillSummaryProgressDialog> createState() =>
      _PrefillSummaryProgressDialogState();
}

class _PrefillSummaryProgressDialogState
    extends State<PrefillSummaryProgressDialog> {
  final Random _random = Random();
  late int _phraseIndex;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _phraseIndex = BusyStatusMessageCatalog.randomIndex(_random);
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _phraseIndex = BusyStatusMessageCatalog.nextIndex(
          _random,
          currentIndex: _phraseIndex,
        );
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Preparing summary quote',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Text(
                    BusyStatusMessageCatalog.phraseAt(_phraseIndex),
                    key: ValueKey<int>(_phraseIndex),
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
