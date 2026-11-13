import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../app/app.dart';
import '../../../app/design.dart';
import '../../../core/database/database.dart';
import '../../../core/platform/android_gateway.dart';
import '../../floating_lookup/lookup_page.dart';
import '../data/repository.dart';
import '../search/selection.dart';

bool hasJapanese(String text) =>
    RegExp(r'[\u3040-\u30ff\u3400-\u9fff]').hasMatch(text);

void exploreText(BuildContext context, String text) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => LookupPage(text: text)));
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {this.caption, super.key});
  final String title;
  final String? caption;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (caption != null)
          Text(
            caption!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    ),
  );
}

class SentenceWords extends ConsumerStatefulWidget {
  const SentenceWords({required this.text, required this.onChoose, super.key});
  final String text;
  final ValueChanged<String> onChoose;
  @override
  ConsumerState<SentenceWords> createState() => _SentenceWordsState();
}

class _SentenceWordsState extends ConsumerState<SentenceWords> {
  late Future<List<SentenceToken>> tokens;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    tokens = sentenceTokens(
      widget.text,
      ref.read(repositoryProvider),
      cancelled: () => !mounted,
    );
  }

  @override
  void didUpdateWidget(SentenceWords old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<SentenceToken>>(
    future: tokens,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text(
          'Word suggestions unavailable. Tap a character above to look it up.',
        );
      }
      if (!snapshot.hasData) return const LinearProgressIndicator(minHeight: 2);
      final words = snapshot.data!
          .where((t) => t.known)
          .map((t) => t.text)
          .toSet();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final word in words)
            ActionChip(
              label: Text(
                word,
                style: readingStyle(
                  context,
                  Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              onPressed: () => widget.onChoose(word),
              avatar: const Icon(Icons.north_east, size: 14),
            ),
          if (words.isEmpty)
            const Text('Tap any character to explore a shorter word.'),
          if (widget.text.length > 320)
            const Text('Word suggestions cover the first 320 characters.'),
        ],
      );
    },
  );
}

/// A safe native-widget rendering of structured content. No HTML, network or scripts.
class DictionaryContent extends StatelessWidget {
  const DictionaryContent(this.value, {super.key, this.depth = 0});
  final dynamic value;
  final int depth;
  Widget child(dynamic v) => DictionaryContent(v, depth: depth + 1);
  @override
  Widget build(BuildContext context) {
    if (depth > 32) return const Text('Content nesting limit reached.');
    if (value is String) {
      final text = value as String;
      if (text.isEmpty) return const SizedBox.shrink();
      if (!hasJapanese(text)) {
        return SelectableText(
          text,
          style: readingStyle(context, Theme.of(context).textTheme.bodyLarge),
        );
      }
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => exploreText(context, text),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            text,
            style: readingStyle(context, Theme.of(context).textTheme.bodyLarge)
                .copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: Theme.of(context).colorScheme.primary
                      .withValues(alpha: .3),
                ),
          ),
        ),
      );
    }
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final v in value as List) child(v)],
      );
    }
    if (value is! Map) return const SizedBox.shrink();
    final map = value as Map;
    final tag = map['tag'];
    if (tag == 'img' || map['type'] == 'image') {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(Icons.image_outlined, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text('Dictionary image (media rendering unavailable)'),
            ),
          ],
        ),
      );
    }
    if (tag == 'br') return const SizedBox(height: 8);
    final content = map['content'] ?? map['text'];
    if (tag == 'a') {
      final href = map['href'];
      final uri = href is String ? Uri.tryParse(href) : null;
      final query = uri?.queryParameters['query'];
      final label = flatten(content);
      return Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          avatar: const Icon(Icons.north_east, size: 14),
          label: Text(label.isEmpty ? (query ?? 'Reference') : label),
          onPressed: () => exploreText(context, query ?? label),
        ),
      );
    }
    if ((map['data'] as Map?)?['content'] == 'examples') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer
              .withValues(alpha: .25),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IN CONTEXT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            child(content),
          ],
        ),
      );
    }
    if (tag == 'li') {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '•  ',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
            Expanded(child: child(content)),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ['ul', 'ol', 'div', 'p', 'table', 'tr'].contains(tag) ? 4 : 0,
      ),
      child: child(content),
    );
  }
}

