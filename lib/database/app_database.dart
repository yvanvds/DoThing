import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'tables/contacts_table.dart';
import 'tables/contact_identities_table.dart';
import 'tables/messages_table.dart';
import 'tables/message_participants_table.dart';
import 'tables/message_attachments_table.dart';
import 'tables/pending_outgoing_messages_table.dart';
import 'tables/sync_state_table.dart';
import 'tables/ai_conversations_table.dart';
import 'tables/ai_chat_messages_table.dart';
import 'daos/contacts_dao.dart';
import 'daos/messages_dao.dart';
import 'daos/attachments_dao.dart';
import 'daos/pending_outgoing_messages_dao.dart';
import 'daos/sync_state_dao.dart';
import 'daos/search_dao.dart';
import 'daos/ai_chat_dao.dart';

export 'tables/contacts_table.dart';
export 'tables/contact_identities_table.dart';
export 'tables/messages_table.dart';
export 'tables/message_participants_table.dart';
export 'tables/message_attachments_table.dart';
export 'tables/pending_outgoing_messages_table.dart';
export 'tables/sync_state_table.dart';
export 'tables/ai_conversations_table.dart';
export 'tables/ai_chat_messages_table.dart';
export 'daos/contacts_dao.dart';
export 'daos/messages_dao.dart';
export 'daos/attachments_dao.dart';
export 'daos/pending_outgoing_messages_dao.dart';
export 'daos/sync_state_dao.dart';
export 'daos/search_dao.dart';
export 'daos/ai_chat_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Contacts,
    ContactIdentities,
    Messages,
    MessageParticipants,
    MessageAttachments,
    PendingOutgoingMessages,
    SyncState,
    AiConversations,
    AiChatMessages,
  ],
  daos: [
    ContactsDao,
    MessagesDao,
    AttachmentsDao,
    PendingOutgoingMessagesDao,
    SyncStateDao,
    SearchDao,
    AiChatDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _applySchemaV2Prep();
      await _applySchemaV3Prep();
      await _applySchemaV4Prep();
      // Create the FTS5 virtual table for message search.
      // This is a standalone (not external-content) table; all indexing is
      // handled explicitly from SearchDao.
      await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS message_fts USING fts5(
              message_id UNINDEXED,
              subject,
              body_text,
              participant_names,
              attachment_names,
              tokenize = "unicode61"
            )
          ''');
      // Convenience index to speed up join between fts and messages.
      await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_messages_source_external
            ON messages (source, external_id)
          ''');
      await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_messages_mailbox
            ON messages (source, mailbox, is_deleted, is_archived, received_at DESC)
          ''');
      await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_contact_identities_lookup
            ON contact_identities (source, external_id)
          ''');
      await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_message_participants_message
            ON message_participants (message_id, role)
          ''');
      await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_message_attachments_message
            ON message_attachments (message_id)
          ''');
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await _applySchemaV2Prep();
      }
      if (from < 3) {
        await m.createTable(pendingOutgoingMessages);
        await _applySchemaV3Prep();
      }
      if (from < 4) {
        await m.createTable(aiConversations);
        await m.createTable(aiChatMessages);
        await _applySchemaV4Prep();
      }
    },
  );

  Future<void> _applySchemaV2Prep() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS provider_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source TEXT NOT NULL,
        account_key TEXT NOT NULL,
        tenant_id TEXT,
        mailbox TEXT,
        display_name TEXT,
        email TEXT,
        last_authenticated_at INTEGER,
        created_at INTEGER DEFAULT (strftime('%s','now') * 1000),
        updated_at INTEGER DEFAULT (strftime('%s','now') * 1000),
        UNIQUE(source, account_key)
      )
    ''');

    await _tryCustomStatement(
      'ALTER TABLE messages ADD COLUMN account_key TEXT',
    );
    await _tryCustomStatement(
      'ALTER TABLE messages ADD COLUMN conversation_key TEXT',
    );
    await _tryCustomStatement(
      'ALTER TABLE messages ADD COLUMN parent_external_id TEXT',
    );
    await _tryCustomStatement(
      'ALTER TABLE sync_state ADD COLUMN account_key TEXT',
    );

    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_provider_accounts_lookup
      ON provider_accounts (source, account_key)
    ''');

    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_messages_source_account_mailbox
      ON messages (source, account_key, mailbox, received_at DESC)
    ''');

    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_messages_conversation
      ON messages (source, account_key, conversation_key, received_at DESC)
    ''');
  }

  Future<void> _applySchemaV3Prep() async {
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_pending_outgoing_next_attempt
      ON pending_outgoing_messages (next_attempt_at, created_at)
    ''');
  }

  Future<void> _applySchemaV4Prep() async {
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_conversation_created
      ON ai_chat_messages (conversation_id, created_at)
    ''');

    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_status
      ON ai_chat_messages (status, updated_at)
    ''');
  }

  Future<void> _tryCustomStatement(String sql) async {
    try {
      await customStatement(sql);
    } catch (_) {}
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final file = await _resolveDatabaseFile();
      return NativeDatabase.createInBackground(file);
    });
  }

  /// Open the production database.
  ///
  /// Stored in `%APPDATA%/DoThing/do_thing_messages.sqlite` on Windows.
  static AppDatabase openInAppSupport() {
    return AppDatabase(_openConnection());
  }

  static Future<File> _resolveDatabaseFile() async {
    final appData = Platform.environment['APPDATA'];
    final targetDir = Directory(
      appData != null && appData.isNotEmpty
          ? '$appData${Platform.pathSeparator}DoThing'
          : (await getApplicationSupportDirectory()).path,
    );

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final targetFile = File(
      '${targetDir.path}${Platform.pathSeparator}do_thing_messages.sqlite',
    );

    // One-time migration from the old default location in Documents.
    if (!await targetFile.exists()) {
      final docsDir = await getApplicationDocumentsDirectory();
      final oldFile = File(
        '${docsDir.path}${Platform.pathSeparator}do_thing_messages.sqlite',
      );
      if (await oldFile.exists()) {
        await oldFile.copy(targetFile.path);
      }
    }

    return targetFile;
  }
}
