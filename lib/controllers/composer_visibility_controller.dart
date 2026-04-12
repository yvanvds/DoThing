import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls whether the composer panel is visible in the detail pane.
final composerVisibilityProvider =
    NotifierProvider<ComposerVisibilityController, bool>(
      ComposerVisibilityController.new,
    );

class ComposerVisibilityController extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
}
