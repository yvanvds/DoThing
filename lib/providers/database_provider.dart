import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/repositories/ai_chat_repository.dart';
import '../database/repositories/smartschool_sync_repository.dart';

export '../database/app_database.dart';
export '../database/repositories/ai_chat_repository.dart';
export '../database/repositories/smartschool_sync_repository.dart';

/// The single shared [AppDatabase] instance for the lifetime of the app.
///
/// Initialized during app startup via [ProviderScope] overrides:
///
/// ```dart
/// final db = await AppDatabase.openInAppSupport();
/// runApp(ProviderScope(
///   overrides: [appDatabaseProvider.overrideWithValue(db)],
///   child: const MyApp(),
/// ));
/// ```
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('AppDatabase must be provided at startup'),
);

/// Provides a [SmartschoolSyncRepository] backed by the shared database.
final smartschoolSyncRepositoryProvider = Provider<SmartschoolSyncRepository>(
  (ref) => SmartschoolSyncRepository(ref.watch(appDatabaseProvider)),
);

final aiChatRepositoryProvider = Provider<AiChatRepository>(
  (ref) => AiChatRepository(ref.watch(appDatabaseProvider)),
);

/// Stream provider for inbox messages from the local database.
final inboxMessagesProvider = StreamProvider<List<Message>>(
  (ref) => ref.watch(smartschoolSyncRepositoryProvider).watchInbox(),
);

/// Stream provider for the unread inbox count from the local database.
final localUnreadCountProvider = StreamProvider<int>(
  (ref) => ref.watch(smartschoolSyncRepositoryProvider).watchUnreadCount(),
);
