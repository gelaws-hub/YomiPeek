import 'dart:io';

import 'package:yomipeek/core/database/database.dart';
import 'package:yomipeek/features/dictionary/import/importer.dart';
import 'package:yomipeek/features/dictionary/data/repository.dart';

import '../test/fixture.dart';

Future<void> main() async {
  final temp = await Directory.systemTemp.createTemp('yomipeek-benchmark');
  final db = DictionaryDb.file(File('${temp.path}/dictionary.sqlite'));
  final user = UserDb.file(File('${temp.path}/user.sqlite'));
  try {
    final archive = await fixture(temp, copies: 5000);
    final watch = Stopwatch()..start();
    await importDictionary(archive.path, db);
    watch.stop();
    stdout.writeln(
      'Synthetic 30,000 terms: import ${watch.elapsedMilliseconds} ms',
    );
    final repo = DictionaryRepository(db, user);
    for (final query in ['食べる', '食べました', 'meal', '食']) {
      final samples = <int>[];
      for (var i = 0; i < 21; i++) {
        final timer = Stopwatch()..start();
        await repo.search(query);
        timer.stop();
        if (i > 0) samples.add(timer.elapsedMicroseconds);
      }
      samples.sort();
      stdout.writeln(
        '$query: median ${(samples[10] / 1000).toStringAsFixed(2)} ms; max ${(samples.last / 1000).toStringAsFixed(2)} ms (20 warm queries)',
      );
    }
  } finally {
    await db.close();
    await user.close();
    await temp.delete(recursive: true);
  }
}
