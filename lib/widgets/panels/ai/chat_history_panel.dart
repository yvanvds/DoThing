import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/ai/ai_chat_controller.dart';
import '../../../models/ai/ai_chat_models.dart';
import '../../../providers/database_provider.dart';

final aiConversationHistoryProvider = StreamProvider<List<AiConversationModel>>(
  (ref) {
    return ref.watch(aiChatRepositoryProvider).watchConversations();
  },
);

class ChatHistoryPanel extends ConsumerStatefulWidget {
  const ChatHistoryPanel({super.key});

  @override
  ConsumerState<ChatHistoryPanel> createState() => _ChatHistoryPanelState();
}

class _ChatHistoryPanelState extends ConsumerState<ChatHistoryPanel> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final value = _searchController.text;
      if (value != _query) {
        setState(() => _query = value);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(aiConversationHistoryProvider);
    final aiState = ref.watch(aiChatControllerProvider);
    final activeConversationId = aiState.asData?.value.conversationId;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chat history',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  ref
                      .read(aiChatControllerProvider.notifier)
                      .startNewConversation();
                },
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('New conversation'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search conversations…',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      tooltip: 'Clear search',
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: historyAsync.when(
              data: (conversations) {
                final filtered = _query.isEmpty
                    ? conversations
                    : conversations
                          .where(
                            (c) => c.title.toLowerCase().contains(
                              _query.toLowerCase(),
                            ),
                          )
                          .toList(growable: false);

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _query.isEmpty
                          ? 'No conversations yet.'
                          : 'No conversations match "$_query".',
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final conversation = filtered[index];
                    final isActive = activeConversationId == conversation.id;

                    return _ConversationTile(
                      conversation: conversation,
                      isActive: isActive,
                      query: _query,
                      onOpen: () {
                        ref
                            .read(aiChatControllerProvider.notifier)
                            .openConversation(conversation.id);
                      },
                      onDelete: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Delete conversation?'),
                              content: Text(
                                'This will permanently remove "${conversation.title}".',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );

                        if (shouldDelete == true) {
                          await ref
                              .read(aiChatControllerProvider.notifier)
                              .deleteConversation(conversation.id);
                        }
                      },
                    );
                  },
                );
              },
              error: (error, _) {
                return Center(
                  child: Text('Could not load chat history: $error'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.query,
    required this.onOpen,
    required this.onDelete,
  });

  final AiConversationModel conversation;
  final bool isActive;
  final String query;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isActive
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              const Icon(Icons.forum_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightText(
                      text: conversation.title,
                      query: query,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(conversation.updatedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Delete conversation',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _HighlightText extends StatelessWidget {
  const _HighlightText({
    required this.text,
    required this.query,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final lower = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = lower.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            backgroundColor: colorScheme.tertiaryContainer,
            color: colorScheme.onTertiaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = index + query.length;
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
