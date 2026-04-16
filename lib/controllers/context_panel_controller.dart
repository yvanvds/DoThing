import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The view currently shown inside the context panel.
///
/// Add new entries here as new views are created.
enum ContextView { empty, settings, messages, chatHistory }

/// Provides the current [ContextView] to the widget tree.
final contextPanelProvider =
    NotifierProvider<ContextPanelController, ContextView>(
      ContextPanelController.new,
    );

/// Controls which view is displayed in the context panel.
///
/// Commands and UI both interact with this controller through
/// [contextPanelProvider].
class ContextPanelController extends Notifier<ContextView> {
  @override
  ContextView build() => ContextView.empty;

  /// Navigate the context panel to [view].
  void show(ContextView view) => state = view;

  /// Reset to the default empty view.
  void reset() => state = ContextView.empty;
}
