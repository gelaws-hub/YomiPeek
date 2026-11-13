import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

class Dictionaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().unique()();
  TextColumn get revision => text()();
  TextColumn get metadata => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get entries => integer()();
  IntColumn get bytes => integer()();
}

class Terms extends Table {
  TextColumn get rawEntry => text().withDefault(const Constant(''))();
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dictionaryId =>
      integer().references(Dictionaries, #id, onDelete: KeyAction.cascade)();
  TextColumn get expression => text()();
  TextColumn get reading => text()();
  TextColumn get normalized => text()();
  TextColumn get normalizedReading => text()();
  TextColumn get definitions => text()();
  TextColumn get tags => text()();
  TextColumn get rules => text()();
}

class EntryExtras extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dictionaryId =>
      integer().references(Dictionaries, #id, onDelete: KeyAction.cascade)();
  TextColumn get expression => text()();
  TextColumn get mode => text()();
  TextColumn get payload => text()();
}

class SavedWords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get expression => text()();
  TextColumn get reading => text()();
  TextColumn get definitions => text()();
  TextColumn get source => text()();
  DateTimeColumn get created => dateTime().withDefault(currentDateAndTime)();
  @override
  List<Set<Column>> get uniqueKeys => [
    {expression, reading, definitions},
  ];
}

class History extends Table {
  TextColumn get query => text()();
  DateTimeColumn get searched => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {query};
}

class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Dictionaries, Terms, EntryExtras])
class DictionaryDb extends _$DictionaryDb {
  DictionaryDb(super.e);
  factory DictionaryDb.file(File file) =>
      DictionaryDb(NativeDatabase.createInBackground(file));
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(terms, terms.rawEntry);
        await m.createTable(entryExtras);
        await customStatement(
          'CREATE INDEX extras_lookup ON entry_extras(dictionary_id, expression, mode)',
        );
      }
    },
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX extras_lookup ON entry_extras(dictionary_id, expression, mode)',
      );
      await customStatement(
        'CREATE INDEX term_expression ON terms(normalized COLLATE NOCASE)',
      );
      await customStatement(
        'CREATE INDEX term_reading ON terms(normalized_reading COLLATE NOCASE)',
      );
      await customStatement(
        'CREATE VIRTUAL TABLE term_fts USING fts5(definitions, content=terms, content_rowid=id)',
      );
      await customStatement(
        "CREATE TRIGGER terms_ai AFTER INSERT ON terms BEGIN INSERT INTO term_fts(rowid, definitions) VALUES (new.id,new.definitions); END",
      );
      await customStatement(
        "CREATE TRIGGER terms_ad AFTER DELETE ON terms BEGIN INSERT INTO term_fts(term_fts,rowid,definitions) VALUES ('delete',old.id,old.definitions); END",
      );
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys=ON');
      await customStatement('PRAGMA journal_mode=WAL');
      await customStatement('PRAGMA busy_timeout=5000');
    },
  );
}

@DriftDatabase(tables: [SavedWords, History, Preferences])
class UserDb extends _$UserDb {
  UserDb(super.e);
  factory UserDb.file(File file) =>
      UserDb(NativeDatabase.createInBackground(file));
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      await customStatement('PRAGMA journal_mode=WAL');
      await customStatement('PRAGMA busy_timeout=5000');
    },
  );
}
