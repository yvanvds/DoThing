import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/theme_mode_controller.dart';

/// Settings content for the Theme section.
class ThemeSection extends ConsumerWidget {
  const ThemeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThemeModeOption(
          label: 'System default',
          description: 'Follows your OS light/dark setting.',
          icon: Icons.brightness_auto_outlined,
          mode: ThemeMode.system,
          current: current,
          ref: ref,
        ),
        const SizedBox(height: 8),
        _ThemeModeOption(
          label: 'Light',
          description: 'Always use the light theme.',
          icon: Icons.wb_sunny_outlined,
          mode: ThemeMode.light,
          current: current,
          ref: ref,
        ),
        const SizedBox(height: 8),
        _ThemeModeOption(
          label: 'Dark',
          description: 'Always use the dark theme.',
          icon: Icons.nightlight_outlined,
          mode: ThemeMode.dark,
          current: current,
          ref: ref,
        ),
      ],
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.mode,
    required this.current,
    required this.ref,
  });

  final String label;
  final String description;
  final IconData icon;
  final ThemeMode mode;
  final ThemeMode current;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = current == mode;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => ref.read(themeModeProvider.notifier).setMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.8,
                            )
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
