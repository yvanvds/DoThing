import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/smartschool_inbox_controller.dart';
import '../services/office365/office365_polling_controller.dart';

/// Provides the initial polling completion state.
///
/// Returns true once both Smartschool and Office365 have completed their
/// initial sync/polling operations.
final appInitializationProvider = Provider<bool>((ref) {
  // Trigger SmartSchool inbox initialization by watching it
  // This will cause _fetchInboxHeaders to run
  ref.watch(smartschoolInboxProvider);
  final smartschoolInitialRetrievalDone = ref.watch(
    smartschoolInitialInboxRetrievalDoneProvider,
  );

  // Watch Office365 polling
  final office365Count = ref.watch(office365PollingProvider);

  // Initialization is complete when:
  // 1. SmartSchool has completed initial inbox header retrieval
  // 2. Office365 has completed at least one poll (count > 0)
  final smartschoolReady = smartschoolInitialRetrievalDone;
  final office365Ready = office365Count > 0;

  return smartschoolReady && office365Ready;
});
