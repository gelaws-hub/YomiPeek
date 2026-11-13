import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:yomipeek/core/database/database.dart';
import 'package:yomipeek/features/dictionary/data/repository.dart';
import 'package:yomipeek/features/dictionary/import/importer.dart';
import 'package:yomipeek/features/dictionary/search/japanese.dart';

import 'fixture.dart';

import 'package:yomipeek/features/dictionary/search/selection.dart';

void main() {
  late Directory temp;
  late DictionaryDb db;
  late UserDb user;
  late DictionaryRepository repo;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('yomipeek-test');
    db = DictionaryDb(NativeDatabase.memory());
    user = UserDb(NativeDatabase.memory());
    repo = DictionaryRepository(db, user);
  });
  tearDown(() async {
    await db.close();
    await user.close();
    await temp.delete(recursive: true);
  });
  test('normalization handles half width, full width, dakuten and kana', () {
    expect(normalize(' ﾀﾍﾞﾙ '), 'たべる');
    expect(normalize('ＡＢＣ'), 'abc');
  });
  test('bounded deinflection covers common conjugations', () {
    for (final pair in [
      ('食べました', '食べる'),
      ('食べた', '食べる'),
      ('行かなかった', '行く'),
      ('読んでいる', '読む'),
      ('高かった', '高い'),
      ('しました', 'する'),
      ('来た', '来る'),
      ('来ました', '来る'),
      ('きました', 'くる'),
      ('しませんでした', 'する'),
      ('している', 'する'),
      ('話している', '話す'),
      ('食べませんでした', '食べる'),
      ('高くなかった', '高い'),
    ]) {
      expect(deinflect(pair.$1).map((v) => v.word), contains(pair.$2));
    }
    expect(deinflect('た' * 200).length, lessThanOrEqualTo(128));
  });
  test(
    'import, normalization, prefix, FTS and validated inflections',
    () async {
      final file = await fixture(temp);
      await importDictionary(file.path, db);
      for (final query in [
        '食べる',
        'ﾀﾍﾞﾙ',
        '食',
        'meal',
        '食べました',
        '食べた',
        '行かなかった',
        '読んでいる',
        '高かった',
        'しました',
        '来た',
      ]) {
        expect(await repo.search(query), isNotEmpty, reason: query);
      }
      expect(
        (await repo.search('食べました')).first.inflection,
        contains('polite past'),
      );
      expect(
        (await repo.search('arrival')).first.term.definitions,
        'synthetic arrival',
      );
      expect(await repo.search('" OR *'), isEmpty);
      final d = (await db.select(db.dictionaries).get()).single;
      await (db.update(db.dictionaries)..where((t) => t.id.equals(d.id))).write(
        const DictionariesCompanion(enabled: drift.Value(false)),
      );
      expect(await repo.search('食べる'), isEmpty);
    },
  );
  test('duplicate, failed update, cancellation and unsafe paths preserve active data', () async {
    final f = await fixture(temp);
    await importDictionary(f.path, db);
    await expectLater(
      importDictionary(f.path, db),
      throwsA(isA<ImportFailure>()),
    );
    final bad = await fixture(temp, revision: '2', malformed: true);
    await expectLater(
      importDictionary(bad.path, db),
      throwsA(isA<ImportFailure>()),
    );
    expect((await repo.search('meal')).length, 1);
    final control = ImportControl();
    final update = await fixture(temp, revision: '3', copies: 100);
    await expectLater(
      importDictionary(
        update.path,
        db,
        control: control,
        progress: (p) {
          if (p.contains('entries imported')) control.cancelled = true;
        },
      ),
      throwsA(isA<ImportCancelled>()),
    );
    expect((await db.select(db.dictionaries).get()).single.revision, '1');
    expect((await repo.search('meal')).length, 1);
    final unsafe = await fixture(temp, revision: '4', unsafe: true);
    await expectLater(
      importDictionary(unsafe.path, db),
      throwsA(isA<ImportFailure>()),
    );
  });
  test('successful replacement preserves settings and leaves a consistent FTS index', () async {
    await importDictionary((await fixture(temp)).path, db);
    final old = (await db.select(db.dictionaries).get()).single;
    await (db.update(db.dictionaries)..where((d) => d.id.equals(old.id))).write(
      const DictionariesCompanion(
        priority: drift.Value(5),
        enabled: drift.Value(false),
      ),
    );
    await importDictionary((await fixture(temp, revision: 'new')).path, db);
    final replaced = (await db.select(db.dictionaries).get()).single;
    expect(replaced.revision, 'new');
    expect(replaced.priority, 5);
    expect(replaced.enabled, false);
    expect(await db.select(db.terms).get(), hasLength(6));
    await (db.update(db.dictionaries)..where((d) => d.id.equals(replaced.id)))
        .write(const DictionariesCompanion(enabled: drift.Value(true)));
    expect(await repo.search('meal'), hasLength(1));
  });

  test(
    'multiple dictionaries rank by priority and delete independently',
    () async {
      await importDictionary((await fixture(temp)).path, db);
      await importDictionary(
        (await fixture(temp, title: 'Second synthetic source')).path,
        db,
      );
      final second = (await db.select(db.dictionaries).get()).last;
      await (db.update(db.dictionaries)..where((d) => d.id.equals(second.id)))
          .write(const DictionariesCompanion(priority: drift.Value(7)));
      expect((await repo.search('meal')).map((w) => w.source), [
        'Second synthetic source',
        'YomiPeek synthetic test',
      ]);
      await (db.delete(
        db.dictionaries,
      )..where((d) => d.id.equals(second.id))).go();
      expect(
        (await repo.search('meal')).single.source,
        'YomiPeek synthetic test',
      );
    },
  );
  test('unsupported schemas and excessive declared expansion are rejected before decoding', () async {
    await expectLater(
      importDictionary((await fixture(temp, format: 2)).path, db),
      throwsA(isA<ImportFailure>()),
    );
    final file = await fixture(temp);
    final bytes = await file.readAsBytes();
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i < bytes.length - 28; i++) {
      if (data.getUint32(i, Endian.little) == 0x02014b50) {
        data.setUint32(i + 24, 64 * 1024 * 1024, Endian.little);
        break;
      }
    }
    await file.writeAsBytes(bytes);
    await expectLater(
      importDictionary(file.path, db),
      throwsA(isA<ImportFailure>()),
    );
    expect(await db.select(db.dictionaries).get(), isEmpty);
  });
  test('inflected matches require matching dictionary rule classes', () async {
    await importDictionary((await fixture(temp)).path, db);
    await db
        .update(db.terms)
        .write(const TermsCompanion(rules: drift.Value('n')));
    expect(await repo.search('食べました'), isEmpty);
    expect(await repo.search('食べる'), isNotEmpty);
  });

  test(
    'selected sentence lookup chooses bounded valid dictionary forms',
    () async {
      await importDictionary((await fixture(temp)).path, db);
      expect(await wordAt('食べました。読んでいる。', 0, repo), '食べました');
      expect(await wordAt('食べました。読んでいる。', 6, repo), '読んでいる');
      expect(await wordAt('  高かった。', 0, repo), '高かった');
      expect(await wordAt('', 0, repo), '');
      expect(await wordAt('食べる', 99, repo), '');
      expect(await wordAt('。', 0, repo), '');
      expect(await wordAt('😀食べる', 1, repo), '😀');
    },
  );

  test('bookmarks, history and schemas persist after reopening; deletion preserves user data', () async {
    await db.close();
    await user.close();
    final df = File('${temp.path}/dictionary.sqlite');
    final uf = File('${temp.path}/user.sqlite');
    db = DictionaryDb.file(df);
    user = UserDb.file(uf);
    repo = DictionaryRepository(db, user);
    await importDictionary((await fixture(temp)).path, db);
    final word = (await repo.search('食べる')).first;
    await repo.save(word);
    await repo.save(word);
    await repo.remember('食べる');
    await db.close();
    await user.close();
    db = DictionaryDb.file(df);
    user = UserDb.file(uf);
    repo = DictionaryRepository(db, user);
    expect(await repo.search('meal'), hasLength(1));
    expect(await user.select(user.savedWords).get(), hasLength(1));
    expect(await user.select(user.history).get(), hasLength(1));
    await db.delete(db.dictionaries).go();
    expect(await repo.search('meal'), isEmpty);
    expect(await user.select(user.savedWords).get(), hasLength(1));
    expect(await db.select(db.terms).get(), isEmpty);
    expect(
      await db
          .customSelect('PRAGMA integrity_check')
          .getSingle()
          .then((r) => r.data.values.first),
      'ok',
    );
  });
}
