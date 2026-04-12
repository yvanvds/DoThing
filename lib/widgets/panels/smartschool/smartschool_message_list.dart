import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/smartschool_inbox_controller.dart';
import '../../../controllers/status_controller.dart';
import '../../../services/office365/office365_mail_service.dart';
import '../../../services/office365/office365_polling_controller.dart';
import '../../../services/smartschool/smartschool_messages_controller.dart';
import '../../../services/smartschool/smartschool_polling_controller.dart';
import '../../../services/smartschool/smartschool_selected_message_controller.dart';
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
  bool _isRefreshing = false;
  bool _refreshInFlight = false;
  String? _errorText;
  String _query = '';
  List<SmartschoolContactInbox> _contacts = const [];
  final Set<int> _bulkBusyContacts = {};
  final Map<int, _BulkProgress> _bulkProgressByContact = {};
  final Set<String> _newMessageKeys = {};
  final Set<Timer> _pendingNewMessageTimers = {};

  final Set<int> _expandedContacts = {};

  @override
  void initState() {
    super.initState();
    _refresh(background: false);

    ref.listenManual(smartschoolPollingProvider, (previous, next) {
      if (!mounted) return;
      if (next != previous) {
        _refresh(background: true);
      }
    });

    ref.listenManual(office365PollingProvider, (previous, next) {
      if (!mounted) return;
      if (next != previous) {
        _refreshFromLocal();
      }
    });
  }

  @override
  void dispose() {
    for (final timer in _pendingNewMessageTimers) {
      timer.cancel();
    }
    _pendingNewMessageTimers.clear();
    super.dispose();
  }

  Future<void> _refreshFromLocal() async {
    try {
      final contacts = await ref
          .read(smartschoolInboxProvider.notifier)
          .loadContactInboxesFromLocal();
      if (!mounted) return;

      _applyContactsUpdate(contacts);

      final selected = ref.read(smartschoolSelectedMessageProvider);
      if (selected != null && !_containsHeader(selected)) {
        ref.read(smartschoolSelectedMessageProvider.notifier).select(null);
      }
    } catch (_) {}
  }

  Future<void> _refresh({bool background = true}) async {
    if (_refreshInFlight) return;
    _refreshInFlight = true;

    final showBlockingLoader = !background && _contacts.isEmpty;
    if (mounted) {
      setState(() {
        _errorText = null;
        _isLoading = showBlockingLoader;
        _isRefreshing = !showBlockingLoader;
      });
    }

    try {
      final contacts = await ref
          .read(smartschoolInboxProvider.notifier)
          .refreshInboxAndGetContactInboxes(showLoading: false);
      if (!mounted) return;

      _applyContactsUpdate(contacts);

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });

      final selected = ref.read(smartschoolSelectedMessageProvider);
      if (selected != null && !_containsHeader(selected)) {
        ref.read(smartschoolSelectedMessageProvider.notifier).select(null);
      }
    } catch (error) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, 'Failed to load people list: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorText = 'Failed to load people list.';
      });
    } finally {
      _refreshInFlight = false;
    }
  }

  void _applyContactsUpdate(List<SmartschoolContactInbox> contacts) {
    final previousKeys = _allMessageKeys(_contacts);
    final nextKeys = _allMessageKeys(contacts);
    final addedKeys = nextKeys.difference(previousKeys);

    setState(() {
      _contacts = contacts;
      _newMessageKeys.addAll(addedKeys);
    });

    if (addedKeys.isNotEmpty) {
      late final Timer timer;
      timer = Timer(const Duration(seconds: 6), () {
        _pendingNewMessageTimers.remove(timer);
        if (!mounted) return;
        setState(() {
          _newMessageKeys.removeAll(addedKeys);
        });
      });
      _pendingNewMessageTimers.add(timer);
    }
  }

  Set<String> _allMessageKeys(List<SmartschoolContactInbox> contacts) {
    final keys = <String>{};
    for (final contact in contacts) {
      for (final item in contact.items) {
        final header = item.messageHeader;
        keys.add('${header.source}:${header.id}');
      }
    }
    return keys;
  }

  bool _containsHeader(SmartschoolMessageHeader header) {
    for (final contact in _contacts) {
      if (contact.items.any(
        (item) =>
            item.messageHeader.id == header.id &&
            item.messageHeader.source == header.source,
      )) {
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
        if (item.messageHeader.id != updatedHeader.id ||
            item.messageHeader.source != updatedHeader.source) {
          return item;
        }
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
    if (selected?.id == updatedHeader.id &&
        selected?.source == updatedHeader.source) {
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

  Future<void> _archiveAllForContact(SmartschoolContactInbox contact) async {
    await _runBulkContactAction(
      contact: contact,
      actionLabel: 'Archiving',
      progressLabel: 'Archive',
      successVerb: 'Archived',
      perform: (status, total, state) async {
        await _archiveSmartschoolMessages(
          contact: contact,
          status: status,
          total: total,
          state: state,
        );
        await _archiveOutlookMessages(
          contact: contact,
          status: status,
          total: total,
          state: state,
        );
      },
    );
  }

  Future<void> _deleteAllForContact(SmartschoolContactInbox contact) async {
    await _runBulkContactAction(
      contact: contact,
      actionLabel: 'Deleting',
      progressLabel: 'Delete',
      successVerb: 'Deleted',
      perform: (status, total, state) async {
        await _deleteMessagesForContact(
          contact: contact,
          status: status,
          total: total,
          state: state,
        );
      },
    );
  }

  Future<void> _runBulkContactAction({
    required SmartschoolContactInbox contact,
    required String actionLabel,
    required String progressLabel,
    required String successVerb,
    required Future<void> Function(
      StatusController status,
      int total,
      _BulkActionState state,
    )
    perform,
  }) async {
    if (_bulkBusyContacts.contains(contact.contactId)) return;

    setState(() => _bulkBusyContacts.add(contact.contactId));

    final status = ref.read(statusProvider.notifier);
    final total = contact.items.length;
    final state = _BulkActionState();

    _setBulkProgress(
      contact.contactId,
      _BulkProgress(processed: 0, total: total, actionLabel: actionLabel),
    );
    status.add(
      StatusEntryType.info,
      '$actionLabel $total message${total == 1 ? '' : 's'} for ${contact.displayName}...',
    );

    try {
      await perform(status, total, state);
      await _refresh(background: true);
      _reportBulkActionCompletion(
        contact: contact,
        total: total,
        state: state,
        progressLabel: progressLabel,
        successVerb: successVerb,
      );
    } finally {
      _clearBulkAction(contact.contactId);
    }
  }

  Future<void> _archiveSmartschoolMessages({
    required SmartschoolContactInbox contact,
    required StatusController status,
    required int total,
    required _BulkActionState state,
  }) async {
    final smartschoolIds = contact.items
        .map((item) => item.messageHeader)
        .where((header) => header.source == 'smartschool')
        .map((header) => header.id)
        .toList();
    if (smartschoolIds.isEmpty) {
      return;
    }

    status.add(
      StatusEntryType.info,
      'Archiving ${smartschoolIds.length} Smartschool message${smartschoolIds.length == 1 ? '' : 's'}...',
    );

    try {
      await ref
          .read(smartschoolMessagesProvider.notifier)
          .archive(smartschoolIds);
      state.successCount += smartschoolIds.length;
    } catch (error) {
      state.recordError(error);
      status.add(
        StatusEntryType.warning,
        'Failed archiving Smartschool batch for ${contact.displayName}: $error',
      );
    } finally {
      state.processedCount += smartschoolIds.length;
      _updateBulkActionProgress(
        contact: contact,
        total: total,
        state: state,
        actionLabel: 'Archiving',
        progressLabel: 'Archive',
        shouldLog: true,
        status: status,
      );
    }
  }

  Future<void> _archiveOutlookMessages({
    required SmartschoolContactInbox contact,
    required StatusController status,
    required int total,
    required _BulkActionState state,
  }) async {
    final outlookHeaders = contact.items
        .map((item) => item.messageHeader)
        .where((header) => header.source == 'outlook')
        .toList();

    for (final header in outlookHeaders) {
      try {
        await ref.read(office365MailServiceProvider).archiveMessage(header.id);
        state.successCount++;
      } catch (error) {
        state.recordError(error);
        status.add(
          StatusEntryType.warning,
          'Failed archiving Outlook message ${header.id} for ${contact.displayName}: $error',
        );
      }

      state.processedCount++;
      _updateBulkActionProgress(
        contact: contact,
        total: total,
        state: state,
        actionLabel: 'Archiving',
        progressLabel: 'Archive',
        shouldLog:
            outlookHeaders.length <= 5 ||
            state.processedCount == total ||
            state.processedCount % 5 == 0,
        status: status,
      );
    }
  }

  Future<void> _deleteMessagesForContact({
    required SmartschoolContactInbox contact,
    required StatusController status,
    required int total,
    required _BulkActionState state,
  }) async {
    for (final item in contact.items) {
      final header = item.messageHeader;
      try {
        await _deleteMessageHeader(header);
        state.successCount++;
      } catch (error) {
        state.recordError(error);
        status.add(
          StatusEntryType.warning,
          'Failed deleting ${header.source} message ${header.id} for ${contact.displayName}: $error',
        );
      }

      state.processedCount++;
      _updateBulkActionProgress(
        contact: contact,
        total: total,
        state: state,
        actionLabel: 'Deleting',
        progressLabel: 'Delete',
        shouldLog:
            total <= 5 ||
            state.processedCount == total ||
            state.processedCount % 5 == 0,
        status: status,
      );
    }
  }

  Future<void> _deleteMessageHeader(SmartschoolMessageHeader header) async {
    if (header.source == 'smartschool') {
      await ref.read(smartschoolMessagesProvider.notifier).trash(header.id);
      return;
    }
    if (header.source == 'outlook') {
      await ref.read(office365MailServiceProvider).deleteMessage(header.id);
    }
  }

  void _updateBulkActionProgress({
    required SmartschoolContactInbox contact,
    required int total,
    required _BulkActionState state,
    required String actionLabel,
    required String progressLabel,
    required bool shouldLog,
    required StatusController status,
  }) {
    _setBulkProgress(
      contact.contactId,
      _BulkProgress(
        processed: state.processedCount,
        total: total,
        actionLabel: actionLabel,
      ),
    );

    if (!shouldLog) {
      return;
    }

    status.add(
      StatusEntryType.info,
      '$progressLabel progress (${contact.displayName}): ${state.processedCount}/$total',
    );
  }

  void _reportBulkActionCompletion({
    required SmartschoolContactInbox contact,
    required int total,
    required _BulkActionState state,
    required String progressLabel,
    required String successVerb,
  }) {
    final status = ref.read(statusProvider.notifier);
    final statusType = state.firstError == null
        ? StatusEntryType.success
        : StatusEntryType.warning;
    final completionText = state.firstError == null
        ? '$progressLabel completed for ${contact.displayName}: ${state.successCount}/$total succeeded.'
        : '$progressLabel completed for ${contact.displayName}: ${state.successCount}/$total succeeded (errors occurred).';

    status.add(statusType, completionText);
    if (!mounted) {
      return;
    }

    final messageWord = state.successCount == 1 ? 'message' : 'messages';
    String snackBarText;
    if (state.firstError == null) {
      snackBarText =
          '$successVerb ${state.successCount} $messageWord from ${contact.displayName}.';
    } else {
      snackBarText =
          '$successVerb ${state.successCount} of ${contact.items.length} messages. First error: ${state.firstError}';
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(snackBarText)));
  }

  void _clearBulkAction(int contactId) {
    if (!mounted) {
      return;
    }

    setState(() {
      _bulkBusyContacts.remove(contactId);
      _bulkProgressByContact.remove(contactId);
    });
  }

  void _setBulkProgress(int contactId, _BulkProgress progress) {
    if (!mounted) return;
    setState(() {
      _bulkProgressByContact[contactId] = progress;
    });
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
                  'People',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              if (_isRefreshing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              if (_isRefreshing) const SizedBox(width: 8),
              IconButton(
                onPressed: () => _refresh(background: true),
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh people list',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Search people',
              prefixIcon: Icon(Icons.search, size: 18),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
          ),
        ),
        Expanded(child: _buildListBody(colorScheme, filtered)),
      ],
    );
  }

  Widget _buildListBody(
    ColorScheme colorScheme,
    List<SmartschoolContactInbox> filtered,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorText != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          _errorText!,
          style: TextStyle(color: colorScheme.error, fontSize: 12),
        ),
      );
    }

    if (filtered.isEmpty) {
      final emptyText = _contacts.isEmpty
          ? 'No people yet'
          : 'No matching people';
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final contact = filtered[index];
        return _ContactTile(
          contact: contact,
          isExpanded: _expandedContacts.contains(contact.contactId),
          isBulkBusy: _bulkBusyContacts.contains(contact.contactId),
          bulkProgress: _bulkProgressByContact[contact.contactId],
          onToggleExpand: () => _toggleContact(contact),
          onArchiveAll: _archiveAllForContact,
          onDeleteAll: _deleteAllForContact,
          onRemoveFromList: _removeHeaderFromList,
          onHeaderUpdated: _updateHeaderInList,
        );
      },
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

