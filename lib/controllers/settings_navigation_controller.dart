import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When non-null, the settings page should scroll to this section id.
/// Set from a command or the left nav; cleared by the page after scrolling.
class SettingsNavigationController extends Notifier<String?> {
  @override
  String? build() => null;

  void navigateTo(String id) => state = id;
  void clear() => state = null;
}

final settingsNavigationProvider =
    NotifierProvider<SettingsNavigationController, String?>(
      SettingsNavigationController.new,
    );
