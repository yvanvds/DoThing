import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the app-wide [ThemeMode], allowing the user to switch between
/// light, dark, and system themes at runtime.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}
