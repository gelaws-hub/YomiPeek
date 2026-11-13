// Validates a user-supplied archive without bundling or downloading dictionary data.
import 'dart:io';

import 'package:yomipeek/core/database/database.dart';
import 'package:yomipeek/features/dictionary/data/repository.dart';
import 'package:yomipeek/features/dictionary/import/importer.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/validate_dictionary.dart /path/to/dictionary.zip',
    );
    exitCode = 64;
    return;
  }
  final root = await Directory.systemTemp.createTemp(
    'yomipeek-real-validation-',
  );
  final db = DictionaryDb.file(File('${root.path}/dictionary.sqlite'));
  final user = UserDb.file(File('${root.path}/user.sqlite'));
  try {
    final timer = Stopwatch()..start();
    await importDictionary(args.single, db);
    stdout.writeln('Import: ${timer.elapsedMilliseconds} ms');
    final dictionary = await db.select(db.dictionaries).getSingle();
    stdout.writeln('${dictionary.title}: ${dictionary.entries} rows');
    final repo = DictionaryRepository(db, user);
    for (final pair in {
      '食べる': '食べる',
      'たべる': '食べる',
      'ﾀﾍﾞﾙ': '食べる',
      '食べました': '食べる',
      '行かなかった': '行く',
      '読んでいる': '読む',
      '高かった': '高い',
      'eat': '',
    }.entries) {
      final samples = <int>[];
      for (var i = 0; i < 6; i++) {
        final watch = Stopwatch()..start();
        final results = await repo.search(pair.key);
        if (results.isEmpty ||
            (pair.value.isNotEmpty &&
                !results.any((r) => r.term.expression == pair.value)) ||
            (pair.value.isEmpty &&
                !results.every(
                  (r) => r.term.definitions.toLowerCase().contains('eat'),
                ))) {
          throw StateError('${pair.key}: missing expected ${pair.value}');
        }
        if (i > 0) samples.add(watch.elapsedMicroseconds);
      }
      samples.sort();
      stdout.writeln(
        '${pair.key} -> ${pair.value.isEmpty ? 'English matches' : pair.value}: median ${samples[2] / 1000} ms; max ${samples.last / 1000} ms',
      );
    }
    final check = await db.customSelect('PRAGMA integrity_check').getSingle();
    stdout.writeln('SQLite integrity: ${check.data}');
  } finally {
    await db.close();
    await user.close();
    await root.delete(recursive: true);
  }
}
