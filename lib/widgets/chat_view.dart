import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/chat_controller.dart';

class ChatView extends ConsumerWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatController = ref.watch(chatControllerProvider);

    return Chat(
      currentUserId: currentUserId,
      chatController: chatController,
      resolveUser: resolveUser,
      onMessageSend: (text) => _handleSend(text, chatController),
      theme: ChatTheme.fromThemeData(Theme.of(context)),
      builders: Builders(
        composerBuilder: (context) => const Composer(sendOnEnter: true),
      ),
      timeFormat: DateFormat(''),
    );
  }

  void _handleSend(String text, InMemoryChatController controller) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final message = Message.text(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: currentUserId,
      createdAt: DateTime.now(),
      text: trimmed,
    );

    controller.insertMessage(message);
  }
}
