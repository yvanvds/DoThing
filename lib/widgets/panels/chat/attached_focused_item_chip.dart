part of 'chat_view.dart';

/// Inline pill rendered above the composer text field while a focused
/// item is pinned to the next turn. Close icon clears the pin; the
/// chat controller also clears it automatically once the turn is sent.
class _AttachedFocusedItemChip extends StatelessWidget {
  const _AttachedFocusedItemChip({
    required this.metadata,
    required this.onClear,
  });

  final FocusedItemMetadata metadata;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = metadata.title.trim().isEmpty
        ? '(no title)'
        : metadata.title.trim();
    final sublabel = metadata.subtitle?.trim();

    return Align(
      alignment: Alignment.centerLeft,
      child: InputChip(
        avatar: Icon(
          _iconForType(metadata.type),
          size: 16,
          color: colorScheme.onSecondaryContainer,
        ),
        label: Text(
          sublabel == null || sublabel.isEmpty ? label : '$label · $sublabel',
          overflow: TextOverflow.ellipsis,
        ),
        onDeleted: onClear,
        deleteIconColor: colorScheme.onSecondaryContainer,
        backgroundColor: colorScheme.secondaryContainer,
        labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
        visualDensity: VisualDensity.compact,
        side: BorderSide.none,
      ),
    );
  }

  IconData _iconForType(FocusedItemType type) {
    return switch (type) {
      FocusedItemType.message => Icons.mail_outline,
      FocusedItemType.document => Icons.description_outlined,
      FocusedItemType.calendarEvent => Icons.event_outlined,
      FocusedItemType.todo => Icons.check_circle_outline,
      FocusedItemType.account => Icons.person_outline,
    };
  }
}
