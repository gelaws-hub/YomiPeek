import 'dart:io';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/database.dart';
import '../dictionary/data/repository.dart';
import '../dictionary/search/selection.dart';

/// A service-owned headless engine uses the exact same repository as the app.
Future<void> startOverlayBridge() async {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('org.yomipeek/overlay');
  final directory = await getApplicationSupportDirectory();
  final db = DictionaryDb.file(File('${directory.path}/dictionaries.sqlite'));
  final user = UserDb.file(File('${directory.path}/user.sqlite'));
  final repository = DictionaryRepository(db, user);
  channel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'search':
        final query = (call.arguments as String).trim();
        final results = await repository.search(query);
        return results
            .take(30)
            .map(
              (r) => {
                'expression': r.term.expression,
                'reading': r.term.reading,
                'definitions': r.term.definitions,
                'source': r.source,
                'tags': r.term.tags,
                'inflection': r.inflection.join(' → '),
                'parameters': r.term.rawEntry.isEmpty
                    ? r.term.rules
                    : entryParameters(r.term.rawEntry),
                'references': r.term.rawEntry.isEmpty
                    ? <String>[]
                    : entryReferences(jsonDecode(r.term.rawEntry)),
              },
            )
            .toList();
      case 'wordAt':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        return wordAt(
          args['text'] as String,
          args['offset'] as int,
          repository,
        );
      case 'save':
        final word = Map<String, dynamic>.from(call.arguments as Map);
        await user
            .into(user.savedWords)
            .insert(
              SavedWordsCompanion.insert(
                expression: word['expression'] as String,
                reading: word['reading'] as String,
                definitions: word['definitions'] as String,
                source: word['source'] as String,
              ),
              mode: InsertMode.insertOrIgnore,
            );
        return null;
      case 'remember':
        await repository.remember(call.arguments as String);
        return null;
      case 'dispose':
        await db.close();
        await user.close();
        channel.setMethodCallHandler(null);
        return null;
      default:
        throw MissingPluginException();
    }
  });
  await channel.invokeMethod<void>('ready');
}

String entryParameters(String raw) {
  final row = jsonDecode(raw) as List;
  return 'Rules: ${row[3]} · Score: ${row[4]} · Sequence: ${row[6]}';
}

List<String> entryReferences(dynamic node, [int depth = 0]) {
  if (depth > 32) return [];
  if (node is List) {
    return node.expand((v) => entryReferences(v, depth + 1)).toList();
  }
  if (node is Map) {
    final uri = node['href'] is String
        ? Uri.tryParse(node['href'] as String)
        : null;
    return [
      if (uri?.queryParameters['query'] != null) uri!.queryParameters['query']!,
      ...entryReferences(node['content'], depth + 1),
    ];
  }
  return [];
}
