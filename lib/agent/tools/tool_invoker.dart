import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../executor/tool_call.dart';
import '../executor/tool_result.dart';
import 'tool_registry.dart';

/// Executes a [ToolCall] against the [ToolRegistry], enforcing argument
/// validation and uniform error handling.
///
/// Never throws: every failure mode — unknown tool, invalid arguments,
/// handler exception — becomes a [ToolResult] marked `isError`, so the
/// executor can feed the failure back to the model and let it recover.
class ToolInvoker {
  ToolInvoker(this._ref, this._registry);

  final Ref _ref;
  final ToolRegistry _registry;

  Future<ToolResult> invoke(ToolCall call) async {
    final descriptor = _registry.byName(call.toolName);
    if (descriptor == null) {
      return ToolResult.error(
        call.id,
        'Unknown tool "${call.toolName}".',
      );
    }

    final validationError = descriptor.arguments.validate(call.arguments);
    if (validationError != null) {
      return ToolResult.error(
        call.id,
        'Invalid arguments for "${call.toolName}": ${validationError.message}',
        structured: <String, Object?>{'validation': validationError.toJson()},
      );
    }

    try {
      final raw = await descriptor.invoke(_ref, call.arguments);
      return raw.withToolCallId(call.id);
    } catch (error) {
      return ToolResult.error(
        call.id,
        'Tool "${call.toolName}" failed: $error',
      );
    }
  }
}

/// Provides the app-wide [ToolInvoker], bound to the default
/// [toolRegistryProvider].
final toolInvokerProvider = Provider<ToolInvoker>((ref) {
  return ToolInvoker(ref, ref.watch(toolRegistryProvider));
});
