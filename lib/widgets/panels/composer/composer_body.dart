import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/composer_controller.dart';

/// Rich text body editor for the message composer.
///
/// Creates a [QuillController] seeded from the current [DraftMessage.body]
/// and syncs changes back to [composerProvider].
class ComposerBody extends ConsumerStatefulWidget {
  const ComposerBody({super.key});

  @override
  ConsumerState<ComposerBody> createState() => _ComposerBodyState();
}

class _ComposerBodyState extends ConsumerState<ComposerBody> {
  late final QuillController _quillController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initialBody = ref.read(composerProvider).body;
    _quillController = QuillController(
      document: Document.fromJson(initialBody),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _quillController.addListener(_onDocumentChanged);
  }

  void _onDocumentChanged() {
    final ops = _quillController.document.toDelta().toJson();
    ref
        .read(composerProvider.notifier)
        .updateBody(List<Map<String, dynamic>>.from(ops));
  }

  @override
  void dispose() {
    _quillController.removeListener(_onDocumentChanged);
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final seedColor = colorScheme.primary;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          // Exclude toolbar from Tab traversal so focus goes directly from
          // Subject → editor body. Toolbar buttons remain fully clickable.
          child: FocusTraversalGroup(
            descendantsAreFocusable: false,
            child: QuillSimpleToolbar(
              controller: _quillController,
              config: const QuillSimpleToolbarConfig(
                showFontFamily: false,
                showFontSize: false,
                showInlineCode: false,
                showCodeBlock: false,
                showSubscript: false,
                showSuperscript: false,
                showSearchButton: false,
                showAlignmentButtons: true,
                // quote, indent, and link are enabled (flutter_quill defaults)
              ),
            ),
          ),
        ),
        // Force a light theme with white background for the editing area so
        // the composed text always appears on white — matching how recipients
        // will typically view the message.
        Expanded(
          child: Theme(
            data: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ),
            ),
            child: ColoredBox(
              color: Colors.white,
              // Explicitly set text color to black so QuillEditor inherits it
              // via DefaultTextStyle regardless of the surrounding app theme.
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.black87, height: 1.5),
                child: QuillEditor.basic(
                  controller: _quillController,
                  focusNode: _focusNode,
                  config: const QuillEditorConfig(
                    padding: EdgeInsets.all(12),
                    expands: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