String flatten(dynamic value) {
  if (value is String) return value;
  if (value is List) return value.map(flatten).join(' ');
  if (value is Map) return flatten(value['content'] ?? value['text']);
  return '';
}

class WordDetailPage extends ConsumerStatefulWidget {
  const WordDetailPage({required this.result, super.key});
  final WordResult result;
  @override
  ConsumerState<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends ConsumerState<WordDetailPage> {
  bool saved = false;
  late final future = load();
  Future<(Dictionary?, List<EntryExtra>, List<WordResult>)> load() async {
    final repo = ref.read(repositoryProvider);
    final word = widget.result.term;
    final dictionary = await (repo.db.select(
      repo.db.dictionaries,
    )..where((d) => d.id.equals(word.dictionaryId))).getSingleOrNull();
    final expressions = {
      word.expression,
      ...word.expression.runes.map(String.fromCharCode),
    };
    final enabledIds = (await (repo.db.select(
      repo.db.dictionaries,
    )..where((d) => d.enabled.equals(true))).get()).map((d) => d.id);
    final extras =
        await (repo.db.select(repo.db.entryExtras)
              ..where((e) => e.dictionaryId.isIn(enabledIds))
              ..where((e) => e.expression.isIn(expressions)))
            .get();
    final related = await repo.search(word.expression);
    return (
      dictionary,
      extras,
      related.where((r) => r.term.id != word.id).take(12).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final word = result.term;
    final colors = Theme.of(context).colorScheme;
    final raw = word.rawEntry.isEmpty
        ? null
        : jsonDecode(word.rawEntry) as List;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word explorer'),
        actions: [
          IconButton(
            tooltip: 'Copy expression',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: word.expression)),
          ),
          IconButton(
            tooltip: saved ? 'Word saved' : 'Save word',
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_add_outlined),
            onPressed: () async {
              try {
                await ref.read(repositoryProvider).save(result);
                if (mounted) setState(() => saved = true);
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<(Dictionary?, List<EntryExtra>, List<WordResult>)>(
        future: future,
        builder: (context, snapshot) {
          final dictionary = snapshot.data?.$1;
          final meta = dictionary == null
              ? <String, dynamic>{}
              : jsonDecode(dictionary.metadata) as Map<String, dynamic>;
          final tagInfo = meta['yomipeekTags'] as Map? ?? {};
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ことば  /  WORD',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.primary, letterSpacing: 2),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      word.expression,
                      style: readingStyle(
                        context,
                        Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontSize: 40),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            word.reading,
                            style: readingStyle(
                              context,
                              Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: colors.primary),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Speak Japanese',
                          icon: const Icon(Icons.volume_up_outlined),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(androidProvider)
                                  .speak(
                                    word.reading.isEmpty
                                        ? word.expression
                                        : word.reading,
                                  );
                            } catch (e) {
                              if (context.mounted) showError(context, e);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag
                            in word.tags.split(' ').where((t) => t.isNotEmpty))
                          Tooltip(
                            message:
                                (tagInfo[tag] is List
                                        ? (tagInfo[tag] as List)[3]
                                        : tag)
                                    .toString(),
                            child: Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(fontSize: 12),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                    if (result.inflection.isNotEmpty)
                      Text(
                        'Matched via ${result.inflection.join(' → ')}',
                        style: TextStyle(color: colors.primary),
                      ),
                  ],
                ),
              ),
              const SectionHeading(
                'Meanings & usage',
                caption: 'Follow a reference or tap Japanese text to keep exploring.',
              ),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: DictionaryContent(
                    raw == null ? word.definitions : raw[5],
                  ),
                ),
              ),
              if (raw == null)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Reimport this dictionary to unlock its original structured definitions and entry fields. Your saved vocabulary will be kept.',
                  ),
                ),
              const SectionHeading(
                'Explore the writing',
                caption: 'Words and characters open another dictionary search.',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final character
                      in word.expression.runes
                          .map(String.fromCharCode)
                          .where(hasJapanese)
                          .toSet())
                    ActionChip(
                      label: Text(
                        character,
                        style: readingStyle(
                          context,
                          const TextStyle(fontSize: 22),
                        ),
                      ),
                      onPressed: () => openKanji(context, character),
                    ),
                ],
              ),
              for (final extra in snapshot.data?.$2 ?? <EntryExtra>[]) ...[
                SectionHeading(
                  '${extra.expression} · ${extra.mode == 'kanji' ? 'Character' : extra.mode}',
                ),
                ExtraDetails(extra: extra),
              ],
              if (snapshot.hasError)
                const Text(
                  'Additional dictionary details could not be loaded.',
                ),
              if (snapshot.data?.$3.isNotEmpty ?? false) ...[
                const SectionHeading(
                  'Keep exploring',
                  caption: 'Other senses, spellings and nearby entries.',
                ),
                for (final related in snapshot.data!.$3)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      related.term.expression,
                      style: readingStyle(
                        context,
                        Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    subtitle: Text(
                      '${related.term.reading} · ${related.term.definitions}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => WordDetailPage(result: related),
                      ),
                    ),
                  ),
              ],
              const SectionHeading('From your dictionary'),
              Text(
                result.source,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (dictionary != null)
                Text(
                  'Revision ${dictionary.revision}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (raw != null)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Entry fields'),
                  children: [
                    for (final entry in {
                      'Expression': raw[0],
                      'Reading': raw[1],
                      'Definition tags': raw[2],
                      'Inflection rules': raw[3],
                      'Score': raw[4],
                      'Sequence': raw[6],
                      'Term tags': raw[7],
                    }.entries)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.key),
                        subtitle: SelectableText('${entry.value}'),
                      ),
                    for (final tag
                        in word.tags
                            .split(' ')
                            .toSet()
                            .where((t) => tagInfo[t] is List))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(tag),
                        subtitle: Text('${(tagInfo[tag] as List)[3]}'),
                      ),
                    ExpansionTile(
                      title: const Text('Original entry data'),
                      children: [
                        SelectableText(
                          const JsonEncoder.withIndent('  ').convert(raw),
                        ),
                      ],
                    ),
                  ],
                ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Source & attribution'),
                children: [
                  for (final entry in meta.entries.where(
                    (e) => !e.key.startsWith('yomipeek'),
                  ))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.key),
                      subtitle: SelectableText('${entry.value}'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class SentenceStudioPage extends StatefulWidget {
  const SentenceStudioPage({super.key});
  @override
  State<SentenceStudioPage> createState() => _SentenceStudioPageState();
}

class _SentenceStudioPageState extends State<SentenceStudioPage> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const SizedBox(height: 12),
      Text(
        'Read between\nthe words.',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 14),
      Text(
        'A sentence is the start of a small adventure. Tap a word, follow a reference, and find your way back.',
        style: readingStyle(context, Theme.of(context).textTheme.bodyLarge),
      ),
      const SizedBox(height: 28),
      TextField(
        key: const Key('sentence-input'),
        controller: controller,
        minLines: 4,
        maxLines: 8,
        maxLength: 2000,
        decoration: InputDecoration(
          hintText: 'Paste something you want to understand…',
          suffixIcon: IconButton(
            tooltip: 'Paste sentence',
            icon: const Icon(Icons.content_paste_outlined),
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (mounted) {
                controller.text = (data?.text ?? '').runes
                    .take(2000)
                    .map(String.fromCharCode)
                    .join();
              }
            },
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: IconButton.filled(
          tooltip: 'Explore sentence',
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              exploreText(context, controller.text.trim());
            }
          },
        ),
      ),
      const SectionHeading('A small reading ritual'),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.touch_app_outlined),
        title: Text('Start with a sentence'),
        subtitle: Text(
          'Choose any Japanese text from a message, book or example.',
        ),
      ),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.account_tree_outlined),
        title: Text('Follow a word'),
        subtitle: Text(
          'Explore meanings, references, senses and the characters inside it.',
        ),
      ),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.bookmark_outline),
        title: Text('Keep what matters'),
        subtitle: Text(
          'Save a discovery to your vocabulary. Everything stays on your device.',
        ),
      ),
    ],
  );
}

