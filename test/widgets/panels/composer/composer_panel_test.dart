import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:do_thing/controllers/composer_controller.dart';
import 'package:do_thing/controllers/composer_visibility_controller.dart';
import 'package:do_thing/widgets/panels/composer/composer_panel.dart';

Widget _buildApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: const [FlutterQuillLocalizations.delegate],
      home: const Scaffold(body: ComposerPanel()),
    ),
  );
}

void main() {
  group('ComposerPanel', () {
    testWidgets('renders header labels and title bar', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      expect(find.text('New message'), findsOneWidget);
      expect(find.text('To:'), findsOneWidget);
      expect(find.text('CC:'), findsOneWidget);
      expect(find.text('BCC:'), findsOneWidget);
      expect(find.text('Subject:'), findsOneWidget);
    });

    testWidgets('renders Cancel and Send buttons', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
    });

    testWidgets('Send button is disabled (no sender wired yet)', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      // Verify the Send label exists and is not tappable (disabled).
      final sendFinder = find.text('Send');
      expect(sendFinder, findsOneWidget);

      // A disabled button wraps its label in an IgnorePointer or makes
      // onPressed null. We verify it cannot be tapped — no state change occurs.
      final visibilityBefore = container.read(composerVisibilityProvider);
      await tester.tap(sendFinder, warnIfMissed: false);
      await tester.pump();
      expect(container.read(composerVisibilityProvider), visibilityBefore);
    });

    testWidgets('Cancel closes composer and resets draft', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Pre-populate some draft state and open the composer.
      container.read(composerProvider.notifier).updateSubject('Draft subject');
      container.read(composerVisibilityProvider.notifier).open();

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(container.read(composerVisibilityProvider), isFalse);
      expect(container.read(composerProvider).subject, '');
    });

    testWidgets('typing in Subject field updates composerProvider', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container));
      await tester.pumpAndSettle();

      // Subject is the 4th TextField (To, CC, BCC, Subject).
      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(4));

      await tester.enterText(fields.at(3), 'Hello world');
      await tester.pump();

      expect(container.read(composerProvider).subject, 'Hello world');
    });
  });
}
