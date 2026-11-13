import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';

import '../core/database/database.dart';
import '../core/platform/android_gateway.dart';
import '../features/floating_lookup/lookup_page.dart';
import '../features/floating_lookup/settings_page.dart';
import '../features/dictionary/data/repository.dart';
import '../features/dictionary/import/importer.dart';
import '../features/dictionary/explorer/explorer.dart';
import 'design.dart';
import '../features/appearance/fonts.dart';
import '../features/appearance/font_settings_page.dart';

final repositoryProvider = Provider<DictionaryRepository>(
  (ref) => throw StateError('Repository must be supplied'),
);
final themeProvider = NotifierProvider<ThemeSetting, ThemeMode>(
  ThemeSetting.new,
);

class ThemeSetting extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final repo = ref.read(repositoryProvider);
    (repo.user.select(
      repo.user.preferences,
    )..where((p) => p.key.equals('theme'))).getSingleOrNull().then((p) {
      if (ref.mounted && p != null) {
        state = ThemeMode.values.firstWhere(
          (v) => v.name == p.value,
          orElse: () => ThemeMode.system,
        );
      }
      if (ref.mounted) ref.read(androidProvider).setTheme(state.name);
    });
    return ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref
        .read(repositoryProvider)
        .user
        .into(ref.read(repositoryProvider).user.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(key: 'theme', value: mode.name),
        );
    await ref.read(androidProvider).setTheme(mode.name);
  }
}