void openKanji(BuildContext context, String character) => Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => KanjiExplorerPage(character: character),
  ),
);

class ExtraDetails extends StatelessWidget {
  const ExtraDetails({required this.extra, super.key});
  final EntryExtra extra;
  @override
  Widget build(BuildContext context) {
    final row = jsonDecode(extra.payload) as List;
    final data = row.last;
    final fields = <String, dynamic>{};
    final additional = <String, dynamic>{};
    if (extra.mode == 'kanji') {
      fields.addAll({
        'On readings': row[1],
        'Kun readings': row[2],
        'Meanings': (row[4] as List).join(' · '),
      });
      const labels = {
        'strokes': 'Stroke count',
        'grade': 'School grade',
        'jlpt': 'JLPT level (source)',
        'freq': 'Frequency rank',
      };
      if (data is Map) {
        for (final key in labels.keys) {
          if (data.containsKey(key)) fields[labels[key]!] = data[key];
        }
        additional.addAll({
          'Tags': row[3],
          ...data.map((key, value) => MapEntry(key.toString(), value)),
        });
      }
    } else if (data is Map) {
      const labels = {
        'reading': 'Reading',
        'frequency': 'Frequency',
        'pitches': 'Pitch patterns',
      };
      fields.addAll(
        data.map(
          (key, value) => MapEntry(labels[key] ?? key.toString(), value),
        ),
      );
    } else {
      fields[extra.mode] = data;
    }
    Widget field(String title, dynamic value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 3),
          SelectableText(
            value is String || value is num
                ? '$value'
                : const JsonEncoder.withIndent('  ').convert(value),
            style: readingStyle(context, Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in fields.entries)
              if ('${entry.value}'.isNotEmpty) field(entry.key, entry.value),
            if (additional.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('More dictionary fields'),
                children: [
                  for (final entry in additional.entries)
                    field(entry.key, entry.value),
                ],
              ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Original metadata'),
              children: [
                SelectableText(const JsonEncoder.withIndent('  ').convert(row)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class KanjiExplorerPage extends ConsumerStatefulWidget {
  const KanjiExplorerPage({required this.character, super.key});
  final String character;
  @override
  ConsumerState<KanjiExplorerPage> createState() => _KanjiExplorerPageState();
}

class _KanjiExplorerPageState extends ConsumerState<KanjiExplorerPage> {
  late final details = load();
  Future<List<(EntryExtra, Dictionary)>> load() async {
    final db = ref.read(repositoryProvider).db;
    final dictionaries = await (db.select(
      db.dictionaries,
    )..where((d) => d.enabled.equals(true))).get();
    final rows =
        await (db.select(db.entryExtras)
              ..where((e) => e.expression.equals(widget.character))
              ..where((e) => e.mode.equals('kanji')))
            .get();
    return [
      for (final row in rows)
        for (final d in dictionaries)
          if (row.dictionaryId == d.id) (row, d),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Character explorer')),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: .5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              widget.character,
              style: readingStyle(context, const TextStyle(fontSize: 88)),
            ),
          ),
        ),
        const SectionHeading('Readings & meaning'),
        FutureBuilder<List<(EntryExtra, Dictionary)>>(
          future: details,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Character details could not be loaded.');
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            if (snapshot.data!.isEmpty) {
              return const Text(
                'No character entry in your enabled dictionaries. Import a KANJIDIC-compatible Yomitan dictionary for readings and character details.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final row in snapshot.data!) ...[
                  ExtraDetails(extra: row.$1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      row.$2.title,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SectionHeading('Find it in a word'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Words beginning with ${widget.character}'),
          trailing: const Icon(Icons.north_east),
          onTap: () => exploreText(context, widget.character),
        ),
      ],
    ),
  );
}
