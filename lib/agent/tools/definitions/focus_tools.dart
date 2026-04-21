import '../../../services/focus/focused_item_service.dart';
import '../../capabilities/capability_domain.dart';
import '../../executor/tool_result.dart';
import '../tool_argument_schema.dart';
import '../tool_descriptor.dart';
import '../tool_mode.dart';
import '../tool_risk_tier.dart';

const int _kSnippetMaxChars = 400;

/// Tools that let the agent inspect whatever the user is currently
/// looking at in the app, without coupling to any specific source.
///
/// The two tools form a deliberate two-step shape: a cheap metadata
/// probe the planner can run every turn, and an opt-in content fetch
/// the executor runs only when it actually needs the body. The same
/// abstraction ([FocusedItemService]) backs both, so adapters are the
/// single integration point when new item types land.
List<ToolDescriptor> focusTools() => [
  ToolDescriptor(
    name: 'get_focused_item_metadata',
    description:
        'Return lightweight metadata about the item the user is currently '
        'viewing (type, source, title, subtitle, snippet, timestamp). '
        'Returns `{"focused": false}` when nothing is focused. Cheap — '
        'does not load bodies, participants, or attachments.',
    domain: CapabilityDomain.system,
    mode: ToolMode.read,
    risk: ToolRiskTier.read,
    arguments: ToolArgumentSchema.empty,
    invoke: (ref, _) async {
      final metadata = ref
          .read(focusedItemServiceProvider)
          .currentMetadata();
      if (metadata == null) {
        return const ToolResult(
          toolCallId: '',
          summary: 'No item is currently focused.',
          structured: <String, Object?>{'focused': false},
        );
      }
      return ToolResult(
        toolCallId: '',
        summary:
            'Focused ${metadata.source} ${metadata.type.name}: ${metadata.title}',
        structured: <String, Object?>{
          'focused': true,
          'item': metadata.toJson(),
        },
      );
    },
  ),
  ToolDescriptor(
    name: 'get_focused_item_content',
    description:
        'Return the full content of the currently focused item (body '
        'text, participants, attachment names). Use after '
        '`get_focused_item_metadata` confirms something is focused. '
        'May hit caches or the network; prefer it over re-reading the '
        'item via a source-specific tool. Returns `{"focused": false}` '
        'when nothing is focused.',
    domain: CapabilityDomain.system,
    mode: ToolMode.read,
    risk: ToolRiskTier.read,
    arguments: ToolArgumentSchema.empty,
    invoke: (ref, _) async {
      final service = ref.read(focusedItemServiceProvider);
      final metadata = service.currentMetadata();
      if (metadata == null) {
        return const ToolResult(
          toolCallId: '',
          summary: 'No item is currently focused.',
          structured: <String, Object?>{'focused': false},
        );
      }
      if (!metadata.contentAvailable) {
        return ToolResult(
          toolCallId: '',
          summary:
              'Focused item ${metadata.source}:${metadata.id} does not expose '
              'content.',
          structured: <String, Object?>{
            'focused': true,
            'content_available': false,
            'item': metadata.toJson(),
          },
        );
      }

      final content = await service.resolveContent(metadata);
      if (content == null) {
        return ToolResult(
          toolCallId: '',
          summary:
              'Could not resolve content for ${metadata.source}:${metadata.id}.',
          isError: true,
          structured: <String, Object?>{
            'focused': true,
            'resolved': false,
            'item': metadata.toJson(),
          },
        );
      }

      final preview = _previewOf(content.bodyText) ??
          _previewOf(content.bodyHtml) ??
          '';
      final summary = preview.isEmpty
          ? 'Resolved ${metadata.source} ${metadata.type.name} "${metadata.title}".'
          : 'Resolved ${metadata.source} ${metadata.type.name} "${metadata.title}" — $preview';

      return ToolResult(
        toolCallId: '',
        summary: summary,
        structured: <String, Object?>{
          'focused': true,
          'resolved': true,
          'content': content.toJson(),
        },
      );
    },
  ),
];

String? _previewOf(String? text) {
  if (text == null) return null;
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.length <= _kSnippetMaxChars) return trimmed;
  return '${trimmed.substring(0, _kSnippetMaxChars)}…';
}
