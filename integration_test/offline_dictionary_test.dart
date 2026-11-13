import 'dart:io';

import 'package:flutter/services.dart';
import 'package:yomipeek/features/appearance/fonts.dart';
import 'package:yomipeek/features/appearance/font_settings_page.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yomipeek/app/app.dart';
import 'package:yomipeek/core/database/database.dart';
import 'package:yomipeek/features/dictionary/data/repository.dart';
import 'package:yomipeek/features/dictionary/import/importer.dart';

import '../test/fixture.dart';

import 'package:yomipeek/features/dictionary/explorer/explorer.dart';

import 'package:yomipeek/core/platform/android_gateway.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android import, lookup, bookmark, reopen, disable and removal', (
    tester,
  ) async {
    final root = await getTemporaryDirectory();
    final directory = await Directory(
      '${root.path}/integration-${DateTime.now().millisecondsSinceEpoch}',
    ).create();
    final dictionaryFile = File('${directory.path}/dictionary.sqlite');
    final userFile = File('${directory.path}/user.sqlite');
    var db = DictionaryDb.file(dictionaryFile);
    var user = UserDb.file(userFile);
    var repo = DictionaryRepository(db, user);
    final zip = await fixture(directory);
    await importDictionary(zip.path, db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const YomiPeekApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search')), '食べました');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.text('食べる'), findsOneWidget);
    expect(find.text('Matched via polite past'), findsOneWidget);
    await tester.tap(find.byTooltip('Save word'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is NavigationDestination && widget.label == 'Vocabulary',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('synthetic meal action'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await db.close();
    await user.close();
    db = DictionaryDb.file(dictionaryFile);
    user = UserDb.file(userFile);
    repo = DictionaryRepository(db, user);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const YomiPeekApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('食べました'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is NavigationDestination && widget.label == 'Vocabulary',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('synthetic meal action'), findsOneWidget);
    await tester.tap(find.byTooltip('Manage dictionaries'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(await repo.search('meal'), isEmpty);
    await tester.tap(find.byTooltip('Delete dictionary'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('No dictionaries installed.'), findsOneWidget);
    expect(await user.select(user.savedWords).get(), hasLength(1));
    final bad = await fixture(directory, revision: 'bad', malformed: true);
    await expectLater(
      importDictionary(bad.path, db),
      throwsA(isA<ImportFailure>()),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await db.close();
    await user.close();
    await directory.delete(recursive: true);
  });
  testWidgets(
    'native permission status and floating settings need no permission grant',
    (tester) async {
      final db = DictionaryDb.file(
        File(
          '${(await getTemporaryDirectory()).path}/native-status-dictionary.sqlite',
        ),
      );
      final user = UserDb.file(
        File(
          '${(await getTemporaryDirectory()).path}/native-status-user.sqlite',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(
              DictionaryRepository(db, user),
            ),
          ],
          child: const YomiPeekApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomePage)),
      );
      final state = await container.read(androidProvider).state();
      expect(state.available, true);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is NavigationDestination && widget.label == 'Settings',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Floating lookup'));
      await tester.pumpAndSettle();
      expect(find.text('Display over other apps'), findsOneWidget);
      expect(find.text('Clipboard privacy'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
      await user.close();
    },
  );
  testWidgets(
    'dictionary browser follows an example into another entry and back',
    (tester) async {
      final directory = await Directory(
        '${(await getTemporaryDirectory()).path}/explorer-${DateTime.now().millisecondsSinceEpoch}',
      ).create();
      final db = DictionaryDb.file(File('${directory.path}/dictionary.sqlite'));
      final user = UserDb.file(File('${directory.path}/user.sqlite'));
      final repo = DictionaryRepository(db, user);
      await importDictionary((await fixture(directory, rich: true)).path, db);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: const YomiPeekApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('search')), '食べました');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await tester.tap(find.byTooltip('Explore word'));
      await tester.pumpAndSettle();
      final example = find.text('食べました。読んでいる。');
      await tester.ensureVisible(example);
      await tester.tap(example);
      await tester.pumpAndSettle();
      expect(find.text('Explore text'), findsOneWidget);
      final readChip = find.byWidgetPredicate(
        (w) =>
            w is ActionChip &&
            w.label is Text &&
            (w.label as Text).data == '読んでいる',
      );
      await tester.ensureVisible(readChip);
      await tester.tap(readChip);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.text('読む'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Explore word'));
      await tester.tap(find.byTooltip('Explore word'));
      await tester.pumpAndSettle();
      expect(find.byType(WordDetailPage), findsOneWidget);
      expect(find.text('読む'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Explore text'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<WordDetailPage>(find.byType(WordDetailPage))
            .result
            .term
            .expression,
        '食べる',
      );
      // The persisted native preference matches changes from the Flutter theme setting.
      final context = tester.element(find.byType(WordDetailPage));
      final container = ProviderScope.containerOf(context);
      final previous = (await container.read(androidProvider).state()).theme;
      await container.read(androidProvider).setTheme('dark');
      expect((await container.read(androidProvider).state()).theme, 'dark');
      await container.read(androidProvider).setTheme('light');
      expect((await container.read(androidProvider).state()).theme, 'light');
      await container.read(androidProvider).setTheme(previous);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
      await user.close();
      await directory.delete(recursive: true);
    },
  );
  testWidgets(
    'Japanese presets and imported font survive preference reload and mirror to native popup',
    (tester) async {
      final root = await Directory(
        '${(await getTemporaryDirectory()).path}/fonts-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final db = DictionaryDb.file(File('${root.path}/dictionary.sqlite'));
      final user = UserDb.file(File('${root.path}/user.sqlite'));
      const channel = MethodChannel('org.yomipeek/platform');
      final previous = await channel.invokeMapMethod<String, dynamic>(
        'typography',
      );
      File? importedFile;
      addTearDown(() async {
        await channel.invokeMethod<void>(
          'setTypography',
          previous ?? {'key': 'system'},
        );
        if (importedFile != null && await importedFile.exists()) {
          await importedFile!.delete();
        }
        await db.close();
        await user.close();
        await root.delete(recursive: true);
      });
      Widget screen() => ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(DictionaryRepository(db, user)),
        ],
        child: const MaterialApp(home: FontSettingsPage()),
      );
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      var container = ProviderScope.containerOf(
        tester.element(find.byType(FontSettingsPage)),
      );
      await container
          .read(japaneseFontsProvider.notifier)
          .save(
            container
                .read(japaneseFontsProvider)
                .copyWith(selected: 'mincho', scale: 1.1, lineHeight: 1.8),
          );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('font-preview')))
            .style!
            .fontFamily,
        'YomiNotoSerifJP',
      );
      expect(
        (await container.read(androidProvider).typography())['key'],
        'mincho',
      );
      final data = await rootBundle.load(
        'assets/fonts/zen-maru-gothic/font.ttf',
      );
      final source = File('${root.path}/My Japanese.ttf');
      await source.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      await container
          .read(japaneseFontsProvider.notifier)
          .importFont(source.path, 'My Japanese.ttf');
      await source.delete();
      final selected = container.read(japaneseFontsProvider);
      importedFile = File(
        '${(await container.read(japaneseFontsProvider.notifier).directory).path}/${selected.custom!.file}',
      );
      expect(await importedFile.exists(), true);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('font-preview')))
            .style!
            .fontFamily,
        selected.family,
      );
      final broken = File('${root.path}/broken.ttf');
      await broken.writeAsString('not a font');
      await expectLater(
        container
            .read(japaneseFontsProvider.notifier)
            .importFont(broken.path, 'broken.ttf'),
        throwsA(isA<FontImportFailure>()),
      );
      expect(container.read(japaneseFontsProvider).selected, selected.selected);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      container = ProviderScope.containerOf(
        tester.element(find.byType(FontSettingsPage)),
      );
      // A no-op frame wait lets the asynchronous preference restore and native acknowledgement finish.
      for (
        var i = 0;
        i < 20 &&
            container.read(japaneseFontsProvider).selected != selected.selected;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(container.read(japaneseFontsProvider).selected, selected.selected);
      expect(container.read(japaneseFontsProvider).scale, 1.1);
      final native = await container.read(androidProvider).typography();
      expect(native['key'], selected.selected);
      expect(native['lineHeight'], closeTo(1.8, .01));
      await container
          .read(japaneseFontsProvider.notifier)
          .remove(selected.custom!);
      expect(container.read(japaneseFontsProvider).selected, 'system');
      expect(await importedFile.exists(), false);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
