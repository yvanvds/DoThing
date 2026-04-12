import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/recipients/recipient_chip.dart';
import '../../../models/recipients/recipient_chip_source.dart';
import '../../../models/recipients/recipient_endpoint.dart';
import '../../../models/recipients/recipient_endpoint_kind.dart';
import '../../../models/recipients/recipient_endpoint_label.dart';
import '../../../models/recipients/recipient_person_suggestion.dart';
import '../../../services/recipients/recipient_email_validator.dart';
import '../../../services/recipients/recipient_search_providers.dart';

class RecipientField extends ConsumerStatefulWidget {
  const RecipientField({
    super.key,
    required this.label,
    required this.chips,
    required this.onChanged,
    required this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final List<RecipientChip> chips;
  final ValueChanged<List<RecipientChip>> onChanged;
  final FocusNode focusNode;
  final bool autofocus;

  @override
  ConsumerState<RecipientField> createState() => _RecipientFieldState();
}

class _RecipientFieldState extends ConsumerState<RecipientField> {
  final TextEditingController _inputController = TextEditingController();

  Timer? _debounce;
  int _searchToken = 0;
  bool _loading = false;

  List<RecipientPersonSuggestion> _suggestions = const [];
  int _highlightedIndex = 0;

  int? _selectedChipIndex;
  int? _endpointPickerPersonIndex;
  int _endpointPickerEndpointIndex = 0;

  bool get _isEndpointPickerOpen => _endpointPickerPersonIndex != null;

  bool get _isRawEmailFallbackVisible {
    final value = _inputController.text.trim().toLowerCase();
    if (!RecipientEmailValidator.isValid(value)) return false;
    return !widget.chips.any(
      (chip) => chip.endpoint.value.toLowerCase() == value,
    );
  }

  int get _mainSuggestionCount =>
      _suggestions.length + (_isRawEmailFallbackVisible ? 1 : 0);

  bool get _showSuggestionPanel {
    if (_isEndpointPickerOpen) return true;
    if (_loading && _inputController.text.trim().isNotEmpty) return true;
    return _mainSuggestionCount > 0;
  }

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant RecipientField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }

    if (_selectedChipIndex != null &&
        _selectedChipIndex! >= widget.chips.length) {
      _selectedChipIndex = null;
    }
  }

  void _onFocusChange() {
    if (!widget.focusNode.hasFocus) {
      setState(() {
        _endpointPickerPersonIndex = null;
        _selectedChipIndex = null;
      });
    }
  }

  void _onInputChanged() {
    setState(() {
      _selectedChipIndex = null;
      _endpointPickerPersonIndex = null;
    });
    _scheduleSearch();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    final query = _inputController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _suggestions = const [];
        _loading = false;
        _highlightedIndex = 0;
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 250), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _inputController.text.trim();
    final token = ++_searchToken;

    final result = await ref.read(recipientSearchServiceProvider).search(query);
    if (!mounted || token != _searchToken) return;

