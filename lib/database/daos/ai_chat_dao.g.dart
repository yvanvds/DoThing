// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat_dao.dart';

// ignore_for_file: type=lint
mixin _$AiChatDaoMixin on DatabaseAccessor<AppDatabase> {
  $AiConversationsTable get aiConversations => attachedDatabase.aiConversations;
  $AiChatMessagesTable get aiChatMessages => attachedDatabase.aiChatMessages;
  AiChatDaoManager get managers => AiChatDaoManager(this);
}

class AiChatDaoManager {
  final _$AiChatDaoMixin _db;
  AiChatDaoManager(this._db);
  $$AiConversationsTableTableManager get aiConversations =>
      $$AiConversationsTableTableManager(
        _db.attachedDatabase,
        _db.aiConversations,
      );
  $$AiChatMessagesTableTableManager get aiChatMessages =>
      $$AiChatMessagesTableTableManager(
        _db.attachedDatabase,
        _db.aiChatMessages,
      );
}
