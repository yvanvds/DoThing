/// A single tool invocation requested by the model.
///
/// Flows:  model stream → executor parses → matched against
/// [ToolDescriptor] in the registry → invoked (or paused for confirmation).
class ToolCall {
  const ToolCall({
    required this.id,
    required this.toolName,
    required this.arguments,
  });

  /// Reconstructs a [ToolCall] from its persisted JSON representation.
  factory ToolCall.fromJson(Map<String, Object?> json) {
    final rawArgs = json['arguments'];
    return ToolCall(
      id: (json['id'] as String?) ?? '',
      toolName: (json['toolName'] as String?) ?? '',
      arguments: rawArgs is Map
          ? Map<String, Object?>.from(rawArgs)
          : const <String, Object?>{},
    );
  }

  /// Provider-assigned id (e.g. OpenAI's `tool_call_id`). Used to pair a
  /// call with its [ToolResult] when sending the follow-up turn back to
  /// the model.
  final String id;

  /// The snake_case tool name, matching [ToolDescriptor.name].
  final String toolName;

  /// Parsed JSON argument object. Already decoded from the provider
  /// stream — the executor is responsible for calling the schema
  /// validator before invoking.
  final Map<String, Object?> arguments;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'toolName': toolName,
    'arguments': arguments,
  };
}
