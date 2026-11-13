import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';

import '../../../core/database/database.dart';
import '../search/japanese.dart';

class ImportCancelled implements Exception {}

class ImportControl {
  bool cancelled = false;
  void check() {
    if (cancelled) throw ImportCancelled();
  }
}

class ImportFailure implements Exception {
  ImportFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

// Never extract archive paths. Bound each decompressed bank and total archive size.
Future<void> importDictionary(
  String path,
  DictionaryDb db, {
  ImportControl? control,
  void Function(String)? progress,
}) async {
  final header = await inspectAsync(path);
  control?.check();
  final metadata = header.$1;
  final title = metadata['title'] as String;
  final revision = metadata['revision'] as String;
  final existing = await (db.select(
    db.dictionaries,
  )..where((d) => d.title.equals(title))).getSingleOrNull();
  if (existing != null &&
      existing.revision == revision &&
      (jsonDecode(existing.metadata) as Map)['yomipeekRichImport'] == true) {
    throw ImportFailure('This dictionary revision is already installed.');
  }
  var count = 0;
  await db.transaction(() async {
    if (existing != null) {
      await (db.delete(
        db.dictionaries,
      )..where((d) => d.id.equals(existing.id))).go();
    }
    final id = await db
        .into(db.dictionaries)
        .insert(
          DictionariesCompanion.insert(
            title: title,
            revision: revision,
            metadata: jsonEncode(metadata),
            entries: 0,
            bytes: header.$3,
            enabled: Value(existing?.enabled ?? true),
            priority: Value(existing?.priority ?? 0),
          ),
        );
    for (final name in header.$2) {
      control?.check();
      progress?.call('Reading $name');
      final rows = await readAsync(path, name);
      for (var start = 0; start < rows.length; start += 500) {
        control?.check();
        final chunk = rows.skip(start).take(500);
        await db.batch((b) {
          b.insertAll(
            db.terms,
            chunk
                .map(
                  (r) => TermsCompanion.insert(
                    dictionaryId: id,
                    expression: r[0],
                    reading: r[1],
                    normalized: normalize(r[0]),
                    normalizedReading: normalize(r[1]),
                    definitions: r[2],
                    tags: r[3],
                    rules: r[4],
                    rawEntry: Value(r[5]),
                  ),
                )
                .toList(),
          );
        });
        count += chunk.length;
        progress?.call('$count entries imported');
      }
    }
    for (final name
        in (metadata['yomipeekExtraBanks'] as List).cast<String>()) {
      control?.check();
      progress?.call('Reading $name');
      final extras = await readExtrasAsync(path, name);
      if (name.startsWith('kanji_bank_')) count += extras.length;
      for (var start = 0; start < extras.length; start += 500) {
        control?.check();
        await db.batch(
          (b) => b.insertAll(
            db.entryExtras,
            extras
                .skip(start)
                .take(500)
                .map(
                  (r) => EntryExtrasCompanion.insert(
                    dictionaryId: id,
                    expression: r[0],
                    mode: r[1],
                    payload: r[2],
                  ),
                )
                .toList(),
          ),
        );
      }
    }
    control?.check();
    if (count == 0) {
      throw ImportFailure('No vocabulary or kanji entries found.');
    }
    await (db.update(db.dictionaries)..where((d) => d.id.equals(id))).write(
      DictionariesCompanion(entries: Value(count)),
    );
  });
}

(Map<String, dynamic>, List<String>, int) inspectArchive(String path) {
  if (File(path).lengthSync() > 512 * 1024 * 1024) {
    throw ImportFailure('ZIP exceeds the 512 MiB compressed limit.');
  }
  final stream = InputFileStream(path);
  try {
    var count = 0;
    var total = 0;
    final names = <String>{};
    for (final file in ZipDirectory().headers(
      stream,
      verify: true,
      files: false,
    )) {
      if (++count > 20000) throw ImportFailure('Too many archive files.');
      if (((file.externalFileAttributes >> 16) & 0xf000) == 0xa000) {
        throw ImportFailure('Symbolic links are not supported.');
      }
      final name = file.filename;
      if (name.startsWith('/') ||
          name.contains('\\') ||
          name.split('/').contains('..') ||
          !names.add(name)) {
        throw ImportFailure('Unsafe or duplicate archive path.');
      }
      total += file.uncompressedSize;
      if (file.uncompressedSize > 32 * 1024 * 1024 ||
          total > 1024 * 1024 * 1024) {
        throw ImportFailure(
          'Archive exceeds safe decompression limits (32 MiB per file, 1 GiB total).',
        );
      }
    }
    final archive = ZipDecoder().decodeStream(stream, verify: true);
    final index = archive.findFile('index.json');
    if (index == null || index.size > 1024 * 1024) {
      throw ImportFailure('Missing or oversized index.json.');
    }
    final meta = jsonDecode(utf8.decode(index.content)) as Map<String, dynamic>;
    if (meta['format'] != 3 && meta['version'] != 3) {
      throw ImportFailure('Only Yomitan format 3 is supported.');
    }
    if (meta['title'] is! String ||
        (meta['title'] as String).trim().isEmpty ||
        meta['revision'] is! String) {
      throw ImportFailure('Invalid dictionary title or revision.');
    }
    final banks =
        names
            .where((n) => RegExp(r'^term_bank_[0-9]+\.json$').hasMatch(n))
            .toList()
          ..sort();
    if (banks.isEmpty &&
        !names.any((n) => RegExp(r'^kanji_bank_[0-9]+\.json$').hasMatch(n))) {
      throw ImportFailure(
        'No vocabulary or kanji banks found. Import a dictionary containing entries.',
      );
    }
    final tags = <String, dynamic>{};
    for (final name in names.where(
      (n) => RegExp(r'^tag_bank_[0-9]+\.json$').hasMatch(n),
    )) {
      final rows =
          jsonDecode(utf8.decode(archive.findFile(name)!.content)) as List;
      for (final row in rows) {
        if (row is List && row.length == 5 && row[0] is String) {
          tags[row[0]] = row;
        }
      }
    }
    meta['yomipeekKind'] = banks.isEmpty ? 'Kanji' : 'Vocabulary';
    meta['yomipeekTags'] = tags;
    meta['yomipeekRichImport'] = true;
    meta['yomipeekExtraBanks'] = names
        .where(
          (n) =>
              RegExp(r'^(term_meta|kanji|kanji_meta)_bank_[0-9]+\.json$')
                  .hasMatch(n),
        )
        .toList();
    return (meta, banks, total);
  } finally {
    stream.closeSync();
  }
}

List<List<String>> readTerms(String path, String bank) {
  final stream = InputFileStream(path);
  try {
    final archive = ZipDecoder().decodeStream(stream, verify: true);
    final file = archive.findFile(bank)!;
    final rows = jsonDecode(utf8.decode(file.content)) as List;
    return rows.map((raw) {
      if (raw is! List ||
          raw.length != 8 ||
          raw[0] is! String ||
          raw[1] is! String ||
          raw[2] is! String ||
          raw[3] is! String ||
          raw[4] is! num ||
          raw[5] is! List ||
          raw[6] is! int ||
          raw[7] is! String) {
        throw ImportFailure('Invalid term row in $bank.');
      }
      final definitions = (raw[5] as List)
          .map(plainText)
          .where((s) => s.isNotEmpty)
          .join('\n');
      return [
        raw[0] as String,
        raw[1] as String,
        definitions,
        '${raw[2]} ${raw[7]}'.trim(),
        raw[3] as String,
        jsonEncode(raw),
      ];
    }).toList();
  } finally {
    stream.closeSync();
  }
}

String plainText(dynamic value) {
  if (value is String) return value;
  if (value is List) {
    return value.map(plainText).where((s) => s.isNotEmpty).join('\n');
  }
  if (value is Map) {
    if (value['tag'] == 'img' || value['type'] == 'image') {
      return '[Image omitted]';
    }
    if (value.containsKey('content')) return plainText(value['content']);
    if (value.containsKey('text')) return plainText(value['text']);
  }
  return '';
}

Future<(Map<String, dynamic>, List<String>, int)> inspectAsync(String path) =>
    Isolate.run(() => inspectArchive(path));
Future<List<List<String>>> readAsync(String path, String name) =>
    Isolate.run(() => readTerms(path, name));

List<List<String>> readExtras(String path, String bank) {
  final stream = InputFileStream(path);
  try {
    final archive = ZipDecoder().decodeStream(stream, verify: true);
    final rows =
        jsonDecode(utf8.decode(archive.findFile(bank)!.content)) as List;
    return rows.map((raw) {
      if (raw is! List || raw.isEmpty || raw[0] is! String) {
        throw ImportFailure('Invalid metadata row in $bank.');
      }
      final kanji = bank.startsWith('kanji_bank_');
      if (kanji ? raw.length != 6 : raw.length != 3 || raw[1] is! String) {
        throw ImportFailure('Invalid metadata row in $bank.');
      }
      if (kanji &&
          (raw[1] is! String ||
              raw[2] is! String ||
              raw[3] is! String ||
              raw[4] is! List ||
              raw[5] is! Map)) {
        throw ImportFailure('Invalid kanji row in $bank.');
      }
      return [
        raw[0] as String,
        kanji ? 'kanji' : raw[1] as String,
        jsonEncode(raw),
      ];
    }).toList();
  } finally {
    stream.closeSync();
  }
}

Future<List<List<String>>> readExtrasAsync(String path, String name) =>
    Isolate.run(() => readExtras(path, name));
