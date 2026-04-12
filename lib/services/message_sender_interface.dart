import '../models/draft_message.dart';

/// Plug-in point for sending a composed message.
///
/// Implement this interface for each supported platform (Smartschool, Outlook).
/// Concrete implementations are out of scope for this phase and will be injected
/// via Riverpod when ready.
abstract interface class MessageSender {
  Future<void> sendMessage(DraftMessage draft);
}
