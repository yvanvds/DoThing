import 'package:drift/drift.dart';

import '../app_database.dart';

part 'sync_state_dao.g.dart';

@DriftAccessor(tables: [SyncState])
class SyncStateDao extends DatabaseAccessor<AppDatabase>
    with _$SyncStateDaoMixin {
  SyncStateDao(super.db);

  Future<SyncStateData?> getState({
    required String source,
    required String scope,
  }) =>
      (select(syncState)
            ..where((t) => t.source.equals(source) & t.scope.equals(scope)))
          .getSingleOrNull();

  /// Record that a sync attempt has started.
  Future<void> markAttempt({
    required String source,
    required String scope,
  }) async {
    await into(syncState).insert(
      SyncStateCompanion.insert(
        source: source,
        scope: scope,
        lastAttemptAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
      onConflict: DoUpdate(
        (old) => SyncStateCompanion(
          lastAttemptAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        target: [syncState.source, syncState.scope],
      ),
    );
  }

  /// Record a successful sync completion.
  Future<void> markSuccess({
    required String source,
    required String scope,
    String? remoteCursor,
    DateTime? highWaterReceivedAt,
    String? highWaterExternalId,
  }) async {
    final now = DateTime.now();
    await into(syncState).insert(
      SyncStateCompanion.insert(
        source: source,
        scope: scope,
        lastAttemptAt: Value(now),
        lastSuccessAt: Value(now),
        remoteCursor: Value(remoteCursor),
        highWaterReceivedAt: Value(highWaterReceivedAt),
        highWaterExternalId: Value(highWaterExternalId),
        failureCount: const Value(0),
        lastError: const Value(null),
        updatedAt: Value(now),
      ),
      onConflict: DoUpdate(
        (old) => SyncStateCompanion(
          lastAttemptAt: Value(now),
          lastSuccessAt: Value(now),
          remoteCursor: Value(remoteCursor),
          highWaterReceivedAt: Value(highWaterReceivedAt),
          highWaterExternalId: Value(highWaterExternalId),
          failureCount: const Value(0),
          lastError: const Value(null),
          updatedAt: Value(now),
        ),
        target: [syncState.source, syncState.scope],
      ),
    );
  }

  /// Record a sync failure.
  Future<void> markFailure({
    required String source,
    required String scope,
    required String error,
  }) async {
    final existing = await getState(source: source, scope: scope);
    final failures = (existing?.failureCount ?? 0) + 1;

    await into(syncState).insert(
      SyncStateCompanion.insert(
        source: source,
        scope: scope,
        lastAttemptAt: Value(DateTime.now()),
        lastError: Value(error),
        failureCount: Value(failures),
        updatedAt: Value(DateTime.now()),
      ),
      onConflict: DoUpdate(
        (old) => SyncStateCompanion(
          lastAttemptAt: Value(DateTime.now()),
          lastError: Value(error),
          failureCount: Value(failures),
          updatedAt: Value(DateTime.now()),
        ),
        target: [syncState.source, syncState.scope],
      ),
    );
  }
}
