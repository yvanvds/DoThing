/// Decision handed back by a [ToolConfirmationGate].
///
/// A denied decision carries an optional [reason] string which is fed to
/// the model as the canceled tool result — the model uses it to decide
/// whether to abandon or retry with different arguments.
class ConfirmationDecision {
  const ConfirmationDecision({required this.approved, this.reason});

  const ConfirmationDecision.approved() : approved = true, reason = null;

  const ConfirmationDecision.denied({this.reason}) : approved = false;

  final bool approved;
  final String? reason;
}