class YomiPeekApp extends ConsumerWidget {
  const YomiPeekApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fonts = ref.watch(japaneseFontsProvider);
    return MaterialApp(
      title: 'YomiPeek',
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(themeProvider),
      theme: readingTheme(
        Brightness.light,
        readingFamily: fonts.family,
        readingScale: fonts.scale,
        readingHeight: fonts.lineHeight,
      ),
      darkTheme: readingTheme(
        Brightness.dark,
        readingFamily: fonts.family,
        readingScale: fonts.scale,
        readingHeight: fonts.lineHeight,
      ),
      routes: {
        '/': (_) => const HomePage(),
        '/dictionaries': (_) => const DictionaryManager(),
      },
    );
  }
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error is ImportFailure ? error.message : 'Operation failed. Check the file and available storage, then retry.',
      ),
    ),
  );
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  StreamSubscription<String>? selectionEvents;
  StreamSubscription<void>? nativeChanges;
  @override
  void initState() {
    super.initState();
    final gateway = ref.read(androidProvider);
    selectionEvents = gateway.selections.listen(openSelection);
    nativeChanges = gateway.changes.listen((_) {
      final user = ref.read(repositoryProvider).user;
      user.markTablesUpdated({user.savedWords, user.history});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final text = await gateway.initialSelection();
        if (text != null && mounted) openSelection(text);
      } catch (e) {
        if (mounted) showError(context, e);
      }
    });
  }

  void openSelection(String text) {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LookupPage(text: text),
          settings: const RouteSettings(name: '/lookup'),
        ),
      );
    }
  }

  @override
  void dispose() {
    selectionEvents?.cancel();
    nativeChanges?.cancel();
    super.dispose();
  }

  int index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          'design/logo-final/yomipeek-icon-1024.png',
          semanticLabel: 'YomiPeek logo',
        ),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YomiPeek'),
          Text(
            'A little Japanese, every day.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Manage dictionaries',
          onPressed: () => Navigator.pushNamed(context, '/dictionaries'),
          icon: const Icon(Icons.library_books_outlined),
        ),
      ],
    ),
    body: IndexedStack(
      index: index,
      children: const [
        SearchPage(),
        SentenceStudioPage(),
        VocabularyPage(),
        SettingsPage(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      selectedIndex: index,
      onDestinationSelected: (v) => setState(() => index = v),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.search),
          label: 'Dictionary',
          tooltip: 'Dictionary',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_stories_outlined),
          label: 'Explore',
          tooltip: 'Explore',
        ),
        NavigationDestination(
          icon: Icon(Icons.bookmark_outline),
          label: 'Vocabulary',
          tooltip: 'Vocabulary',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
          tooltip: 'Settings',
        ),
      ],
    ),
  );
}

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final controller = TextEditingController();
  Timer? timer;
  int generation = 0;
  List<WordResult> results = [];
  bool loading = false;
  String? error;
  late final dictionaries = ref
      .read(repositoryProvider)
      .db
      .select(ref.read(repositoryProvider).db.dictionaries)
      .watch();
  late final history =
      (ref
              .read(repositoryProvider)
              .user
              .select(ref.read(repositoryProvider).user.history)
            ..orderBy([(h) => drift.OrderingTerm.desc(h.searched)]))
          .watch();
  StreamSubscription<List<Dictionary>>? dictionaryChanges;
  @override
  void initState() {
    super.initState();
    dictionaryChanges = dictionaries.listen((_) {
      if (mounted && controller.text.isNotEmpty) search(controller.text);
    });
  }

  void search(String value, {bool remember = false}) {
    timer?.cancel();
    final request = ++generation;
    setState(() {
      loading = value.trim().isNotEmpty;
      error = null;
    });
    timer = Timer(Duration(milliseconds: remember ? 0 : 250), () async {
      try {
        final repo = ref.read(repositoryProvider);
        final found = await repo.search(value);
        if (remember) await repo.remember(value);
        if (mounted && request == generation) {
          setState(() {
            results = found;
            loading = false;
          });
        }
      } catch (_) {
        if (mounted && request == generation) {
          setState(() {
            loading = false;
            error = 'Search could not read local storage. Try again.';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    dictionaryChanges?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Dictionary>>(
    stream: dictionaries,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(
          child: Text('Could not read installed dictionaries.'),
        );
      }
      final installed = snapshot.data ?? [];
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find your next word.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Japanese at a glance. A whole world underneath.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.local_florist_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 30,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              key: const Key('search'),
              style: readingStyle(context, const TextStyle(fontSize: 18)),
              controller: controller,
              inputFormatters: [LengthLimitingTextInputFormatter(512)],
              onChanged: search,
              onSubmitted: (v) => search(v, remember: true),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'A word, a meaning, a new discovery…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    controller.clear();
                    search('');
                  },
                  icon: const Icon(Icons.close),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          if (controller.text.runes.length == 1 && hasJapanese(controller.text))
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 8),
                child: ActionChip(
                  label: const Text('Explore character'),
                  avatar: const Icon(Icons.translate, size: 16),
                  onPressed: () => openKanji(context, controller.text),
                ),
              ),
            ),
          Expanded(
            child: installed.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'design/logo-final/yomipeek-icon-1024.png',
                              width: 72,
                              height: 72,
                              semanticLabel: 'YomiPeek logo',
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your Japanese dictionary,\nyour way.',
                              textAlign: TextAlign.center,
                              style: readingStyle(
                                context,
                                Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Japanese at a glance.\n\nNo dictionaries installed. Import a Yomitan-compatible dictionary to get started.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            IconButton.filled(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/dictionaries'),
                              icon: const Icon(Icons.file_upload_outlined),
                              tooltip: 'Import Dictionary ZIP',
                            ),
                            const SizedBox(height: 20),
                            const Text('No account required. Works offline.'),
                          ],
                        ),
                      ),
                    ),
                  )
                : loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(child: Text(error!))
                : controller.text.trim().isEmpty
                ? StreamBuilder<List<HistoryData>>(
                    stream: history,
                    builder: (context, snapshot) => ListView(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: .45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_stories_outlined, size: 30),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Follow your curiosity',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const Text(
                                      'Paste a sentence. Discover its words. Follow where they lead.',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Open sentence explorer',
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const Scaffold(
                                      body: SafeArea(
                                        child: SentenceStudioPage(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const ListTile(
                          title: Text('Your recent discoveries'),
                          subtitle: Text('Pick up where you left off.'),
                        ),
                        ...?snapshot.data?.map(
                          (h) => ListTile(
                            leading: const Icon(Icons.history),
                            title: Text(h.query),
                            onTap: () {
                              controller.text = h.query;
                              search(h.query, remember: true);
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        installed.every((d) => !d.enabled)
                            ? 'All dictionaries are disabled. Enable one in the dictionary manager.'
                            : 'No results. Try a shorter word or another dictionary.',
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: results.length + 2,
                    itemBuilder: (context, i) => i == 0
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${results.length} matches',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge,
                                  ),
                                ),
                                if (hasJapanese(controller.text))
                                  IconButton(
                                    tooltip: 'Explore sentence',
                                    onPressed: () =>
                                        exploreText(context, controller.text),
                                    icon: const Icon(
                                      Icons.account_tree_outlined,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : i == results.length + 1
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Showing up to 100 results. Refine your search for more.',
                            ),
                          )
                        : WordCard(result: results[i - 1]),
                  ),
          ),
        ],
      );
    },
  );
}

