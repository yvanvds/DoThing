import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../../../services/smartschool_messages_service.dart';
import 'outlook_message_detail.dart';
import 'smartschool_message_detail.dart';
import 'smartschool_message_list.dart';

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

    return MultiSplitView(
      axis: Axis.horizontal,
      controller: _controller,
      builder: (context, area) {
        final index = _controller.areas.indexOf(area);

        if (index == 0) {
          return Container(
            color: colorScheme.surface,
            child: const SmartschoolMessageList(),
          );
        }

        return Container(
          color: colorScheme.surfaceContainerLow,
          child: selectedHeader != null
              ? selectedHeader.source == 'smartschool'
                    ? SmartschoolMessageDetailView(header: selectedHeader)
                    : OutlookMessageDetailView(header: selectedHeader)
              : Center(
                  child: Text(
                    'Select an item to view details',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ),
        );
      },
    );
  }
}

@Deprecated('Use MessagesPanel instead.')
class SmartschoolMessagesPanel extends MessagesPanel {
  const SmartschoolMessagesPanel({super.key});
}
