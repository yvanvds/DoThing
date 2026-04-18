import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../../../controllers/composer_visibility_controller.dart';
import '../../../services/smartschool/smartschool_messages_controller.dart';
import '../../../services/smartschool/smartschool_selected_message_controller.dart';
import '../composer/composer_panel.dart';
import 'outlook_message_detail.dart';
import 'smartschool_message_detail.dart';
import 'message_list.dart';

class MessagesPanel extends ConsumerStatefulWidget {
  const MessagesPanel({super.key});

  @override
  ConsumerState<MessagesPanel> createState() => _MessagesPanelState();
}

class _MessagesPanelState extends ConsumerState<MessagesPanel> {
  final MultiSplitViewController _controller = MultiSplitViewController(
    areas: [Area(size: 340, min: 300), Area(flex: 1)],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedHeader = ref.watch(smartschoolSelectedMessageProvider);
    final composerOpen = ref.watch(composerVisibilityProvider);

    return MultiSplitView(
      axis: Axis.horizontal,
      controller: _controller,
      builder: (context, area) {
        final index = _controller.areas.indexOf(area);

        if (index == 0) {
          return Container(
            color: colorScheme.surface,
            child: const MessageList(),
          );
        }

        return Container(
          color: colorScheme.surfaceContainerLow,
          child: composerOpen
              ? const ComposerPanel()
              : _buildSelectedHeaderView(context, colorScheme, selectedHeader),
        );
      },
    );
  }

  Widget _buildSelectedHeaderView(
    BuildContext context,
    ColorScheme colorScheme,
    MessageHeader? selectedHeader,
  ) {
    if (selectedHeader == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.78,
              child: Image.asset(
                'assets/background.png',
                width: 240,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Select an item to view details',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    if (selectedHeader.source == 'smartschool') {
      return SmartschoolMessageDetailView(header: selectedHeader);
    }

    return OutlookMessageDetailView(header: selectedHeader);
  }
}
