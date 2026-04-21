import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/focus/focused_item_content.dart';
import '../../models/focus/focused_item_metadata.dart';

/// Adapter that exposes a specific app feature (mail, todos, documents,
/// ...) as the currently focused item.
///
/// The controller/service layer never knows which concrete provider
/// answered — it asks each one in order and accepts the first non-null
/// metadata. Providers must therefore be cheap to probe: no I/O in
/// [currentMetadata]; the heavy work belongs in [resolveContent].
abstract class FocusedItemProvider {
  const FocusedItemProvider();

  /// Stable source key (`smartschool`, `outlook`, ...) this provider
  /// claims. Used by [FocusedItemService.resolveContent] to route a
  /// content fetch back to the right adapter.
  String get source;

  /// Returns the metadata for whatever this adapter considers focused,
  /// or `null` when the adapter has nothing to expose. Called from
  /// synchronous Riverpod reads — must not do I/O.
  FocusedItemMetadata? currentMetadata(Ref ref);

  /// Fetches full content for a [metadata] previously produced by this
  /// adapter. Implementations may hit caches, databases, or remote
  /// APIs. Returns `null` when the item can no longer be resolved
  /// (deleted, logged-out, ...).
  Future<FocusedItemContent?> resolveContent(
    Ref ref,
    FocusedItemMetadata metadata,
  );
}
