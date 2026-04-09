import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/smartschool_inbox_controller.dart';
import '../../../controllers/status_controller.dart';
import '../../../models/smartschool_message.dart';
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
  List<SmartschoolMessageThread> _threads = const [];

  /// Thread keys that are currently expanded; all others are collapsed.
  final Set<String> _expandedThreads = {};

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
      final threads = await ref
          .read(smartschoolInboxProvider.notifier)
          .refreshInboxAndGetThreads(showLoading: false);
      if (!mounted) return;
      setState(() {
        _threads = threads;
        _isLoading = false;
      });
    } catch (error) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, 'Failed to load messages: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Failed to load messages.';
      });
    }
  }

  void _removeHeaderFromList(int messageId) {
    final updated = <SmartschoolMessageThread>[];
    for (final thread in _threads) {
      final filtered = thread.messages.where((h) => h.id != messageId).toList();
      if (filtered.isEmpty) continue;
      updated.add(
        SmartschoolMessageThread(
          threadKey: thread.threadKey,
          subject: filtered.first.subject,
          latestDate: filtered.first.date,
          messageCount: filtered.length,
          hasUnread: filtered.any((h) => h.unread),
          hasReply: thread.hasReply,
          messages: filtered,
        ),
      );
    }
    setState(() => _threads = updated);

    final selected = ref.read(smartschoolSelectedMessageProvider);
    if (selected?.id == messageId) {
      ref.read(smartschoolSelectedMessageProvider.notifier).select(null);
    }
  }

  void _updateHeaderInList(SmartschoolMessageHeader updatedHeader) {
    final updated = <SmartschoolMessageThread>[];
    for (final thread in _threads) {
      final idx = thread.messages.indexWhere((h) => h.id == updatedHeader.id);
      if (idx == -1) {
        updated.add(thread);
        continue;
      }
      final msgs = [...thread.messages];
      msgs[idx] = updatedHeader;
      updated.add(
        SmartschoolMessageThread(
          threadKey: thread.threadKey,
          subject: thread.subject,
          latestDate: thread.latestDate,
          messageCount: msgs.length,
          hasUnread: msgs.any((h) => h.unread),
          hasReply: thread.hasReply,
          messages: msgs,
        ),
      );
    }
    setState(() => _threads = updated);

    final selected = ref.read(smartschoolSelectedMessageProvider);
    if (selected?.id == updatedHeader.id) {
      ref
          .read(smartschoolSelectedMessageProvider.notifier)
          .select(updatedHeader);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ── header bar ────────────────────────────────────────────────────
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
                  'Messages',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh messages',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),

        // ── body ──────────────────────────────────────────────────────────
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
              : _threads.isEmpty
              ? Center(
                  child: Text(
                    'No messages',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _threads.length,
                  itemBuilder: (context, index) {
                    final thread = _threads[index];
                    return _ThreadTile(
                      thread: thread,
                      isExpanded: _expandedThreads.contains(thread.threadKey),
                      onToggleExpand: () => _toggleThread(thread.threadKey),
                      onRemoveFromList: _removeHeaderFromList,
                      onHeaderUpdated: _updateHeaderInList,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _toggleThread(String threadKey) {
    setState(() {
      if (_expandedThreads.contains(threadKey)) {
        _expandedThreads.remove(threadKey);
      } else {
        _expandedThreads.add(threadKey);
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thread tile – renders a single thread row (collapsed or expanded).
// ─────────────────────────────────────────────────────────────────────────────

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.thread,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onRemoveFromList,
    required this.onHeaderUpdated,
  });

  final SmartschoolMessageThread thread;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<int> onRemoveFromList;
  final ValueChanged<SmartschoolMessageHeader> onHeaderUpdated;

  @override
  Widget build(BuildContext context) {
    // Single-message threads are rendered directly without grouping chrome.
    if (thread.messageCount <= 1) {
      return SmartschoolMessageHeaderTile(
        header: thread.messages.first,
        onRemoveFromList: onRemoveFromList,
        onHeaderUpdated: onHeaderUpdated,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final newestMessage = thread.messages.first;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── collapsed summary row ───────────────────────────────────────
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggleExpand,
            child: Container(
              decoration: BoxDecoration(
                color: thread.hasUnread
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
                  const SizedBox(width: 6),
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
                      '${thread.messageCount}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: thread.hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: thread.hasUnread
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          newestMessage.from,
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
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(newestMessage.date),
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

        // ── expanded children ──────────────────────────────────────────
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
                for (final header in thread.messages)
                  SmartschoolMessageHeaderTile(
                    header: header,
                    onRemoveFromList: onRemoveFromList,
                    onHeaderUpdated: onHeaderUpdated,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