class _ContactTile extends StatefulWidget {
  const _ContactTile({
    required this.contact,
    required this.isExpanded,
    required this.isBulkBusy,
    required this.bulkProgress,
    required this.onToggleExpand,
    required this.onArchiveAll,
    required this.onDeleteAll,
    required this.onRemoveFromList,
    required this.onHeaderUpdated,
  });

  final SmartschoolContactInbox contact;
  final bool isExpanded;
  final bool isBulkBusy;
  final _BulkProgress? bulkProgress;
  final VoidCallback onToggleExpand;
  final Future<void> Function(SmartschoolContactInbox contact) onArchiveAll;
  final Future<void> Function(SmartschoolContactInbox contact) onDeleteAll;
  final ValueChanged<int> onRemoveFromList;
  final ValueChanged<SmartschoolMessageHeader> onHeaderUpdated;

  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showBulkActions = _isHovered || widget.isBulkBusy;
    final progress = widget.bulkProgress;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildContactHeader(colorScheme, showBulkActions, progress),
        if (widget.isExpanded)
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
                for (final item in widget.contact.items)
                  SmartschoolMessageHeaderTile(
                    header: item.messageHeader,
                    highlightAsNew: _isNew(item.messageHeader),
                    onRemoveFromList: widget.onRemoveFromList,
                    onHeaderUpdated: widget.onHeaderUpdated,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContactHeader(
    ColorScheme colorScheme,
    bool showBulkActions,
    _BulkProgress? progress,
  ) {
    final avatarUrl = widget.contact.avatarUrl?.trim() ?? '';
    final hasAvatar = avatarUrl.isNotEmpty;
    final unreadColor = widget.contact.unreadCount > 0
        ? colorScheme.primaryContainer.withValues(alpha: 0.15)
        : Colors.transparent;
    final contactWeight = widget.contact.unreadCount > 0
        ? FontWeight.w700
        : FontWeight.w500;
    final contactColor = widget.contact.unreadCount > 0
        ? colorScheme.primary
        : colorScheme.onSurface;
    final itemWord = widget.contact.itemCount == 1 ? 'item' : 'items';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onToggleExpand,
          child: Container(
            decoration: BoxDecoration(
              color: unreadColor,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                  child: hasAvatar
                      ? null
                      : Text(
                          _initial(widget.contact.displayName),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.contact.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: contactWeight,
                          color: contactColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.contact.itemCount} related $itemWord',
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
                if (widget.contact.unreadCount > 0) ...[
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
                      '${widget.contact.unreadCount}',
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
                  _formatDate(
                    widget.contact.latestActivityAt.toIso8601String(),
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${progress.actionLabel} ${progress.processed}/${progress.total}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
                if (showBulkActions) _buildBulkActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulkActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 8),
        IconButton(
          onPressed: widget.isBulkBusy
              ? null
              : () async {
                  final confirmed = await _confirmBulkAction(
                    context,
                    title: 'Archive all messages?',
                    message:
                        'Archive all ${widget.contact.itemCount} related items for ${widget.contact.displayName}?',
                    confirmLabel: 'Archive all',
                  );
                  if (!confirmed) return;
                  await widget.onArchiveAll(widget.contact);
                },
          icon: const Icon(Icons.archive_outlined, size: 18),
          tooltip: 'Archive all for this contact',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: widget.isBulkBusy
              ? null
              : () async {
                  final confirmed = await _confirmBulkAction(
                    context,
                    title: 'Delete all messages?',
                    message:
                        'Delete all ${widget.contact.itemCount} related items for ${widget.contact.displayName}? This cannot be undone.',
                    confirmLabel: 'Delete all',
                    isDestructive: true,
                  );
                  if (!confirmed) return;
                  await widget.onDeleteAll(widget.contact);
                },
          icon: const Icon(Icons.delete_outline, size: 18),
          tooltip: 'Delete all for this contact',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  bool _isNew(SmartschoolMessageHeader header) {
    final state = context
        .findAncestorStateOfType<_SmartschoolMessageListState>();
    if (state == null) return false;
    return state._newMessageKeys.contains('${header.source}:${header.id}');
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

  Future<bool> _confirmBulkAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: isDestructive
                  ? FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result == true;
  }
}

class _BulkProgress {
  const _BulkProgress({
    required this.processed,
    required this.total,
    required this.actionLabel,
  });

  final int processed;
  final int total;
  final String actionLabel;
}

class _BulkActionState {
  int successCount = 0;
  int processedCount = 0;
  Object? firstError;

  void recordError(Object error) {
    firstError ??= error;
  }
}
