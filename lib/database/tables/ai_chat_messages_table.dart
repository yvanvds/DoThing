import 'package:drift/drift.dart';

import 'ai_conversations_table.dart';

class AiChatMessages extends Table {
  TextColumn get id => text()();

  TextColumn get conversationId =>
      text().references(AiConversations, #id, onDelete: KeyAction.cascade)();

  TextColumn get role => text()();

  TextColumn get content => text().withDefault(const Constant(''))();

  TextColumn get status => text().withDefault(const Constant('completed'))();

  TextColumn get errorCode => text().nullable()();

  TextColumn get errorMessage => text().nullable()();

  TextColumn get providerMessageId => text().nullable()();

  TextColumn get parentMessageId => text().nullable()();

  TextColumn get contextKind => text().nullable()();

  TextColumn get contextReferenceId => text().nullable()();

  TextColumn get contextSummary => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
