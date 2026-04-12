import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/settings_navigation_controller.dart';
import 'sections/ai_section.dart';
import 'sections/office365_section.dart';
import 'sections/smartschool_section.dart';
import 'sections/theme_section.dart';
import 'settings_section.dart';

/// All registered settings sections, in display order.
///
/// To add a new section, append a [SettingsSection] to this list and create
/// a corresponding widget under `sections/`.
final _sections = <SettingsSection>[
  SettingsSection(
    id: 'theme',
    title: 'Theme',
    icon: Icons.palette_outlined,
    builder: (_) => const ThemeSection(),
  ),
  SettingsSection(
    id: 'smartschool',
    title: 'Smartschool',
    icon: Icons.school_outlined,
    builder: (_) => const SmartschoolSection(),
  ),
  SettingsSection(
    id: 'office365',
    title: 'Office 365',
    icon: Icons.mail_lock_outlined,
    builder: (_) => const Office365Section(),
  ),
  SettingsSection(
    id: 'ai',
    title: 'AI',
    icon: Icons.smart_toy_outlined,
    builder: (_) => const AiSection(),
  ),
  // Add more sections here.
];

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _scrollController = ScrollController();
  final _sectionKeys = <String, GlobalKey>{};
  String _activeSection = _sections.first.id;

  @override
  void initState() {
    super.initState();
    for (final s in _sections) {
      _sectionKeys[s.id] = GlobalKey();
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    for (final section in _sections.reversed) {
      final context = _sectionKeys[section.id]?.currentContext;
      if (context == null) continue;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final offset = box.localToGlobal(Offset.zero);
      // Mark as active if the section header has passed the top third.
      if (offset.dy < MediaQuery.of(this.context).size.height * 0.45) {
        if (_activeSection != section.id) {
          setState(() => _activeSection = section.id);
        }
        break;
      }
    }
  }

  void _scrollTo(String id) {
    final context = _sectionKeys[id]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Respond to programmatic navigation requests (e.g., from command palette).
    ref.listen<String?>(settingsNavigationProvider, (_, next) {
      if (next != null) {
        _scrollTo(next);
        ref.read(settingsNavigationProvider.notifier).clear();
      }
    });

    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsNav(
          sections: _sections,
          activeId: _activeSection,
          onTap: _scrollTo,
        ),
        VerticalDivider(width: 1, color: colorScheme.outlineVariant),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                return _SectionContainer(
                  key: _sectionKeys[section.id],
                  section: section,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Left navigation sidebar
// ---------------------------------------------------------------------------

class _SettingsNav extends StatelessWidget {
  const _SettingsNav({
    required this.sections,
    required this.activeId,
    required this.onTap,
  });

  final List<SettingsSection> sections;
  final String activeId;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 160,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        children: sections.map((s) {
          final active = s.id == activeId;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onTap(s.id),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: active
                      ? colorScheme.secondaryContainer
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      s.icon,
                      size: 15,
                      color: active
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: active
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual section wrapper
// ---------------------------------------------------------------------------

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({super.key, required this.section});

  final SettingsSection section;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, size: 17, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          section.builder(context),
        ],
      ),
    );
  }
}
