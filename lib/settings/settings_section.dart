import 'package:flutter/widgets.dart';

/// Describes one section in the settings page.
class SettingsSection {
  const SettingsSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
  });

  /// Unique id used for programmatic scroll navigation.
  final String id;
  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}
