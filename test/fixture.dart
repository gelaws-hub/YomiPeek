import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

// Original synthetic entries; no third-party dictionary content.
Future<File> fixture(
  Directory directory, {
  String revision = '1',
  String title = 'YomiPeek synthetic test',
  int format = 3,
  bool malformed = false,
  bool unsafe = false,
  int copies = 1,
}) async {
  final archive = Archive();
  void add(String name, Object content) {
    final bytes = utf8.encode(jsonEncode(content));
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  add('index.json', {
    'format': format,
    'title': title,
    'revision': revision,
    'author': 'YomiPeek tests',
    'description': 'Original test data only',
  });
  final rows = [
    [
      '食べる',
      'たべる',
      'verb',
      'v1',
      0,
      ['synthetic meal action'],
      1,
      '',
    ],
    [
      '行く',
      'いく',
      '',
      'v5',
      0,
      ['synthetic movement'],
      2,
      '',
    ],
    [
      '読む',
      'よむ',
      '',
      'v5',
      0,
      ['synthetic text action'],
      3,
      '',
    ],
    [
      '高い',
      'たかい',
      '',
      'adj-i',
      0,
      ['synthetic height'],
      4,
      '',
    ],
    [
      'する',
      'する',
      '',
      'vs',
      0,
      ['synthetic activity'],
      5,
      '',
    ],
    [
      '来る',
      'くる',
      '',
      'vk',
      0,
      [
        {
          'type': 'structured-content',
          'content': {'tag': 'span', 'content': 'synthetic arrival'},
        },
      ],
      6,
      '',
    ],
  ];
  add(
    'term_bank_1.json',
    malformed
        ? [
            ['bad'],
          ]
        : [for (var i = 0; i < copies; i++) ...rows],
  );
  if (unsafe) add('../escape.json', {});
  final file = File('${directory.path}/fixture-$revision.zip');
  await file.writeAsBytes(ZipEncoder().encode(archive));
  return file;
}
