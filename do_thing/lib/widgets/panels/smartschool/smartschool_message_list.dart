import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/smartschool_inbox_controller.dart';
import '../../../controllers/status_controller.dart';
import '../../../services/smartschool_messages_service.dart';
import 'smartschool_message_header_tile.dart';

class SmartschoolMessageList extends ConsumerStatefulWidget {
  const SmartschoolMessageList({super.key});

  @override
  ConsumerState<SmartschoolMessageList> createState() =>
      _SmartschoolMessageListState();
}

class _SmartschoolMessageListState
    extends ConsumerState<SmartschoolMessageList> {
  bool _isLoading = true;
  String? _errorText;
  String _query = '';
  List<SmartschoolContactInbox> _contacts = const [];

  final Set<int> _expandedContacts = {};

  @override
  void initState() {
    super.initState();
    _refresh();

    ref.listenManual(smartschoolPollingProvider, (previous, next) {
      if (!mounted) return;
      if (next != previous) {
        _refresh();
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final contacts = await ref
          .read(smartschoolInboxProvider.notifier)
          .refreshInboxAndGetContactInboxes(showLoading: false);
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });

      final selected = ref.read(smartschoolSelectedMessageProvider);
      if (selected != null && !_containsMessage(selected.id)) {
        ref.read(smartschoolSelectedMessageProvider.notifier).select(null);
      }
    } catch (error) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, 'Failed to load contacts: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Failed to load contacts.';
      });
    }
  }

  bool _containsMessage(int messageId) {
    for (final contact in _contacts) {
      if (contact.items.any((item) => item.messageHeader.id == messageId)) {
        return true;
      }
    }
    return false;
  }

  void _removeHeaderFromList(int messageId) {
    final updatedContacts = <SmartschoolContactInbox>[];

    for (final contact in _contacts) {
      final remainingItems = contact.items
          .where((item) => item.messageHeader.id != messageId)
          .toList();
      if (remainingItems.isEmpty) continue;

      final unreadCount = remainingItems
          .where((item) => item.messageHeader.unread)
          .length;
      final latestActivityAt = remainingItems.first.activityAt;

      updatedContacts.add(
        SmartschoolContactInbox(
          contactId: contact.contactId,
          displayName: contact.displayName,
          avatarUrl: contact.avatarUrl,
          latestActivityAt: latestActivityAt,
          unreadCount: unreadCount,
          items: remainingItems,
        ),
      );
    }

    updatedContacts.sort(
      (a, b) => b.latestActivityAt.compareTo(a.latestActivityAt),
    );

    setState(() {
      _contacts = updatedContacts;
      _expandedContacts.removeWhere(
        (contactId) => !_contacts.any((c) => c.contactId == contactId),
      );
    });

    final selected = ref.read(smartschoolSelectedMessageProvider);
    if (selected?.id == messageId) {
      ref.read(smartschoolSelectedMessageProvider.notifier).select(null);
    }
  }

  void _updateHeaderInList(SmartschoolMessageHeader updatedHeader) {
    final updatedContacts = _contacts.map((contact) {
      final updatedItems = contact.items.map((item) {
        if (item.messageHeader.id != updatedHeader.id) return item;
        return SmartschoolRelatedItem(
          type: item.type,
          activityAt: item.activityAt,
          messageHeader: updatedHeader,
        );
      }).toList();

      final unreadCount = updatedItems
          .where((item) => item.messageHeader.unread)
          .length;

      return SmartschoolContactInbox(
        contactId: contact.contactId,
        displayName: contact.displayName,
        avatarUrl: contact.avatarUrl,
        latestActivityAt: contact.latestActivityAt,
        unreadCount: unreadCount,
        items: updatedItems,
      );
    }).toList();

    setState(() => _contacts = updatedContacts);

    final selected = ref.read(smartschoolSelectedMessageProvider);
    if (selected?.id == updatedHeader.id) {
      ref
          .read(smartschoolSelectedMessageProvider.notifier)
          .select(updatedHeader);
    }
  }

  void _toggleContact(SmartschoolContactInbox contact) {
    setState(() {
      if (_expandedContacts.contains(contact.contactId)) {
        _expandedContacts.clear();
      } else {
        _expandedContacts
          ..clear()
          ..add(contact.contactId);
      }
    });

    if (contact.items.isNotEmpty) {
      ref
          .read(smartschoolSelectedMessageProvider.notifier)
          .select(contact.items.first.messageHeader);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredContacts();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Contacts',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh contacts',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search contacts',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorText != null
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _errorText!,
                    style: TextStyle(color: colorScheme.error, fontSize: 12),
                  ),
                )
              : filtered.isEmpty
              ? Center(
                  child: Text(
                    _contacts.isEmpty ? 'No contacts' : 'No matching contacts',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final contact = filtered[index];
                    return _ContactTile(
                      contact: contact,
                      isExpanded: _expandedContacts.contains(contact.contactId),
                      onToggleExpand: () => _toggleContact(contact),
                      onRemoveFromList: _removeHeaderFromList,
                      onHeaderUpdated: _updateHeaderInList,
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<SmartschoolContactInbox> _filteredContacts() {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _contacts;

    return _contacts
        .where((contact) => contact.displayName.toLowerCase().contains(query))
        .toList();
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onRemoveFromList,
    required this.onHeaderUpdated,
  });

  final SmartschoolContactInbox contact;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<int> onRemoveFromList;
  final ValueChanged<SmartschoolMessageHeader> onHeaderUpdated;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggleExpand,
            child: Container(
              decoration: BoxDecoration(
                color: contact.unreadCount > 0
                    ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundImage:
                        contact.avatarUrl != null &&
                            contact.avatarUrl!.trim().isNotEmpty
                        ? NetworkImage(contact.avatarUrl!)
                        : null,
                    child:
                        contact.avatarUrl == null ||
                            contact.avatarUrl!.trim().isEmpty
                        ? Text(
                            _initial(contact.displayName),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: contact.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: contact.unreadCount > 0
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${contact.itemCount} related item${contact.itemCount == 1 ? '' : 's'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (contact.unreadCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${contact.unreadCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _formatDate(contact.latestActivityAt.toIso8601String()),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            margin: const EdgeInsets.only(left: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in contact.items)
                  SmartschoolMessageHeaderTile(
                    header: item.messageHeader,
                    onRemoveFromList: onRemoveFromList,
                    onHeaderUpdated: onHeaderUpdated,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
