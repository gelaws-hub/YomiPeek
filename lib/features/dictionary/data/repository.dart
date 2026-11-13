import 'package:drift/drift.dart';

import '../../../core/database/database.dart';
import '../search/japanese.dart';

class WordResult {
  WordResult(this.term, this.source, this.inflection);
  final Term term;
  final String source;
  final List<String> inflection;
}

class DictionaryRepository {
  DictionaryRepository(this.db, this.user);
  final DictionaryDb db;
  final UserDb user;
  Future<List<WordResult>> search(String input) async {
    final query = normalize(input);
    if (query.isEmpty) return [];
    final variants = deinflect(input);
    final words = variants.map((v) => v.word).toSet().toList();
    final placeholders = List.filled(words.length, '?').join(',');
    final prefix =
        '${query.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%';
    final tokens = RegExp(r'[a-z0-9]+')
        .allMatches(query)
        .map((m) => '"${m[0]}"*')
        .join(' AND ');
    final rows = await db
        .customSelect(
          '''SELECT t.*, d.title AS source,
      CASE WHEN t.normalized COLLATE NOCASE=? OR t.normalized_reading COLLATE NOCASE=? THEN 0
      WHEN t.normalized COLLATE NOCASE IN ($placeholders) OR t.normalized_reading COLLATE NOCASE IN ($placeholders) THEN 1 ELSE 2 END AS rank
      FROM terms t JOIN dictionaries d ON d.id=t.dictionary_id
      WHERE d.enabled=1 AND t.id IN (
      SELECT id FROM terms WHERE normalized COLLATE NOCASE IN ($placeholders)
      UNION SELECT id FROM terms WHERE normalized_reading COLLATE NOCASE IN ($placeholders)
      UNION SELECT id FROM terms WHERE normalized COLLATE NOCASE LIKE ? ESCAPE '\\'
      UNION SELECT id FROM terms WHERE normalized_reading COLLATE NOCASE LIKE ? ESCAPE '\\'
      ${tokens.isEmpty ? '' : 'UNION SELECT rowid FROM term_fts WHERE term_fts MATCH ?'} )
      ORDER BY rank, d.priority DESC, length(t.expression), t.id LIMIT 100''',
          variables: [
            Variable(query),
            Variable(query),
            ...words.map(Variable.new),
            ...words.map(Variable.new),
            ...words.map(Variable.new),
            ...words.map(Variable.new),
            Variable(prefix),
            Variable(prefix),
            if (tokens.isNotEmpty) Variable(tokens),
          ],
        )
        .get();
    final results = <WordResult>[];
    for (final row in rows) {
      final term = db.terms.map(row.data);
      final matches = variants.where(
        (v) =>
            (v.word == term.normalized || v.word == term.normalizedReading) &&
            (v.steps.isEmpty ||
                v.rule.isEmpty ||
                term.rules.split(' ').any((r) => r.startsWith(v.rule))),
      );
      if (row.read<int>('rank') == 1 && matches.isEmpty) continue;
      results.add(
        WordResult(
          term,
          row.read<String>('source'),
          matches.isEmpty ? [] : matches.first.steps,
        ),
      );
    }
    return results;
  }

  Future<Set<String>> validCandidates(List<String> candidates) async {
    final variants = {for (final c in candidates) c: deinflect(c)};
    final roots = variants.values
        .expand((v) => v)
        .map((v) => v.word)
        .toSet()
        .toList();
    final found = <Term>[];
    for (var start = 0; start < roots.length; start += 350) {
      final batch = roots.skip(start).take(350).toList();
      final marks = List.filled(batch.length, '?').join(',');
      if (batch.isEmpty) continue;
      final rows = await db
          .customSelect(
            '''SELECT t.* FROM terms t JOIN dictionaries d ON d.id=t.dictionary_id
        WHERE d.enabled=1 AND t.id IN (SELECT id FROM terms WHERE normalized COLLATE NOCASE IN ($marks)
        UNION SELECT id FROM terms WHERE normalized_reading COLLATE NOCASE IN ($marks))''',
            variables: [...batch.map(Variable.new), ...batch.map(Variable.new)],
          )
          .get();
      found.addAll(rows.map((r) => db.terms.map(r.data)));
    }
    return variants.entries
        .where(
          (e) => e.value.any(
            (v) => found.any(
              (t) =>
                  (t.normalized == v.word || t.normalizedReading == v.word) &&
                  (v.steps.isEmpty ||
                      v.rule.isEmpty ||
                      t.rules.split(' ').any((r) => r.startsWith(v.rule))),
            ),
          ),
        )
        .map((e) => e.key)
        .toSet();
  }

  Future<void> remember(String query) async {
    if (query.trim().isEmpty) return;
    await user
        .into(user.history)
        .insertOnConflictUpdate(
          HistoryCompanion.insert(
            query: query.trim(),
            searched: Value(DateTime.now()),
          ),
        );
    await user.customStatement(
      'DELETE FROM history WHERE query NOT IN (SELECT query FROM history ORDER BY searched DESC LIMIT 50)',
    );
  }

  Future<void> save(WordResult result) => user
      .into(user.savedWords)
      .insert(
        SavedWordsCompanion.insert(
          expression: result.term.expression,
          reading: result.term.reading,
          definitions: result.term.definitions,
          source: result.source,
        ),
        mode: InsertMode.insertOrIgnore,
      );
}