class WordCard extends ConsumerWidget {
  const WordCard({required this.result, super.key});
  final WordResult result;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = result.term;
    final colors = Theme.of(context).colorScheme;
    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => WordDetailPage(result: result)),
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.expression,
                          style: readingStyle(
                            context,
                            Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        if (word.reading.isNotEmpty)
                          Text(
                            word.reading,
                            style: readingStyle(
                              context,
                              TextStyle(color: colors.primary, fontSize: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Save word',
                    icon: const Icon(Icons.bookmark_add_outlined),
                    onPressed: () async {
                      try {
                        await ref.read(repositoryProvider).save(result);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved to vocabulary'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) showError(context, e);
                      }
                    },
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag
                      in word.tags
                          .split(' ')
                          .where((t) => t.isNotEmpty)
                          .take(5))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
              if (result.inflection.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Matched via ${result.inflection.join(' → ')}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.primary),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                word.definitions,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: readingStyle(
                  context,
                  Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.source,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Explore word',
                    onPressed: open,
                    icon: const Icon(Icons.north_east, size: 19),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VocabularyPage extends ConsumerWidget {
  const VocabularyPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(repositoryProvider).user;
    return StreamBuilder<List<SavedWord>>(
      stream: (user.select(
        user.savedWords,
      )..orderBy([(w) => drift.OrderingTerm.desc(w.created)])).watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not read saved words.'));
        }
        final words = snapshot.data ?? [];
        if (words.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Your vocabulary starts here.\nSave a word from dictionary results.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          children: [
            const ListTile(
              title: Text('Saved vocabulary'),
              subtitle: Text('Kept even if you remove the dictionary.'),
            ),
            ...words.map(
              (w) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  isThreeLine: true,
                  onTap: () => exploreText(context, w.expression),
                  title: Text(
                    '${w.expression}  ${w.reading}',
                    style: readingStyle(
                      context,
                      Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  subtitle: Text('${w.definitions}\n${w.source}'),
                  trailing: IconButton(
                    tooltip: 'Remove saved word',
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    onPressed: () async {
                      if (await confirm(
                        context,
                        'Remove ${w.expression} from vocabulary?',
                      )) {
                        try {
                          await (user.delete(
                            user.savedWords,
                          )..where((v) => v.id.equals(w.id))).go();
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<bool> confirm(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.close),
          ),
          IconButton.filled(
            tooltip: 'Remove',
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    ) ??
    false;

class DictionaryManager extends ConsumerStatefulWidget {
  const DictionaryManager({super.key});
  @override
  ConsumerState<DictionaryManager> createState() => _DictionaryManagerState();
}

class _DictionaryManagerState extends ConsumerState<DictionaryManager> {
  bool busy = false;
  String status = '';
  ImportControl? control;
  late final db = ref.read(repositoryProvider).db;
  late final stream = (db.select(
    db.dictionaries,
  )..orderBy([(d) => drift.OrderingTerm.desc(d.priority)])).watch();
  Future<void> importFiles() async {
    if (busy) return;
    setState(() {
      busy = true;
      status = 'Choose dictionary ZIP files';
    });
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (selection.isEmpty) return;
      for (final file in selection) {
        if (file.path == null) {
          throw ImportFailure('The selected file could not be opened.');
        }
        control = ImportControl();
        await importDictionary(
          file.path!,
          db,
          control: control,
          progress: (message) {
            if (mounted) setState(() => status = '${file.name}: $message');
          },
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dictionary import complete')),
        );
      }
    } on ImportCancelled {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import cancelled. No partial dictionary was kept.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      try {
        await FilePicker.clearTemporaryFiles();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Temporary ZIP cleanup failed. Android may reclaim the import cache later.',
              ),
            ),
          );
        }
      }
      control = null;
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    control?.cancelled = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Dictionaries')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bring your own dictionary',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Import a Yomitan format-3 word or character dictionary you are authorized to use. Your dictionaries stay on this device.',
                ),
                const SizedBox(height: 12),
                IconButton.filled(
                  key: const Key('import'),
                  onPressed: busy ? null : importFiles,
                  icon: const Icon(Icons.add),
                  tooltip: 'Import ZIP files',
                ),
                if (busy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                  Text(status),
                  IconButton(
                    tooltip: 'Cancel import',
                    onPressed: () => control?.cancelled = true,
                    icon: const Icon(Icons.cancel_outlined),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Dictionary>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not read dictionaries.'),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No dictionaries installed.'),
                  );
                }
                return ListView(
                  children: items
                      .map(
                        (d) => Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(d.title),
                                  subtitle: Text(
                                    '${(jsonDecode(d.metadata) as Map)['yomipeekKind'] ?? 'Vocabulary'} · format 3\nRevision ${d.revision}\n${d.entries} entries · ${(d.bytes / 1048576).toStringAsFixed(1)} MiB source',
                                  ),
                                  value: d.enabled,
                                  onChanged: busy
                                      ? null
                                      : (v) => change(
                                          () =>
                                              (db.update(db.dictionaries)
                                                    ..where(
                                                      (t) => t.id.equals(d.id),
                                                    ))
                                                  .write(
                                                    DictionariesCompanion(
                                                      enabled: drift.Value(v),
                                                    ),
                                                  ),
                                        ),
                                ),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text('Priority ${d.priority}'),
                                    IconButton(
                                      tooltip: 'Lower priority',
                                      onPressed: busy
                                          ? null
                                          : () => priority(d, -1),
                                      icon: const Icon(Icons.remove),
                                    ),
                                    IconButton(
                                      tooltip: 'Higher priority',
                                      onPressed: busy
                                          ? null
                                          : () => priority(d, 1),
                                      icon: const Icon(Icons.add),
                                    ),
                                    IconButton(
                                      tooltip: 'Dictionary information',
                                      onPressed: () => showDialog<void>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(d.title),
                                          content: SingleChildScrollView(
                                            child: SelectableText(
                                              const JsonEncoder.withIndent(
                                                '  ',
                                              ).convert(jsonDecode(d.metadata)),
                                            ),
                                          ),
                                          actions: [
                                            IconButton(
                                              tooltip: 'Close',
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              icon: const Icon(Icons.close),
                                            ),
                                          ],
                                        ),
                                      ),
                                      icon: const Icon(Icons.info_outline),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete dictionary',
                                      onPressed: busy
                                          ? null
                                          : () async {
                                              if (await confirm(
                                                context,
                                                'Delete ${d.title}? Saved vocabulary will be kept.',
                                              )) {
                                                await change(
                                                  () =>
                                                      (db.delete(
                                                            db.dictionaries,
                                                          )..where(
                                                            (t) => t.id.equals(
                                                              d.id,
                                                            ),
                                                          ))
                                                          .go(),
                                                );
                                              }
                                            },
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
  Future<void> change(Future<dynamic> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void priority(Dictionary d, int delta) => change(
    () => (db.update(db.dictionaries)..where((t) => t.id.equals(d.id))).write(
      DictionariesCompanion(priority: drift.Value(d.priority + delta)),
    ),
  );
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    children: [
      const ListTile(title: Text('Appearance')),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonFormField<ThemeMode>(
          key: ValueKey(ref.watch(themeProvider)),
          initialValue: ref.watch(themeProvider),
          decoration: const InputDecoration(labelText: 'Theme'),
          items: ThemeMode.values
              .map(
                (mode) => DropdownMenuItem(value: mode, child: Text(mode.name)),
              )
              .toList(),
          onChanged: (mode) async {
            if (mode != null) {
              try {
                await ref.read(themeProvider.notifier).set(mode);
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            }
          },
        ),
      ),
      ListTile(
        leading: const Icon(Icons.font_download_outlined),
        title: const Text('Japanese typography'),
        subtitle: const Text('Mincho, Gothic, rounded and your own fonts'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const FontSettingsPage()),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.library_books_outlined),
        title: const Text('Dictionaries'),
        onTap: () => Navigator.pushNamed(context, '/dictionaries'),
      ),
      ListTile(
        leading: const Icon(Icons.picture_in_picture_alt),
        title: const Text('Floating lookup'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const FloatingSettingsPage()),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.history),
        title: const Text('Clear search history'),
        onTap: () async {
          try {
            await ref
                .read(repositoryProvider)
                .user
                .delete(ref.read(repositoryProvider).user.history)
                .go();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search history cleared')),
              );
            }
          } catch (e) {
            if (context.mounted) showError(context, e);
          }
        },
      ),
      ListTile(
        title: const Text('Open-source licenses'),
        onTap: () =>
            showLicensePage(context: context, applicationName: 'YomiPeek'),
      ),
      const ListTile(
        title: Text('Privacy'),
        subtitle: Text(
          'No account, telemetry, or remote lookup. Dictionary imports and saved vocabulary remain on your device.',
        ),
      ),
      const ListTile(
        title: Text('About YomiPeek'),
        subtitle: Text(
          'Japanese at a glance.\nAn offline dictionary for curious readers.',
        ),
      ),
    ],
  );
}
