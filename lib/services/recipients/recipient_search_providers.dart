import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import 'local_recipient_candidate_provider.dart';
import 'office365_recipient_candidate_provider.dart';
import 'recipient_candidate_provider.dart';
import 'recipient_search_service.dart';
import 'smartschool_recipient_candidate_provider.dart';

final localRecipientCandidateProvider = Provider<RecipientCandidateProvider>(
  (ref) => LocalRecipientCandidateProvider(ref.watch(appDatabaseProvider)),
);

final smartschoolRecipientCandidateProvider =
    Provider<RecipientCandidateProvider>(
      (ref) => SmartschoolRecipientCandidateProvider(),
    );

final office365RecipientCandidateProvider =
    Provider<RecipientCandidateProvider>(
      (ref) => Office365RecipientCandidateProvider(),
    );

final recipientSearchServiceProvider = Provider<RecipientSearchService>((ref) {
  return RecipientSearchService(
    providers: [
      ref.watch(localRecipientCandidateProvider),
      ref.watch(smartschoolRecipientCandidateProvider),
      ref.watch(office365RecipientCandidateProvider),
    ],
  );
});