    setState(() {
      _suggestions = result.people
          .where(
            (candidate) => !widget.chips.any(
              (chip) =>
                  chip.endpoint.dedupeKey ==
                  candidate.preferredEndpoint.dedupeKey,
            ),
          )
          .toList(growable: false);
      _loading = false;
      _highlightedIndex = 0;
    });
  }

  KeyEventResult _onKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(next: true);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(next: false);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      _closePickerOrSuggestions();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.backspace && _inputController.text.isEmpty) {
      _handleBackspaceWithEmptyInput();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight && !_isEndpointPickerOpen) {
      if (_tryOpenEndpointPicker()) {
        return KeyEventResult.handled;
      }
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.tab) {
      final accepted = _acceptCurrentSelection(
        allowEndpointPickerOpen: key == LogicalKeyboardKey.enter,
      );
      return accepted ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  void _moveSelection({required bool next}) {
    setState(() {
      if (_isEndpointPickerOpen) {
        final person = _suggestions[_endpointPickerPersonIndex!];
        if (person.endpoints.isEmpty) return;
        final maxIndex = person.endpoints.length - 1;
        if (next) {
          _endpointPickerEndpointIndex = (_endpointPickerEndpointIndex + 1)
              .clamp(0, maxIndex);
        } else {
          _endpointPickerEndpointIndex = (_endpointPickerEndpointIndex - 1)
              .clamp(0, maxIndex);
        }
        return;
      }

      final maxIndex = _mainSuggestionCount - 1;
      if (maxIndex < 0) return;

      if (next) {
        _highlightedIndex = (_highlightedIndex + 1).clamp(0, maxIndex);
      } else {
        _highlightedIndex = (_highlightedIndex - 1).clamp(0, maxIndex);
      }
    });
  }

  bool _acceptCurrentSelection({required bool allowEndpointPickerOpen}) {
    if (_isEndpointPickerOpen) {
      final person = _suggestions[_endpointPickerPersonIndex!];
      if (person.endpoints.isEmpty) return false;
      final endpoint = person.endpoints[_endpointPickerEndpointIndex];
      _addChipFromPerson(
        person,
        endpoint: endpoint,
        autoSelectedPreferred: false,
      );
      return true;
    }

    if (_mainSuggestionCount == 0) {
      if (_isRawEmailFallbackVisible) {
        _addRawEmailChip(_inputController.text.trim());
        return true;
      }
      return false;
    }

    if (_highlightedIndex < _suggestions.length) {
      final person = _suggestions[_highlightedIndex];
      if (person.requiresDisambiguation && allowEndpointPickerOpen) {
        _openEndpointPickerForIndex(_highlightedIndex);
        return true;
      }

      _addChipFromPerson(
        person,
        endpoint: person.preferredEndpoint,
        autoSelectedPreferred: true,
      );
      return true;
    }

    if (_isRawEmailFallbackVisible) {
      _addRawEmailChip(_inputController.text.trim());
      return true;
    }

    return false;
  }

  bool _tryOpenEndpointPicker() {
    if (_highlightedIndex >= _suggestions.length) return false;
    final person = _suggestions[_highlightedIndex];
    if (!person.requiresDisambiguation || person.endpoints.length <= 1) {
      return false;
    }
    _openEndpointPickerForIndex(_highlightedIndex);
    return true;
  }

  void _openEndpointPickerForIndex(int index) {
    setState(() {
      _endpointPickerPersonIndex = index;
      _endpointPickerEndpointIndex = 0;
    });
  }

  void _closePickerOrSuggestions() {
    setState(() {
      if (_isEndpointPickerOpen) {
        _endpointPickerPersonIndex = null;
        return;
      }
      _suggestions = const [];
      _highlightedIndex = 0;
    });
  }

  void _handleBackspaceWithEmptyInput() {
    if (widget.chips.isEmpty) return;

    if (_selectedChipIndex == null) {
      setState(() {
        _selectedChipIndex = widget.chips.length - 1;
      });
      return;
    }

    final index = _selectedChipIndex!;
    final next = [...widget.chips]..removeAt(index);
    widget.onChanged(next);

    setState(() {
      if (next.isEmpty) {
        _selectedChipIndex = null;
      } else {
        _selectedChipIndex = (index - 1).clamp(0, next.length - 1);
      }
    });
  }

  void _removeChipAt(int index) {
    final next = [...widget.chips]..removeAt(index);
    widget.onChanged(next);
    setState(() {
      _selectedChipIndex = null;
    });
  }

  void _addChipFromPerson(
    RecipientPersonSuggestion person, {
    required RecipientEndpoint endpoint,
    required bool autoSelectedPreferred,
  }) {
    final chip = RecipientChip(
      displayName: person.displayName,
      endpoint: endpoint,
      source: person.source,
      sourceContactId: person.contactId,
      sourceIdentityKey: person.identityKeys.isEmpty
          ? null
          : person.identityKeys.first,
      autoSelectedPreferred: autoSelectedPreferred,
    );
    _addChip(chip);
  }

  void _addRawEmailChip(String value) {
    final normalized = value.trim().toLowerCase();
    if (!RecipientEmailValidator.isValid(normalized)) return;

    final chip = RecipientChip(
      displayName: normalized,
      endpoint: RecipientEndpoint(
        kind: RecipientEndpointKind.email,
        value: normalized,
        label: RecipientEndpointLabel.other,
      ),
      source: RecipientChipSource.manual,
      autoSelectedPreferred: false,
    );
    _addChip(chip);
  }

  void _addChip(RecipientChip chip) {
    final exists = widget.chips.any(
      (existing) => existing.dedupeKey == chip.dedupeKey,
    );
    if (exists) {
      _inputController.clear();
      return;
    }

    widget.onChanged([...widget.chips, chip]);
    _inputController.clear();
    setState(() {
      _suggestions = const [];
      _endpointPickerPersonIndex = null;
      _highlightedIndex = 0;
      _selectedChipIndex = null;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFocused = widget.focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isFocused
            ? colorScheme.primary.withValues(alpha: 0.07)
            : Colors.transparent,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${widget.label}:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isFocused
                          ? colorScheme.primary
                          : colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Focus(
                  focusNode: widget.focusNode,
                  onKeyEvent: _onKeyEvent,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...List.generate(widget.chips.length, (index) {
                        final chip = widget.chips[index];
                        final selected = _selectedChipIndex == index;
                        return InputChip(
                          selected: selected,
                          label: Text(
                            '${chip.displayName} (${chip.endpoint.badgeText})',
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedChipIndex = index;
                            });
                          },
                          onDeleted: () => _removeChipAt(index),
                        );
                      }),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 140,
                          maxWidth: 280,
                        ),
                        child: IntrinsicWidth(
                          child: TextField(
                            controller: _inputController,
                            autofocus: widget.autofocus,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: 'Type a name or email',
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showSuggestionPanel)
            Padding(
              padding: const EdgeInsets.only(left: 56, top: 8),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                color: colorScheme.surface,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: _buildSuggestionList(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionList(BuildContext context) {
    if (_loading && !_isEndpointPickerOpen) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Searching...'),
          ],
        ),
      );
    }

    if (_isEndpointPickerOpen) {
      return _buildEndpointPickerList();
    }

    final total = _mainSuggestionCount;
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return _buildMainSuggestionList(total);
  }

  Widget _buildEndpointPickerList() {
    final person = _suggestions[_endpointPickerPersonIndex!];

    return ListView.builder(
      shrinkWrap: true,
      itemCount: person.endpoints.length,
      itemBuilder: (context, index) => _buildEndpointPickerRow(person, index),
    );
  }

  Widget _buildEndpointPickerRow(RecipientPersonSuggestion person, int index) {
    final endpoint = person.endpoints[index];
    final highlighted = index == _endpointPickerEndpointIndex;

    return ListTile(
      dense: true,
      selected: highlighted,
      leading: Icon(
        endpoint.kind == RecipientEndpointKind.smartschool
            ? Icons.school_outlined
            : Icons.alternate_email,
        size: 18,
      ),
      title: Text(endpoint.value),
      trailing: _Badge(text: endpoint.badgeText),
      onTap: () {
        _addChipFromPerson(
          person,
          endpoint: endpoint,
          autoSelectedPreferred: false,
        );
      },
    );
  }

  Widget _buildMainSuggestionList(int total) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: total,
      itemBuilder: (context, index) {
        if (index < _suggestions.length) {
          return _buildPersonSuggestionRow(index);
        }
        return _buildRawEmailSuggestionRow(index);
      },
    );
  }

  Widget _buildPersonSuggestionRow(int index) {
    final person = _suggestions[index];
    final highlighted = index == _highlightedIndex;
    final endpointSummary = person.endpoints
        .take(3)
        .map((endpoint) => endpoint.badgeText)
        .join(' , ');

    return ListTile(
      dense: true,
      selected: highlighted,
      title: Text(person.displayName),
      subtitle: endpointSummary.isEmpty ? null : Text(endpointSummary),
      trailing: person.requiresDisambiguation
          ? const Icon(Icons.chevron_right, size: 18)
          : _Badge(text: person.preferredEndpoint.badgeText),
      onTap: () {
        if (person.requiresDisambiguation) {
          _openEndpointPickerForIndex(index);
        } else {
          _addChipFromPerson(
            person,
            endpoint: person.preferredEndpoint,
            autoSelectedPreferred: true,
          );
        }
      },
    );
  }

  Widget _buildRawEmailSuggestionRow(int index) {
    final value = _inputController.text.trim();

    return ListTile(
      dense: true,
      selected: index == _highlightedIndex,
      leading: const Icon(Icons.alternate_email, size: 18),
      title: Text('Use "$value"'),
      subtitle: const Text('Direct email recipient'),
      onTap: () => _addRawEmailChip(value),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
