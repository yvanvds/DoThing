import 'package:do_thing/database/app_database.dart';
import 'package:do_thing/database/repositories/ai_chat_repository.dart';
import 'package:do_thing/models/ai/ai_chat_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiChatRepository', () {
    group('deleteEmptyConversations', () {
      test('deletes all conversations when none have messages', () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = AiChatRepository(db);

        await repo.createConversation(title: 'Empty A');
        await repo.createConversation(title: 'Empty B');

        await repo.deleteEmptyConversations();

        final remaining = await repo.listConversations();
        expect(remaining, isEmpty);
      });

      test('keeps conversations that have messages', () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = AiChatRepository(db);

        final idWithMessages = await repo.createConversation(title: 'Has msg');
        final idEmpty = await repo.createConversation(title: 'No msg');

        await repo.upsertMessage(
          AiChatMessageModel(
            id: 'msg-1',
            conversationId: idWithMessages,
            role: AiMessageRole.user,
            content: 'Hello',
            createdAt: DateTime.now(),
            status: AiMessageStatus.completed,
          ),
        );

        await repo.deleteEmptyConversations();

        final remaining = await repo.listConversations();
        expect(remaining, hasLength(1));
        expect(remaining.single.id, idWithMessages);

        final deleted = await repo.listConversations();
        expect(deleted.any((c) => c.id == idEmpty), isFalse);
      });

      test('does nothing when all conversations have messages', () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = AiChatRepository(db);

        final id1 = await repo.createConversation(title: 'Conv 1');
        final id2 = await repo.createConversation(title: 'Conv 2');

        for (final entry in [(id1, 'msg-a'), (id2, 'msg-b')]) {
          await repo.upsertMessage(
            AiChatMessageModel(
              id: entry.$2,
              conversationId: entry.$1,
              role: AiMessageRole.user,
              content: 'Hi',
              createdAt: DateTime.now(),
              status: AiMessageStatus.completed,
            ),
          );
        }

        await repo.deleteEmptyConversations();

        final remaining = await repo.listConversations();
        expect(remaining, hasLength(2));
      });
    });

    group('updateConversationTitle', () {
      test('updates title in the database', () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = AiChatRepository(db);

        final id = await repo.createConversation();
        await repo.updateConversationTitle(id, 'My new title');

        final conversations = await repo.listConversations();
        expect(conversations.single.title, 'My new title');
      });
    });
  });
}
