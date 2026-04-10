import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Severity level for a status terminal entry.
enum StatusEntryType { info, success, warning, error }

/// A single line in the status terminal.
class StatusEntry {
  const StatusEntry({
    required this.type,
    required this.message,
    required this.timestamp,
  });

  final StatusEntryType type;
  final String message;
  final DateTime timestamp;
}

/// Provides the list of [StatusEntry] items to the status terminal widget.
final statusProvider = NotifierProvider<StatusController, List<StatusEntry>>(
  StatusController.new,
);

/// Manages the status / actions terminal output.
///
/// Commands and services call [add] or [clear] via [statusProvider].
class StatusController extends Notifier<List<StatusEntry>> {
  @override
  List<StatusEntry> build() => [
    StatusEntry(
      type: StatusEntryType.info,
      message: 'Ready.',
      timestamp: DateTime.now(),
    ),
  ];

  /// Append a new entry.
  void add(StatusEntryType type, String message) {
    state = [
      ...state,
      StatusEntry(type: type, message: message, timestamp: DateTime.now()),
    ];
  }

  /// Remove all entries.
  void clear() => state = const [];
}
