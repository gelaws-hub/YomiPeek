import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:yomipeek/core/database/database.dart';
import 'package:yomipeek/features/dictionary/data/repository.dart';
import 'package:yomipeek/features/dictionary/import/importer.dart';
import 'package:yomipeek/features/dictionary/search/selection.dart';

import 'fixture.dart';

void main() {
  test('rich import retains original fields, structured examples, tags and auxiliary metadata', () async {
    final temp = await Directory.systemTemp.createTemp('yomipeek-rich');
    final db = DictionaryDb(NativeDatabase.memory());
    final user = UserDb(NativeDatabase.memory());
    try {
      await importDictionary((await fixture(temp, rich: true)).path, db);
      final repo = DictionaryRepository(db, user);
      final food = (await repo.search('食べました')).first;
      final raw = jsonDecode(food.term.rawEntry) as List;
      expect(raw[4], 0);
      expect(raw[6], 1);
      expect(jsonEncode(raw[5]), contains('href'));
      expect(food.term.definitions, contains('食べました。読んでいる。'));
      final meta = jsonDecode(
        (await db.select(db.dictionaries).getSingle()).metadata,
      ) as Map;
      expect(meta['yomipeekTags']['verb'][3], 'An original verb tag');
      expect(
        (await db.select(db.entryExtras).get()).map((e) => e.mode),
        containsAll(['freq', 'pitch', 'kanji']),
      );
      final tokens = await sentenceTokens('食べました。読んでいる。', repo);
      expect(
        tokens.where((t) => t.known).map((t) => t.text),
        containsAll(['食べました', '読んでいる']),
      );
      expect(tokens.map((t) => t.text).join(), '食べました。読んでいる。');
      final mixed = await sentenceTokens('hello 食べました 😀', repo);
      expect(mixed.map((t) => t.text).join(), 'hello 食べました 😀');
      await repo.save(food);
      // A legacy import may be enriched at the same revision without losing settings or bookmarks.
      final dictionary = await db.select(db.dictionaries).getSingle();
      await (db.update(
        db.dictionaries,
      )..where((d) => d.id.equals(dictionary.id))).write(
        const DictionariesCompanion(
          metadata: drift.Value('{}'),
          priority: drift.Value(7),
          enabled: drift.Value(false),
        ),
      );
      await importDictionary((await fixture(temp, rich: true)).path, db);
      final enriched = await db.select(db.dictionaries).getSingle();
      expect(enriched.priority, 7);
      expect(enriched.enabled, false);
      expect(await user.select(user.savedWords).get(), hasLength(1));
      expect(await repo.validCandidates(['食べました']), isEmpty);
      await expectLater(
        importDictionary((await fixture(temp, rich: true)).path, db),
        throwsA(isA<ImportFailure>()),
      );
    } finally {
      await db.close();
      await user.close();
      await temp.delete(recursive: true);
    }
  });
  test(
    'kanji-only archives import and retain readings, meanings and statistics',
    () async {
      final temp = await Directory.systemTemp.createTemp('yomipeek-kanji');
      final db = DictionaryDb(NativeDatabase.memory());
      try {
        await importDictionary(
          (await fixture(temp, rich: true, kanjiOnly: true)).path,
          db,
        );
        expect((await db.select(db.dictionaries).getSingle()).entries, 1);
        final kanji = await (db.select(
          db.entryExtras,
        )..where((e) => e.mode.equals('kanji'))).getSingle();
        expect((jsonDecode(kanji.payload) as List)[1], 'ショク');
        expect((jsonDecode(kanji.payload) as List)[5]['strokes'], '9');
      } finally {
        await db.close();
        await temp.delete(recursive: true);
      }
    },
  );
}
