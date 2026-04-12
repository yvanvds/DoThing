import 'package:drift/drift.dart';

class AiConversations extends Table {
  TextColumn get id => text()();

  TextColumn get title => text().withDefault(const Constant('New chat'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
