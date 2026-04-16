part of 'chat_view.dart';

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.data, this.tooltip, this.label});

  final String data;
  final String? tooltip;
  final String? label;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}
