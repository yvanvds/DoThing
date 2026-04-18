/// Result of invoking a tool, fed back to the model as the next turn.
///
/// Keep [summary] short — it is the only piece guaranteed to reach the
/// model context window unless [structured] is also forwarded.
class ToolResult {
  const ToolResult({
    required this.toolCallId,
    required this.summary,
    this.isError = false,
    this.structured,
  });

  /// Constructs a synthetic canceled result for a tool call the user
  /// rejected via the confirmation UI. The model sees this and can
  /// choose to continue or abandon the plan.
  factory ToolResult.canceled(String toolCallId, {String? reason}) {
    return ToolResult(
      toolCallId: toolCallId,
      isError: true,
      summary: reason ?? 'User canceled this action.',
      structured: const <String, Object?>{'canceled': true},
    );
  }

  factory ToolResult.error(
    String toolCallId,
    String message, {
    Map<String, Object?>? structured,
  }) {
    return ToolResult(
      toolCallId: toolCallId,
      isError: true,
      summary: message,
      structured: structured,
    );
  }

  final String toolCallId;
  final bool isError;
  final String summary;
  final Map<String, Object?>? structured;
}
