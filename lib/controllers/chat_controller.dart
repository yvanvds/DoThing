import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User IDs used in this one-on-one chat.
const currentUserId = 'user';
const systemUserId = 'system';

/// Pre-defined users.
const currentUser = User(id: currentUserId, name: 'You');
const systemUser = User(id: systemUserId, name: 'DoThing');

/// Provides and manages the [InMemoryChatController] for the app.
///
/// Widgets watch this provider to get the controller. Commands or services
/// call [addUserMessage] / [addSystemMessage] to push messages.
final chatControllerProvider = Provider.autoDispose<InMemoryChatController>((
  ref,
) {
  final controller = InMemoryChatController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Resolves a [User] from the known user IDs.
Future<User?> resolveUser(String id) async {
  return switch (id) {
    currentUserId => currentUser,
    systemUserId => systemUser,
    _ => null,
  };
}
