import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/focus/focused_item_content.dart';
import '../../models/focus/focused_item_metadata.dart';
import 'focused_item_provider.dart';
import 'providers/outlook_focused_item_provider.dart';
import 'providers/smartschool_focused_item_provider.dart';

/// Registered focused-item adapters, probed in order.
///
/// Order matters only when two adapters could claim the same selection
/// at once (which should not happen today — the selected-message
/// Notifier holds at most one header). Kept as a plain const list so
/// adding a new adapter is a one-line change here plus the new file.
const List<FocusedItemProvider> _kFocusedItemProviders =
    <FocusedItemProvider>[
  SmartschoolFocusedItemProvider(),
  OutlookFocusedItemProvider(),
];

/// Aggregator over the registered [FocusedItemProvider]s.
///
/// The rest of the app (planner, agent tools, composer chip) only talks
/// to this service and the two reactive providers below, so it never
/// needs to know which backend is currently focused. Adding a new
/// source means writing an adapter and appending it to
/// [_kFocusedItemProviders] — no controller/tool/UI changes required.
class FocusedItemService {
  const FocusedItemService(this._ref);

  final Ref _ref;

  /// Synchronous probe of every registered adapter. Returns the first
  /// non-null metadata.
  ///
  /// Uses `ref.watch` via the adapter so callers inside a Provider
  /// rebuild reactively when the underlying selection changes. Safe to
  /// call from [Notifier.build] / providers — adapters must not do I/O
  /// in [FocusedItemProvider.currentMetadata].
  FocusedItemMetadata? currentMetadata() {
    for (final provider in _kFocusedItemProviders) {
      final metadata = provider.currentMetadata(_ref);
      if (metadata != null) return metadata;
    }
    return null;
  }

  /// Asks the adapter that owns [metadata.source] for full content.
  /// Returns `null` when no adapter claims that source or the adapter
  /// itself could not resolve the item (e.g. deleted upstream).
  Future<FocusedItemContent?> resolveContent(
    FocusedItemMetadata metadata,
  ) async {
    for (final provider in _kFocusedItemProviders) {
      if (provider.source == metadata.source) {
        return provider.resolveContent(_ref, metadata);
      }
    }
    return null;
  }
}

/// Singleton service — stateless, safe to keep around.
final focusedItemServiceProvider = Provider<FocusedItemService>(
  FocusedItemService.new,
);

/// Reactive handle to the currently focused item's metadata, or `null`
/// when nothing is focused.
///
/// Watch this to react to selection changes in the UI (composer attach
/// button, awareness chip, ...). Tools that need the metadata at call
/// time should read this provider rather than touching adapters
/// directly.
final focusedItemMetadataProvider = Provider<FocusedItemMetadata?>((ref) {
  return ref.watch(focusedItemServiceProvider).currentMetadata();
});
