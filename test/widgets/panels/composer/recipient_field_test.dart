import 'package:do_thing/models/recipients/recipient_chip.dart';
import 'package:do_thing/models/recipients/recipient_chip_source.dart';
import 'package:do_thing/models/recipients/recipient_endpoint.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_kind.dart';
import 'package:do_thing/models/recipients/recipient_endpoint_label.dart';
import 'package:do_thing/models/recipients/recipient_person_suggestion.dart';
import 'package:do_thing/models/recipients/recipient_search_result.dart';
import 'package:do_thing/services/recipients/recipient_search_providers.dart';
import 'package:do_thing/services/recipients/recipient_search_service.dart';
import 'package:do_thing/widgets/panels/composer/recipient_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecipientField', () {
    testWidgets('shows suggestions and adds selected suggestion as a chip', (
      tester,
    ) async {
      final fakeService = _FakeRecipientSearchService(
        onSearch: (_, {limitPerProvider = 25}) async {
          return RecipientSearchResult(
            people: [
              _person(
                name: 'Jan Peeters',
                endpoints: const [
                  RecipientEndpoint(
                    kind: RecipientEndpointKind.email,
                    value: 'jan@example.com',
                    label: RecipientEndpointLabel.work,
                  ),
                ],
              ),
            ],
          );
        },
      );

      await tester.pumpWidget(_buildApp(fakeService: fakeService));

      await tester.enterText(find.byType(TextField), 'jan');
      await tester.pump();

      expect(find.text('Searching...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Jan Peeters'), findsOneWidget);

      await tester.tap(find.text('Jan Peeters'));
      await tester.pump();

      expect(find.text('Jan Peeters (Work)'), findsOneWidget);
      expect(find.text('Searching...'), findsNothing);
    });

    testWidgets('opens endpoint picker and accepts highlighted endpoint', (
      tester,
    ) async {
      final fakeService = _FakeRecipientSearchService(
        onSearch: (_, {limitPerProvider = 25}) async {
          return RecipientSearchResult(
            people: [
              _person(
                name: 'Alex Demo',
                endpoints: const [
                  RecipientEndpoint(
                    kind: RecipientEndpointKind.email,
                    value: 'alex.work@school.be',
                    label: RecipientEndpointLabel.work,
                  ),
                  RecipientEndpoint(
                    kind: RecipientEndpointKind.email,
                    value: 'alex.private@gmail.com',
                    label: RecipientEndpointLabel.private,
                  ),
                ],
                requiresDisambiguation: true,
              ),
            ],
          );
        },
      );

      await tester.pumpWidget(_buildApp(fakeService: fakeService));
      await tester.enterText(find.byType(TextField), 'alex');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Alex Demo'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.text('alex.work@school.be'), findsOneWidget);
      expect(find.text('alex.private@gmail.com'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(find.text('Alex Demo (Private)'), findsOneWidget);
    });

    testWidgets('backspace with empty input removes selected chip', (
      tester,
    ) async {
      final initial = [
        const RecipientChip(
          displayName: 'Alice',
          endpoint: RecipientEndpoint(
            kind: RecipientEndpointKind.email,
            value: 'alice@example.com',
            label: RecipientEndpointLabel.other,
          ),
          source: RecipientChipSource.manual,
          autoSelectedPreferred: false,
        ),
      ];

      await tester.pumpWidget(
        _buildApp(
          fakeService: _FakeRecipientSearchService.empty(),
          initial: initial,
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('accepts raw email fallback with Enter', (tester) async {
      await tester.pumpWidget(
        _buildApp(fakeService: _FakeRecipientSearchService.empty()),
      );

      await tester.enterText(find.byType(TextField), 'new@example.com');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Use "new@example.com"'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(find.text('new@example.com (Email)'), findsOneWidget);
    });
  });
}

Widget _buildApp({
  required _FakeRecipientSearchService fakeService,
  List<RecipientChip> initial = const [],
}) {
  final container = ProviderContainer(
    overrides: [recipientSearchServiceProvider.overrideWithValue(fakeService)],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(body: _RecipientFieldHarness(initial: initial)),
    ),
  );
}

class _RecipientFieldHarness extends StatefulWidget {
  const _RecipientFieldHarness({required this.initial});

  final List<RecipientChip> initial;

  @override
  State<_RecipientFieldHarness> createState() => _RecipientFieldHarnessState();
}

class _RecipientFieldHarnessState extends State<_RecipientFieldHarness> {
  late List<RecipientChip> _chips;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _chips = [...widget.initial];
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RecipientField(
      label: 'To',
      chips: _chips,
      focusNode: _focusNode,
      autofocus: true,
      onChanged: (next) {
        setState(() {
          _chips = next;
        });
      },
    );
  }
}

class _FakeRecipientSearchService extends RecipientSearchService {
  _FakeRecipientSearchService({required this.onSearch})
    : super(providers: const []);

  _FakeRecipientSearchService.empty()
    : onSearch = ((_, {limitPerProvider = 25}) async =>
          const RecipientSearchResult(people: [])),
      super(providers: const []);

  final Future<RecipientSearchResult> Function(
    String query, {
    int limitPerProvider,
  })
  onSearch;

  @override
  Future<RecipientSearchResult> search(
    String query, {
    int limitPerProvider = 25,
  }) {
    return onSearch(query, limitPerProvider: limitPerProvider);
  }
}

RecipientPersonSuggestion _person({
  required String name,
  required List<RecipientEndpoint> endpoints,
  bool requiresDisambiguation = false,
}) {
  return RecipientPersonSuggestion(
    displayName: name,
    endpoints: endpoints,
    preferredEndpoint: endpoints.first,
    requiresDisambiguation: requiresDisambiguation,
    source: RecipientChipSource.local,
    relevanceScore: 100,
    identityKeys: const {'id:1'},
  );
}
