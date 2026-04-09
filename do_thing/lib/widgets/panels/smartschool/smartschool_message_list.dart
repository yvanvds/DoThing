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
  List<SmartschoolMessageHeader> _headers = const [];

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

  Future<List<SmartschoolMessageHeader>> _loadHeaders() async {
    try {
      return await ref
          .read(smartschoolInboxProvider.notifier)
          .refreshInboxAndGetHeaders(showLoading: false);
    } catch (error) {
      ref
          .read(statusProvider.notifier)
          .add(StatusEntryType.error, 'Failed to load messages: $error');
      rethrow;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final headers = await _loadHeaders();
      if (!mounted) return;
      setState(() {
        _headers = headers;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Failed to load messages.';
      });
    }
  }

  void _removeHeaderFromList(int messageId) {
    setState(() {
      _headers = _headers.where((header) => header.id != messageId).toList();
    });

    final selected = ref.read(smartschoolSelectedMessageProvider);
    if (selected?.id == messageId) {
      ref.read(smartschoolSelectedMessageProvider.notifier).select(null);
    }
  }

  void _updateHeaderInList(SmartschoolMessageHeader updatedHeader) {
    final index = _headers.indexWhere((h) => h.id == updatedHeader.id);
    if (index == -1) return;

    final updatedList = [..._headers];
    updatedList[index] = updatedHeader;

    setState(() {
      _headers = updatedList;
    });

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
              : _headers.isEmpty
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
                  itemCount: _headers.length,
                  itemBuilder: (context, index) {
                    return SmartschoolMessageHeaderTile(
                      header: _headers[index],
                      onRemoveFromList: _removeHeaderFromList,
                      onHeaderUpdated: _updateHeaderInList,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
