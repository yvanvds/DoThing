import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/smartschool_inbox_controller.dart';
import '../../../services/smartschool_messages_service.dart';

class SmartschoolMessageHeaderTile extends ConsumerStatefulWidget {
  const SmartschoolMessageHeaderTile({
    required this.header,
    required this.onRemoveFromList,
    required this.onHeaderUpdated,
    super.key,
  });

  final SmartschoolMessageHeader header;
  final ValueChanged<int> onRemoveFromList;
  final ValueChanged<SmartschoolMessageHeader> onHeaderUpdated;

  @override
  ConsumerState<SmartschoolMessageHeaderTile> createState() =>
      _SmartschoolMessageHeaderTileState();
}

class _SmartschoolMessageHeaderTileState
    extends ConsumerState<SmartschoolMessageHeaderTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final header = widget.header;
    final colorScheme = Theme.of(context).colorScheme;
    final subjectColor = header.unread
        ? colorScheme.primary
        : colorScheme.onSurface;
    final selectedHeader = ref.watch(smartschoolSelectedMessageProvider);
    final isSelected = selectedHeader?.id == header.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleOpenMessage,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.surfaceContainerHighest
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _SenderAvatar(header: header),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  header.subject,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: header.unread
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: subjectColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(header.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  header.from,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (header.hasReply)
                                Icon(
                                  Icons.reply,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              if (header.hasForward) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.forward,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                              if (header.hasAttachment) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.attach_file,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isHovered)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ActionButtons(
                        header: header,
                        onArchive: () => _handleArchive(),
                        onTrash: () => _handleTrash(),
                        onMarkUnread: () => _handleMarkUnread(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;

    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _handleArchive() async {
    try {
      await ref
          .read(smartschoolMessagesProvider.notifier)
          .archive(widget.header.id);
      widget.onRemoveFromList(widget.header.id);
      if (mounted) setState(() => _isHovered = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to archive: $e')));
      }
    }
  }

  Future<void> _handleTrash() async {
    try {
      await ref
          .read(smartschoolMessagesProvider.notifier)
          .trash(widget.header.id);
      widget.onRemoveFromList(widget.header.id);
      if (mounted) setState(() => _isHovered = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to trash: $e')));
      }
    }
  }

  Future<void> _handleOpenMessage() async {
    final currentHeader = widget.header;

    if (!currentHeader.unread) {
      ref
          .read(smartschoolSelectedMessageProvider.notifier)
          .select(currentHeader);
      return;
    }

    final readHeader = _copyHeaderWithUnread(currentHeader, unread: false);

    widget.onHeaderUpdated(readHeader);
    ref.read(smartschoolSelectedMessageProvider.notifier).select(readHeader);

    try {
      await ref
          .read(smartschoolMessagesProvider.notifier)
          .markRead(currentHeader.id);
      await ref
          .read(smartschoolInboxProvider.notifier)
          .refreshInboxAndGetHeaders(showLoading: false);
    } catch (e) {
      final unreadHeader = _copyHeaderWithUnread(currentHeader, unread: true);
      widget.onHeaderUpdated(unreadHeader);
      ref
          .read(smartschoolSelectedMessageProvider.notifier)
          .select(unreadHeader);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark message as read: $e')),
        );
      }
    }
  }

  Future<void> _handleMarkUnread() async {
    try {
      // Update local state immediately
      final updatedHeader = _copyHeaderWithUnread(widget.header, unread: true);

      widget.onHeaderUpdated(updatedHeader);

      // Call the service
      await ref
          .read(smartschoolMessagesProvider.notifier)
          .markUnread(widget.header.id);
      await ref
          .read(smartschoolInboxProvider.notifier)
          .refreshInboxAndGetHeaders(showLoading: false);

      if (mounted) setState(() => _isHovered = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to mark unread: $e')));
      }
    }
  }

  SmartschoolMessageHeader _copyHeaderWithUnread(
    SmartschoolMessageHeader source, {
    required bool unread,
  }) {
    return SmartschoolMessageHeader(
      id: source.id,
      from: source.from,
      fromImage: source.fromImage,
      subject: source.subject,
      date: source.date,
      status: source.status,
      unread: unread,
      hasAttachment: source.hasAttachment,
      label: source.label,
      deleted: source.deleted,
      allowReply: source.allowReply,
      allowReplyEnabled: source.allowReplyEnabled,
      hasReply: source.hasReply,
      hasForward: source.hasForward,
      realBox: source.realBox,
      sendDate: source.sendDate,
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.header,
    required this.onArchive,
    required this.onTrash,
    required this.onMarkUnread,
  });

  final SmartschoolMessageHeader header;
  final VoidCallback onArchive;
  final VoidCallback onTrash;
  final VoidCallback onMarkUnread;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionIconButton(
            icon: Icons.archive,
            tooltip: 'Archive',
            onPressed: onArchive,
          ),
          _ActionIconButton(
            icon: Icons.delete,
            tooltip: 'Delete',
            onPressed: onTrash,
          ),
          _ActionIconButton(
            icon: Icons.mail,
            tooltip: 'Mark as unread',
            onPressed: onMarkUnread,
            enabled: !header.unread,
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        iconSize: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        color: enabled ? colorScheme.onSurface : colorScheme.outlineVariant,
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.header});

  final SmartschoolMessageHeader header;

  @override
  Widget build(BuildContext context) {
    final imageUrl = header.fromImage.trim();

    if (imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _InitialsAvatar(name: header.from);
          },
        ),
      );
    }

    return _InitialsAvatar(name: header.from);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _buildInitials(name);
    final colors = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
    ];
    final background = colors[name.hashCode.abs() % colors.length];

    return CircleAvatar(
      radius: 16,
      backgroundColor: background,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  String _buildInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }

    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
