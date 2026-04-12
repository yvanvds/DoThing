import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/composer_controller.dart';

/// Header fields for the message composer: To, CC, BCC, Subject.
///
/// Each field has its own [FocusNode] so the row can highlight when active.
/// Tab traversal flows To → CC → BCC → Subject → editor body naturally.
class ComposerHeader extends ConsumerStatefulWidget {
  const ComposerHeader({super.key});

  @override
  ConsumerState<ComposerHeader> createState() => _ComposerHeaderState();
}

class _ComposerHeaderState extends ConsumerState<ComposerHeader> {
  late final TextEditingController _toCtrl;
  late final TextEditingController _ccCtrl;
  late final TextEditingController _bccCtrl;
  late final TextEditingController _subjectCtrl;

  late final FocusNode _toFocus;
  late final FocusNode _ccFocus;
  late final FocusNode _bccFocus;
  late final FocusNode _subjectFocus;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(composerProvider);
    _toCtrl = TextEditingController(text: draft.to.join(', '));
    _ccCtrl = TextEditingController(text: draft.cc.join(', '));
    _bccCtrl = TextEditingController(text: draft.bcc.join(', '));
    _subjectCtrl = TextEditingController(text: draft.subject);

    _toFocus = FocusNode();
    _ccFocus = FocusNode();
    _bccFocus = FocusNode();
    _subjectFocus = FocusNode();

    _toCtrl.addListener(
      () => ref
          .read(composerProvider.notifier)
          .updateTo(_splitAddresses(_toCtrl.text)),
    );
    _ccCtrl.addListener(
      () => ref
          .read(composerProvider.notifier)
          .updateCc(_splitAddresses(_ccCtrl.text)),
    );
    _bccCtrl.addListener(
      () => ref
          .read(composerProvider.notifier)
          .updateBcc(_splitAddresses(_bccCtrl.text)),
    );
    _subjectCtrl.addListener(
      () =>
          ref.read(composerProvider.notifier).updateSubject(_subjectCtrl.text),
    );
  }

  List<String> _splitAddresses(String raw) {
    return raw
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _toCtrl.dispose();
    _ccCtrl.dispose();
    _bccCtrl.dispose();
    _subjectCtrl.dispose();
    _toFocus.dispose();
    _ccFocus.dispose();
    _bccFocus.dispose();
    _subjectFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderField(
          label: 'To',
          controller: _toCtrl,
          focusNode: _toFocus,
          autofocus: true,
        ),
        _HeaderField(label: 'CC', controller: _ccCtrl, focusNode: _ccFocus),
        _HeaderField(label: 'BCC', controller: _bccCtrl, focusNode: _bccFocus),
        _HeaderField(
          label: 'Subject',
          controller: _subjectCtrl,
          focusNode: _subjectFocus,
        ),
      ],
    );
  }
}

class _HeaderField extends StatefulWidget {
  const _HeaderField({
    required this.label,
    required this.controller,
    required this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;

  @override
  State<_HeaderField> createState() => _HeaderFieldState();
}

class _HeaderFieldState extends State<_HeaderField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_HeaderField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isFocused
            ? colorScheme.primary.withValues(alpha: 0.07)
            : Colors.transparent,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '${widget.label}:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isFocused ? colorScheme.primary : colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
